unit cDIBStandardCompressors;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBStandardCompressors.PAS, released September 04, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To provide at least 1 working example of a DIBCompressor

Contributor(s):
None as yet


Last Modified: September 04, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   November 21, 2000
By:     Peter Morris
Change: Fixed TLZHDIBCompressor to stop it corrupting the end of DIB data.
*)

interface

uses
  cDIBCompressor, Classes, Windows, SysUtils, cDIB;

type
  TRLEDIBCompressor = class(TAbstractDIBCompressor)
  private
    function RLE(const Source, Dest; const SourceSize: DWord): DWord;
    procedure UnRLE(const Source, Dest; const SourceSize: DWord);
  public
    function GetAboutText: string; override;
    function GetAuthor: string; override;
    function GetEmail: string; override;
    function GetURL: string; override;

    function GetGUID: TGUID; override;
    function CanDecompress(const GUID: TGUID): Boolean; override;
    function Compress(const DIB: TAbstractSuperDIB; const Source; var Dest;
      const SourceSize: DWord): DWord; override;
    procedure Decompress(const DIB: TAbstractSuperDIB; const GUID: TGUID;
      const Source; var Dest; const SourceSize, DestSize: DWord; out DecompressedDirectlyToDIB: Boolean); override;
    function GetDisplayName: string; override;
  end;

  TLZHDIBCompressor = class(TAbstractDIBCompressor)
  private
  public
    function GetAboutText: string; override;
    function GetAuthor: string; override;
    function GetEmail: string; override;
    function GetURL: string; override;

    function GetGUID: TGUID; override;
    function CanDecompress(const GUID: TGUID): Boolean; override;
    function Compress(const DIB: TAbstractSuperDIB; const Source; var Dest;
      const SourceSize: DWord): DWord; override;
    procedure Decompress(const DIB: TAbstractSuperDIB; const GUID: TGUID;
      const Source; var Dest; const SourceSize, DestSize: DWord; out DecompressedDirectlyToDIB: Boolean); override;
    function GetDisplayName: string; override;
  end;

implementation

uses
  ComObj, DIBLZH;
  
const
  cRLEGUID: TGUID = '{CABA9056-7349-43A4-B010-3764FBFAC230}';
  cLZHGUID: TGUID = '{BC0C10FC-E045-41E7-A37C-B86AF21320B8}';

  { TRLEDIBCompressor }

function TRLEDIBCompressor.CanDecompress(const GUID: TGUID): Boolean;
begin
  Result := (GUIDToString(GUID) = GUIDToString(cRLEGUID));
end;

function TRLEDIBCompressor.Compress(const DIB: TAbstractSuperDIB; const Source; var Dest;
  const SourceSize: DWord): DWord;
var
  pDest: Pointer;
begin
  Getmem(pDest, SourceSize);
  try
    Shuffle(Source, pDest^, SourceSize);
    Result := RLE(pDest^, Dest, SourceSize);
  finally
    Freemem(pDest);
  end;
end;

procedure TRLEDIBCompressor.Decompress(const DIB: TAbstractSuperDIB;
  const GUID: TGUID; const Source; var Dest;
  const SourceSize, DestSize: DWord; out DecompressedDirectlyToDIB: Boolean);
var
  pDest: Pointer;
begin
  DecompressedDirectlyToDIB := False;
  Getmem(pDest, DestSize);
  try
    UnRLE(Source, pDest^, SourceSize);
    UnShuffle(pDest^, Dest, DestSize);
  finally
    Freemem(pDest);
  end;
end;

function TRLEDIBCompressor.GetAboutText: string;
begin
  Result := 'Shuffle4 RLE' + #13#10 +
    #13#10 +
    'Shuffles the RGBA values from' + #13#10 +
    'RGBA,RGBA,RGBA,RGBA to' + #13#10 +
    'RRRR,GGGG,BBBB,AAAA' + #13#10 +
    'in order to create higher repitition,' + #13#10 +
    'and then performs a simple RLE compression';
end;

function TRLEDIBCompressor.GetAuthor: string;
begin
  Result := 'Peter Morris';
end;

function TRLEDIBCompressor.GetDisplayName: string;
begin
  Result := 'Shuffle4 RLE';
end;

function TRLEDIBCompressor.GetEmail: string;
begin
  Result := 'support@droopyeyes.com';
end;

function TRLEDIBCompressor.GetGUID: TGUID;
begin
  Result := cRLEGUID;
end;

function TRLEDIBCompressor.GetURL: string;
begin
  Result := 'http://www.droopyeyes.com';
end;

function TRLEDIBCompressor.RLE(const Source; const Dest;
  const SourceSize: DWord): DWord; assembler;
asm
      push ESI
      push EDI
      push EBX
      push Dest

      mov  ESI, Source
      mov  EDI, Dest
      //Read bytes left
      mov  ECX, SourceSize
      //Write bytes left
      mov  EBX, SourceSize

      xor  dl, dl //Byte count
      mov  ah, [ESI] // Repeat value

      //each write to Dest takes 2 bytes
      shr  EBX, 1

  @OuterLoop:
      mov  al, ah //Value = repeat value
  @InnerLoop:
      inc  dl
      inc  ESI
      dec  ECX
      jz   @WriteValues
      cmp  dl, 255
      jz   @WriteValues

      mov  ah, [ESI] //Get the next value
      cmp  ah, al //compare
      jnz  @WriteValues //if <> then write values
      jmp  @InnerLoop

  @WriteValues:
      mov  [EDI], dl
      inc  EDI
      xor  dl, dl
      mov  [EDI], al
      inc  EDI
      cmp  ECX, 0
      jz   @Compressed
      //If we are here, we are not at the end of SOURCE
      //Dec EBX (Dest bytes remaining), if 0 then quit
      dec  EBX
      jz   @NotCompressed
      jmp  @OuterLoop

  //We reached the end of the destination buffer before the
  //end of the source buffer, in other words, Dest is bigger than Source
  @NotCompressed:
      //pop the extra push that we no longer need
      pop  EDI

      mov  Result, 0
      jmp  @TheEnd

  @Compressed:
      //Get the original @Dest into ESI
      pop  ESI
      //See how far it is from ESI -> EDI
      sub  EDI, ESI
      mov  Result, EDI
  @TheEnd:
  //pop Source
      pop  EBX
      pop  EDI
      pop  ESI

end;

procedure TRLEDIBCompressor.UnRLE(const Source, Dest;
  const SourceSize: DWord); assembler;
asm
      push ESI
      push EDI
      push EBX

      mov  EBX, SourceSize
      mov  ESI, Source
      mov  EDI, Dest
      xor  ECX, ECX
      shr  EBX, 1
  @ReadLoop:
      mov  CL, [ESI]
      inc  ESI
      LodSB
      repnz StoSB

      dec  EBX
      jnz  @ReadLoop

      pop  EBX
      pop  EDI
      pop  ESI
end;


{ TLZHDIBCompressor }

function TLZHDIBCompressor.CanDecompress(const GUID: TGUID): Boolean;
begin
  Result := (GUIDToString(GUID) = GUIDToString(cLZHGUID));
end;

function TLZHDIBCompressor.Compress(const DIB: TAbstractSuperDIB; const Source; var Dest;
  const SourceSize: DWord): DWord;
var
  msSource, msDest: TMemoryStream;
  LZH: TLZHStream;
begin
  msSource := TMemoryStream.Create;
  msDest := TMemoryStream.Create;
  LZH := TLZHStream.Create(msSource, msDest);
  try
    msSource.SetSize(SourceSize);
    msDest.SetSize(SourceSize);
    try
      Move(Source, msSource.Memory^, SourceSize);
      Result := LZH.Pack(SourceSize) + 4; //Can anyone tell me why I need + 4 ?
      Move(msDest.Memory^, Dest, Result);
    except
      Result := 0;
    end;
  finally
    msSource.Free;
    msDest.Free;
  end;
end;

procedure TLZHDIBCompressor.Decompress(const DIB: TAbstractSuperDIB;
  const GUID: TGUID; const Source;
  var Dest; const SourceSize, DestSize: DWord; out DecompressedDirectlyToDIB: Boolean);
var
  msSource, msDest: TMemoryStream;
  LZH: TLZHStream;
begin
  DecompressedDirectlyToDIB := False;
  msSource := TMemoryStream.Create;
  msDest := TMemoryStream.Create;
  LZH := TLZHStream.Create(msSource, msDest);
  try
    msSource.SetSize(SourceSize);
    msDest.SetSize(DestSize);
    Move(Source, msSource.memory^, SourceSize);
    LZH.Unpack;
    Move(msDest.Memory^, Dest, DestSize);
  finally
    msSource.Free;
    msDest.Free;
  end;
end;

function TLZHDIBCompressor.GetAboutText: string;
begin
  Result :=
    'Uses LZH compression to compress the graphics,' + #13#10 +
    'Compression is slow, decompression is not so slow, but the savings ' +
    'in size are very large.';
end;

function TLZHDIBCompressor.GetAuthor: string;
begin
  Result := 'Peter Morris';
end;

function TLZHDIBCompressor.GetDisplayName: string;
begin
  Result := 'DIB LZH';
end;

function TLZHDIBCompressor.GetEmail: string;
begin
  Result := 'support@droopyeyes.com';
end;

function TLZHDIBCompressor.GetGUID: TGUID;
begin
  Result := cLZHGUID;
end;

function TLZHDIBCompressor.GetURL: string;
begin
  Result := 'http://www.droopyeyes.com';
end;

initialization
  RegisterDIBCompressor(TRLEDIBCompressor.Create);
  RegisterDIBCompressor(TLZHDIBCompressor.Create);
end.
