unit ProcessNode;

interface

uses
  System.Classes, System.Types, System.Generics.Collections, Vcl.ComCtrls;

type
  TScanResult = (
    srPending,       // Not yet analysed
    srFound,         // "https://" found inside the file
    srNotFound,      // File was read; "https://" not present
    srAccessDenied   // File could not be opened / read
  );

  TProcessNode = class;   //forward declararion
  TSnapshot = TObjectDictionary<DWORD, TProcessNode>; // PID -> ProcessNode

  TProcessNode = class
  private
    FScanResult        : TScanResult;
    FScanFoundInChild  : Boolean;  //Keep Track of srFound in Childs

    procedure SetScanResult(aValue : TScanResult);
    procedure SetScanFoundInChild(aValue : Boolean);
  public
    PID               : DWORD;
    ParentPID         : DWORD;
    ExeName           : string;   // file name only
    ExePath           : string;   // full path
    SessionID         : DWORD;
    TreeNode          : TTreeNode;
    ParentNode        : TProcessNode;


    Childs   : TSnapshot;

    function IsScanFound: Boolean;

    property ScanResult: TScanResult read FScanResult write SetScanResult;
    property ScanFoundInChild: Boolean read FScanFoundInChild write SetScanFoundInChild;

    constructor Create;
    destructor Destroy; override;
  end;

  function GetSnapshot: TSnapshot;

implementation

uses Windows, TLHelp32, System.SysUtils, WinUtils;

constructor TProcessNode.Create;
begin
  inherited;
  ParentNode := Nil;
  ScanResult := srPending;
  ScanFoundInChild := False;
  Childs := TSnapshot.Create; // dont own objects
end;

destructor TProcessNode.Destroy;
begin
  Childs.Free;
  inherited;
end;

procedure TProcessNode.SetScanResult(aValue : TScanResult);
begin
  if (aValue = srFound) and (FScanResult <> srFound) then
  begin
    if Assigned(ParentNode) then
      ParentNode.ScanFoundInChild := True;
  end;

  FScanResult := aValue;
end;

procedure TProcessNode.SetScanFoundInChild(aValue : Boolean);
begin
  if aValue and not FScanFoundInChild then
  begin
    if Assigned(ParentNode) then
      ParentNode.ScanFoundInChild := True;
  end;

  FScanFoundInChild := aValue;
end;

function TProcessNode.IsScanFound: Boolean;
begin
  Result := (ScanResult = srFound) or ScanFoundInChild;
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
  SystemProcessInfo: TSystemProcessInfo;
  ProcessInfos : TDictionary<DWORD, TSystemProcessInfo>;
begin
  Result := TSnapshot.Create([doOwnsValues]);  // own objects

  // Try to enable debug privilege first (best effort - continues even if it fails)
  EnableDebugPrivilege;

  try
    ProcessInfos := GetAllProcessInfo;

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

        ProcessInfos.TryGetValue(node.PID, SystemProcessInfo);

        if (FilePath = '') then
          FilePath := SystemProcessInfo.FilePath;

        node.ExePath   := UpperCase(FilePath);
        node.SessionID := SystemProcessInfo.SessionID;

        Result.Add(node.PID, node);
      until not Process32NextW(hSnap, pe32);
    finally
      CloseHandle(hSnap);
    end;

  finally
    ProcessInfos.Free;
  end;
end;

end.
