unit ProcessNode;

interface

uses
  System.Classes, System.Types, System.Generics.Collections;

type

  TProcessInfo = record
    PID        : DWORD;
    ParentPID  : DWORD;
    ExeName    : string;   // file name only
    ExePath    : string;   // full path
    SessionID  : DWORD;
  end;

  TProcessNode = class
  public
    ProcessInfo : TProcessInfo;
    Childs   : TObjectList<TProcessNode>;
    constructor Create;
    destructor Destroy; override;
  end;

  TSnapshot = TDictionary<DWORD, TProcessNode>; // PID -> ProcessNode

  function GetSnapshot: TSnapshot;

implementation

uses Windows, TLHelp32, System.SysUtils, WinUtils;

constructor TProcessNode.Create;
begin
  inherited;
  Childs := TObjectList<TProcessNode>.Create(True); // owns object True
end;

destructor TProcessNode.Destroy;
begin
  Childs.Free;
  inherited;
end;


function GetSnapshot: TSnapshot;
var
  hSnap  : THandle;
  pe32   : TProcessEntry32W;
  node   : TProcessNode;
  FilePath : String;
  ImageNames : TDictionary<WORD, String>;
begin
  Result := TSnapshot.Create;

  // Try to enable debug privilege first (best effort - continues even if it fails)
  EnableDebugPrivilege;

  ImageNames := GetAllImageNames;

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
      FilePath := GetProcessFilePath(pe32.th32ProcessID);

      if (FilePath = '') then
        ImageNames.TryGetValue(pe32.th32ProcessID, FilePath);

      node.ProcessInfo.ExePath   := FilePath;
      node.ProcessInfo.SessionID := QuerySessionID(pe32.th32ProcessID);

      Result.Add(node.ProcessInfo.PID, node);
    until not Process32NextW(hSnap, pe32);
  finally
    CloseHandle(hSnap);
    ImageNames.Free;
  end;
end;

end.
