unit cDIBGlyphButton;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBGlyphButton.PAS, released March 23, 2003.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2003 Peter Morris.
All Rights Reserved.

Purpose of file:
To create a simple non-animated button.

Contributor(s):
None as yet


Last Modified: March 23, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:
By:
Change:
*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBControl, cDIBButton, cDIBImageList, cDIB;

type
  TNumGlyphs = 2..5;

  EDIBGlyphButtonError = class(EDIBError);
  
  TCustomDIBGlyphButton = class(TAbstractDIBButton)
  private
    FGlyph: TDIBImageLink;
    FNumGlyphs: TNumGlyphs;
    FCaptionOffsetMouseClick: TPointProperty;
    FCaptionOffsetDown: TPointProperty;
    FCaptionOffsetMouseOver: TPointProperty;
    FCaptionOffsetEnabled: TPointProperty;
    FCaptionOffsetDisabled: TPointProperty;
    FFontDisabled: TFont;
    procedure CaptionOffsetChanged(Sender: TObject);
    procedure SetNumGlyphs(const Value: TNumGlyphs);
    procedure SetCaptionOffsetDisabled(const Value: TPointProperty);
    procedure SetCaptionOffsetMouseClick(const Value: TPointProperty);
    procedure SetCaptionOffsetDown(const Value: TPointProperty);
    procedure SetCaptionOffsetEnabled(const Value: TPointProperty);
    procedure SetCaptionOffsetMouseOver(const Value: TPointProperty);
    procedure SetFontDisabled(const Value: TFont);
  protected
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); override;
    procedure Paint; override;

    property CaptionOffsetEnabled: TPointProperty read FCaptionOffsetEnabled write SetCaptionOffsetEnabled;
    property CaptionOffsetMouseClick: TPointProperty read FCaptionOffsetMouseClick write SetCaptionOffsetMouseClick;
    property CaptionOffsetDown: TPointProperty read FCaptionOffsetDown write SetCaptionOffsetDown;
    property CaptionOffsetDisabled: TPointProperty read FCaptionOffsetDisabled write SetCaptionOffsetDisabled;
    property CaptionOffsetMouseOver: TPointProperty read FCaptionOffsetMouseOver write SetCaptionOffsetMouseOver;
    property FontDisabled: TFont read FFontDisabled write SetFontDisabled;
    property Glyph: TDIBImageLink read FGlyph write FGlyph;
    property NumGlyphs: TNumGlyphs read FNumGlyphs write SetNumGlyphs default 2;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TDIBGlyphButton = class(TCustomDIBGlyphButton)
  public
    property Canvas;
    constructor Create(AOwner: TComponent); override;
  published
    property Accelerator;
    property Anchors;
    property Caption;
    property CaptionOffsetEnabled;
    property CaptionOffsetDisabled;
    property CaptionOffsetDown;
    property CaptionOffsetMouseClick;
    property CaptionOffsetMouseOver;
    property Children;
    property Constraints;
    property Cursor;
    property DIBFeatures;
    property DIBImageList;
    property Down;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FontDisabled;
    property Glyph;
    property Group;
    property Hint;
    property NumGlyphs;
    property Opacity;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property DIBTabOrder;
    property Tag;
    property ToggleDown;
    property Visible;

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
    property OnPaintStart;
    property OnPaintEnd;
    property OnStartDock;
    property OnStartDrag;
    property OnResize;
  end;

implementation

{ TCustomDIBGlyphButton }

function TCustomDIBGlyphButton.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
var
  CurrentDIB: TMemoryDIB;
begin
  if Glyph.GetImage(CurrentDIB) then
  begin
    NewWidth := CurrentDIB.Width div NumGlyphs;
    NewHeight := CurrentDIB.Height;
  end;
  Result := True;
end;

procedure TCustomDIBGlyphButton.CaptionOffsetChanged(Sender: TObject);
begin
  Invalidate;
end;

constructor TCustomDIBGlyphButton.Create(AOwner: TComponent);
begin
  inherited;
  FFontDisabled := TFont.Create;
  FCaptionOffsetMouseClick := TPointProperty.Create;
  FCaptionOffsetDown := TPointProperty.Create;
  FCaptionOffsetMouseOver := TPointProperty.Create;
  FCaptionOffsetEnabled := TPointProperty.Create;
  FCaptionOffsetDisabled := TPointProperty.Create;
  FCaptionOffsetMouseClick.OnChanged := CaptionOffsetChanged;
  FCaptionOffsetDown.OnChanged := CaptionOffsetChanged;
  FCaptionOffsetMouseOver.OnChanged := CaptionOffsetChanged;
  FCaptionOffsetEnabled.OnChanged := CaptionOffsetChanged;
  FCaptionOffsetDisabled.OnChanged := CaptionOffsetChanged;
  AutoSize := True;
  FNumGlyphs := 2;
  FGlyph := TDIBImageLink.Create(Self);
  AddIndexProperty(FGlyph);
  AddTemplateProperty('NumGlyphs');
  AddTemplateProperty('Opacity');
end;

destructor TCustomDIBGlyphButton.Destroy;
begin
  FreeAndNil(FGlyph);
  FreeAndNil(FCaptionOffsetMouseClick);
  FreeAndNil(FCaptionOffsetDown);
  FreeAndNil(FCaptionOffsetMouseOver);
  FreeAndNil(FCaptionOffsetEnabled);
  FreeAndNil(FCaptionOffsetDisabled);
  FreeAndNil(FFontDisabled);
  inherited;
end;


procedure TCustomDIBGlyphButton.ImageChanged(Index: Integer;
  Operation: TDIBOperation);
begin
  inherited;
  if AutoSize then AdjustSize;
end;

procedure TCustomDIBGlyphButton.Paint;
  function GetGlyphNumber(State: TButtonState): TButtonState;
  begin
    Result := State;
    if Ord(Result) + 1 > NumGlyphs then
    begin
      case State of
        bsDisabled: Result := bsEnabled;
        bsMouseOver : Result := bsEnabled;
        bsDown: Result := bsMouseClick;
      end;
    end;
  end;

var
  CurrentDIB: TMemoryDIB;
  CaptionWidth: Integer;
  CaptionHeight: Integer;
  CaptionX: Integer;
  CaptionY: Integer;
  Offset: TPointProperty;
begin
  inherited;
  if Glyph.GetImage(CurrentDIB) then
  begin
    CurrentDIB.Draw(0, 0, Width, Height, ControlDIB, Width * Ord(GetGlyphNumber(ButtonState)), 0);
    if Caption <> '' then
    begin
      if ButtonState = bsDisabled then
        ControlDIB.Canvas.Font := FontDisabled
      else
        ControlDIB.Canvas.Font := Font;

      CaptionWidth := ControlDIB.Canvas.TextWidth(Caption);
      CaptionHeight := ControlDIB.Canvas.TextHeight(Caption);
      CaptionX := (Width div 2) - (CaptionWidth div 2);
      CaptionY := (Height div 2) - (CaptionHeight div 2);
      case ButtonState of
        bsEnabled: Offset := CaptionOffsetEnabled;
        bsMouseClick: Offset := CaptionOffsetMouseClick;
        bsDisabled: Offset := CaptionOffsetDisabled;
        bsMouseOver: Offset := CaptionOffsetMouseOver;
        bsDown: Offset := CaptionOffsetMouseClick;
      else
        raise EDIBGlyphButtonError.Create('Unknown button state');
      end;
      CaptionX := CaptionX + Offset.X;
      CaptionY := CaptionY + Offset.Y;
      ControlDIB.Canvas.Brush.Style := bsClear;
      ControlDIB.Canvas.TextOut(CaptionX, CaptionY, Caption);
    end;
  end;
end;

procedure TCustomDIBGlyphButton.SetCaptionOffsetDisabled(const Value: TPointProperty);
begin
  FCaptionOffsetMouseClick.Assign(Value);
end;

procedure TCustomDIBGlyphButton.SetCaptionOffsetMouseClick(const Value: TPointProperty);
begin
  FCaptionOffsetMouseClick.Assign(Value);
end;

procedure TCustomDIBGlyphButton.SetCaptionOffsetDown(const Value: TPointProperty);
begin
  FCaptionOffsetDown.Assign(Value);
end;

procedure TCustomDIBGlyphButton.SetCaptionOffsetEnabled(
  const Value: TPointProperty);
begin
  FCaptionOffsetEnabled.Assign(Value);
end;

procedure TCustomDIBGlyphButton.SetCaptionOffsetMouseOver(const Value: TPointProperty);
begin
  FCaptionOffsetMouseOver.Assign(Value);
end;

procedure TCustomDIBGlyphButton.SetFontDisabled(const Value: TFont);
begin
  FFontDisabled.Assign(Value);
  Invalidate;
end;

procedure TCustomDIBGlyphButton.SetNumGlyphs(const Value: TNumGlyphs);
begin
  Assert((Value >= Low(TNumGlyphs)) and (Value <= High(TNumGlyphs)));
  FNumGlyphs := Value;
  if AutoSize then AdjustSize;
end;

{ TDIBGlyphButton }

constructor TDIBGlyphButton.Create(AOwner: TComponent);
begin
  inherited;
  AddTemplateProperty('CaptionOffsetEnabled');
  AddTemplateProperty('CaptionOffsetMouseClick');
  AddTemplateProperty('CaptionOffsetDisabled');
  AddTemplateProperty('CaptionOffsetMouseOver');
  AddTemplateProperty('CaptionOffsetDown');
  AddTemplateProperty('Font');
  AddTemplateProperty('FontDisabled');
end;

end.
