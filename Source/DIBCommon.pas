unit DIBCommon;

interface

uses
  Classes;

  {
type

  TDIBPoint = class(TPersistent)
  private
    FOwner: TPersistent;
    FX: Integer;
    FY: Integer;
    FOnChange: TNotifyEvent;
    procedure Changed;
    procedure SetX(const Value: Integer);
    procedure SetY(const Value: Integer);
  protected
    function GetOwner: TPersistent; override;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TPersistent);
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property X: Integer read FX write SetX;
    property Y: Integer read FY write SetY;
  end;
  }

implementation


{ TDIBPoint 

procedure TDIBPoint.AssignTo(Dest: TPersistent);
var
  DestDIBPoint: TDIBPoint;
begin
  if Dest is TDIBPoint then
  begin
    DestDIBPoint := TDIBPoint(Dest);
    DestDIBPoint.X := X;
    DestDIBPoint.Y := Y;
  end else
    inherited;
end;

procedure TDIBPoint.Changed;
begin
  if Assigned(FOnChange) then
    OnChange(Self);
end;

constructor TDIBPoint.Create(AOwner: TPersistent);
begin
  Assert(AOwner <> nil);
end;

function TDIBPoint.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TDIBPoint.SetX(const Value: Integer);
begin
  FX := Value;
  Changed;
end;

procedure TDIBPoint.SetY(const Value: Integer);
begin
  FY := Value;
  Changed;
end;
}

end.
