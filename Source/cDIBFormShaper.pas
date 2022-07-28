unit cDIBFormShaper;

interface

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBFormShaper.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Will shape any TWinControl based on a bitmap

Contributor(s):
None as yet


Last Modified: November 03, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   November 03, 2000
BY:     Peter Morris
Change: Added capability for the shaper to work from a DIBImageList, also added
        OffsetX and OffsetY properties to allow you to offset the region.
*)


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, cDIB,
  cDIBImageList;

type
  TDIBFormShaper = class(TComponent)
  private
    { Private declarations }
    FActive: Boolean;
    FBitmap: TBitmap;
    FControlToShape: TWinControl;
    FClientAreaOnly: Boolean;
    FIndexShape: TDIBImageLink;
    FTransparentColor: TColor;
    FTransparentMode: TTransparentMode;
    FOffsetX,
    FOffsetY: Integer;
    procedure BitmapChanged(Sender: TObject);
    procedure DIBImageChanged(Sender: TObject; Index: Integer; Operation: TDIBOperation);
    function GetControlToShape: TWinControl;
    procedure SetClientAreaOnly(const Value: Boolean);
    procedure SetTransparentColor(const Value: TColor);
    procedure SetTransparentMode(const Value: TTransparentMode);
    function GetDIBImageList: TCustomDIBImageList;
    procedure SetDIBImageList(const Value: TCustomDIBImageList);
    procedure SetOffsetX(const Value: Integer);
    procedure SetOffsetY(const Value: Integer);
  protected
    { Protected declarations }
    procedure ApplyRGN;
    procedure DoBitmapChanged; virtual;
    procedure Loaded; override;
    procedure SetActive(const Value: Boolean); virtual;
    procedure SetBitmap(const Value: TBitmap); virtual;
    procedure SetControlToShape(const Value: TWinControl); virtual;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetRGN: HRGN;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Reset;
  published
    { Published declarations }
    property Active: Boolean read FActive write SetActive;
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property ClientAreaOnly: Boolean read FClientAreaOnly write SetClientAreaOnly;
    property ControlToShape: TWinControl read GetControlToShape write SetControlToShape;
    property DIBImageList: TCustomDIBImageList read GetDIBImageList write SetDIBImageList;
    property IndexShape: TDIBImageLink read FIndexShape write FIndexShape;
    property OffsetX: Integer read FOffsetX write SetOffsetX;
    property OffsetY: Integer read FOffsetY write SetOffsetY;
    property TransparentColor: TColor read FTransparentColor write SetTransparentColor;
    property TransparentMode: TTransparentMode 
      read FTransparentMode write SetTransparentMode;
  end;

implementation
{ TDIBFormShaper }

constructor TDIBFormShaper.Create(AOwner: TComponent);
begin
  inherited;
  FActive := False;
  FBitmap := TBitmap.Create;
  FBitmap.OnChange := BitmapChanged;
  FIndexShape := TDIBImageLink.Create(Self);
  FIndexShape.OnImageChanged := DIBImageChanged;
end;

destructor TDIBFormShaper.Destroy;
begin
  FBitmap.Free;
  FIndexShape.Free;
  inherited;
end;

procedure TDIBFormShaper.ApplyRGN;
var
  XOffset, YOffset: Integer;
  RGN: HRGN;
begin
  FActive := True;
  if csLoading in ComponentState then exit;
  if (Bitmap.Width = 0) and not (FIndexShape.Valid) then exit;

  //Now we need to offset the region if
  //A) ClientAreaOnly is true OR
  //B) We are in designtime and Form.BorderStyle = BsNone
  //C) This is being applied to a form

  RGN := GetRGN;

  if ControlToShape is TForm then with TForm(ControlToShape) do
      if (ClientAreaOnly and (BorderStyle <> bsNone)) or
        ((csDesigning in ComponentState) and
        (TForm(ControlToShape).BorderStyle = bsNone)) then
      begin
        XOffset := (Width - ClientWidth) div 2;
        YOffset := Height - ClientHeight - XOffset;
        OffsetRgn(RGN, XOffset, YOffset);
      end;

  if FControlToShape <> nil then
    SetWindowRGN(FControlToShape.Handle, RGN, True)
  else
    SetWindowRGN(TWinControl(Owner).Handle, RGN, True);
end;

procedure TDIBFormShaper.Reset;
begin
  if ControlToShape <> nil then
    SetWindowRGN(ControlToShape.Handle, 0, True)
  else
    SetWindowRGN(TWincontrol(Owner).Handle, 0, True);
end;

procedure TDIBFormShaper.SetActive(const Value: Boolean);
var
  Control: TWinControl;
begin
  if ControlToShape <> nil then
    Control := ControlToShape
  else
    Control := TWinControl(Owner);

  if Control = nil then exit;

  if not (csLoading in ComponentState) then 
  begin
    if Value then
      ApplyRGN  //Sets active to true
    else 
    begin
      SetWindowRGN(Control.Handle, 0, True);
      FActive := False;
    end;
  end 
  else
    FActive := Value;
end;

procedure TDIBFormShaper.SetControlToShape(const Value: TWinControl);
begin
  if ControlToShape <> nil then ControlToShape.RemoveFreeNotification(Self);

  if not (csLoading in ComponentState) then
    if Active then Active := False;
  FControlToShape := Value;
  if not (ControlToShape is TForm) then FClientAreaOnly := False;

  if ControlToShape <> nil then ControlToShape.FreeNotification(Self);
end;

procedure TDIBFormShaper.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (AComponent = Self) or (csDestroying in ComponentState) then exit;
  if Operation = opRemove then
    if AComponent = ControlToShape then 
    begin
      FControlToShape := nil;
      FActive := False;
    end;
end;

procedure TDIBFormShaper.Loaded;
begin
  inherited;
  if FActive then 
  begin
    FActive := False;
    Active := True;
    ApplyRGN;
  end;
end;

function TDIBFormShaper.GetControlToShape: TWinControl;
  function FindForm: TForm;
  var
    Component: TComponent;
  begin
    Result := nil;
    Component := Owner;
    while (not (Component is TForm)) and (Component <> nil) do
      Component := Component.Owner;

    if Component is TForm then Result := TForm(Component);
  end;
begin
  if FControlToShape <> nil then
    Result := FControlToShape
  else if Owner is TWinControl then
    Result := TWinControl(Owner)
  else
    Result := FindForm;
end;

procedure TDIBFormShaper.SetClientAreaOnly(const Value: Boolean);
begin
  if ControlToShape is TForm then 
  begin
    FClientAreaOnly := Value;
    if Active then ApplyRGN;
  end;
end;

function TDIBFormShaper.GetRGN: HRGN;
var
  Pixel: TPixel32;
  Color: TColor;
  MemDIB: TMemoryDIB;
  DIB: TWinDIB;
begin
  if FIndexShape.GetImage(MemDIB) then
  begin
    if TransparentMode = tmAuto then
    begin
      Pixel := MemDIB.Pixels[0, MemDIB.Height - 1];
      asm
        mov EAX, Pixel
        shl EAX, 8
        BSWAP EAX
        mov Color, EAX
      end;
    end 
    else if MemDIB.Transparent then
      Color := MemDIB.TransparentColor
    else
      Color := TColor(TransparentColor);

    Result := MemDIB.MakeRGNFromColor(Color);
  end 
  else
  begin
    if TransparentMode = tmAuto then
      Color := Bitmap.Canvas.Pixels[0, Bitmap.Height - 1]
    else
      Color := TransparentColor;

    DIB := TWinDIB.Create(Bitmap.Width, Bitmap.Height);
    try
      BitBlt(DIB.Canvas.Handle, 0, 0, Bitmap.Width, Bitmap.Height,
        Bitmap.Canvas.Handle, 0, 0, SRCCOPY);
      Result := DIB.MakeRGNFromColor(Color);
    finally
      DIB.Free;
    end;
  end;
  OffsetRGN(Result, OffsetX, OffsetY);
end;

procedure TDIBFormShaper.SetBitmap(const Value: TBitmap);
begin
  FBitmap.Assign(Value);
  if Active then ApplyRGN;
end;

procedure TDIBFormShaper.SetTransparentColor(const Value: TColor);
begin
  if Value = TransparentColor then exit;

  FTransparentColor := Value;
  if Active then ApplyRGN;
end;

procedure TDIBFormShaper.SetTransparentMode(const Value: TTransparentMode);
begin
  if Value = TransparentMode then exit;
  
  FTransparentMode := Value;
  if Active then ApplyRGN;
end;

procedure TDIBFormShaper.BitmapChanged(Sender: TObject);
begin
  DoBitmapChanged;
end;

procedure TDIBFormShaper.DoBitmapChanged;
begin
  if Active then ApplyRGN;
end;

function TDIBFormShaper.GetDIBImageList: TCustomDIBImageList;
begin
  Result := FIndexShape.DIBImageList;
end;

procedure TDIBFormShaper.SetDIBImageList(const Value: TCustomDIBImageList);
begin
  FIndexShape.DIBImageList := Value;
end;

procedure TDIBFormShaper.DIBImageChanged(Sender: TObject; Index: Integer;
  Operation: TDIBOperation);
begin
  DoBitmapChanged;
end;

procedure TDIBFormShaper.SetOffsetX(const Value: Integer);
begin
  FOffsetX := Value;
  if Active then ApplyRGN;
end;

procedure TDIBFormShaper.SetOffsetY(const Value: Integer);
begin
  FOffsetY := Value;
  if Active then ApplyRGN;
end;

end.
