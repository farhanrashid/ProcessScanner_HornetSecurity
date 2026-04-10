unit ProcessNode;

interface

uses
  System.Types, System.SysUtils, System.Generics.Collections;

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

implementation

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

end.
