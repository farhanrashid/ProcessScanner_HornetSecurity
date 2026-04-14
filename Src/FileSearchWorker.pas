unit FileSearchWorker;

interface

uses
  System.Types, System.Classes, System.SysUtils, System.SyncObjs, ProcessNode;

type
  TWorkerDoneCallback = procedure(aExePath: string; aResult: TScanResult) of object;
  TLogCallback = procedure(aMessage: string) of object;

  TFileSearchWorker = class(TThread)
  private
    FExePath      : string;
    FCancelFlag   : TEvent;      // signalled to request cooperative cancel
    FOnDone       : TWorkerDoneCallback;
    FOnLog        : TLogCallback;
    FResult       : TScanResult;
    FIsRunning    : Boolean;

    function  ScanFile: TScanResult;
    procedure DoCallback;
    procedure DoLog(aMessage: string);
  protected
    procedure Execute; override;
  public
    constructor Create(const ExePath: string; OnDone: TWorkerDoneCallback; LogCall: TLogCallback);
    destructor Destroy; override;

    /// Signal the worker to stop. Non-blocking; the thread terminates shortly after.
    procedure RequestCancel;

    property ExePath : string read FExePath;
    property IsRunning : Boolean read FIsRunning;

  end;

implementation

const
  NEEDLE          : RawByteString = 'https://';
  NEEDLE_LEN      = 8;            // Length of 'https://'
  BLOCK_SIZE      = 65536;        // 64 KB I/O buffer

{ TFileSearchWorker }

constructor TFileSearchWorker.Create(const ExePath: string; OnDone: TWorkerDoneCallback; LogCall: TLogCallback);
begin
  inherited Create(True {suspended});
  FIsRunning  := False;
  FExePath    := ExePath;
  FOnDone     := OnDone;
  FOnLog      := LogCall;

  FCancelFlag := TEvent.Create(nil, True, False, '');
  FreeOnTerminate := False;

  DoLog('Scan worker created ' + FExePath);
end;

destructor TFileSearchWorker.Destroy;
begin
  FCancelFlag.Free;
  inherited;
end;

procedure TFileSearchWorker.RequestCancel;
begin
  FCancelFlag.SetEvent;

  DoLog('Cancel Requested ' + FExePath);

end;

procedure TFileSearchWorker.Execute;
begin
  try
    FIsRunning := True;
    try
      FResult := ScanFile;
    except
      on Exception do
        FResult := srAccessDenied;
    end;

  finally
    FIsRunning := False;
    DoCallback;
  end;

end;

procedure TFileSearchWorker.DoCallback;
begin
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOnDone) then
        FOnDone(FExePath, FResult);
    end);
end;

procedure TFileSearchWorker.DoLog(aMessage: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOnLog) then
        FOnLog(aMessage);
    end);
end;

function TFileSearchWorker.ScanFile: TScanResult;
var
  fs         : TFileStream;
  block      : TBytes;
  carry      : TBytes;       // tail of previous block to catch split needles
  bytesRead  : Integer;
  i          : Integer;
  b          : Byte;
  matchLen   : Integer;
begin
  Result := srNotFound;

  if FExePath = '' then
  begin
    DoLog('Empty file path');
    Exit(srAccessDenied);
  end;

  try
    fs := TFileStream.Create(FExePath, fmOpenRead or fmShareDenyNone);
  except
    DoLog('Access Denied ' + FExePath);
    Exit(srAccessDenied);
  end;

  DoLog('Scan Started ' + FExePath);

  try
    SetLength(block, BLOCK_SIZE);
    SetLength(carry, 0);
    matchLen   := 0;

    repeat

      bytesRead := fs.Read(block[0], BLOCK_SIZE);
      if bytesRead = 0 then
        Break;

      // Prepend carry bytes from the previous block so a needle that straddles the boundary is never missed.
      // We do this by appending carry in front of the usable data in a temporary combined view.
      // Rather than allocating, we simply process the carry continuation of matchLen already tracked.

      for i := 0 to bytesRead - 1 do
      begin
        b := block[i];

        if b = Ord(NEEDLE[matchLen + 1]) then
        begin
          Inc(matchLen);
          if matchLen = NEEDLE_LEN then
            Exit(srFound);        // ← short-circuit: no need to read more
        end
        else
        begin
          // Mismatch: reset, but check immediately if current byte starts
          // the needle to avoid missing overlapping matches.
          matchLen := 0;
          if b = Ord(NEEDLE[1]) then
            matchLen := 1;
        end;

        if FCancelFlag.WaitFor(0) = wrSignaled then  //Cancelled
        begin
          DoLog('Scan Cancelled ' + FExePath);
          Exit(srPending);
        end;
      end;

    until bytesRead < BLOCK_SIZE;

    DoLog('Scan done ' + FExePath);

  finally
    fs.Free;
  end;
end;

end.

