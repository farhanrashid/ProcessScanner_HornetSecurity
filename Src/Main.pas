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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
  private
    { Private declarations }
    FSnapshot : TSnapshot;
    FRootNode : TProcessNode;
    FinRefresh : Boolean;
    procedure RefreshView;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  RefreshView;
end;

procedure TfrmMain.RefreshView;
var
  node   : TProcessNode;
  oldSnapshot : TSnapshot;
  oldRootNode : TProcessNode;
begin
  if FinRefresh then exit;
  FinRefresh := True;

  oldSnapshot := FSnapshot;
  oldRootNode := FRootNode;

  try
    FSnapshot := GetSnapshot;
    FRootNode := TProcessNode.Create;

    for node in FSnapshot.Values do
      memoLog.Lines.Add(node.ExeName + '=' + node.PID.ToString + '=' + node.ParentPID.ToString);
  finally
    if Assigned(oldSnapshot) then oldSnapshot.Free;
    if Assigned(oldRootNode) then oldRootNode.Free;
    FinRefresh := False;
  end;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FSnapshot := Nil;
  FRootNode := Nil;
  FinRefresh := False;
  RefreshView;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FSnapshot) then FSnapshot.Free;
  FRootNode.Free;
end;

end.
