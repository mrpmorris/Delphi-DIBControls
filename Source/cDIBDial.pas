unit cDIBDial;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, cDIBImageList,
  cDIBControl, cDIB;

const
  DHT_NONE = 0;
  DHT_POINTER = 1;
  DHT_SMALLCHANGEDOWN = 2;
  DHT_SMALLCHANGEUP = 3;
  DHT_PAGECHANGEDOWN = 4;
  DHT_PAGECHANGEUP = 5;
  DHT_USER = 6;

type
  EDIBDialError = class(EDIBControlError);
  TDIBDialMouseControlStyle = (mcsCircular, mcsLinear);
  TDIBDialMouseLinearSensitivity = (mlsVertical, mlsHorizontal, mlsBoth);


  TDIBDialSettings = class(TPersistent)
  private
    FOnChange: TNotifyEvent;
  private
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  protected
    procedure Changed;
  public
    constructor Create; virtual;
  end;

  TCustomDIBDialPointerAngles = class(TDIBDialSettings)
  private
    FResolution: Extended;
    FStart: Integer;
    FRange: Integer;
    procedure SetRange(const Value: Integer);
    procedure SetResolution(const Value: Extended);
    procedure SetStart(const Value: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    property Start: Integer read FStart write SetStart default 0;
    property Range: Integer read FRange write SetRange default 360;
    property Resolution: Extended read FResolution write SetResolution;
  public
    constructor Create; override;
  end;

  TCustomDIBDialPointerOpacities = class(TDIBDialSettings)
  private
    FActive: Byte;
    FNormal: Byte;
    procedure SetActive(const Value: Byte);
    procedure SetNormal(const Value: Byte);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    property Active: Byte read FActive write SetActive default 255;
    property Normal: Byte read FNormal write SetNormal default 255;
  public
    constructor Create; override;
  end;

  TDIBDialPointerAngles = class(TCustomDIBDialPointerAngles)
  published
    property Start;
    property Range;
    property Resolution;
  end;

  TDIBDialPointerOpacities = class(TCustomDIBDialPointerOpacities)
  published
    property Active;
    property Normal;
  end;

  TAbstractDIBDial = class(TCustomDIBControl)
  private
    FPointerAngles: TCustomDIBDialPointerAngles;
    FPointerOpacities: TCustomDIBDialPointerOpacities;
    FPosition: Integer;
    FMin: Integer;
    FMax: Integer;
    FPageSize: Integer;
    FSmallChange: Integer;
    FIndexPointer: TDIBImageLink;
    FIndexMain: TDIBImageLink;
    FOnChange: TNotifyEvent;
    FPointerNumGlyphs: Integer;
    FPointerRotate: Boolean;
    FPointerRadius: Integer;
    FPointerCaptured: Boolean;
    FHorizontalPixelsPerPosition: Extended;
    FVerticalPixelsPerPosition: Extended;
    FMouseControlStyle: TDIBDialMouseControlStyle;
    FMouseLinearSensitivity: TDIBDialMouseLinearSensitivity;
    FMouseDownPosition: Integer;
    FCapturePosition: TPoint;
    function CircularMouseToPosition(X, Y: Integer): Integer;
    function LinearMouseToPosition(X, Y: Integer): Integer;
    procedure SetPointerAngles(const Value: TCustomDIBDialPointerAngles);
    procedure SetPointerOpacities(const Value: TCustomDIBDialPointerOpacities);
    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetPosition(const Value: Integer);
    procedure SetPageSize(const Value: Integer);
    procedure SetSmallChange(const Value: Integer);
    procedure SetPointerNumGlyphs(const Value: Integer);
    procedure SetPointerRotate(const Value: Boolean);
    procedure SetPointerRadius(const Value: Integer);
    procedure SetHorizontalPixelsPerPosition(const Value: Extended);
    procedure SetVerticalPixelsPerPosition(const Value: Extended);
  protected
    function CanAutoSize(var Width, Height: Integer): Boolean; override;
    function CreatePointerAngles: TCustomDIBDialPointerAngles; virtual; abstract;
    function CreatePointerOpacities: TCustomDIBDialPointerOpacities; virtual; abstract;
    function PositionToAngle: Integer; virtual; abstract;

    procedure CapturePointer;
    function ConstrainPosition(APosition: Integer): Integer;
    function DialHitTest(X, Y: Integer): Integer; virtual;
    procedure ReleasePointer;
    procedure Changed; virtual;
    function GetPointerRect: TRect;
    function MouseToPosition(X, Y: Integer): Integer; virtual;
    procedure Paint; override;
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); override;
    procedure SettingsChanged(Sender: TObject); virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    property CapturePosition: TPoint read FCapturePosition;
    property HorizontalPixelsPerPosition: Extended read FHorizontalPixelsPerPosition write SetHorizontalPixelsPerPosition;
    property IndexMain: TDIBImageLink read FIndexMain write FIndexMain;
    property IndexPointer: TDIBImageLink read FIndexPointer write FIndexPointer;
    property Max: Integer read FMax write SetMax default 100;
    property Min: Integer read FMin write SetMin default 0;
    property MouseControlStyle: TDIBDialMouseControlStyle read FMouseControlStyle write FMouseControlStyle default mcsCircular;
    property MouseDownPosition: Integer read FMouseDownPosition;
    property MouseLinearSensitivity: TDIBDialMouseLinearSensitivity read FMouseLinearSensitivity write FMouseLinearSensitivity default mlsBoth;
    property PageSize: Integer read FPageSize write SetPageSize default 1;
    property PointerAngles: TCustomDIBDialPointerAngles read FPointerAngles write SetPointerAngles;
    property PointerNumGlyphs: Integer read FPointerNumGlyphs write SetPointerNumGlyphs default 1;
    property PointerOpacities: TCustomDIBDialPointerOpacities read FPointerOpacities write SetPointerOpacities;
    property PointerRadius: Integer read FPointerRadius write SetPointerRadius default -1;
    property PointerRotate: Boolean read FPointerRotate write SetPointerRotate default False;
    property Position: Integer read FPosition write SetPosition default 0;
    property SmallChange: Integer read FSmallChange write SetSmallChange default 1;
    property VerticalPixelsPerPosition: Extended read FVerticalPixelsPerPosition write SetVerticalPixelsPerPosition;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
  end;

  TCustomDIBDial = class(TAbstractDIBDial)
  private
    function GetPointerAngles: TDIBDialPointerAngles;
    function GetPointerOpacities: TDIBDialPointerOpacities;
    procedure SetPointerAngles(const Value: TDIBDialPointerAngles);
    procedure SetPointerOpacities(const Value: TDIBDialPointerOpacities);
  protected
    function CreatePointerAngles: TCustomDIBDialPointerAngles; override;
    function CreatePointerOpacities: TCustomDIBDialPointerOpacities; override;
    function PositionToAngle: Integer; override;

    property PointerAngles: TDIBDialPointerAngles read GetPointerAngles write SetPointerAngles;
    property PointerOpacities: TDIBDialPointerOpacities read GetPointerOpacities write SetPointerOpacities;
  end;

  TDIBDial = class(TCustomDIBDial)
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Accelerator;
    property Align;
    property Anchors;
    property AutoSize;
    property DIBFeatures;
    property DIBImageList;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property HorizontalPixelsPerPosition;
    property IndexMain;
    property IndexPointer;
    property Max;
    property Min;
    property MouseControlStyle;
    property MouseLinearSensitivity;
    property Opacity;
    property PageSize;
    property ParentShowHint;
    property PointerAngles;
    property PointerOpacities;
    property PointerNumGlyphs;
    property PointerRadius;
    property PointerRotate;
    property PopupMenu;
    property Position;
    property ShowHint;
    property SmallChange;
    property DIBTabOrder;
    property Tag;
    property VerticalPixelsPerPosition;
    property Visible;

    {$I WinControlEvents.inc}

    property OnChange;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnstartDrag;
  end;

implementation

{ TDIBDialSettings }

procedure TDIBDialSettings.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TDIBDialSettings.Create;
begin
  inherited;
end;

{ TCustomDIBDialPointerAngles }

procedure TCustomDIBDialPointerAngles.AssignTo(Dest: TPersistent);
begin
  if Dest is TCustomDIBDialPointerAngles then with TCustomDIBDialPointerAngles(Dest) do
  begin
    FRange := Self.Range;
    FStart := Self.Start;
    FResolution := Self.Resolution;
    Changed; 
  end else
    inherited;
end;

constructor TCustomDIBDialPointerAngles.Create;
begin
  inherited;
  FStart := 0;
  FRange := 360;
  FResolution := 0;
end;

procedure TCustomDIBDialPointerAngles.SetRange(const Value: Integer);
begin
  if (Range < 1) or (Range > 360) then
    raise EDIBDialError.Create('Range must be 1..360');
  FRange := Value;
  if Range > Resolution then Resolution := Range;
  Changed;
end;

procedure TCustomDIBDialPointerAngles.SetResolution(const Value: Extended);
begin
  if (Value < 0) or (Value > Range) then
    raise EDIBDialError.Create('Resolution must be above 0 and less than ' + IntToStr(Range + 1));
  FResolution := Value;
  Changed;
end;

procedure TCustomDIBDialPointerAngles.SetStart(const Value: Integer);
begin
  if (Value < 0) or (Value > 359) then
    raise EDIBDialError.Create('Start must be 0..359');
  FStart := Value;
  Changed;
end;

{ TCustomDIBDialPointerOpacities }

procedure TCustomDIBDialPointerOpacities.AssignTo(Dest: TPersistent);
begin
  if Dest is TCustomDIBDialPointerOpacities then with TCustomDIBDialPointerOpacities(Dest) do
  begin
    FActive := Self.Active;
    FNormal := Self.Normal;
    Changed;
  end else
    inherited;
end;

constructor TCustomDIBDialPointerOpacities.Create;
begin
  inherited;
  FActive := 255;
  FNormal := 255;
end;

procedure TCustomDIBDialPointerOpacities.SetActive(const Value: Byte);
begin
  FActive := Value;
  Changed;
end;

procedure TCustomDIBDialPointerOpacities.SetNormal(const Value: Byte);
begin
  FNormal := Value;
  Changed;
end;

{ TAbstractDIBDial }

function TAbstractDIBDial.CanAutoSize(var Width, Height: Integer): Boolean;
var
  MainDIB: TMemoryDIB;
  PointerDIB: TMemoryDIB;
  BiggestPointerSize: Integer;
  SmallestDimension: Integer;
begin
  Result := False;
  if IndexMain.GetImage(MainDIB) then
  begin
    Width := MainDIB.Width;
    Height := MainDIB.Height;
    if IndexPointer.GetImage(PointerDIB) then
    begin
      if MainDIB.Width < MainDIB.Height then
        SmallestDimension := MainDIB.Width
      else
        SmallestDimension := MainDIB.Height;

      if PointerDIB.Width > PointerDIB.Height then
        BiggestPointerSize := PointerDIB.Width
      else
        BiggestPointerSize := PointerDIB.Height;
      if PointerRadius > 0 then
      begin
        if SmallestDimension < (BiggestPointerSize div 2) + PointerRadius then
          SmallestDimension := (BiggestPointerSize div 2) + PointerRadius;
        if Width < SmallestDimension then Width := SmallestDimension;
        if Height < SmallestDimension then Height := SmallestDimension;
      end;
    end;
    Result := True;
  end;
end;

procedure TAbstractDIBDial.CapturePointer;
begin
  if IsMouseRepeating then StopRepeating;
  FPointerCaptured := True;
  Invalidate;
end;

procedure TAbstractDIBDial.Changed;
begin
  Invalidate;
end;

function TAbstractDIBDial.CircularMouseToPosition(X, Y: Integer): Integer;
var
  Range: Integer;
  Angle: Extended;
begin
  Range := Max - (Min - 1);
  Angle := SafeAngle(RelativeAngle(Width div 2, Height div 2, X, Y) - PointerAngles.Start);
  Result := Round(Angle * Range / PointerAngles.Range);
  if Result > Max then Result := Max;
  if Result < Min then Result := Min;
end;

function TAbstractDIBDial.ConstrainPosition(APosition: Integer): Integer;
begin
  if APosition > Max then Result := Max
  else if APosition < Min then Result := Min
  else Result := APosition;
end;

constructor TAbstractDIBDial.Create(AOwner: TComponent);
begin
  inherited;
  FIndexMain := TDIBImageLink.Create(Self);
  AddIndexProperty(FIndexMain);
  FIndexPointer := TDIBImageLink.Create(Self);
  AddIndexProperty(FIndexPointer);
  FPointerAngles := CreatePointerAngles;
  FPointerAngles.OnChange := SettingsChanged;
  FPointerOpacities := CreatePointerOpacities;
  FPointerOpacities.OnChange := SettingsChanged;
  FSmallChange := 1;
  FPageSize := 1;
  FMin := 0;
  FMax := 100;
  FPosition := 0;
  FPointerNumGlyphs := 1;
  FPointerRotate := False;
  FPointerRadius := -1;
  FHorizontalPixelsPerPosition := 1;
  FVerticalPixelsPerPosition := 1;
  FMouseControlStyle := mcsCircular;
  FMouseLinearSensitivity := mlsBoth;
  AutoSize := True;
  MouseRepeat := True;
  MouseRepeatInterval := 50;
end;

destructor TAbstractDIBDial.Destroy;
begin
  FreeAndNil(FPointerOpacities);
  FreeAndNil(FPointerAngles);
  FreeAndNil(FIndexPointer);
  FreeAndNil(FIndexMain);
  inherited;
end;

function TAbstractDIBDial.DialHitTest(X, Y: Integer): Integer;
var
  PR: TRect;
  PositionDelta: Integer;
begin
  if MouseControlStyle = mcsLinear then
    Result := DHT_POINTER
  else
  begin
    PR := GetPointerRect;
    if PtInRect(PR, Point(X, Y)) then
      Result := DHT_POINTER
    else
    begin
      PositionDelta := MouseToPosition(X, Y) - Position;
      if Abs(PositionDelta) > (Max - Min) div 4 then
      begin
        if PositionDelta < 0 then
          Result := DHT_PAGECHANGEDOWN
        else
          Result := DHT_PAGECHANGEUP;
      end else
        if PositionDelta < 0 then
          Result := DHT_SMALLCHANGEDOWN
        else
          Result := DHT_SMALLCHANGEUP;
    end;
  end;
end;

function TAbstractDIBDial.GetPointerRect: TRect;
var
  Angle: Extended;
  Radius: Integer;
  CenterPoint: TPoint;
  RotatedSizes: TPoint;
  SmallestDimension: Integer;
  PointerDIB: TMemoryDIB;
begin
  Result := Rect(0, 0, 0, 0);
  Angle := SafeAngle(PositionToAngle);
  SmallestDimension := Smallest(Width, Height);
  if IndexPointer.GetImage(PointerDIB) then
  begin
    if PointerRadius > 0 then
      Radius := PointerRadius
    else
      Radius := SmallestDimension + PointerRadius - PointerDIB.Height;
    CenterPoint := GetRotatedPoint(Width div 2, Height div 2, Radius, Angle);
    if not PointerRotate then Angle := 0;
    RotatedSizes := GetRotatedSize(PointerDIB.Width div PointerNumGlyphs, PointerDIB.Height, Angle, 100, 100);

    Result.Left := CenterPoint.X - (RotatedSizes.X div 2);
    Result.Top := CenterPoint.Y - (RotatedSizes.Y div 2);
    Result.Right := Result.Left + RotatedSizes.X - 1;
    Result.Bottom := Result.Top + RotatedSizes.Y - 1;
  end;
end;

procedure TAbstractDIBDial.ImageChanged(Index: Integer;
  Operation: TDIBOperation);
begin
  if AutoSize then AdjustSize;
  Invalidate;
end;

function TAbstractDIBDial.LinearMouseToPosition(X, Y: Integer): Integer;
var
  XDistance: Integer;
  YDistance: Integer;
  MovementSize: Extended;
begin
  XDistance := X - CapturePosition.X;
  YDistance := CapturePosition.Y - Y;
  if MouseLinearSensitivity in [mlsVertical, mlsBoth] then
    MovementSize := YDistance / VerticalPixelsPerPosition
  else
    MovementSize := 0;
  if MouseLinearSensitivity in [mlsHorizontal, mlsBoth] then
    MovementSize := MovementSize + XDistance / HorizontalPixelsPerPosition;
  Result := MouseDownPosition + Trunc(MovementSize);
end;

procedure TAbstractDIBDial.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ActualPosition: Integer;
begin
  inherited;
  if Button = mbLeft then
  begin
    FMouseDownPosition := Position;
    FCapturePosition := Point(X, Y);
    ActualPosition := MouseToPosition(X, Y);
    case DialHitTest(X, Y) of
      DHT_POINTER: CapturePointer;
      DHT_SMALLCHANGEDOWN:
        if Position - SmallChange < ActualPosition then
          Position := ActualPosition
        else
          Position := Position - SmallChange;
      DHT_SMALLCHANGEUP:
        if Position + SmallChange > ActualPosition then
          Position := ActualPosition
        else
          Position := Position + SmallChange;
      DHT_PAGECHANGEDOWN:
        if Position - PageSize < ActualPosition then
          Position := ActualPosition
        else
          Position := Position - PageSize;
      DHT_PAGECHANGEUP:
        if Position + PageSize > ActualPosition then
          Position := ActualPosition
        else
          Position := Position + PageSize;
    end;
  end;
end;

procedure TAbstractDIBDial.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FPointerCaptured then
    Position := MouseToPosition(X, Y);
end;

function TAbstractDIBDial.MouseToPosition(X, Y: Integer): Integer;
begin
  if MouseControlStyle = mcsCircular then
    Result := CircularMouseToPosition(X, Y)
  else
    Result := LinearMouseToPosition(X, Y);
end;

procedure TAbstractDIBDial.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and FPointerCaptured then ReleasePointer;
end;

procedure TAbstractDIBDial.Paint;
var
  PointerRect: TRect;
  MainDIB, PointerDIB: TMemoryDIB;
begin
  inherited;
  if IndexMain.GetImage(MainDIB) then
  begin
    MainDIB.Draw(Width div 2 - (MainDIB.Width div 2), Height div 2 - (MainDIB.Height div 2),
      MainDIB.Width, MainDIB.Height, ControlDIB, 0, 0);
    if IndexPointer.GetImage(PointerDIB) then
    begin
      PointerRect := GetPointerRect;
      if PointerRotate then PointerDIB.Angle := PositionToAngle;
      PointerDIB.AutoSize := True;
      if FPointerCaptured then
        PointerDIB.Opacity := PointerOpacities.Active
      else
        PointerDIB.Opacity := PointerOpacities.Normal;
      PointerDIB.DrawGlyphTween(PointerRect.Left, PointerRect.Top, PointerNumGlyphs,
        ControlDIB, 0, 359, PositionToAngle, True);
    end;
  end;
end;

procedure TAbstractDIBDial.ReleasePointer;
begin
  FPointerCaptured := False;
  Invalidate;  
end;

procedure TAbstractDIBDial.SetHorizontalPixelsPerPosition(const Value: Extended);
begin
  if (Value <= 0) then
    raise EDIBDialError.Create('HorizontalPixelsPerPosition must be greater than zero');
  FHorizontalPixelsPerPosition := Value;
end;

procedure TAbstractDIBDial.SetMax(const Value: Integer);
begin
  if not (csLoading in ComponentState) then
    if (Value <= Min) then
      raise EDIBDialError.Create('Max must be greater than min');
  FMax := Value;
  if Position > Max then Position := Max;
  Invalidate;
end;

procedure TAbstractDIBDial.SetMin(const Value: Integer);
begin
  if not (csLoading in ComponentState) then
    if (Value >= Max) then
      raise EDIBDialError.Create('Min must be less than max');
  FMin := Value;
  if Position < Min then Position := Min;
  Invalidate;
end;

procedure TAbstractDIBDial.SetPageSize(const Value: Integer);
begin
  if not (csLoading in ComponentState) then
    if (Value < 0) then
      raise EDIBDialError.Create('PageSize cannot be less than 0');
  FPageSize := Value;
end;

procedure TAbstractDIBDial.SetPointerAngles(const Value: TCustomDIBDialPointerAngles);
begin
  FPointerAngles.Assign(Value);
end;

procedure TAbstractDIBDial.SetPointerNumGlyphs(const Value: Integer);
begin
  if Value < 1 then
    raise EDIBDialError.Create('PointerNumGlyphs must be at least 1');
  FPointerNumGlyphs := Value;
  Invalidate;
end;

procedure TAbstractDIBDial.SetPointerOpacities(const Value: TCustomDIBDialPointerOpacities);
begin
  FPointerOpacities.Assign(Value);
end;

procedure TAbstractDIBDial.SetPointerRadius(const Value: Integer);
begin
  FPointerRadius := Value;
  Invalidate;
end;

procedure TAbstractDIBDial.SetPointerRotate(const Value: Boolean);
begin
  FPointerRotate := Value;
  Invalidate;
end;

procedure TAbstractDIBDial.SetPosition(const Value: Integer);
begin
  FPosition := ConstrainPosition(Value);
  Changed;
  if not (csLoading in ComponentState) then
    if Assigned(FOnChange) then
      FOnChange(Self);
  Invalidate;
end;

procedure TAbstractDIBDial.SetSmallChange(const Value: Integer);
begin
  if not (csLoading in ComponentState) then
    if (Value < 0) then
      raise EDIBDialError.Create('SmallChange cannot be less than 0');
  FSmallChange := Value;
end;

procedure TAbstractDIBDial.SettingsChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TAbstractDIBDial.SetVerticalPixelsPerPosition(const Value: Extended);
begin
  if (Value <= 0) then
    raise EDIBDialError.Create('VerticalPixelsPerPosition must be greater than zero');
  FVerticalPixelsPerPosition := Value;
end;

{ TCustomDIBDial }

function TCustomDIBDial.CreatePointerAngles: TCustomDIBDialPointerAngles;
begin
  Result :=  TDIBDialPointerAngles.Create;
end;

function TCustomDIBDial.CreatePointerOpacities: TCustomDIBDialPointerOpacities;
begin
  Result := TDIBDialPointerOpacities.Create;
end;

function TCustomDIBDial.GetPointerAngles: TDIBDialPointerAngles;
begin
  Result := (inherited PointerAngles as TDIBDialPointerAngles);
end;

function TCustomDIBDial.GetPointerOpacities: TDIBDialPointerOpacities;
begin
  Result := (inherited PointerOpacities as TDIBDialPointerOpacities);
end;

function TCustomDIBDial.PositionToAngle: Integer;
var
  Percircle: Extended;
  Range: Extended;
begin
  Range := Max - Min;
  Percircle := (Position - Min) * 360 / Range;
  Result := Round(SafeAngle(PointerAngles.Start + (PointerAngles.Range * Percircle / 360)));
end;

procedure TCustomDIBDial.SetPointerAngles(const Value: TDIBDialPointerAngles);
begin
  inherited PointerAngles := Value;
end;

procedure TCustomDIBDial.SetPointerOpacities(const Value: TDIBDialPointerOpacities);
begin
  inherited PointerOpacities := Value;
end;

{ TDIBDial }

constructor TDIBDial.Create(AOwner: TComponent);
begin
  inherited;
  AddTemplateProperty('AutoSize');
  AddTemplateProperty('Max');
  AddTemplateProperty('Min');
  AddTemplateProperty('Opacity');
  AddTemplateProperty('PageSize');
  AddTemplateProperty('PointerAngles');
  AddTemplateProperty('PointerOpacities');
  AddTemplateProperty('PointerNumGlyphs');
  AddTemplateProperty('PointerRadius');
  AddTemplateProperty('PointerRotate');
  AddTemplateProperty('Position');
  AddTemplateProperty('SmallChange');
  AddTemplateProperty('HorizontalPixelsPerPosition');
  AddTemplateProperty('VerticalPixelsPerPosition');
  AddTemplateProperty('MouseControlStyle');
  AddTemplateProperty('MouseLinearSensitivity');
end;

end.
