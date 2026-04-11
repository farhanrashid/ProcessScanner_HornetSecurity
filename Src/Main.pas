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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FNodeMap : TSnapshot;
    FRootNode : TProcessNode;

  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  node   : TProcessNode;
begin
  FNodeMap := GetSnapshot;
  FRootNode := TProcessNode.Create;

  for node in FNodeMap.Values do
    memoLog.Lines.Add(node.ProcessInfo.ExeName + '=' + node.ProcessInfo.ExePath);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FNodeMap) then FNodeMap.Free;
  FRootNode.Free;
end;

end.
