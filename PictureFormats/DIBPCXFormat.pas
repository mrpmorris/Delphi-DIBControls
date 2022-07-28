unit DIBPCXFormat;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBRSBFormat.PAS, released December 2, 2000.

The Initial Developer of the Original Code is Dan Strandberg (webmaster@game-editing.net),
Portions created by Dan Strandberg are Copyright (C) 2000 Dan Strandberg.
All Rights Reserved.

Purpose of file:
To import and export rogue spear bitmaps.

Contributor(s):
Peter Morris


Last Modified: December 2, 2000

You may retrieve the latest version of this file from my home page
located at  http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   December 2, 2000
By:     Dan Strandberg / Peter Morris
Change: Added save capability

*)

interface

uses
  Classes, Windows, SysUtils, Math, cDIBFormat;

type
  TDIBPCXFormat = class(TAbstractDIBFormat)
  protected
    function GetDisplayName: string; override;
    procedure InternalLoadFromStream(FileExt: string; Stream: TStream); override;
    procedure InternalSaveToStream(FileExt: string; Stream: TStream); override;
  public
    function CanLoadFormat(FileExt: string): Boolean; override;
    function CanSaveFormat(FileExt: string): Boolean; override;
    procedure GetImportFormats(const Result: TStrings); override;
    procedure GetExportFormats(const Result: TStrings); override;
  end;

implementation

uses
  cDIB;

const
  cMaxScanLineLength = $FFF;
  cMaxDataFileLength = $7FFFFF;
  WIDTH_ERROR = 'Illegal width entry in PCX file header';
  HEIGHT_ERROR = 'Illegal height entry in PCX file header';
  FILE_FORMAT_ERROR = 'Invalid file format';
  VERSION_ERROR = 'Only PCX (PC Paintbrush) version 3.0 is supported';
  PALETTE_ERROR = 'Invalid palette found';
  ASSIGN_ERROR = 'Can only assign a bitmap to a PCX image';
  ASSIGNTO_ERROR = 'Can only assign to a bitmap';
  PCXIMAGE_EMPTY = 'The PCX image is empty';
  BITMAP_EMPTY = 'The bitmap is empty';
  INPUT_FILE_TOO_LARGE = 'The input file is too large to read';
  WIDTH_TOO_LARGE = 'Width of PCX image too large';

type
  TColorRecord = packed record
    R, G, B: Byte;
  end;

  TPCXPalette = packed record
    Signature: Byte;
    Palette: array[0..255] of TColorRecord;
  end;

  TWindowRecord = record
    Left,
    Top,
    Right,
    Bottom: Word;
  end;

  TPCXImageHeader = packed record
    ID: Byte;
    Version: Byte;
    Compressed: Byte;
    BitsPerPixel: Byte;
    Window: TWindowRecord;
    HorzResolution: Word;
    VertResolution: Word;
    ColorMap: array[0..15] of TColorRecord;
    Reserved: Byte;
    Planes: Byte;
    BytesPerLine: Word;
    PaletteInfo: Word;
    Filler: array[0..57] of Byte;
  end;


  { TDIBPCXFormat }

function TDIBPCXFormat.CanLoadFormat(FileExt: string): Boolean;
begin
  Result := CompareText(FileExt, '.PCX') = 0;
end;

function TDIBPCXFormat.CanSaveFormat(FileExt: string): Boolean;
begin
  Result := False;
end;

function TDIBPCXFormat.GetDisplayName: string;
begin
  Result := 'PCX';
end;

procedure TDIBPCXFormat.GetExportFormats(const Result: TStrings);
begin
end;

procedure TDIBPCXFormat.GetImportFormats(const Result: TStrings);
begin
  Result.Add('PCX file (*.pcx)|*.pcx');
end;

procedure TDIBPCXFormat.InternalLoadFromStream(FileExt: string; Stream: TStream);
var
  Cnt, Value: Byte;
  Header: TPCXImageHeader;
  Width, Height: Integer;
  I, J, K, X, Y, ColorDepth, FileLength: Cardinal;
  Palette: TPCXPalette;
  Data, RLine, GLine, BLine: array of Byte;
  DIBData: PByteArray;
begin
  Stream.Read(Header, SizeOf(Header));
  if Header.ID <> $0A then
    raise EDIBFormatError.Create(VERSION_ERROR);
  Width := Header.Window.Right - Header.Window.Left + 1;
  if Width < 0 then
    raise EDIBFormatError.Create(WIDTH_ERROR);
  if Width > cMaxScanLineLength then
    raise Exception.Create(WIDTH_TOO_LARGE);
  Height := Header.Window.Bottom - Header.Window.Top + 1;
  if Height < 0 then
    raise EDIBFormatError.Create(HEIGHT_ERROR);
  ColorDepth := 1 shl (Header.Planes * Header.BitsPerPixel);

  if ColorDepth <= 16 then
    for I := 0 to ColorDepth - 1 do
      if Header.Version = 3 then
      begin
        Palette.Palette[I].R := Header.ColorMap[I].R shl 2;
        Palette.Palette[I].G := Header.ColorMap[I].G shl 2;
        Palette.Palette[I].B := Header.ColorMap[I].B shl 2;
      end 
    else
    begin
      Palette.Palette[I].R := Header.ColorMap[I].R;
      Palette.Palette[I].G := Header.ColorMap[I].G;
      Palette.Palette[I].B := Header.ColorMap[I].B;
    end;
  FileLength := Stream.Size - Stream.Position;
  SetLength(Data, FileLength);
  if FileLength > cMaxDataFileLength then
    raise EDIBFormatError.Create(INPUT_FILE_TOO_LARGE);
  Stream.Read(Data[0], FileLength);

  DIB.ReSize(Width, Height);

  SetLength(RLine, Width);
  SetLength(GLine, Width);
  SetLength(BLine, Width);

  I := 0;
  for Y := 0 to Height - 1 do
  begin
    //Process RED line
    J := 0;
    repeat
      Value := Data[I];
      Inc(I);

      if Value < $C1 then
      begin
        RLine[J] := Value;
        Inc(J);
      end;

      // multiple bytes (RLE)
      if Value > $C0 then
      begin
        Cnt := Value and $3F;
        Value := Data[I];
        Inc(I);
        for K := 1 to Cnt do
        begin
          RLine[J] := Value;
          Inc(J);
        end;
      end;
    until Integer(J) >= Width;

    //Process GREEN line
    J := 0;
    repeat
      Value := Data[I];
      Inc(I);

      // one byte
      if Value < $C1 then
      begin
        GLine[J] := Value;
        Inc(J);
      end;

      // multiple bytes (RLE)
      if Value > $C0 then
      begin
        Cnt := Value and $3F;
        Value := Data[I];
        Inc(I);
        for K := 1 to Cnt do
        begin
          GLine[J] := Value;
          Inc(J);
        end;
      end;
    until Integer(J) >= Width;

    //Process BLUE line
    J := 0;
    repeat
      Value := Data[I];
      Inc(I);

      // one byte
      if Value < $C1 then
      begin
        BLine[J] := Value;
        Inc(J);
      end;

      // multiple bytes (RLE)
      if Value > $C0 then
      begin
        Cnt := Value and $3F;
        Value := Data[I];
        Inc(I);
        for K := 1 to Cnt do
        begin
          BLine[J] := Value;
          Inc(J);
        end;
      end;
    until Integer(J) >= Width;

    DIBData := DIB.ScanLine[Y];
    X := 0;
    for K := 0 to Width - 1 do
    begin
      DIBData[X] := BLine[K];
      Inc(X);
      DIBData[X] := GLine[K];
      Inc(X);
      DIBData[X] := RLine[K];
      Inc(X, 2);
    end;
  end;
end;

procedure TDIBPCXFormat.InternalSaveToStream(FileExt: string; Stream: TStream);
begin
  inherited;
end;

initialization
  RegisterDIBFormat(TDIBPCXFormat.Create);
end.
