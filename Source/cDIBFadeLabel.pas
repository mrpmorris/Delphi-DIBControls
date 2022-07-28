unit cDIBFadeLabel;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBFadeLabel.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
A label that highlights when the mouse enters (or it is focused) and then
fades over X steps at X speed back to the original colour.

Contributor(s):
None as yet


Last Modified: August 28, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
Colours can get all screwed up at design time.  Something to do with Transparency.

Need to take into account the Angle property when calculating the BoundsRect for AutoSize
-----------------------------------------------------------------------------}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBControl, cDIB, extctrls, cDIBTimer;

type
  TTextLayout = (tlTop, tlCenter, tlBottom);
  TCustomDIBFadeLabel = class(TCustomDIBControl)
  private
    FTimer: TDIBTimer;
    FCurrentColor: TColor;
    FCurrentColorIndex: Integer;
    FColorTable: TList;
    FColorHighlighted: TColor;
    FFrameCount: Byte;
    FFrameDelay: Cardinal;
    FAngle: Extended;
    FAlignment: TAlignment;
    FLayout: TTextLayout;
    FScale: Extended;
    FShowAccelChar: Boolean;
    FTransparent: Boolean;
    FWordWrap: Boolean;

    procedure DoTimer(Sender: TObject);
    procedure SetTransparent(const Value: Boolean);
    procedure SetAlignment(const Value: TAlignment);
    procedure SetWordWrap(const Value: Boolean);
    procedure SetLayout(const Value: TTextLayout);
    procedure SetShowAccelChar(const Value: Boolean);
    procedure SeExtended(const Value: Extended);
    procedure SetScale(const Value: Extended);
    procedure SetColorHighLighted(const Value: TColor);
    procedure SetFrameCount(const Value: Byte);
    procedure SetFrameDelay(const Value: Cardinal);

    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
  protected
    procedure CalcColorTable; dynamic;
    function CanAutoSize(var NewWidth: Integer; var NewHeight: Integer): Boolean; override;
    procedure DoAnyEnter; override;
    procedure DoAnyLeave; override;
    procedure DoDrawText(var Rect: TRect; Flags: Longint); virtual;
    procedure KeyPress(var Key: Char); override;
    procedure Loaded; override;
    procedure Paint; override;

    property Angle: Extended read FAngle write SeExtended;
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property ColorHighLighted: TColor read FColorHighLighted write SetColorHighLighted;
    property FrameCount: Byte read FFrameCount write SetFrameCount;
    property FrameDelay: Cardinal read FFrameDelay write SetFrameDelay;
    property Layout: TTextLayout read FLayout write SetLayout;
    property Scale: Extended read FScale write SetScale;
    property ShowAccelChar: Boolean read FShowAccelChar write SetShowAccelChar;
    property Transparent: Boolean read FTransparent write SetTransparent;
    property WordWrap: Boolean read FWordWrap write SetWordWrap;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
  end;

  TDIBFadeLabel = class(TCustomDIBFadeLabel)
  private
  protected
  public
  published
    property Align;
    property Alignment default taLeftJustify;
    property Anchors;
    property Angle;
    property AutoSize default False;
    property BidiMode;
    property Caption;
    property Children;
    property Color;
    property ColorHighlighted;
    property Constraints;
    property Cursor;
    property DIBFeatures;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FrameCount;
    property FrameDelay;
    property Hint;
    property Layout;
    property Opacity;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Scale;
    property DIBTabOrder;
    property Tag;
    property Transparent;
    property Visible;
    property WordWrap;

    {$I WinControlEvents.inc}
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
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
  end;

implementation

type
  THackAbstractSuperDIB = class(TAbstractSuperDIB);

  { TCustomDIBFadeLabel }


procedure TCustomDIBFadeLabel.CalcColorTable;
var
  X: Integer;
  RAdj, GAdj, BAdj, CR, CG, CB: Extended;
  TempCol: Longint;

  function MakeColor: Longint;
  begin
    Result := Byte(Trunc(CR));
    Result := (Result shl 8) + Byte(Trunc(CG));
    Result := (Result shl 8) + Byte(Trunc(CB));
  end;
begin
  FColorTable.Clear;
  if FFrameCount <= 1 then exit;

  TempCol := ColorToRGB(Font.Color);
  CB := TempCol and 255;

  TempCol := TempCol shr 8;
  CG := TempCol and 255;

  TempCol := TempCol shr 8;
  CR := TempCol and 255;

  TempCol := ColorToRGB(ColorHighlighted);
  BAdj := (TempCol and 255) - CB;

  TempCol := TempCol shr 8;
  GAdj := (TempCol and 255) - CG;

  TempCol := TempCol shr 8;
  RAdj := (TempCol and 255) - CR;

  RAdj := RAdj / FFrameCount;
  GAdj := GAdj / FFrameCount;
  BAdj := BAdj / FFrameCount;

  for X := 0 to FFrameCount - 1 do 
  begin
    CR := CR + RAdj;
    CG := CG + GAdj;
    CB := CB + BAdj;
    TempCol := MakeColor;
    FColorTable.Add(Pointer(TempCol));
  end;
end;

procedure TCustomDIBFadeLabel.CMDialogChar(var Message: TCMDialogChar);
begin
  if Enabled and IsAccel(Message.CharCode, Caption) and FShowAccelChar and
    Parent.Canfocus then
  begin
    Click;
    Message.Result := 1;
  end;
end;

procedure TCustomDIBFadeLabel.CMFontChanged(var Message: TMessage);
begin
  if not MouseInControl then FCurrentColor := Font.Color;
  if AutoSize then AdjustSize;
  CalcColorTable;
  Invalidate;
end;

procedure TCustomDIBFadeLabel.CMTextChanged(var Message: TMessage);
begin
  if AutoSize then AdjustSize;
  Invalidate;
end;

constructor TCustomDIBFadeLabel.Create(AOwner: TComponent);
begin
  inherited;
  FTimer := TDIBTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := DoTimer;
  FColorTable := TList.Create;
  ControlStyle := ControlStyle + [csSetCaption];
  FShowAccelChar := True;
  AutoSize := False;
  FScale := 100;
  FAngle := 0;
  FFrameCount := 10;
  FFrameDelay := 50;
  FTransparent := True;
  Alignment := taLeftJustify;
  ColorHighLighted := clWhite;
end;

destructor TCustomDIBFadeLabel.Destroy;
begin
  FTimer.Free;
  FColorTable.Free;
  inherited;
end;

procedure TCustomDIBFadeLabel.DoDrawText(var Rect: TRect; Flags: Longint);
var
  Text: string;
begin
  Text := Caption;
  if (Flags and DT_CALCRECT <> 0) and ((Text = '') or FShowAccelChar and
    (Text[1] = '&') and (Text[2] = #0)) then Text := Text + ' ';
  if not FShowAccelChar then Flags := Flags or DT_NOPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);
  Canvas.Font := Font;
  Canvas.Font.Color := FCurrentColor;
  Canvas.Brush.Style := bsClear;
  if not Enabled then
  begin
    OffsetRect(Rect, 1, 1);
    Canvas.Font.Color := ColorHighLighted;
    DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect, Flags);
    OffsetRect(Rect, - 1, - 1);
    Canvas.Font.Color := Font.Color;
    DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect, Flags);
  end
  else
    DrawText(Canvas.Handle, PChar(Text), Length(Text), Rect, Flags);
end;

procedure TCustomDIBFadeLabel.DoTimer(Sender: TObject);
begin
  if FCurrentColorIndex = 0 then 
  begin
    FTimer.Enabled := False;
    FCurrentColor := Font.Color;
  end 
  else 
  begin
    FCurrentColor := Integer(FColorTable[FCurrentColorIndex]);
    Dec(FCurrentColorIndex);
  end;
  invalidate;
end;

procedure TCustomDIBFadeLabel.DoAnyEnter;
begin
  FTimer.Enabled := False;
  FCurrentColor := ColorHighlighted;
  invalidate;
end;

procedure TCustomDIBFadeLabel.DoAnyLeave;
begin
  if (FFrameCount <= 1) or (FFrameDelay = 0) then 
  begin
    FCurrentColor := Font.Color;
    invalidate;
  end 
  else 
  begin
    FTimer.Interval := FFrameDelay;
    FCurrentColorIndex := FFrameCount - 1;
    FTimer.Enabled := True;
  end;
end;

procedure TCustomDIBFadeLabel.KeyPress(var Key: Char);
begin
  inherited;
  if Ord(Key) = VK_Space then Click;
end;

procedure TCustomDIBFadeLabel.Loaded;
begin
  inherited;
  if AutoSize then
    AdjustSize;
end;

procedure TCustomDIBFadeLabel.Paint;
const
  Alignments: array[TAlignment] of Word = (DT_LEFT, DT_RIGHT, DT_CENTER);
  WordWraps: array[Boolean] of Word = (0, DT_WORDBREAK);
var
  Rect, CalcRect: TRect;
  DrawStyle: Longint;
begin
  with Canvas do
  begin
    if not Transparent then
      ControlDIB.QuickFill(Color);
    Rect := ClientRect;
    { DoDrawText takes care of BiDi alignments }
    DrawStyle := DT_EXPANDTABS or WordWraps[FWordWrap] or Alignments[FAlignment];
    { Calculate vertical layout }
    if FLayout <> tlTop then
    begin
      CalcRect := Rect;
      DoDrawText(CalcRect, DrawStyle or DT_CALCRECT);
      if FLayout = tlBottom then OffsetRect(Rect, 0, Height - CalcRect.Bottom)
      else
        OffsetRect(Rect, 0, (Height - CalcRect.Bottom) div 2);
    end;
    DoDrawText(Rect, DrawStyle);

    ControlDIB.Angle := Angle;
    ControlDIB.Scale := Scale;
  end;
end;

procedure TCustomDIBFadeLabel.SetAlignment(const Value: TAlignment);
begin
  FAlignment := Value;
  invalidate;
end;

procedure TCustomDIBFadeLabel.SeExtended(const Value: Extended);
begin
  FAngle := Value;
  invalidate;
end;

procedure TCustomDIBFadeLabel.SetColorHighLighted(const Value: TColor);
begin
  FColorHighLighted := Value;
  CalcColorTable;
end;

procedure TCustomDIBFadeLabel.SetFrameCount(const Value: Byte);
begin
  FFrameCount := Value;
  CalcColorTable;
end;

procedure TCustomDIBFadeLabel.SetFrameDelay(const Value: Cardinal);
begin
  FFrameDelay := Value;
end;

procedure TCustomDIBFadeLabel.SetLayout(const Value: TTextLayout);
begin
  FLayout := Value;
  invalidate;
end;

procedure TCustomDIBFadeLabel.SetScale(const Value: Extended);
begin
  FScale := Value;
  invalidate;
end;

procedure TCustomDIBFadeLabel.SetShowAccelChar(const Value: Boolean);
begin
  FShowAccelChar := Value;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCustomDIBFadeLabel.SetTransparent(const Value: Boolean);
begin
  FTransparent := Value;
  invalidate;
end;

procedure TCustomDIBFadeLabel.SetWordWrap(const Value: Boolean);
begin
  FWordWrap := Value;
  invalidate;
end;

function TCustomDIBFadeLabel.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
const
  WordWraps: array[Boolean] of Word = (0, DT_WORDBREAK);
var
  DC: HDC;
  Rect: TRect;
begin
  Rect := ClientRect;
  DC := GetDC(0);
  try
    Canvas.Handle := DC;
    DoDrawText(Rect, (DT_EXPANDTABS or DT_CALCRECT) or WordWraps[FWordWrap]);
  finally
    Canvas.Handle := 0;
    ReleaseDC(0, DC);
  end;
  NewWidth := Rect.Right;
  NewHeight := Rect.Bottom;
  Result := True;
end;

end.
