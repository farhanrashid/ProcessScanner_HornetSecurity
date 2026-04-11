program TaskManager;

uses
  Vcl.Forms,
  Main in 'Src\Main.pas' {frmMain},
  ProcessNode in 'Src\ProcessNode.pas',
  WinUtils in 'Src\WinUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
