unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  System.Types, System.Generics.Collections, ProcessNode;

type

  TfrmMain = class(TForm)
    pnlSettings: TPanel;
    pnlMain: TPanel;
    pnlDetails: TPanel;
    pnlLog: TPanel;
    memoLog: TMemo;
    lblLog: TLabel;
    lblDetails: TLabel;
    Label1: TLabel;
    tvProcesses: TTreeView;
    cbSystemProcess: TCheckBox;
    cbProcessOtherUsers: TCheckBox;
    lvDetails: TListView;
    btnRefresh: TButton;
    CountdownTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure CountdownTimerTimer(Sender: TObject);
    procedure tvProcessesChange(Sender: TObject; Node: TTreeNode);
    procedure tvProcessesCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
  private
    { Private declarations }
    FSnapshot : TSnapshot;
    FRootNode : TProcessNode;
    FinRefresh : Boolean;
    FCountdown : Integer;
    procedure Refresh;
    procedure RebuildTreeView(aOldSnapshot: TSnapshot; aOldRootNode: TProcessNode);
    procedure PopulateNode(ParentItem: TTreeNode; Node: TProcessNode);
    procedure PopulateNewNode(aNewNode, aOldNode: TProcessNode);
  public
    { Public declarations }
    procedure AddLog(aMessage : string);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}
const
  COUNTDOWN_START = 10;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  Refresh;
end;

procedure TfrmMain.Refresh;
var
  node, Parent : TProcessNode;
  oldSnapshot : TSnapshot;
  oldRootNode : TProcessNode;
begin
  if FinRefresh then exit;
  FinRefresh := True;
  CountdownTimer.Enabled := False;

  oldSnapshot := FSnapshot;
  oldRootNode := FRootNode;

  try
    FSnapshot := GetSnapshot;
    FRootNode := TProcessNode.Create;

    for node in FSnapshot.Values do
    begin
      //AddLog(node.ExeName + '=' + node.PID.ToString + '=' + node.ParentPID.ToString);

      if (node.PID = 0) or not FSnapshot.TryGetValue(node.ParentPID, Parent) then
        Parent := FRootNode;

      Parent.Childs.Add(node.PID, node);
      node.ParentNode := Parent;

    end;

    RebuildTreeView(oldSnapshot, oldRootNode);

  finally
    if Assigned(oldSnapshot) then oldSnapshot.Free;
    if Assigned(oldRootNode) then oldRootNode.Free;
    FinRefresh := False;
    FCountdown := COUNTDOWN_START;
    CountdownTimer.Enabled := True;
  end;

end;

procedure TfrmMain.tvProcessesChange(Sender: TObject; Node: TTreeNode);
var
  pid : DWORD;
  ProcessNode: TProcessNode;
begin
  if not Assigned(Node) then Exit;

  pid := DWORD(NativeUInt(Node.Data));

  if FSnapshot.TryGetValue(pid, ProcessNode) then
  begin
    lvDetails.Items[0].SubItems[0] := ProcessNode.ExePath;
    lvDetails.Items[1].SubItems[0] := ProcessNode.PID.ToString;
    lvDetails.Items[2].SubItems[0] := ProcessNode.SessionID.ToString;

  end;
end;

procedure TfrmMain.tvProcessesCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  pid : DWORD;
  ProcessNode: TProcessNode;
begin

  pid := DWORD(NativeUInt(Node.Data));
  if FSnapshot.TryGetValue(pid, ProcessNode) then
  begin
    if ProcessNode.IsScanFound then
      Sender.Canvas.Font.Color := clBlue
    else if ProcessNode.ScanResult = srNotFound then
      Sender.Canvas.Font.Color := clRed
    else if ProcessNode.ScanResult = srAccessDenied then
      Sender.Canvas.Font.Color := clGreen;
  end;
end;

procedure TfrmMain.RebuildTreeView(aOldSnapshot: TSnapshot; aOldRootNode: TProcessNode);
var
  node: TProcessNode;
  pid : DWORD;
begin
  tvProcesses.Items.BeginUpdate;
  tvProcesses.Enabled := False;
  try
    if not Assigned(aOldSnapshot) or not Assigned(aOldRootNode) then  //first run
    begin
      tvProcesses.Items.Clear;
      for node in FRootNode.Childs.Values do
        PopulateNode(nil, node);
    end
    else  //successive refresh
    begin

      for pid in aOldSnapshot.Keys do
      begin
        if not FSnapshot.TryGetValue(pid, node) then  // delete killed/gone processes
          aOldSnapshot[pid].TreeNode.Delete
        else
          node.TreeNode := aOldSnapshot[pid].TreeNode; // update retained processes
      end;

      //Add only new nodes
      PopulateNewNode(FRootNode, aOldRootNode);

    end;

    //update Scan Result
    for Node in FSnapshot.Values do
    begin
      //TODO : new dictionary
      if Node.ExeName = 'plugin_host-3.8.exe' then
        Node.ScanResult := srFound;
    end;

  finally
    tvProcesses.Enabled := True;
    tvProcesses.Items.EndUpdate;
  end;

end;

procedure TfrmMain.PopulateNewNode(aNewNode, aOldNode: TProcessNode);
var
  node: TProcessNode;
  pid : DWORD;
begin
  for pid in aNewNode.Childs.Keys do
  begin
    if not aOldNode.Childs.TryGetValue(pid, node) then  //add new
      PopulateNode(aNewNode.Childs[pid].ParentNode.TreeNode, aNewNode.Childs[pid])
    else
      PopulateNewNode(aNewNode.Childs[pid], node);
  end;
end;

procedure TfrmMain.PopulateNode(ParentItem: TTreeNode; Node: TProcessNode);
var
  item  : TTreeNode;
  child : TProcessNode;
begin
  if ParentItem = nil then
    item := tvProcesses.Items.AddObject(nil, Node.ExeName, Pointer(NativeUInt(Node.PID)))
  else
    item := tvProcesses.Items.AddChildObject(ParentItem, Node.ExeName, Pointer(NativeUInt(Node.PID)));

  Node.TreeNode := item;

  for child in Node.Childs.Values do
    PopulateNode(item, child);

  item.Expanded := True;//(Node.ExeName <> 'services.exe') or (Node.Childs.Count < 20); //dont expand service by default

end;

procedure TfrmMain.CountdownTimerTimer(Sender: TObject);
begin
  Dec(FCountdown);
  btnRefresh.Caption := Format('Refresh Now (%ds)', [FCountdown]);

  if FCountdown <= 0 then
    Refresh;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FSnapshot := Nil;
  FRootNode := Nil;
  FinRefresh := False;
  Refresh;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FSnapshot) then FSnapshot.Free;
  FRootNode.Free;
end;

procedure TfrmMain.AddLog(aMessage : string);
begin
  memoLog.Lines.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + aMessage);
end;

end.
