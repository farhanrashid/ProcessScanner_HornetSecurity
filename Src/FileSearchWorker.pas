unit FileSearchWorker;

interface

uses
  System.Types, System.Classes, System.SysUtils, System.SyncObjs, ProcessNode;

type
  TWorkerDoneCallback = procedure(aExePath: string; aResult: TScanResult) of object;

  TFileSearchWorker = class(TThread)
  private
    FExePath      : string;
    FCancelFlag   : TEvent;      // signalled to request cooperative cancel
    FOnDone       : TWorkerDoneCallback;
    FResult       : TScanResult;

    function  ScanFile: TScanResult;
    procedure DoCallback;
  protected
    procedure Execute; override;
  public
    constructor Create(const ExePath: string; OnDone: TWorkerDoneCallback);
    destructor Destroy; override;

    /// Signal the worker to stop. Non-blocking; the thread terminates shortly after.
    procedure RequestCancel;

    property ExePath : string read FExePath;
  end;

implementation

const
  NEEDLE          : RawByteString = 'https://';
  NEEDLE_LEN      = 8;            // Length of 'https://'
  BLOCK_SIZE      = 65536;        // 64 KB I/O buffer

{ TFileSearchWorker }

constructor TFileSearchWorker.Create(const ExePath: string;  OnDone: TWorkerDoneCallback);
begin
  inherited Create(True {suspended});
  FExePath    := ExePath;
  FOnDone     := OnDone;
  FCancelFlag := TEvent.Create(nil, True, False, '');
  FreeOnTerminate := False;
end;

destructor TFileSearchWorker.Destroy;
begin
  FCancelFlag.Free;
  inherited;
end;

procedure TFileSearchWorker.RequestCancel;
begin
  FCancelFlag.SetEvent;
  // Do NOT call Terminate; we rely only on cooperative checking.
end;

procedure TFileSearchWorker.Execute;
begin
  try
    FResult := ScanFile;
  except
    on Exception do
      FResult := srAccessDenied;
  end;

  Synchronize(DoCallback);
end;

procedure TFileSearchWorker.DoCallback;
begin
  if Assigned(FOnDone) then
    FOnDone(FExePath, FResult);
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
  totalBytes : Int64;
begin
  Result := srNotFound;

  if FExePath = '' then
    Exit(srAccessDenied);

  try
    fs := TFileStream.Create(FExePath, fmOpenRead or fmShareDenyNone);
  except
    Exit(srAccessDenied);
  end;

  try
    SetLength(block, BLOCK_SIZE);
    SetLength(carry, 0);
    matchLen   := 0;
    totalBytes := 0;

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

        Inc(totalBytes);

        if FCancelFlag.WaitFor(0) = wrSignaled then  //Cancelled
          Exit(srPending);
      end;

    until bytesRead < BLOCK_SIZE;

  finally
    fs.Free;
  end;
end;

end.

