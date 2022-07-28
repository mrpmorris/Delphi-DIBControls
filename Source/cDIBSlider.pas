unit cDIBSlider;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBSlider.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
This is an implementation of the Slider component.

Contributor(s):
None as yet


Last Modified: November 16, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
Need to add a StretchPointer property so that this component can also be a scrollbar

Allow the <- and -> to both be at the top or bottom (like on an apple mac)
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   October 4, 2000
BY:     Peter Morris
Change: Added a StretchBackground property, if false the background is tiled.

Date:   November 16, 2001
By:     CAM Moorman (nthdominion@earthlink.net
Bug:    GUI: Small Max-Min would result in an additional scroll increment
        ex: Scrollbar of Min:0 Max:1 would get 3 small changes (Pos:0/1/1)
            should get 2 (Pos:0/1)
Change: Visual and Actual Ranges now compute correctly
*)


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBImageList, cDIBControl, cDIB;

type
  TSliderType = (stHorizontal, stVertical);
  TSliderInc = 1..32767;

  TCustomDIBSlider = class(TCustomDIBControl)
  private
    { Private declarations }
    FCapturePosition: TPoint;
    FCapturePointer: Boolean;
    FPointerPosition: Integer;
    FPointerOpacityLow,
    FPointerOpacityHigh: Byte;
    FIndexEnd1,
    FIndexEnd2,
    FIndexMain,
    FIndexOverlay,
    FIndexPointer: TDIBImageLink;
    FLargeChange: TSliderInc;
    FLastPosition: Integer;
    FMax,
    FMin: Integer;
    FOverlayOpacity,
    FOverlayBorderX,
    FOverlayBorderY: Byte;
    FPointerOffset: Integer;
    FRectEnd1,
    FRectEnd2,
    FRectMain,
    FRectOverlay,
    FRectPointer: TRect;
    FSliderType: TSliderType;
    FSmallChange: TSliderInc;
    FPageSize: TSliderInc;
    FPosition: Integer;
    FStretchBackground: Boolean;

    FOnChange: TNotifyEvent;
    function ActualRange: Integer;
    function CalcPointerFromPosition(const P: Integer): Integer;
    function CalcPositionFromPointer(const P: Integer): Integer;
    procedure CalcRects;
    procedure SetSliderType(const Value: TSliderType);
    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetPosition(const Value: Integer);
    procedure SetPointerPosition(const Value: Integer);
    procedure SetPointerOpacityLow(const Value: Byte);
    procedure SetPointerOpacityHigh(const Value: Byte);
    function VisualRange: Integer;
    procedure SetPointerOffset(const Value: Integer);
    procedure SetOverlayBorderX(const Value: Byte);
    procedure SetOverlayBorderY(const Value: Byte);
    procedure SetOverlayOpacity(const Value: Byte);
    procedure SetStretchBackground(const Value: Boolean);
  protected
    { Protected declarations }
    function CalcMinimumSize: TPoint; virtual;
    function CanAutoSize(var NewWidth: Integer; var NewHeight: Integer): Boolean; override;
    procedure Change; virtual;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); override;
    procedure Loaded; override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    property IndexEnd1: TDIBImageLink read FIndexEnd1 write FIndexEnd1;
    property IndexEnd2: TDIBImageLink read FIndexEnd2 write FIndexEnd2;
    property IndexMain: TDIBImageLink read FIndexMain write FIndexMain;
    property IndexOverlay: TDIBImageLink read FIndexOverlay write FIndexOverlay;
    property IndexPointer: TDIBImageLink read FIndexPointer write FIndexPointer;
    property LargeChange: TSliderInc read FLargeChange write FLargeChange;
    property Max: Integer read FMax write SetMax;
    property Min: Integer read FMin write SetMin;
    property OverlayBorderX: Byte read FOverlayBorderX write SetOverlayBorderX default 0;
    property OverlayBorderY: Byte read FOverlayBorderY write SetOverlayBorderY default 0;
    property OverlayOpacity: Byte read FOverlayOpacity write SetOverlayOpacity default 64;
    property PointerOffset: Integer read FPointerOffset write SetPointerOffset;
    property PointerOpacityLow: Byte read FPointerOpacityLow write SetPointerOpacityLow
      default 196;
    property PointerOpacityHigh: Byte read FPointerOpacityHigh write SetPointerOpacityHigh
      default 255;
    property PointerPosition: Integer read FPointerPosition write SetPointerPosition;
    property SliderType: TSliderType read FSliderType write SetSliderType;
    property SmallChange: TSliderInc read FSmallChange write FSmallChange;
    property PageSize: TSliderInc read FPageSize write FPageSize;
    property Position: Integer read FPosition write SetPosition;
    property StretchBackground: Boolean read FStretchBackground write SetStretchBackground;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;


    procedure Paint; override;

  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    { Published declarations }
  end;

  TDIBSlider = class(TCustomDIBSlider)
  published
    property Accelerator;
    property Align;
    property Anchors;
    property AutoSize;
    property Constraints;
    property DIBFeatures;
    property DIBImageList;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property IndexEnd1;
    property IndexEnd2;
    property IndexMain;
    property IndexOverlay;
    property IndexPointer;
    property LargeChange;
    property Max;
    property Min;
    property Opacity;
    property OverlayBorderX;
    property OverlayBorderY;
    property OverlayOpacity;
    property PageSize;
    property ParentShowHint;
    property PointerOffset;
    property PointerOpacityHigh;
    property PointerOpacityLow;
    property PopupMenu;
    property Position;
    property ShowHint;
    property SliderType;
    property SmallChange;
    property DIBTabOrder;
    property StretchBackground;
    property Tag;
    property Visible;

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
    property OnStartDrag;
    {$I WinControlEvents.inc}
  end;

implementation

type
  EDIBSliderError = class(Exception);

  { TCustomDIBSlider }

function TCustomDIBSlider.ActualRange: Integer;
begin
  //CAM**  Result := Max - Min + 1;
  Result := Max - Min;
end;

function TCustomDIBSlider.CalcMinimumSize: TPoint;
var
  TheDIB: TMemoryDIB;
begin
  Result.x := 2;
  Result.y := 2;
  if IndexEnd1.GetImage(TheDIB) then
  begin
    Result.x := Result.x + TheDIB.Width;
    Result.y := Result.y + TheDIB.Height;
  end;
  if IndexMain.GetImage(TheDIB) then 
  begin
    Result.x := Result.x + TheDIB.Width;
    Result.y := Result.y + TheDIB.Height;
  end;
  if IndexEnd2.GetImage(TheDIB) then 
  begin
    Result.x := Result.x + TheDIB.Width;
    Result.y := Result.y + TheDIB.Height;
  end;
  case SliderType of
    stHorizontal: Result.y := 2;
    stVertical: Result.x := 2;
  end;
end;

function TCustomDIBSlider.CalcPointerFromPosition(const P: Integer): Integer;
begin
  //CAM**  Result := (P - Min) * VisualRange div ActualRange;
  if ActualRange <> 0 then
    Result := (P - Min) * VisualRange div ActualRange
  else
    Result := (P - Min) * VisualRange;

  if Result < 0 then
    Result := 0
  else if Result > VisualRange then
    Result := VisualRange;
end;

function TCustomDIBSlider.CalcPositionFromPointer(const P: Integer): Integer;
begin
  //CAM**  Result := (P * ActualRange div VisualRange) + Min;
  Result := P * ActualRange div VisualRange;
  
  if Result < Min then
    Result := Min
  else if Result > Max then
    Result := Max;
end;

procedure TCustomDIBSlider.CalcRects;
var
  TheImage: TMemoryDIB;
  XPos, YPos: Integer;
begin
  FRectEnd1 := Rect(-1, - 1, - 1, - 1);
  FRectEnd2 := Rect(Width, Height, Width, Height);
  FRectMain := FRectEnd1;
  FRectPointer := FRectEnd1;

  //End1 = Top or Left
  if IndexEnd1.GetImage(TheImage) then 
  begin
    XPos := 0;
    YPos := 0;
    case SliderType of
      stHorizontal: YPos := (Height div 2) - (TheImage.Height div 2);
      stVertical: XPos := (Width div 2) - (TheImage.Width div 2);
    end;
    FRectEnd1 := Rect(XPos, YPos, XPos + TheImage.Width - 1, YPos + TheImage.Height - 1);
  end;

  //End2 = Bottom or right
  if IndexEnd2.GetImage(TheImage) then 
  begin
    XPos := (Width - 1) - TheImage.Width;
    YPos := (Height - 1) - TheImage.Height;
    case SliderType of
      stHorizontal:
        begin
          YPos := (Height div 2) - (TheImage.Height div 2);
          if XPos <= FRectEnd1.Right then XPos := FRectEnd1.Right;
        end;
      stVertical:
        begin
          XPos := (Width div 2) - (TheImage.Width div 2);
          if YPos <= FRectEnd1.Bottom then YPos := FRectEnd1.Bottom;
        end;
    end;
    FRectEnd2 := Rect(XPos, YPos, XPos + TheImage.Width - 1, YPos + TheImage.Height - 1);
  end;

  //Main is the stretchy bit
  if IndexMain.GetImage(TheImage) then 
  begin
    FRectMain.Left := FRectEnd1.Right;
    FRectMain.Top := FRectEnd1.Bottom;
    FRectMain.Right := FRectEnd2.Left;
    FRectMain.Bottom := FRectEnd2.Top;

    case SliderType of
      stHorizontal:
        begin
          FRectMain.Top := (Height div 2) - (TheImage.Height div 2);
          FRectMain.Bottom := (FRectMain.Top + (TheImage.Height - 1));
        end;
      stVertical:
        begin
          FRectMain.Left := (Width div 2) - (TheImage.Width div 2);
          FRectMain.Right := (FRectMain.Left + (TheImage.Width - 1));
        end;
    end;
  end;

  //Overlay is used for a progress-bar type effect
  FRectOverLay := Rect(FRectMain.Left + OverlayBorderX,
    FRectMain.Top + OverlayBorderY,
    FRectMain.Right - OverlayBorderX,
    FRectMain.Bottom - OverlayBorderY);

  //Pointer is the little twiddly bit
  if IndexPointer.GetImage(TheImage) then 
  begin
    XPos := 0;
    YPos := 0;
    case SliderType of
      stHorizontal:
        begin
          XPos := FRectMain.Left + FPointerPosition;
          YPos := (Height div 2) - (TheImage.Height div 2) + FPointerOffset;
        end;

      stVertical:
        begin
          XPos := (Width div 2) - (TheImage.Width div 2) + FPointerOffset;
          YPos := FRectMain.Top + FPointerPosition;
        end;
    end;
    FRectPointer := Rect(XPos, YPos, XPos + TheImage.Width - 1, YPos + TheImage.Height - 1);
  end;
end;

function TCustomDIBSlider.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;

  function Biggest(End1, End2, Current: Integer): Integer;
  begin
    Result := End2 - (End1 - 1);
    if Result < Current then Result := Current;
  end;

var
  MaxSize: Integer;
  MinSize: TPoint;
begin
  Result := False;
  if not FIndexMain.Valid then exit;

  MinSize := CalcMinimumSize;
  if NewWidth < MinSize.x then NewWidth := MinSize.x;
  if NewHeight < MinSize.y then NewHeight := MinSize.y;

  CalcRects;
  MaxSize := 0;
  case SliderType of
    stHorizontal:
      begin
        MaxSize := Biggest(FRectEnd1.Top, FRectEnd1.Bottom, MaxSize);
        MaxSize := Biggest(FRectEnd2.Top, FRectEnd2.Bottom, MaxSize);
        MaxSize := Biggest(FRectMain.Top, FRectMain.Bottom, MaxSize);
        if MaxSize < Constraints.MinHeight then
          MaxSize := Constraints.MinHeight;
        if MaxSize > 0 then
          if MaxSize <> NewHeight then NewHeight := MaxSize;
      end;
    stVertical:
      begin
        MaxSize := Biggest(FRectEnd1.Left, FRectEnd1.Right, MaxSize);
        MaxSize := Biggest(FRectEnd2.Left, FRectEnd2.Right, MaxSize);
        MaxSize := Biggest(FRectMain.Left, FRectMain.Right, MaxSize);
        if MaxSize < Constraints.MinWidth then
          MaxSize := Constraints.MinWidth;
        if MaxSize > 0 then
          if MaxSize <> NewWidth then NewWidth := MaxSize;
      end;
  end;
  Result := True;
end;

procedure TCustomDIBSlider.Change;
begin
  if FLastPosition <> Position then
    if Assigned(FOnChange) then FOnChange(Self);
  FLastPosition := Position;
end;

constructor TCustomDIBSlider.Create(AOwner: TComponent);
begin
  inherited;
  AddIndexProperty(FIndexEnd1);
  AddIndexProperty(FIndexEnd2);
  AddIndexProperty(FIndexMain);
  AddIndexProperty(FIndexOverlay);
  AddIndexProperty(FIndexPointer);
  FRectEnd1 := Rect(-1, - 1, - 1, - 1);
  FRectEnd2 := Rect(-1, - 1, - 1, - 1);
  FRectMain := Rect(-1, - 1, - 1, - 1);
  FRectPointer := Rect(-1, - 1, - 1, - 1);
  FMax := 100;
  FMin := 0;
  FPosition := 0;
  FPointerPosition := 0;
  FCapturePointer := False;
  FPointerOpacityHigh := 255;
  FPointerOpacityLow := 196;
  FSmallChange := 1;
  FLargeChange := 5;
  FPageSize := 5;
  AutoSize := True;
  MouseRepeat := True;
  FPointerOffset := 0;
  FOverlayBorderX := 0;
  FOverlayBorderY := 0;
  FOverlayOpacity := 64;
  FStretchBackground := True;

  AddTemplateProperty('AutoSize');
  AddTemplateProperty('LargeChange');
  AddTemplateProperty('Min');
  AddTemplateProperty('Max');
  AddTemplateProperty('Opacity');
  AddTemplateProperty('OverlayBorderX');
  AddTemplateProperty('OverlayBorderY');
  AddTemplateProperty('OverlayOpacity');
  AddTemplateProperty('PageSize');
  AddTemplateProperty('PointerOffset');
  AddTemplateProperty('PointerOpacityHigh');
  AddTemplateProperty('PointerOpacityLow');
  AddTemplateProperty('Position');
  AddTemplateProperty('SliderType');
  AddTemplateProperty('SmallChange');
  AddTemplateProperty('StretchBackground');
end;

destructor TCustomDIBSlider.Destroy;
begin
  FIndexEnd1.Free;
  FIndexEnd2.Free;
  FIndexMain.Free;
  FIndexOverlay.Free;
  FIndexPointer.Free;
  inherited;
end;

procedure TCustomDIBSlider.DoEnter;
begin
  inherited;
  Invalidate;
end;

procedure TCustomDIBSlider.DoExit;
begin
  inherited;
  Invalidate;
end;

procedure TCustomDIBSlider.ImageChanged(Index: Integer; Operation: TDIBOperation);
begin
  if AutoSize then
    AdjustSize
  else
    CalcRects;
end;

procedure TCustomDIBSlider.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  case SliderType of
    stHorizontal:
      begin
        case Key of
          VK_LEFT: Position := Position - SmallChange;
          VK_RIGHT: Position := Position + SmallChange;
        end;
      end;

    stVertical:
      begin
        case Key of
          VK_UP: Position := Position - SmallChange;
          VK_DOWN: Position := Position + SmallChange;
        end;
      end;
  end;

  case Key of
    VK_PRIOR: Position := Position - PageSize;
    VK_NEXT: Position := Position + PageSize;
  end;
end;

procedure TCustomDIBSlider.Loaded;
begin
  inherited;
  FLastPosition := Position;
  if AutoSize then AdjustSize;
  FPointerPosition := CalcPointerFromPosition(FPosition);
  CalcRects;
end;


procedure TCustomDIBSlider.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  MaxAllowedRange, Range: Integer;
  ShouldCapture: Boolean;
begin
  inherited;
  if not IndexPointer.Valid then exit;

  ShouldCapture := False;
  //If the X,Y is within the rect, then we capture
  if PtInRect(FRectPointer, Point(X, Y)) then
    ShouldCapture := True
  else //If MouseRepeating, we should capture if X/Y is within the Left & Right/ Top & Botton
  //range, this is because PointerOffset may cause the pointer to be inline with the
  //cursor but not actually beneath it (Or the cursor may not be within the slider)
  if IsMouseRepeating then
    case SliderType of
      stHorizontal:
        if (X >= FRectPointer.Left) and (X <= FRectPointer.Right) then
          ShouldCapture := True;
      stVertical:
        if (Y >= FRectPointer.Top) and (Y <= FRectPointer.Bottom) then
          ShouldCapture := True;
    end;

  if ShouldCapture then
  begin
    StopRepeating;
    FCapturePointer := True;
    FCapturePosition := Point(X - FRectPointer.Left, Y - FRectPointer.Top);
    Invalidate;
  end 
  else if PtInRect(FRectEnd1, Point(X, Y)) then
    Position := Position - SmallChange
  else if PtInRect(FRectEnd2, Point(X, Y)) then
    Position := Position + SmallChange
  else 
  begin
    Range := 0;
    case SliderType of
      stHorizontal:
        begin
          Range := X - FRectPointer.Left - ((FRectPointer.Right - FRectPointer.Left) div 2);
        end;

      stVertical:
        begin
          Range := Y - FRectPointer.Top - ((FRectPointer.Bottom - FRectPointer.Top) div 2);
        end;
    end;

    MaxAllowedRange := CalcPositionFromPointer(Abs(Range));
    if MaxAllowedRange > LargeChange then
      MaxAllowedRange := LargeChange;

    if Range < 0 then
      Position := Position - MaxAllowedRange
    else
      Position := Position + MaxAllowedRange;
  end;
end;

procedure TCustomDIBSlider.MouseMove(Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  if FCapturePointer then 
  begin
    case SliderType of
      stHorizontal: PointerPosition := X - FRectMain.Left - FCapturePosition.X;
      stVertical: PointerPosition := Y - FRectMain.Top - FCapturePosition.Y;
    end;
  end;
end;

procedure TCustomDIBSlider.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FCapturePointer then Invalidate;
  FCapturePointer := False;
  inherited;
end;

procedure TCustomDIBSlider.Paint;
var
  TheDIB: TMemoryDIB;
  TempDIB: TMemoryDIB;
  NewClip, OrigClip: TRect;
  Position, FinalPosition, IncPosition, OverlayWidth, OverlayHeight: Integer;
begin
  if IndexMain.GetImage(TheDIB) then
  begin
    if FStretchBackground then 
    begin
      TempDIB :=
        TMemoryDIB.Create(FRectMain.Right - (FRectMain.Left - 1),
        FRectMain.Bottom - (FRectMain.Top - 1));
      try
        TempDIB.StretchCopyPicture(TheDIB);
        TheDIB.AssignHeaderTo(TempDIB);
        TempDIB.Draw(FRectMain.Left, FRectMain.Top,
          FRectMain.Right - (FRectMain.Left - 1), FRectMain.Bottom - (FRectMain.Top - 1),
          ControlDIB, 0, 0);
      finally
        TempDIB.Free;
      end;
    end 
    else 
    begin
      OrigClip := ControlDIB.ClipRect;
      try
        IntersectRect(NewClip, OrigClip, FRectMain);
        ControlDIB.ClipRect := NewClip;

        if SliderType = stHorizontal then 
        begin
          Position := FRectMain.Left;
          FinalPosition := FRectMain.Right;
          IncPosition := TheDIB.Width;
        end 
        else 
        begin
          Position := FRectMain.Top;
          FinalPosition := FRectMain.Bottom;
          IncPosition := TheDIB.Height;
        end;

        while (Position < FinalPosition) do 
        begin
          if SliderType = stHorizontal then
            TheDIB.Draw(Position, FRectMain.Top, TheDIB.Width, TheDIB.Height,
              ControlDIB, 0, 0)
          else
            TheDIB.Draw(FRectMain.Left, Position, TheDIB.Width, TheDIB.Height,
              ControlDIB, 0, 0);

          Inc(Position, IncPosition);
        end;
      finally
        ControlDIB.ClipRect := OrigClip;
      end;
    end;
  end;

  if IndexOverlay.GetImage(TheDIB) then 
  begin
    TempDIB :=
      TMemoryDIB.Create(FRectOverlay.Right - (FRectOverlay.Left - 1),
      FRectOverlay.Bottom - (FRectOverlay.Top - 1));
    try
      TempDIB.StretchCopyPicture(TheDIB);
      TheDIB.AssignHeaderTo(TempDIB);
      TempDIB.Opacity := OverlayOpacity;

      OverlayWidth := 0;
      OverlayHeight := 0;

      //Now, we only draw as far as the pointer position
      case SliderType of
        stHorizontal:
          begin
            if csDesigning in ComponentState then
              OverlayWidth := FRectOverlay.Right - (FRectOverlay.Left - 1)
            else
              OverlayWidth := FPointerPosition - OverlayBorderX;
            OverlayHeight := FRectOverlay.Bottom - (FRectOverlay.Top - 1);
          end;

        stVertical:
          begin
            OverlayWidth := FRectOverlay.Left - (FRectOverlay.Right - 1);
            if csDesigning in ComponentState then
              OverlayHeight := FRectOverlay.Bottom - (FRectOverlay.Top - 1)
            else
              OverlayHeight := FPointerPosition - OverlayBorderY;
          end;
      end;


      TempDIB.Draw(FRectOverlay.Left, FRectOverlay.Top, OverlayWidth, OverlayHeight,
        ControlDIB, 0, 0);
    finally
      TempDIB.Free;
    end;
  end;

  if IndexEnd1.GetImage(TheDIB) then
    TheDIB.Draw(FRectEnd1.Left, FRectEnd1.Top, TheDIB.Width, TheDIB.Height,
      ControlDIB, 0, 0);
  if IndexEnd2.GetImage(TheDIB) then
    TheDIB.Draw(FRectEnd2.Left, FRectEnd2.Top, TheDIB.Width, TheDIB.Height,
      ControlDIB, 0, 0);
  if IndexPointer.GetImage(TheDIB) then
  begin
    if FCapturePointer then
      TheDIB.Opacity := PointerOpacityHigh
    else
      TheDIB.Opacity := PointerOpacityLow;
    TheDIB.Draw(FRectPointer.Left, FRectPointer.Top, TheDIB.Width,
      TheDIB.Height, ControlDIB, 0, 0);
  end;
end;

procedure TCustomDIBSlider.SetBounds(ALeft, ATop, AWidth,
  AHeight: Integer);
var
  MinSize: TPoint;
begin
  MinSize := CalcMinimumSize;
  if aWidth < MinSize.x then aWidth := MinSize.x;
  if aHeight < MinSize.y then aHeight := MinSize.y;
  inherited;
  if not Creating then
  begin
    FPointerPosition := CalcPointerFromPosition(FPosition);
    CalcRects;
    Invalidate;
  end;
end;

procedure TCustomDIBSlider.SetMax(const Value: Integer);
begin
  FMax := Value;
  if Max <= Min then Min := Max - 1;
  if Max < Position then Position := Max;
end;

procedure TCustomDIBSlider.SetMin(const Value: Integer);
begin
  FMin := Value;
  if Min >= Max then Max := Min + 1;
  if Min > Position then Position := Min;
end;

procedure TCustomDIBSlider.SetOverlayBorderX(const Value: Byte);
begin
  FOverlayBorderX := Value;
  if AutoSize then
    AdjustSize
  else
    CalcRects;
  Invalidate;
end;

procedure TCustomDIBSlider.SetOverlayBorderY(const Value: Byte);
begin
  FOverlayBorderY := Value;
  if AutoSize then
    AdjustSize
  else
    CalcRects;
  Invalidate;
end;

procedure TCustomDIBSlider.SetOverlayOpacity(const Value: Byte);
begin
  FOverlayOpacity := Value;
  Invalidate;
end;

procedure TCustomDIBSlider.SetPointerOffset(const Value: Integer);
begin
  FPointerOffset := Value;
  if AutoSize then
    AdjustSize
  else
    CalcRects;
  Invalidate;
end;

procedure TCustomDIBSlider.SetPointerOpacityHigh(const Value: Byte);
begin
  FPointerOpacityHigh := Value;
  invalidate;
end;

procedure TCustomDIBSlider.SetPointerOpacityLow(const Value: Byte);
begin
  FPointerOpacityLow := Value;
  Invalidate;
end;

procedure TCustomDIBSlider.SetPointerPosition(const Value: Integer);
begin
  if VisualRange = 0 then exit;

  if Value < 0 then
    FPointerPosition := 0
  else if Value > VisualRange then
    FPointerposition := VisualRange
  else
    FPointerPosition := Value;
  FPosition := CalcPositionFromPointer(Value);
  CalcRects;
  Invalidate;
  Change;
end;

procedure TCustomDIBSlider.SetPosition(const Value: Integer);
begin
  if Value < Min then
    FPosition := Min
  else if Value > Max then
    FPosition := Max
  else
    FPosition := Value;

  FPointerPosition := CalcPointerFromPosition(Value);
  CalcRects;
  Invalidate;
  Change;
end;

procedure TCustomDIBSlider.SetSliderType(const Value: TSliderType);
begin
  FSliderType := Value;
  if AutoSize then
    AdjustSize
  else
    CalcRects;
  Invalidate;
end;

procedure TCustomDIBSlider.SetStretchBackground(const Value: Boolean);
begin
  FStretchBackground := Value;
  Invalidate;
end;

function TCustomDIBSlider.VisualRange: Integer;
begin
  Result := 0;
  case SliderType of
    stHorizontal:
      begin
        Result := FRectMain.Right - (FRectMain.Left - 1);
        Result := Result - (FRectPointer.Right - (FRectPointer.Left - 1));
      end;
    stVertical:
      begin
        Result := FRectMain.Bottom - (FRectMain.Top - 1);
        Result := Result - (FRectPointer.Bottom - (FRectPointer.Top - 1));
      end;
  end;
end;

end.
