unit cDIBKnob;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBKnob.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Mouse up/down Knob components

Contributor(s):
Duncan Parsons - www.betabugsaudio.com


Last Modified: April 14, 2003

You may retrieve the latest version of this file at
http://www.droopyeyes.com


Known Issues:
To be updated !
-----------------------------------------------------------------------------}
//MODIFICATIONS
(*
Date:   January 17, 2006
By:     Duncan Parsons
Change: Added "UseFineTune" property.  If True then the mouse will move by PageSize
        instead of SmallChange, SmallChange will be used if the user holds down the
        shift key.
        If False then the mouse will always move by SmallChange.
        (ie. anything other than itself).
*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  cDIBImageList, cDIBControl, cDIB;

type
  TKnobInc = 1..32767;
  TKnobOrientation = (koVertical, koHorizontal);
  EDIBKnobError = class(EDIBError);

  TCustomDIBKnob = class(TCustomDIBControl)
  private
    { Private declarations }
    FPointerCaptured: Boolean;
    FPointerCapturePos: TPoint;
    FIndexMain: TDIBImageLink;
    FMax,
    FMin: Integer;
    FSmallChange: TKnobInc;
    FPageSize: TKnobInc;
    FPosition: Integer;
    FNumGlyphs: Integer;
    FDrawTweens: Boolean;
    FLoopLastFrame: Boolean;

    FOnChange: TNotifyEvent;
    FOrientation: TKnobOrientation;
    FUseFineTune: Boolean;
    function ActualRange: Integer;
    procedure Change;
    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetPosition(Value: Integer);
    procedure SetNumGlyphs(const Value: Integer);
    procedure SetDrawTweens(const Value: Boolean);
    procedure SetLoopLastFrame(const Value: Boolean);
  protected
    { Protected declarations }
    function CanAutoSize(var NewWidth: Integer; var NewHeight: Integer): Boolean; override;
    procedure CapturePointer; virtual;
    function GetGlyphIndex: Integer; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); override;
    procedure Loaded; override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ReleasePointer; virtual;

    property DrawTweens: Boolean read FDrawTweens write SetDrawTweens default False;
    property UseFineTune: Boolean read FUseFineTune write FUseFineTune default False;
    property IndexMain: TDIBImageLink read FIndexMain write FIndexMain;
    property Orientation: TKnobOrientation read FOrientation write FOrientation default koVertical;
    property LoopLastFrame: Boolean read FLoopLastFrame write SetLoopLastFrame default False;
    property Max: Integer read FMax write SetMax;
    property Min: Integer read FMin write SetMin;
    property NumGlyphs: Integer read FNumGlyphs write SetNumGlyphs default 1;
    property SmallChange: TKnobInc read FSmallChange write FSmallChange;
    property PageSize: TKnobInc read FPageSize write FPageSize;
    property Position: Integer read FPosition write SetPosition;

    {$I WINControlEvents.inc}
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    procedure Paint; override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    { Published declarations }
  end;

  TDIBKnob = class(TCustomDIBKnob)
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Accelerator;
    property Align;
    property Anchors;
    property AutoSize default True;
    property DIBFeatures;
    property DIBImageList;
    property DragCursor;
    property DragKind;
    property DragMode;
    property DrawTweens;
    property Enabled;
    property Hint;
    property IndexMain;
    property LoopLastFrame;
    property Max;
    property Min;
    property NumGlyphs;
    property Opacity;
    property Orientation;
    property PageSize;
    property ParentShowHint;
    property PopupMenu;
    property Position;
    property ShowHint;
    property SmallChange;
    property DIBTabOrder;
    property UseFineTune;
    property Tag;
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

{ TCustomDIBKnob }

function TCustomDIBKnob.ActualRange: Integer;
begin
  Result := Max - Min + 1;
end;

constructor TCustomDIBKnob.Create(AOwner: TComponent);
begin
  inherited;
  AddIndexProperty(FIndexMain);
  AutoSize := True;
  FMax := 100;
  FMin := 0;
  FPosition := 0;
  FSmallChange := 1;
  FPageSize := 5;
  FNumGlyphs := 1;
  FOrientation := koVertical;
end;

destructor TCustomDIBKnob.Destroy;
begin
  FIndexMain.Free;
  inherited;
end;

procedure TCustomDIBKnob.ImageChanged(Index: Integer; Operation: TDIBOperation);
begin
  if AutoSize then
    AdjustSize;
end;

procedure TCustomDIBKnob.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  case Key of
    VK_LEFT: Position := Position - SmallChange;
    VK_RIGHT: Position := Position + SmallChange;
    VK_UP: Position := Position + SmallChange;
    VK_DOWN: Position := Position - SmallChange;
    VK_PRIOR: Position := Position + PageSize;
    VK_NEXT: Position := Position - PageSize;
  end;
end;

procedure TCustomDIBKnob.Loaded;
begin
  inherited;
  if AutoSize then AdjustSize;
end;

procedure TCustomDIBKnob.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
    CapturePointer;
end;

procedure TCustomDIBKnob.MouseMove(Shift: TShiftState; X,
  Y: Integer);
var
  Distance: Integer;
  CurrentCursor: TPoint;
begin
  inherited;
  if FPointerCaptured then
  begin
    GetCursorPos(CurrentCursor);
    if Orientation = koVertical then
      Distance := FPointerCapturePos.Y - CurrentCursor.Y
    else
      Distance := CurrentCursor.X - FPointerCapturePos.X;

    if Distance <> 0 then
    begin
      if not UseFineTune then
        Position := Position + (Distance * SmallChange)
      else
        if ssShift in Shift then
          Position := Position + (Distance * SmallChange)
        else
          Position := Position + (Distance * PageSize);

      SetCursorPos(FPointerCapturePos.X, FPointerCapturePos.Y);
    end;
  end;
end;

procedure TCustomDIBKnob.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
    ReleasePointer;
end;

procedure TCustomDIBKnob.Paint;
var
  D: TMemoryDIB;
begin
  inherited;
  if IndexMain.GetImage(D) then
    if DrawTweens then
      D.DrawGlyphTween(0, 0, NumGlyphs, ControlDIB, Min, Max, Position, LoopLastFrame)
    else
      D.DrawGlyph(0, 0, GetGlyphIndex, NumGlyphs, ControlDIB);
end;

procedure TCustomDIBKnob.SetMax(const Value: Integer);
begin
  FMax := Value;
  if Max <= Min then Min := Max - 1;
  if Max < Position then Position := Max;
  Invalidate;
end;

procedure TCustomDIBKnob.SetMin(const Value: Integer);
begin
  FMin := Value;
  if Min >= Max then Max := Min + 1;
  if Min > Position then Position := Min;
  Invalidate;
end;

procedure TCustomDIBKnob.SetPosition(Value: Integer);

begin
  if Value < Min then
     Value := Min
  else if Value > Max then
    Value := Max;
  if Value <> FPosition then
  begin
    FPosition := Value;
    Change;
  end;
  Invalidate;
end;

function TCustomDIBKnob.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
var
  D: TMemoryDIB;
begin
  Result := True;
  if IndexMain.GetImage(D) then
  begin
    NewWidth := D.Width div NumGlyphs;
    NewHeight := D.Height;
  end;
end;

procedure TCustomDIBKnob.SetNumGlyphs(const Value: Integer);
begin
  if Value < 1 then
    raise EDIBKnobError.Create('NumGlyphs must be greater than 0.');
  FNumGlyphs := Value;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCustomDIBKnob.CapturePointer;
begin
  FPointerCaptured := True;
  GetCursorPos(FPointerCapturePos);
  ShowCursor(False);
end;

procedure TCustomDIBKnob.ReleasePointer;
begin
  FPointerCaptured := False;
  SetCursorPos(FPointerCapturePos.X, FPointerCapturePos.Y);
  ShowCursor(True);
end;

procedure TCustomDIBKnob.SetDrawTweens(const Value: Boolean);
begin
  FDrawTweens := Value;
  Invalidate;
end;

procedure TCustomDIBKnob.SetLoopLastFrame(const Value: Boolean);
begin
  FLoopLastFrame := Value;
  Invalidate;
end;

function TCustomDIBKnob.GetGlyphIndex: Integer;
var
  I: Integer;
begin
  I := Position - Min;
  Result := (I * NumGlyphs div ActualRange);
end;

procedure TCustomDIBKnob.Change;
begin
  if Assigned(OnChange) then OnChange(Self);
end;

{ TDIBKnob }

constructor TDIBKnob.Create(AOwner: TComponent);
begin
  inherited;
  AddTemplateProperty('AutoSize');
  AddTemplateProperty('DrawTweens');
  AddTemplateProperty('LoopLastFrame');
  AddTemplateProperty('Min');
  AddTemplateProperty('Max');
  AddTemplateProperty('NumGlyphs');
  AddTemplateProperty('Opacity');
  AddTemplateProperty('Orientation');
  AddTemplateProperty('PageSize');
  AddTemplateProperty('Position');
  AddTemplateProperty('SmallChange');
end;

end.
