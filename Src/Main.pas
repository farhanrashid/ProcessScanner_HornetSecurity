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
  private
    { Private declarations }
    FSnapshot : TSnapshot;
    FRootNode : TProcessNode;
    FinRefresh : Boolean;
    FCountdown : Integer;
    procedure Refresh;
    procedure RebuildTreeView;
    procedure PopulateNode(ParentItem: TTreeNode; Node: TProcessNode);
  public
    { Public declarations }
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
      memoLog.Lines.Add(node.ExeName + '=' + node.PID.ToString + '=' + node.ParentPID.ToString);

      if (node.PID = 0) or not FSnapshot.TryGetValue(node.ParentPID, Parent) then
        Parent := FRootNode;

      Parent.Childs.Add(node.PID, node);

    end;

    RebuildTreeView;

  finally
    if Assigned(oldSnapshot) then oldSnapshot.Free;
    if Assigned(oldRootNode) then oldRootNode.Free;
    FinRefresh := False;
    FCountdown := COUNTDOWN_START;
    CountdownTimer.Enabled := True;
  end;

end;

procedure TfrmMain.RebuildTreeView;
var
  node: TProcessNode;
begin
  tvProcesses.Items.BeginUpdate;
  try
    tvProcesses.Items.Clear;
    for node in FRootNode.Childs.Values do
      PopulateNode(nil, node);
  finally
    tvProcesses.Items.EndUpdate;
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

  for child in Node.Childs.Values do
    PopulateNode(item, child);
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

end.
