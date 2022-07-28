unit cDIBPalette;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBPalette.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
This handles the rendering of 32bit images to 8 bit display modes through use of
a Colour cube.  This is at least 30 times faster than simply using BitBlt.

Contributor(s):
Sylane - sylane@excite.com
  Assign
  ImportFromRAWFile
  ResetPalette
  PaletteEditor

Last Modified: August 28, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TColorTable = array[0..63, 0..63, 0..63] of Byte;
  PColorTable = ^TColorTable;

  TDIBPalette = class(TComponent)
  private
    { Private declarations }
    //FColors is just used for streaming purposes
    FUseTable: Boolean;
    FLUT: PColorTable;
    pPal: PLogPalette;
    hPalCurrent: HPalette;
    FOldWndProc: TWndMethod;
    FOwner: TCustomForm;
    procedure FormWndProc(var message: TMessage);
    procedure LoadColorsFromStream(S: TStream);
    procedure LoadTableFromStream(S: TStream);
    procedure SaveColorsToStream(S: TStream);
    procedure SaveTableToStream(S: TStream);
    procedure SetTable(const Value: Boolean);
    procedure UpdateLUT;
    procedure WMPaletteChanged(var Message: TMessage);
    procedure WMQueryNewPalette(var Message: TMessage);
  protected
    { Protected declarations }
    procedure DefineProperties(Filer: TFiler); override;
    procedure Loaded; override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    function ColorDistance(const C1, C2: tagPaletteEntry): Integer;
    function FastColorMatch(const Color: tagPaletteEntry): Byte;
    procedure ImportFromFile(const aFilename: string);
    procedure ImportFromRawFile(const aFileName: string);
    procedure ResetPalette;
    function SlowColorMatch(const Color: tagPaletteEntry): Byte;
    procedure UpdateFromBitmap(const Bitmap: TBitmap);
    procedure UpdatePalette;

    property ColorTable: PColorTable read FLUT;
    property PAL: PLogPalette read pPal;
    property Palette: HPalette read hPalCurrent;
  published
    { Published declarations }
    property UseTable: Boolean read FUseTable write SetTable;
  end;

implementation

type
  EDIBPaletteError = class(Exception);
  THackCustomForm = class(TCustomForm);

  { TDIBPalette }

constructor TDIBPalette.Create(AOwner: TComponent);
var
  X: Integer;
  NewPal: pLogPalette;
begin
  if not (AOwner is TCustomForm) then
    raise EDIBPaletteError.Create('Palette owner must be a TCustomForm.');

  //Get more memory than we need, just so we have enough space
  GetMem(NewPal, 4 {bytes} * 255 {Palette entries});
  if NewPal = nil then
    raise EDIBPaletteError.Create('Could not get enough memory for a palette.');

  inherited;
  FOwner := TCustomForm(Owner);
  pPal := NewPal;
  pPal.palVersion := $300;
  pPal.palNumEntries := 235;
  for X := 0 to 234 do 
  begin
    pPal.palPalEntry[X].peRed := 255 - x;
    pPal.palPalEntry[X].peGreen := 255 - X;
    pPal.palPalEntry[X].peBlue := 255 - X;
    pPal.palPalEntry[X].peFlags := 0;
  end;
  UpdatePalette;

  if not (csDesigning in FOwner.ComponentState) then 
  begin
    FOldWndProc := THackCustomForm(Owner).WindowProc;
    THackCustomForm(Owner).WindowProc := FormWndProc;
  end;
end;

procedure TDIBPalette.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('DIBPaletteColors', LoadColorsFromStream,
    SaveColorsToStream, True);
  Filer.DefineBinaryProperty('DIBPaletteTable', LoadTableFromStream,
    SaveTableToStream, FUseTable);
end;

destructor TDIBPalette.Destroy;
begin
  DeleteObject(hPalCurrent);
  FreeMem(pPal);
  pPal := nil;
  if FLUT <> nil then FreeMem(FLUT);
  if not (csDestroying in FOwner.ComponentState) then
    if not (csDesigning in FOwner.ComponentState) then
      THackCustomForm(FOwner).WindowProc := FOldWndProc;
  inherited;
end;

procedure TDIBPalette.FormWndProc(var message: TMessage);
begin
  case Message.msg of
    WM_PaletteChanged: WMPaletteChanged(Message);
    WM_QueryNewPalette: WMQueryNewPalette(Message);
    else
      FOldWndProc(Message);
  end;
end;

procedure TDIBPalette.UpdateFromBitmap(const Bitmap: TBitmap);
begin
  GetPaletteEntries(Bitmap.Palette, 0, 235, pPal.palPalEntry[0]);
  UpdatePalette;
  if UseTable then UpdateLUT;
  SendMessage(FOwner.Handle, WM_QueryNewPalette, 0, 0);
end;

procedure TDIBPalette.LoadColorsFromStream(S: TStream);
var
  X: Integer;
  Value: Byte;
begin
  if S.Size = 0 then exit;
  if S.Size <> (235 * 4) then
    raise EDIBPaletteError.Create('Invalid palette stream.');


  for X := 0 to 234 do 
  begin
    S.ReadBuffer(Value, 1);
    pPal.palPalEntry[X].peRed := Value;
    S.ReadBuffer(Value, 1);
    pPal.palPalEntry[X].peGreen := Value;
    S.ReadBuffer(Value, 1);
    pPal.palPalEntry[X].peBlue := Value;
    S.ReadBuffer(Value, 1);
    pPal.palPalEntry[X].peFlags := Value;
  end;
  UpdatePalette;
end;

procedure TDIBPalette.SaveColorsToStream(S: TStream);
var
  X: Integer;
  Value: Byte;
begin
  for X := 0 to 234 do 
  begin
    Value := pPal.palPalEntry[X].peRed;
    S.WriteBuffer(Value, 1);
    Value := pPal.palPalEntry[X].peGreen;
    S.WriteBuffer(Value, 1);
    Value := pPal.palPalEntry[X].peBlue;
    S.WriteBuffer(Value, 1);
    Value := pPal.palPalEntry[X].peFlags;
    S.WriteBuffer(Value, 1);
  end;
end;

procedure TDIBPalette.UpdatePalette;
  //var
  //  OrigUseTable: Boolean;
begin
  //  OrigUseTable := UseTable;
  //  UseTable := False;
  if hPalCurrent <> 0 then DeleteObject(hPalCurrent);
  hPalCurrent := CreatePalette(pPal^);
  //  UseTable := OrigUseTable;
end;

procedure TDIBPalette.WMPaletteChanged(var Message: TMessage);
var
  DC: Integer;
  OldPal: HPalette;
begin
  //Our app has (probably) just become the foreground application,
  //windows is asking us if we have a custom palette.
  //Don't respond to this message if the sender (wparam) is our form
  with THackCustomForm(Owner) do 
  begin
    if THandle(Message.wParam) <> Handle then 
    begin
      DC := GetDC(Handle);
      OldPal := SelectPalette(DC, hPalCurrent, True);

      //Only need to repaint if logical palette has been remapped
      if RealizePalette(DC) > 0 then Invalidate;
      SelectPalette(DC, OldPal, True);
      RealizePalette(DC);
      ReleaseDC(Handle, DC);
    end;
  end;
end;

procedure TDIBPalette.WMQueryNewPalette(var Message: TMessage);
var
  DC: HDC;
  OldPal: HPalette;
begin
  //Some other app is in the foreground.
  //Windows is asking us what our palette looks like so it can fit in as many
  //of our colors as possible (along with all of the other apps current visible)
  Message.Result := 0;
  with THackCustomForm(Owner) do 
  begin
    DC := GetDC(Handle);
    OldPal := SelectPalette(DC, hPalCurrent, False);
    Message.Result := RealizePalette(DC);
    SelectPalette(DC, OldPal, True);
    RealizePalette(DC);
    ReleaseDC(Handle, DC);
    if Message.Result > 0 then Invalidate;
  end;
  THackCustomForm(FOwner).PaletteChanged(False);
end;

procedure TDIBPalette.ImportFromFile(const aFilename: string);
var
  BMP: TBitmap;
begin
  BMP := TBitmap.Create;
  try
    BMP.LoadFromFile(aFileName);
    if BMP.PixelFormat <> pf8bit then
      raise EDIBPaletteError.Create('Bitmap must be 8 bit.');
    UpdateFromBitmap(BMP);
  finally
    BMP.Free;
  end;
end;

procedure TDIBPalette.Loaded;
begin
  inherited;
  UpdatePalette;
end;

procedure TDIBPalette.SetTable(const Value: Boolean);
begin
  FUseTable := Value;
  if not Value and (FLUT <> nil) then 
  begin
    Freemem(FLUT);
    FLUT := nil;
  end;
  if (FLUT = nil) and Value then GetMem(FLUT, 64 * 64 * 64);
  if not (csLoading in ComponentState) and Value then UpdateLUT;
end;

procedure TDIBPalette.UpdateLUT;
var
  R, G, B: Byte;
  T: tagPaletteEntry;
  OrigCaption: string;
begin
  OrigCaption := Application.Mainform.Caption;
  T.peFlags := 0;
  for B := 0 to 63 do
  begin
    if csDesigning in ComponentState then
      Application.MainForm.Caption := 'Processing ' + IntToStr(B * 100 div 63) + '%';
    T.peBlue := B * 4;
    for G := 0 to 63 do
    begin
      T.peGreen := G * 4;
      for R := 0 to 63 do
      begin
        T.peRed := R * 4;
        FLUT[B, G, R] := SlowColorMatch(T);
      end;
    end;
  end;
  Application.Mainform.Caption := OrigCaption;
end;

function TDIBPalette.ColorDistance(const C1, C2: tagPaletteEntry): Integer;
var
  DX, DY, DZ: Integer;
begin
  DX := C1.peRed - C2.peRed;
  DY := C1.peGreen - C2.peGreen;
  DZ := C1.peBlue - C2.peBlue;
  Result := DX * DX + DY * DY + DZ * DZ;
end;

function TDIBPalette.SlowColorMatch(const Color: tagPaletteEntry): Byte;
var
  X: Byte;
  LastDist, BestDist: Integer;
begin
  Result := 0;
  BestDist := ColorDistance(pPal.palPalEntry[0], Color);

  X := 1;
  repeat
    LastDist := ColorDistance(pPal.palPalEntry[X], Color);
    if (LastDist < BestDist) or (X = 0) then 
    begin
      Result := X;
      BestDist := LastDist;
      if LastDist = 0 then break;
    end;
    Inc(X);
  until (X = 235);
end;

procedure TDIBPalette.LoadTableFromStream(S: TStream);
begin
  if FLUT = nil then Getmem(FLUT, 64 * 64 * 64);
  S.Read(Flut[0, 0, 0], 64 * 64 * 64);
end;

procedure TDIBPalette.SaveTableToStream(S: TStream);
begin
  S.Write(Flut[0, 0, 0], 64 * 64 * 64);
end;

function TDIBPalette.FastColorMatch(const Color: tagPaletteEntry): Byte;
begin
  if FLUT = nil then 
  begin
    Result := 0;
    exit;
  end;

  Result := FLUT[Color.peBlue div 4, Color.peGreen div 4, Color.peRed div 4];
end;

procedure TDIBPalette.Assign(Source: TPersistent);
begin
  inherited;
  if not (Source is TDIBPalette) then
    raise Exception.Create('Not a TDIBPalette Component');

  if Assigned((Source as TDIBPalette).FLUT) then
  begin
    if FLUT = nil then Getmem(FLUT, 64 * 64 * 64);
    Move((Source as TDIBPalette).FLUT^, FLUT^, 64 * 64 * 64);
  end 
  else if Assigned(FLUT) then
  begin
    FreeMem(FLUT);
    FLUT := nil;
  end;

  Move((Source as TDIBPalette).pPal^, pPal^, 4 * 255);
  hPalCurrent := 0;
  UpdatePalette;
end;

procedure TDIBPalette.ImportFromRawFile(const aFileName: string);
var
  lFile: file;
  lReadCount: Integer;
  lIndex: Integer;
  lBuffer: array [0..767] of Byte;
begin
  AssignFile(lFile, aFileName);
  Reset(lFile, 1);
  BlockRead(lFile, lBuffer, 768, lReadCount);
  CloseFile(lFile);
  if (lReadCount <> 768) then
    raise Exception.Create('Invalid Palette File');
  for lIndex := 0 to 234 do
  begin
    pPal.palPalEntry[lIndex].peRed := lBuffer[3 * lIndex];
    pPal.palPalEntry[lIndex].peGreen := lBuffer[3 * lIndex + 1];
    pPal.palPalEntry[lIndex].peBlue := lBuffer[3 * lIndex + 2];
    pPal.palPalEntry[lIndex].peFlags := 0;
  end;
  UpdatePalette;
end;

procedure TDIBPalette.ResetPalette;
var
  lIndex: Integer;
begin
  pPal.palVersion := $300;
  pPal.palNumEntries := 235;
  for lIndex := 0 to 234 do 
  begin
    pPal.palPalEntry[lIndex].peRed := 255 - lIndex;
    pPal.palPalEntry[lIndex].peGreen := 255 - lIndex;
    pPal.palPalEntry[lIndex].peBlue := 255 - lIndex;
    pPal.palPalEntry[lIndex].peFlags := 0;
  end;
  UpdatePalette;
end;

end.
