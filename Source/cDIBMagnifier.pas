unit cDIBMagnifier;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBMagnifier.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Implementation of the magnifier component.

Contributor(s):
None as yet


Last Modified: March 23, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com

Known Issues:

If Windows is in 8bit display, it will not allow dragging off the bottom of
the form IF the form has a shape applied.
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   March 23, 2003
By:     Peter Morris
Change: Added AutoSize
*)


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBControl, cDIB, cDIBImageList, DIBCommon;

type
  TCustomDIBMagnifier = class(TCustomDIBControl)
  private
    { Private declarations }
    FAngle: Extended;
    FMagnifyOpacity: Byte;
    FScale: Extended;
    FIndexMagnifyMask,
    FIndexMain: TDIBImageLink;
    procedure SeExtended(const Value: Extended);
    procedure SetScale(const Value: Extended);
    procedure SetMagnifyOpacity(const Value: Byte);
  protected
    { Protected declarations }
    //AlterUpdateRect gives us the chance to alter the size of the update rect
    procedure AlterUpdateRect(var R: TRect); override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); override;
    procedure Paint; override;
    property Angle: Extended read FAngle write SeExtended;
    property IndexMagnifyMask: TDIBImageLink read FIndexMagnifyMask write FIndexMagnifyMask;
    property IndexMain: TDIBImageLink read FIndexMain write FIndexMain;
    property MagnifyOpacity: Byte read FMagnifyOpacity write SetMagnifyOpacity;
    property Scale: Extended read FScale write SetScale;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    { Published declarations }
  end;

  TDIBMagnifier = class(TCustomDIBMagnifier)
  published
    property Accelerator;
    property Anchors;
    property Angle;
    property AutoSize;
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
    property IndexMagnifyMask;
    property IndexMain;
    property MagnifyOpacity;
    property Opacity;
    property ParentShowHint;
    property PopupMenu;
    property Scale;
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
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

type
  THackAbstractDIB = class(TAbstractSuperDIB);

  { TDIBMagnifier }

procedure TCustomDIBMagnifier.AlterUpdateRect(var R: TRect);
var
  A: TRect;
begin
  inherited;
  if IntersectRect(A, R, BoundsRect) then
    UnionRect(R, R, BoundsRect);
end;

function TCustomDIBMagnifier.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
var
  CurrentDIB: TMemoryDIB;
begin
  if IndexMain.GetImage(CurrentDIB) then
  begin
    NewWidth := CurrentDIB.Width;
    NewHeight := CurrentDIB.Height;
    Result := True;
  end else
    Result := inherited CanAutoSize(NewWidth, NewHeight);
end;

constructor TCustomDIBMagnifier.Create(AOwner: TComponent);
begin
  inherited;
  AddIndexProperty(FIndexMain);
  AddIndexProperty(FIndexMagnifyMask);
  FAngle := 0;
  FScale := 200;
  FMagnifyOpacity := 255;

  AddTemplateProperty('Angle');
  AddTemplateProperty('MagnifyOpacity');
  AddTemplateProperty('Scale');
end;

destructor TCustomDIBMagnifier.Destroy;
begin
  FIndexMain.Free;
  FIndexMagnifyMask.Free;
  inherited;
end;

procedure TCustomDIBMagnifier.ImageChanged(Index: Integer; Operation: TDIBOperation);
begin
  Invalidate;
end;

procedure TCustomDIBMagnifier.Paint;
var
  FinalDIB, MaskDIB, MainDIB, TheDIB: TMemoryDIB;
begin
  TheDIB := TMemoryDIB.Create(Width, Height);
  FinalDIB := TMemoryDIB.Create(Width, Height);
  try
    TheDIB.Assign(ControlDIB);
    TheDIB.Scale := Scale;
    if Angle = 0 then
      TheDIB.Angle := 0.001
    else
      TheDIB.Angle := Angle;
    TheDIB.Draw(0, 0, Width, Height, FinalDIB, 0, 0);

    if IndexMagnifyMask.GetImage(MaskDIB) then
    begin
      FinalDIB.SetMaskedValues(0);
      MaskDIB.DrawMask(0, 0, Width, Height, FinalDIB, 0, 0);
      FinalDIB.Masked := True;
    end
    else
      FinalDIB.Masked := False;


    FinalDIB.Opacity := MagnifyOpacity;
    FinalDIB.Draw(0, 0, Width, Height, ControlDIB, 0, 0);
    if IndexMain.GetImage(MainDIB) then
      MainDIB.Draw(0, 0, Width, Height, ControlDIB, 0, 0);
  finally
    TheDIB.Free;
    FinalDIB.Free;
  end;
end;

procedure TCustomDIBMagnifier.SeExtended(const Value: Extended);
begin
  FAngle := Value;
  Invalidate;
end;

procedure TCustomDIBMagnifier.SetMagnifyOpacity(const Value: Byte);
begin
  FMagnifyOpacity := Value;
  Invalidate;
end;

procedure TCustomDIBMagnifier.SetScale(const Value: Extended);
begin
  FScale := Value;
  Invalidate;
end;

end.
