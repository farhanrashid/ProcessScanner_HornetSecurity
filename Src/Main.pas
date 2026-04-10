unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls,
  System.Types, System.Generics.Collections,
  ProcessNode;

type
  TSnapshot = TDictionary<DWORD, TProcessNode>; // PID -> ProcessNode

  UNICODE_STRING = record
    Length: USHORT;
    MaximumLength: USHORT;
    Buffer: PWideChar;
  end;

  TSystemProcessInformation = packed record
    NextEntryOffset: ULONG;
    NumberOfThreads: ULONG;
    Reserved1: array[0..5] of IntPtr;
    CreateTime: Int64;
    UserTime: Int64;
    KernelTime: Int64;
    ImageName: UNICODE_STRING;
    BasePriority: LongInt;
    UniqueProcessId: Pointer;
    InheritedFromUniqueProcessId: Pointer;
  end;

  PSystemProcessInformation = ^TSystemProcessInformation;

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
    function GetProcessList: TSnapshot;

  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses TLHelp32;

const
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
  SystemProcessInformation = 5;

function QueryFullProcessImageNameW(hProcess: THandle; dwFlags: DWORD;
  lpExeName: PWideChar; var lpdwSize: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'QueryFullProcessImageNameW';

function NtQuerySystemInformation(
  SystemInformationClass: ULONG;
  SystemInformation: Pointer;
  SystemInformationLength: ULONG;
  ReturnLength: PULONG
): NTSTATUS; stdcall; external 'ntdll.dll';

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  node   : TProcessNode;
begin
  FNodeMap := GetSnapshot; //TODO GetProcessList;
  FRootNode := TProcessNode.Create;

  for node in FNodeMap.Values do
    memoLog.Lines.Add(node.ProcessInfo.ExeName + '=' + node.ProcessInfo.ExePath);
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
    hProc := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION or PROCESS_VM_READ, False, PID);
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

function TfrmMain.GetProcessList: TSnapshot;
var
  Buffer: Pointer;
  Size: ULONG;
  Status: NTSTATUS;
  Proc: PSystemProcessInformation;
  node   : TProcessNode;

begin
  Result := TSnapshot.Create;
  Size := 0;

  GetMem(Buffer, 1024 * 1024 * 10); // 10MB initial buffer

  try
    while True do
    begin
      Status := NtQuerySystemInformation(
        SystemProcessInformation,
        Buffer,
        Size,
        @Size
      );

      if Status = 0 then
        Break;

      if Status = $C0000004 {STATUS_INFO_LENGTH_MISMATCH} then
      begin
        ReallocMem(Buffer, Size);
        Continue;
      end;

      Exit;
    end;

    Proc := Buffer;

    while True do
    begin
      node := TProcessNode.Create;
      node.ProcessInfo.PID       := DWORD(NativeUInt(Proc^.UniqueProcessId));
      node.ProcessInfo.ParentPID := DWORD(NativeUInt(Proc^.InheritedFromUniqueProcessId));
      node.ProcessInfo.ExeName   := string(Proc^.ImageName.Buffer);
      node.ProcessInfo.ExePath   := string(Proc^.ImageName.Buffer);

      Result.Add(node.ProcessInfo.PID, node);
      if Proc^.NextEntryOffset = 0 then
        Break;

      Proc := PSystemProcessInformation(
        NativeUInt(Proc) + Proc^.NextEntryOffset
      );
    end;

  finally
    FreeMem(Buffer);
  end;
end;

end.
