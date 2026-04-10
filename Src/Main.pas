unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  System.Types, System.Generics.Collections,
  ProcessNode;

type
  TSnapshot = TDictionary<DWORD, TProcessNode>; // PID -> ProcessNode
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

    function GetSnapshot: TSnapshot;

  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses TLHelp32;

const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;

function QueryFullProcessImageNameW(hProcess: THandle; dwFlags: DWORD;
  lpExeName: PWideChar; var lpdwSize: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'QueryFullProcessImageNameW';

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FNodeMap := GetSnapshot;
  FRootNode := TProcessNode.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FNodeMap) then FNodeMap.Free;
  FRootNode.Free;
end;

function TfrmMain.GetSnapshot: TSnapshot;
var
  hSnap  : THandle;
  pe32   : TProcessEntry32W;
  node   : TProcessNode;

  function QueryFullPath(PID: DWORD): string;
  var
    hProc : THandle;
    buf   : array[0..MAX_PATH] of WideChar;
    len   : DWORD;
  begin
    Result := '';
    // TODO : not working for system processes
    hProc := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, PID);
    if hProc = 0 then
      Exit;
    try
      len := MAX_PATH + 1;
      if QueryFullProcessImageNameW(hProc, 0, buf, len) then
        Result := buf;
    finally
      CloseHandle(hProc);
    end;
  end;

  function QuerySessionID(PID: DWORD): DWORD;
  var
    sid: DWORD;
  begin
    Result := DWORD(-1);
    if ProcessIdToSessionId(PID, sid) then
      Result := sid;
  end;

begin
  Result := TSnapshot.Create;

  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnap = INVALID_HANDLE_VALUE then
    Exit;
  try
    pe32.dwSize := SizeOf(pe32);
    if not Process32FirstW(hSnap, pe32) then
      Exit;

    repeat
      node := TProcessNode.Create;
      node.ProcessInfo.PID       := pe32.th32ProcessID;
      node.ProcessInfo.ParentPID := pe32.th32ParentProcessID;
      node.ProcessInfo.ExeName   := ExtractFileName(pe32.szExeFile);
      node.ProcessInfo.ExePath   := QueryFullPath(pe32.th32ProcessID);
      node.ProcessInfo.SessionID := QuerySessionID(pe32.th32ProcessID);

      Result.Add(node.ProcessInfo.PID, node);
    until not Process32NextW(hSnap, pe32);
  finally
    CloseHandle(hSnap);
  end;
end;

end.
