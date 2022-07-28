unit cDIBImage;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBImage.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
This is a DIB version of TImage.  Has opacity / angle etc.

Contributor(s):
RiceBall <riceb@nether.net>


Last Modified: Jan 2, 2005

You may retrieve the latest version of this file at http://www.droopyeyes.com
----------------------------------------------------------------------------}
//Modifications
(*
Date:   Jan 2, 2005
By:     Peter Morris
Change: Altered Paint routine to calculate Scale correctly when Stretch = True
*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBControl, cDIB, cDIBImageList;

type
  TCustomDIBImage = class(TCustomDIBControl)
  private
    { Private declarations }
    FAngle: Extended;
    FCenter: Boolean;
    FIndexMain: TDIBImageLink;
    FProportional: Boolean;
    FScale: Extended;
    FStretch: Boolean;
    procedure SetAngle(const Value: Extended);
    procedure SetScale(const Value: Extended);
    procedure SetCenter(const Value: Boolean);
    procedure SetStretch(const Value: Boolean);
    procedure SetProportional(const Value: Boolean);
  protected
    { Protected declarations }
    function CanAutoSize(var NewWidth: Integer; var NewHeight: Integer): Boolean; override;
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); override;
    procedure Paint; override;

    property Angle: Extended read FAngle write SetAngle;
    property Center: Boolean read FCenter write SetCenter;
    property IndexMain: TDIBImageLink read FIndexMain write FIndexMain;
    property Proportional: Boolean read FProportional write SetProportional;
    property Scale: Extended read FScale write SetScale;
    property Stretch: Boolean read FStretch write SetStretch;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Click; override;

  published
    { Published declarations }
  end;

  TDIBImage = class(TCustomDIBImage)
  private
  protected
  public
    property Canvas;
  published
    property Accelerator;
    property Align;
    property Anchors;
    property Angle;
    property AutoSize;
    property Center;
    property Children;
    property Constraints;
    property Cursor;
    property DIBFeatures;
    property DIBImageList;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property IndexMain;
    property Opacity;
    property ParentShowHint;
    property PopupMenu;
    property Proportional;
    property Scale;
    property ShowHint;
    property Stretch;
    property DIBTabOrder;
    property Tag;
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

{ TCustomDIBImage }

constructor TCustomDIBImage.Create(AOwner: TComponent);
begin
  inherited;
  Autosize := False;
  FScale := 100;
  AddIndexProperty(FIndexMain);
  AddTemplateProperty('Angle');
  AddTemplateProperty('AutoSize');
  AddTemplateProperty('Center');
  AddTemplateProperty('Opacity');
  AddTemplateProperty('Scale');
  AddTemplateProperty('Stretch');
end;

destructor TCustomDIBImage.Destroy;
begin
  inherited;
end;

procedure TCustomDIBImage.ImageChanged(Index: Integer; Operation: TDIBOperation);
begin
  if (Index = IndexMain.DIBIndex) then
  begin
    if AutoSize then
      AdjustSize;
    Invalidate;
  end;
end;

procedure TCustomDIBImage.Paint;
var
  TheDIB: TMemoryDIB;
  XPos, YPos: Integer;
  NewSizes: TPoint;
  NewScaleX: Extended;
  NewScaleY: Extended;
begin
  inherited;
  if IndexMain.GetImage(TheDIB) then
  begin
    TheDIB.AutoSize := True;
    TheDIB.Angle := Angle;
    TheDIB.Scale := Scale;
    XPos := 0;
    YPos := 0;

    if Stretch then
    begin
      NewScaleX := Width * 100 / TheDIB.Width;
      NewScaleY := Height * 100 / TheDIB.Height;
      if Proportional then
        if NewScaleX < NewScaleY then
          NewScaleY := NewScaleX
        else
          NewScaleX := NewScaleY;
      TheDIB.ScaleX := NewScaleX;
      TheDIB.ScaleY := NewScaleY;
    end;

    NewSizes := GetRotatedSize(TheDIB.Width, TheDIB.Height, Angle,
      TheDIB.ScaleX, TheDIB.ScaleY);

    if Center then
    begin
      XPos := (Width div 2) - (NewSizes.X div 2);
      YPos := (Height div 2) - (NewSizes.Y div 2);
    end;
    TheDIB.ClipRect := ControlDIB.ClipRect;
    TheDIB.Draw(XPos, YPos, TheDIB.Width, TheDIB.Height, ControlDIB, 0, 0);
  end;
end;

procedure TCustomDIBImage.SetAngle(const Value: Extended);
begin
  FAngle := SafeAngle(Value);
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCustomDIBImage.SetScale(const Value: Extended);
begin
  FScale := Value;
  Stretch := False;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCustomDIBImage.SetCenter(const Value: Boolean);
begin
  if Value = Center then exit;
  FCenter := Value;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCustomDIBImage.SetProportional(const Value: Boolean);
begin
  FProportional := Value;
  Invalidate;
end;

procedure TCustomDIBImage.SetStretch(const Value: Boolean);
begin
  FStretch := Value;
  if Value then AutoSize := False;
  Invalidate;
end;

procedure TCustomDIBImage.Click;
begin
  inherited;
end;

function TCustomDIBImage.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
var
  TheDIB: TMemoryDIB;
  Sizes: TPoint;
begin
  Result := False;
  if IndexMain.Valid then
  begin
    if IndexMain.GetImage(TheDIB) then
    begin
      Result := True;
      Sizes := GetRotatedSize(TheDIB.Width, TheDIB.Height, Angle, Scale, Scale);
      NewWidth := Sizes.X;
      NewHeight := Sizes.Y;
    end;
  end;
end;

end.
