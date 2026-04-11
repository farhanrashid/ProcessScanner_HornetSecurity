unit ProcessNode;

interface

uses
  System.Classes, System.Types, System.Generics.Collections;

type

  TProcessNode = class;   //forward declararion
  TSnapshot = TObjectDictionary<DWORD, TProcessNode>; // PID -> ProcessNode

  TProcessNode = class
  public
    PID        : DWORD;
    ParentPID  : DWORD;
    ExeName    : string;   // file name only
    ExePath    : string;   // full path
    SessionID  : DWORD;

    Childs   : TSnapshot;
    constructor Create;
    destructor Destroy; override;
  end;

  function GetSnapshot: TSnapshot;

implementation

uses Windows, TLHelp32, System.SysUtils, WinUtils;

constructor TProcessNode.Create;
begin
  inherited;
  Childs := TSnapshot.Create; // dont own objects
end;

destructor TProcessNode.Destroy;
begin
  Childs.Free;
  inherited;
end;


// ---------------------------------------------------------------------------
// GetSnapshot
// - The caller is fully responsible for freeing the returned TSnapshot object.
// ---------------------------------------------------------------------------

function GetSnapshot: TSnapshot;
var
  hSnap  : THandle;
  pe32   : TProcessEntry32W;
  node   : TProcessNode;
  FilePath : String;
  FilePaths : TDictionary<DWORD, String>;
begin
  Result := TSnapshot.Create([doOwnsValues]);  // own objects

  // Try to enable debug privilege first (best effort - continues even if it fails)
  EnableDebugPrivilege;

  try
    FilePaths := GetAllFilePaths;

    hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if hSnap = INVALID_HANDLE_VALUE then
      Exit;

    try
      pe32.dwSize := SizeOf(pe32);
      if not Process32FirstW(hSnap, pe32) then
        Exit;

      repeat
        node := TProcessNode.Create;
        node.PID       := pe32.th32ProcessID;
        node.ParentPID := pe32.th32ParentProcessID;
        node.ExeName   := ExtractFileName(pe32.szExeFile);
        FilePath := GetProcessFilePath(pe32.th32ProcessID);

        if (FilePath = '') then
          FilePaths.TryGetValue(node.PID, FilePath);

        node.ExePath   := FilePath;
        node.SessionID := QuerySessionID(pe32.th32ProcessID);

        Result.Add(node.PID, node);
      until not Process32NextW(hSnap, pe32);
    finally
      CloseHandle(hSnap);
    end;

  finally
    FilePaths.Free;
  end;
end;

end.
