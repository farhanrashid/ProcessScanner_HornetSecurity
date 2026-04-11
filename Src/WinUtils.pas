unit WinUtils;

interface

uses Windows, SysUtils, System.Generics.Collections;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

function EnableDebugPrivilege: Boolean;
function GetAllFilePaths : TDictionary<WORD, String>; // All PID -> File path
function GetProcessFilePath(ProcessId: DWORD): string;
function QuerySessionID(PID: DWORD): DWORD;

implementation

// ---------------------------------------------------------------------------
// NT types
// ---------------------------------------------------------------------------

const
  ProcessImageFileName      = 27;
  ProcessImageFileNameWin32 = 43;
  SystemProcessInformation  = 5;

  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
  PROCESS_QUERY_INFORMATION         = $0400;

  STATUS_INFO_LENGTH_MISMATCH = NTSTATUS($C0000004);

type
  NTSTATUS = LongInt;

  NT_UNICODE_STRING = record
    Length        : USHORT;
    MaximumLength : USHORT;
    Buffer        : PWideChar;
  end;
  PNT_UNICODE_STRING = ^NT_UNICODE_STRING;

  // SYSTEM_PROCESS_INFORMATION - kernel process list entry.
  SYSTEM_PROCESS_INFORMATION = record
    NextEntryOffset              : ULONG;
    NumberOfThreads              : ULONG;
    WorkingSetPrivateSize        : LARGE_INTEGER;
    HardFaultCount               : ULONG;
    NumberOfThreadsHighWatermark : ULONG;
    CycleTime                    : UInt64;
    CreateTime                   : LARGE_INTEGER;
    UserTime                     : LARGE_INTEGER;
    KernelTime                   : LARGE_INTEGER;
    ImageName                    : NT_UNICODE_STRING;  // native \Device\... path
    BasePriority                 : LongInt;
    UniqueProcessId              : THandle;
    InheritedFromUniqueProcessId : THandle;
    HandleCount                  : ULONG;
    SessionId                    : ULONG;
    UniqueProcessKey             : ULONG_PTR;
    PeakVirtualSize              : ULONG_PTR;
    VirtualSize                  : ULONG_PTR;
    PageFaultCount               : ULONG;
    PeakWorkingSetSize           : ULONG_PTR;
    WorkingSetSize               : ULONG_PTR;
    QuotaPeakPagedPoolUsage      : ULONG_PTR;
    QuotaPagedPoolUsage          : ULONG_PTR;
    QuotaPeakNonPagedPoolUsage   : ULONG_PTR;
    QuotaNonPagedPoolUsage       : ULONG_PTR;
    PagefileUsage                : ULONG_PTR;
    PeakPagefileUsage            : ULONG_PTR;
    PrivatePageCount             : ULONG_PTR;
    ReadOperationCount           : LARGE_INTEGER;
    WriteOperationCount          : LARGE_INTEGER;
    OtherOperationCount          : LARGE_INTEGER;
    ReadTransferCount            : LARGE_INTEGER;
    WriteTransferCount           : LARGE_INTEGER;
    OtherTransferCount           : LARGE_INTEGER;
  end;
  PSYSTEM_PROCESS_INFORMATION = ^SYSTEM_PROCESS_INFORMATION;

  TNtQueryInformationProcess = function(
    ProcessHandle           : THandle;
    ProcessInformationClass : DWORD;
    ProcessInformation      : Pointer;
    ProcessInformationLength: ULONG;
    ReturnLength            : PULONG
  ): NTSTATUS; stdcall;

  TNtQuerySystemInformation = function(
    SystemInformationClass : DWORD;
    SystemInformation      : Pointer;
    SystemInformationLength: ULONG;
    ReturnLength           : PULONG
  ): NTSTATUS; stdcall;

function NT_SUCCESS(Status: NTSTATUS): Boolean; inline;
begin
  Result := Status >= 0;
end;

// ---------------------------------------------------------------------------
// Lazy NT API loading
// ---------------------------------------------------------------------------

// GetSystemWow64Directory is not declared in all Delphi/FPC Windows units
function GetSystemWow64Directory(lpBuffer: PChar; uSize: UINT): UINT; stdcall;
  external 'kernel32.dll' name 'GetSystemWow64DirectoryW';
var
  _NtQueryInformationProcess : TNtQueryInformationProcess = nil;
  _NtQuerySystemInformation  : TNtQuerySystemInformation  = nil;
  _NtApiInitialized          : Boolean = False;

procedure EnsureNtApi;
var
  H: HMODULE;
begin
  if _NtApiInitialized then Exit;
  _NtApiInitialized := True;
  H := GetModuleHandle('ntdll.dll');
  if H = 0 then Exit;
  @_NtQueryInformationProcess := GetProcAddress(H, 'NtQueryInformationProcess');
  @_NtQuerySystemInformation  := GetProcAddress(H, 'NtQuerySystemInformation');
end;

// ---------------------------------------------------------------------------
// SeDebugPrivilege
// ---------------------------------------------------------------------------

function EnableDebugPrivilege: Boolean;
var
  hToken: THandle;
  Luid  : TLargeInteger;
  TP    : TOKEN_PRIVILEGES;
  ReturnLength: DWORD;
begin
  Result := False;
  if not OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
    Exit;
  try
    if not LookupPrivilegeValue(nil, 'SeDebugPrivilege', Luid) then Exit;
    TP.PrivilegeCount           := 1;
    TP.Privileges[0].Luid       := Luid;
    TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

    Result := AdjustTokenPrivileges(hToken, False, TP, SizeOf(TP), nil, ReturnLength)
              and (GetLastError = ERROR_SUCCESS);
  finally
    CloseHandle(hToken);
  end;
end;

// ---------------------------------------------------------------------------
// Device prefix table  (\Device\HarddiskVolumeX -> C:)
// ---------------------------------------------------------------------------

type
  TDevicePrefix = record
    DevicePath  : string;
    DriveLetter : string;
  end;

var
  _DevicePrefixes    : array[0..25] of TDevicePrefix;
  _DevicePrefixCount : Integer = 0;
  _DevicesInitOnce   : Boolean = False;

procedure BuildDevicePrefixTable;
var
  Drive  : Char;
  DosName: string;
  Buffer : array[0..1023] of WideChar;
begin
  if _DevicesInitOnce then Exit;
  _DevicesInitOnce := True;
  _DevicePrefixCount := 0;
  for Drive := 'A' to 'Z' do
  begin
    DosName := Drive + ':';
    if QueryDosDeviceW(PWideChar(WideString(DosName)), Buffer, Length(Buffer)) > 0 then
    begin
      _DevicePrefixes[_DevicePrefixCount].DevicePath  := WideCharToString(Buffer);
      _DevicePrefixes[_DevicePrefixCount].DriveLetter := DosName;
      Inc(_DevicePrefixCount);
    end;
  end;
end;

// ---------------------------------------------------------------------------
// NativePathToWin32Path
// ---------------------------------------------------------------------------

function NativePathToWin32Path(const NativePath: string): string;
var
  i  : Integer;
  Dev: string;
begin
  BuildDevicePrefixTable;
  for i := 0 to _DevicePrefixCount - 1 do
  begin
    Dev := _DevicePrefixes[i].DevicePath;
    if (Length(NativePath) > Length(Dev)) and
       (CompareText(Copy(NativePath, 1, Length(Dev)), Dev) = 0) and
       (NativePath[Length(Dev) + 1] = '\') then
    begin
      Result := _DevicePrefixes[i].DriveLetter + Copy(NativePath, Length(Dev) + 1, MaxInt);
      Exit;
    end;
  end;
  Result := NativePath; // return unchanged if no mapping found
end;

// ---------------------------------------------------------------------------
// NtQueryInformationProcess (requires open process handle)
// ---------------------------------------------------------------------------

function QueryProcessFileNameByHandle(ProcessHandle: THandle; InfoClass: DWORD): string;
var
  Status       : NTSTATUS;
  Buffer       : PByte;
  BufferSize   : ULONG;
  ReturnLength : ULONG;
  UniStr       : PNT_UNICODE_STRING;
begin
  Result := '';
  EnsureNtApi;
  if not Assigned(_NtQueryInformationProcess) then Exit;

  BufferSize := SizeOf(NT_UNICODE_STRING) + (MAX_PATH * 2 * SizeOf(WideChar));
  Buffer := AllocMem(BufferSize);
  try
    ReturnLength := 0;
    Status := _NtQueryInformationProcess(
      ProcessHandle, InfoClass, Buffer, BufferSize, @ReturnLength);

    if (Status = STATUS_INFO_LENGTH_MISMATCH) and (ReturnLength > 0) then
    begin
      FreeMem(Buffer);
      BufferSize := ReturnLength;
      Buffer := AllocMem(BufferSize);
      Status := _NtQueryInformationProcess(
        ProcessHandle, InfoClass, Buffer, BufferSize, @ReturnLength);
    end;

    if NT_SUCCESS(Status) then
    begin
      UniStr := PNT_UNICODE_STRING(Buffer);
      if (UniStr^.Length > 0) and (UniStr^.Buffer <> nil) then
        SetString(Result, UniStr^.Buffer, UniStr^.Length div SizeOf(WideChar));
    end;
  finally
    FreeMem(Buffer);
  end;
end;

// ---------------------------------------------------------------------------
// ResolveShortNameToFullPath
// ---------------------------------------------------------------------------

function ResolveShortNameToFullPath(const ShortName: string): string;
var
  SystemDir : string;
  SysWow64  : string;
  Buffer    : array[0..MAX_PATH] of Char;
  FilePart  : PChar;
  Len       : DWORD;
begin
  Result := '';
  if ShortName = '' then Exit;

  // PID 4 "System" is the kernel — return ntoskrnl.exe path
  if SameText(ShortName, 'System') then
  begin
    SetLength(SystemDir, MAX_PATH);
    SetLength(SystemDir, GetSystemDirectory(PChar(SystemDir), MAX_PATH));
    Result := SystemDir + '\ntoskrnl.exe';
    Exit;
  end;

  // SearchPath checks: app dir -> System32 -> Windows dir -> %PATH%
  // Handles svchost.exe, csrss.exe, smss.exe, wininit.exe, etc.
  FilePart := nil;
  Len := SearchPath(nil, PChar(ShortName), nil, MAX_PATH, Buffer, FilePart);
  if Len > 0 then
  begin
    Result := Buffer;
    Exit;
  end;

  // Explicit System32 check (SearchPath can miss it without SeDebugPrivilege on some configurations)
  SetLength(SystemDir, MAX_PATH);
  SetLength(SystemDir, GetSystemDirectory(PChar(SystemDir), MAX_PATH));
  Result := SystemDir + '\' + ShortName;

  // SysWOW64 for 32-bit processes running on 64-bit Windows
  SetLength(SysWow64, MAX_PATH);
  SetLength(SysWow64, GetSystemWow64Directory(PChar(SysWow64), MAX_PATH));
  if SysWow64 <> '' then
  begin
    Result := SysWow64 + '\' + ShortName;
  end;
end;

// ---------------------------------------------------------------------------
// IsFileNameOnly
// ---------------------------------------------------------------------------

function IsFileNameOnly(const S: string): Boolean;
begin
  Result := ExtractFilePath(S) = '';
end;

// ---------------------------------------------------------------------------
// GetProcessFilePathByHandle
// ---------------------------------------------------------------------------

function GetProcessFilePathByHandle(ProcessHandle: THandle): string;
begin
  Result := '';
  if ProcessHandle = 0 then Exit;

  // Try Win32 path first (Vista+, tracks renames, same file object as kernel)
  Result := QueryProcessFileNameByHandle(ProcessHandle, ProcessImageFileNameWin32);
  if Result <> '' then Exit;

  // Fall back to native NT path + drive letter translation
  Result := QueryProcessFileNameByHandle(ProcessHandle, ProcessImageFileName);
  if Result <> '' then
    Result := NativePathToWin32Path(Result);
end;

// ---------------------------------------------------------------------------
// Public implementation
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// GetAllFilePaths
// ---------------------------------------------------------------------------

function GetAllFilePaths : TDictionary<WORD, String>;
const KB = 1024;
var
  Status       : NTSTATUS;
  Buffer       : PByte;
  BufferSize   : ULONG;
  ReturnLength : ULONG;
  Entry        : PSYSTEM_PROCESS_INFORMATION;
  ImageName    : string;
begin
  Result := TDictionary<WORD, String>.Create();

  EnsureNtApi;
  if not Assigned(_NtQuerySystemInformation) then Exit;

  BufferSize := 512 * KB;
  Buffer := AllocMem(BufferSize);
  try
    while True do
    begin
      ReturnLength := 0;

      Status := _NtQuerySystemInformation( SystemProcessInformation, Buffer, BufferSize, @ReturnLength);

      if NT_SUCCESS(Status) then
        Break;

      if Status <> STATUS_INFO_LENGTH_MISMATCH then
        Exit; // raise error

      FreeMem(Buffer);
      BufferSize := ReturnLength + 8 * KB;
      Buffer := AllocMem(BufferSize);
    end;

    if not NT_SUCCESS(Status) then Exit;

    Entry := PSYSTEM_PROCESS_INFORMATION(Buffer);

    while True do
    begin
      if Entry^.ImageName.Length > 0 then
      begin
        SetString(ImageName,
            Entry^.ImageName.Buffer,
            Entry^.ImageName.Length div SizeOf(WideChar));

        if IsFileNameOnly(ImageName) then
          Result.Add(Entry^.UniqueProcessId, ResolveShortNameToFullPath(ImageName))
        else
          Result.Add(Entry^.UniqueProcessId, ImageName);

      end;

      if Entry^.NextEntryOffset = 0
        then Break;

      Entry := PSYSTEM_PROCESS_INFORMATION(PByte(Entry) + Entry^.NextEntryOffset);
    end;
  finally
    FreeMem(Buffer);
  end;

end;

// ---------------------------------------------------------------------------
// GetProcessFilePath
// ---------------------------------------------------------------------------

function GetProcessFilePath(ProcessId: DWORD): string;
var
  hProcess    : THandle;
  AccessMask: DWORD;
begin
  Result := '';
  hProcess := 0;
  if ProcessId = 0 then Exit; // PID 0 = Idle, no real path

  // --- Step 1: try with minimal access (preferred, works for most) ---
  for AccessMask in [PROCESS_QUERY_LIMITED_INFORMATION,
                     PROCESS_QUERY_INFORMATION,
                     PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
                     PROCESS_ALL_ACCESS] do
  begin
    hProcess := OpenProcess(AccessMask, False, ProcessId);
    if hProcess <> 0 then
      Break;
  end;

  if hProcess <> 0 then
  begin
    try
      Result := GetProcessFilePathByHandle(hProcess);
    finally
      CloseHandle(hProcess);
    end;
  end;

end;

// ---------------------------------------------------------------------------
// QuerySessionID
// ---------------------------------------------------------------------------

function QuerySessionID(PID: DWORD): DWORD;
var
  sid: DWORD;
begin
  Result := DWORD(-1);
  if ProcessIdToSessionId(PID, sid) then
    Result := sid;
end;

end.

