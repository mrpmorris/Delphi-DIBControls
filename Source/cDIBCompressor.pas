unit cDIBCompressor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBCompress.PAS, released September 04, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To handle the compression / decompression of DIB data, and to allow people to register
their own compressors.

Contributor(s):
None as yet


Last Modified: September 04, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}


interface

uses
  Classes, SysUtils, Windows, cDIB;

type
  TAbstractDIBCompressor = class(TPersistent)
  private
  protected
    procedure Shuffle(const Source, Dest; const SourceSize: DWord);
    procedure UnShuffle(const Source, Dest; const SourceSize: Dword);
  public
    function GetGUID: TGUID; virtual; abstract;
    function CanDecompress(const GUID: TGUID): Boolean; virtual; abstract;
    function Compress(const DIB: TAbstractSuperDIB; const Source; var Dest;
      const SourceSize: DWord): DWord; virtual; abstract;
    procedure Decompress(const DIB: TAbstractSuperDIB; const GUID: TGUID;
      const Source; var Dest; const SourceSize, DestSize: DWord; out DecompressedDirectlyToDIB: Boolean); virtual; abstract;
    function GetDisplayName: string; virtual; abstract;

    function GetAboutText: string; virtual;
    function GetAuthor: string; virtual;
    function GetEmail: string; virtual;
    function GetURL: string; virtual;
  end;

procedure RegisterDIBCompressor(const Compressor: TAbstractDIBCompressor);
function CompressorCount: Integer;
function Compressor(Index: Integer): TAbstractDIBCompressor;
procedure Compress(const DIB: TAbstractSuperDIB; const Source, Dest: TStream);
procedure Decompress(const DIB: TAbstractSuperDIB; const Source, Dest: TStream; out DecompressedDirectlyToDIB: Boolean);
function FindCompressor(const GUID: string): TAbstractDIBCompressor;

var
  DefaultCompressor: TAbstractDIBCompressor;

implementation

uses
  COMObj;

type
  EDIBCompressError = class(Exception);

const
  cCompressedSig = 'DIBCMP';

var
  FList: TList;

procedure RegisterDIBCompressor(const Compressor: TAbstractDIBCompressor);
begin
  FList.Add(Compressor);
end;

function CompressorCount: Integer;
begin
  Result := FList.Count;
end;

function Compressor(Index: Integer): TAbstractDIBCompressor;
begin
  if (Index < 0) or (Index >= FList.Count) then
    raise EDIBCompressError.Create('Index ' + IntToStr(Index) + ' out of range.');
  Result := TAbstractDIBCompressor(FList[Index]);
end;

procedure Compress(const DIB: TAbstractSuperDIB; const Source, Dest: TStream);
var
  MSSource, MSDest: TMemoryStream;
  GUID: TGUID;
  OrigPosition: Integer;
  SourceSize, NewDataSize: DWord;
  pSource: Pointer;
begin
  if Source is TMemoryStream then
    MSSource := TMemoryStream(Source)
  else
  begin
    MSSource := TMemoryStream.Create;
    MSSource.CopyFrom(Source, Source.Size);
    MSSource.Seek(0, 0);
  end;

  SourceSize := Source.Size - Source.Position;

  MSDest := TMemoryStream.Create;
  try
    if not Assigned(DefaultCompressor) then
      Dest.CopyFrom(Source, SourceSize)
    else 
    begin
      OrigPosition := Source.Position;
      MSDest.SetSize(SourceSize);
      pSource := Pointer(Integer(MSSource.Memory) + MSSource.Position);
      NewDataSize :=
        DefaultCompressor.Compress(DIB, pSource^, MSDest.Memory^, SourceSize);
      if NewDataSize > 0 then 
      begin
        MSDest.SetSize(NewDataSize);
        Assert(NewDataSize <= DWORD(MSDest.Size));

        Dest.Write(cCompressedSig, Length(cCompressedSig));

        GUID := DefaultCompressor.GetGuid;
        Dest.Write(GUID, SizeOf(GUID));

        Dest.Write(SourceSize, SizeOf(DWord));
        MSDest.Seek(0, soFromBeginning);
        Dest.CopyFrom(MSDest, MSDest.Size);
      end 
      else 
      begin
        Source.Seek(OrigPosition, soFromBeginning);
        Dest.CopyFrom(Source, Source.Size);
      end;
    end;
  finally
    MSDest.Free;
    if MSSource <> Source then MSSource.Free;
  end;
end;

procedure Decompress(const DIB: TAbstractSuperDIB; const Source, Dest: TStream; out DecompressedDirectlyToDIB: Boolean);
var
  I: Integer;
  FCompressor: TAbstractDIBCompressor;
  Signature: array[0..5] of Char;
  GUID: TGUID;
  NeedCompressor: Boolean;
  OrigPosition: Integer;
  OrigDataSize: DWord;
  MSSource, MSDest: TMemoryStream;
  pSource: Pointer;
begin
  NeedCompressor := False;
  OrigPosition := Source.Position;
  OrigDataSize := 0;
  if Source.Size >= Length(cCompressedSIG) + SizeOf(TGUID) + SizeOf(DWord) then 
  begin
    Source.Read(Signature[0], 6);
    if Signature = cCompressedSig then 
    begin
      Source.Read(GUID, SizeOf(GUID));
      Source.Read(OrigDataSize, SizeOf(DWord));
      NeedCompressor := True;
    end 
    else
      Source.Seek(OrigPosition, soFromBeginning);
  end;

  if not NeedCompressor then
    Dest.CopyFrom(Source, Source.Size)
  else
  begin
    FCompressor := nil;
    for I := FList.Count - 1 downto 0 do
      with TAbstractDIBCompressor(FList[I]) do
        if CanDecompress(GUID) then
        begin
          FCompressor := TAbstractDIBCompressor(FList[I]);
          break;
        end;

    if FCompressor = nil then
      raise EDIBCompressError.Create('Could not find a suitable decompressor.')
    else
    begin
      //If a memory stream, point to that data
      if Source is TMemoryStream then
        MSSource := TMemoryStream(Source)
      else
      begin
        //If not a memory stream, Copy the data to a memory stream
        MSSource := TMemoryStream.Create;
        MSSource.CopyFrom(Source, Source.Size - Source.Position);
        MSSource.Seek(0, soFromBeginning);
      end;

      pSource := Pointer(Integer(MSSource.Memory) + MSSource.Position);

      MSDest := TMemoryStream.Create;
      try
        MSDest.SetSize(OrigDataSize);
        FCompressor.Decompress(DIB, GUID, pSource^, MSDest.Memory^,
          MSSource.Size - MSSource.Position, OrigDataSize, DecompressedDirectlyToDIB);
        MSDest.Seek(0, soFromBeginning);
        Dest.CopyFrom(MSDest, MSDest.Size);
      finally
        MSDest.Free;
        if MSSource <> Source then MSSource.Free;
      end;
    end;
  end;
end;



{ TAbstractDIBCompressor }

function TAbstractDIBCompressor.GetAboutText: string;
begin
  Result := 'No information supplied';
end;

function TAbstractDIBCompressor.GetAuthor: string;
begin
  Result := 'No information supplied';
end;

function TAbstractDIBCompressor.GetEmail: string;
begin
  Result := '';
end;

function TAbstractDIBCompressor.GetURL: string;
begin
  Result := '';
end;

function FindCompressor(const GUID: string): TAbstractDIBCompressor;
var
  I: Integer;
begin
  Result := nil;
  for I := FList.Count - 1 downto 0 do 
    if GUIDToString(TAbstractDIBCompressor(FList[I]).GetGUID) = GUID then 
    begin
      Result := TAbstractDIBCompressor(FList[I]);
      break;
    end;
end;

procedure TAbstractDIBCompressor.Shuffle(const Source; const Dest;
  const SourceSize: DWord);
asm
      push ESI
      push EDI
      push EBX

      mov  EBX, Source
      mov  EDX, SourceSize
      mov  EDI, Dest

      //Alpha
      mov  ECX, EDX
      mov  ESI, EBX
      inc  EBX
      shr  ECX, 2
  @AlphaLoop:
      mov  al, [ESI]
      lea  ESI, [ESI+4]
      mov  [EDI], al
      inc  EDI
      dec  ECX
      jnz  @AlphaLoop

      //Blue
      mov  ECX, EDX
      mov  ESI, EBX
      inc  EBX
      shr  ECX, 2
  @BlueLoop:
      mov  al, [ESI]
      lea  ESI, [ESI+4]
      mov  [EDI], al
      inc  EDI
      dec  ECX
      jnz  @BlueLoop

      //Green
      mov  ECX, EDX
      mov  ESI, EBX
      inc  EBX
      shr  ECX, 2
  @GreenLoop:
      mov  al, [ESI]
      lea  ESI, [ESI+4]
      mov  [EDI], al
      inc  EDI
      dec  ECX
      jnz  @GreenLoop

      //Red
      mov  ECX, EDX
      mov  ESI, EBX
      inc  EBX
      shr  ECX, 2
  @RedLoop:
      mov  al, [ESI]
      lea  ESI, [ESI+4]
      mov  [EDI], al
      inc  EDI
      dec  ECX
      jnz  @RedLoop

      pop  EBX
      pop  EDI
      pop  ESI
end;

//The idea is we read 1 byte
//write 1 byte
//skip the dest forward 3 pixels
procedure TAbstractDIBCompressor.UnShuffle(const Source, Dest;
  const SourceSize: Dword); assembler;
asm
      push ESI
      push EDI
      push EBX

      mov  ESI, Source
      mov  EBX, Dest
      mov  EDX, SourceSize


      //Alpha
      mov  ECX, EDX
      mov  EDI, EBX
      inc  EBX
      shr  ECX, 2
  @AlphaLoop:
      mov  al, [ESI]
      inc  ESI
      mov  [EDI], al
      lea  EDI, [EDI+4]
      dec  ECX
      jnz  @AlphaLoop

      //Blue
      mov  ECX, EDX
      mov  EDI, EBX
      inc  EBX
      shr  ECX, 2
  @BlueLoop:
      mov  al, [ESI]
      inc  ESI
      mov  [EDI], al
      lea  EDI, [EDI+4]
      dec  ECX
      jnz  @BlueLoop

      //Green
      mov  ECX, EDX
      mov  EDI, EBX
      inc  EBX
      shr  ECX, 2
  @GreenLoop:
      mov  al, [ESI]
      inc  ESI
      mov  [EDI], al
      lea  EDI, [EDI+4]
      dec  ECX
      jnz  @GreenLoop

      //Red
      mov  ECX, EDX
      mov  EDI, EBX
      inc  EBX
      shr  ECX, 2
  @RedLoop:
      mov  al, [ESI]
      inc  ESI
      mov  [EDI], al
      lea  EDI, [EDI+4]
      dec  ECX
      jnz  @RedLoop


      pop  EBX
      pop  EDI
      pop  ESI
end;

initialization
  FList := TList.Create;

finalization
  while FList.Count > 0 do 
  begin
    TAbstractDIBCompressor(FList[0]).Free;
    FList.Delete(0);
  end;
end.
