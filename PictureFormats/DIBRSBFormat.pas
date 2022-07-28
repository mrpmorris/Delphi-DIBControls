unit DIBRSBFormat;

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
  tagRSB = record
    Version: Integer;
    Width: Integer;
    Height: Integer;
    Red_Bits: Integer;
    Green_Bits: Integer;
    Blue_Bits: Integer;
    Alpha_Bits: Integer;
  end;

  TDIBRSBFormat = class(TAbstractDIBFormat)
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
  
type
  THackDIB = class(TAbstractSuperDIB);

  { TDIBRSBFormat }

function TDIBRSBFormat.CanLoadFormat(FileExt: string): Boolean;
begin
  Result := CompareText(FileExt, '.RSB') = 0;
end;

function TDIBRSBFormat.CanSaveFormat(FileExt: string): Boolean;
begin
  Result := CompareText(FileExt, '.RSB') = 0;
end;

function TDIBRSBFormat.GetDisplayName: string;
begin
  Result := 'Rogue spear bitmap';
end;

procedure TDIBRSBFormat.GetExportFormats(const Result: TStrings);
begin
  GetImportFormats(Result);
end;

procedure TDIBRSBFormat.GetImportFormats(const Result: TStrings);
begin
  Result.Add('Rogue spear bitmap (*.rsb)|*.rsb');
end;

procedure TDIBRSBFormat.InternalLoadFromStream(FileExt: string;
  Stream: TStream);
var
  X, Y: Integer;
  Source: ^Word;
  N: Word;
  P: ^Byte;
  Header: tagRSB;
  BlueShift, GreenShift, RedShift, GreenPower, RedPower: Byte;
  Memory: Pointer;
begin
  Stream.Read(Header, SizeOf(Header));
  if (Header.Version <> 1) then
    raise EDIBFormatError.Create('Only RSB version 1 is supported.');

  DIB.Resize(Header.Width, Header.Height);

  // Calc how many steps to shift for each color
  BlueShift := 8 - Header.Blue_Bits;
  Greenshift := Header.Green_Bits + Header.Blue_Bits - 8;
  RedShift := Header.Red_Bits + Header.Green_Bits + Header.Blue_Bits - 8;

  // Calc what to AND with the color (MASK)
  GreenPower := 256 - Trunc(Power(2, 8 - Header.Blue_Bits));
  RedPower := 256 - Trunc(Power(2, 8 - Header.Red_Bits));

  Getmem(Memory, Header.Width * Header.Height * 2);
  try
    Stream.Read(Memory^, Header.Width * Header.Height * 2);
    Source := Memory;
    for Y := 0 to Header.Height - 1 do
    begin
      P := DIB.Scanline[Y];
      for X := 0 to Header.Width - 1 do
      begin
        N := Source^;
        Inc(Integer(Source), 2);

        // Blue
        P^ := N shl BlueShift;;
        Inc(Integer(P), 1);

        // Green
        P^ := (N shr GreenShift) and GreenPower;
        Inc(Integer(P), 1);

        // Red
        P^ := (N shr RedShift) and RedPower;
        Inc(Integer(P), 1);

        // Alpha
        P^ := 0;
        Inc(Integer(P), 1);
      end;
      Progress(Y, Header.Height - 1);
    end;
    THackDIB(DIB).Masked := Header.Alpha_Bits > 0;
  finally
    Freemem(Memory);
  end;
end;

procedure TDIBRSBFormat.InternalSaveToStream(FileExt: string; Stream: TStream);
var
  r, g, b, a: Byte;
  Dest: ^Word;
  Source: ^Byte;
  X, Y: Integer;
  P: Pointer;
  RSBHeader: tagRSB;
begin
  RSBHeader.Width := DIB.Width;
  RSBHeader.Height := DIB.Height;
  RSBHeader.Version := 1;
  if THackDIB(DIB).Masked then
  begin
    RSBHeader.Red_Bits := 4;
    RSBHeader.Green_Bits := 4;
    RSBHeader.Blue_Bits := 4;
    RSBHeader.Alpha_Bits := 4;
  end 
  else
  begin
    RSBHeader.Red_Bits := 5;
    RSBHeader.Green_Bits := 6;
    RSBHeader.Blue_Bits := 5;
    RSBHeader.Alpha_Bits := 0;
  end;

  GetMem(P, DIB.Width * DIB.Height * 2);
  Dest := P;

  for Y := 0 to DIB.Height - 1 do
  begin
    Source := DIB.ScanLine[Y];
    for X := 0 to DIB.Width - 1 do
    begin
      b := Source^;
      Inc(Integer(Source), 1);

      g := Source^;
      Inc(Integer(Source), 1);

      r := Source^;
      Inc(Integer(Source), 1);

      a := Source^;
      Inc(Integer(Source), 1);

      if THackDIB(DIB).Masked then
        Dest^ := ((a and $F0) shl 8) or ((r and $F0) shl 4) or (g and $F0) or (b shr 4)
      else
        Dest^ := ((r and $F8) shl 8) or ((g and $FC) shl 3) or (b shr 3);

      Inc(Integer(Dest), 2);
    end;
    Progress(Y, DIB.Height - 1);
  end;
  Stream.Write(RSBHeader, SizeOf(RSBHeader));
  Stream.Write(P^, DIB.Width * DIB.Height * 2);
  FreeMem(P);
end;

initialization
  RegisterDIBFormat(TDIBRSBFormat.Create);
end.
