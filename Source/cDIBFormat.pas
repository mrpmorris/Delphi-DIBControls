unit cDIBFormat;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBFormats.PAS, released November 18, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To allow 3rd part developers to support custom file formats for
LoadPicture and SavePicture

Contributor(s):
Dan Strandberg


Last Modified: December 2, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com

Known Issues:
None
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   December 2, 2000
By:     Dan Strandberg
Change: Added DIBRSBFormat to the uses clause.

Date:   December 2, 2000
By:     Peter Morris
Change: Added GetImportFilter and GetExportFilter which will enabled your to
        quickly build the FILTER property for a load/save dialog with all
        available formats.
*)

interface

uses
  SysUtils, Classes, cDIB;

type
  EDIBFormatError = class(Exception);
  TAbstractDIBFormat = class;
  TSetFormatParams = procedure(Sender: TAbstractDIBFormat; var Handled: Boolean) of
  object;
  TFormatProgressEvent = procedure(Sender: TAbstractDIBFormat; Percent: Integer) of
  object;

  TAbstractDIBFormat = class
  private
    FDIB: TAbstractSuperDIB;
    FOnProgress: TFormatProgressEvent;
    FOnSetLoadParams,
    FOnSetSaveParams: TSetFormatParams;
    function GetAbout: string;
  protected
    //Mandatory overrides
    function GetDisplayName: string; virtual; abstract;
    procedure InternalLoadFromStream(FileExt: string; Stream: TStream);
      virtual; abstract;
    procedure InternalSaveToStream(FileExt: string; Stream: TStream); virtual; abstract;

    //Optional overrides
    procedure DisplayLoadParams(var CanContinue: Boolean); virtual;
    procedure DisplaySaveParams(var CanContinue: Boolean); virtual;

    //Call this method to indicate progress (optional)
    procedure Progress(BytesRead, TotalBytes: Integer);

    property DIB: TAbstractSuperDIB read FDIB;
  public
    //Optional overrides
    //FileExt should start with a '.', eg  '.bmp'
    function CanLoadFormat(FileExt: string): Boolean; virtual;
    function CanSaveFormat(FileExt: string): Boolean; virtual;
    procedure GetExportFormats(const Result: TStrings); virtual;
    procedure GetImportFormats(const Result: TStrings); virtual;

    //Do not write your code in these 2 methods, use Internal(Load/Save)Format
    procedure LoadFromFile(const Filename: string; Dest: TAbstractSuperDIB);
    procedure LoadFromStream(FileExt: string; Stream: TStream; Dest: TAbstractSuperDIB);
    procedure SaveToFile(const Filename: string; Source: TAbstractSuperDIB);
    procedure SaveToStream(FileExt: string; Stream: TStream; Source: TAbstractSuperDIB);

    //Author information
    function GetAboutText: string; virtual;
    function GetAuthor: string; virtual;
    function GetEmail: string; virtual;
    function GetURL: string; virtual;

    property About: string read GetAbout;
    property OnProgress: TFormatProgressEvent read FOnProgress write FOnProgress;
    property OnSetLoadParams: TSetFormatParams read FOnSetLoadParams write FOnSetLoadParams;
    property OnSetSaveParams: TSetFormatParams read FOnSetSaveParams write FOnSetSaveParams;
  end;

procedure RegisterDIBFormat(const Format: TAbstractDIBFormat);

function DIBFormatCount: Integer;
function DIBFormat(Index: Integer): TAbstractDIBFormat;
function FindDIBExporter(Filename: string): TAbstractDIBFormat;
function FindDIBImporter(Filename: string): TAbstractDIBFormat;

function GetImportFilter: string;
function GetExportFilter: string;

implementation

//uses
//  DIBRSBFormat;

var
  FList: TList;

  { Unit procedures }
function GetImportFilter: string;
var
  I: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    for I := 0 to FList.Count - 1 do
      DIBFormat(I).GetImportFormats(SL);
    Result := SL.Text;
    Result := StringReplace(Result, #13, '|', [rfReplaceAll]);
    Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  finally
    SL.Free;
  end;
end;

function GetExportFilter: string;
var
  I: Integer;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    for I := 0 to FList.Count - 1 do
      DIBFormat(I).GetExportFormats(SL);
    Result := SL.Text;
    Result := StringReplace(Result, #13, '|', [rfReplaceAll]);
    Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  finally
    SL.Free;
  end;
end;

procedure RegisterDIBFormat(const Format: TAbstractDIBFormat);
begin
  if FList = nil then FList := TList.Create;
  FList.Add(Format);
end;

function DIBFormatCount: Integer;
begin
  Result := FList.Count;
end;

function DIBFormat(Index: Integer): TAbstractDIBFormat;
begin
  Result := TAbstractDIBFormat(FList[Index]);
end;

function FindDIBExporter(Filename: string): TAbstractDIBFormat;
var
  I: Integer;
begin
  Result := nil;
  for I := FList.Count - 1 downto 0 do
    if TAbstractDIBFormat(FList[I]).CanSaveFormat(ExtractFileExt(Filename)) then
    begin
      Result := TAbstractDIBFormat(FList[I]);
      Exit;
    end;
end;

function FindDIBImporter(Filename: string): TAbstractDIBFormat;
var
  I: Integer;
begin
  Result := nil;
  for I := FList.Count - 1 downto 0 do
    if TAbstractDIBFormat(FList[I]).CanLoadFormat(ExtractFileExt(Filename)) then
    begin
      Result := TAbstractDIBFormat(FList[I]);
      Exit;
    end;
end;


{ TDIBFormat }

function TAbstractDIBFormat.CanLoadFormat(FileExt: string): Boolean;
begin
  Result := False;
end;

function TAbstractDIBFormat.CanSaveFormat(FileExt: string): Boolean;
begin
  Result := False;
end;

procedure TAbstractDIBFormat.DisplayLoadParams(var CanContinue: Boolean);
begin
  CanContinue := True;
end;

procedure TAbstractDIBFormat.DisplaySaveParams(var CanContinue: Boolean);
begin
  CanContinue := True;
end;

function TAbstractDIBFormat.GetAbout: string;
begin
  Result := '';
end;

function TAbstractDIBFormat.GetAboutText: string;
begin
  Result := '';
end;

function TAbstractDIBFormat.GetAuthor: string;
begin
  Result := '';
end;

function TAbstractDIBFormat.GetEmail: string;
begin
  Result := '';
end;

procedure TAbstractDIBFormat.GetExportFormats(const Result: TStrings);
begin
(*Import and export formats are similar to the FILTER property on both
  TSaveDialog and TOpenDialog, for example:

  Result.Add('Bitmap file|*.bmp');
  Result.Add('JPeg file|*.jpe; *.jpg; *.jpeg');*)
end;

procedure TAbstractDIBFormat.GetImportFormats(const Result: TStrings);
begin
end;

function TAbstractDIBFormat.GetURL: string;
begin
  Result := '';
end;

procedure TAbstractDIBFormat.LoadFromFile(const Filename: string;
  Dest: TAbstractSuperDIB);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(ExtractFileExt(Filename), FS, Dest);
  finally
    FS.Free;
  end;
end;

procedure TAbstractDIBFormat.LoadFromStream(FileExt: string; Stream: TStream;
  Dest: TAbstractSuperDIB);
var
  CanContinue, Handled: Boolean;
begin
  FDIB := Dest;
  Handled := False;
  CanContinue := True;
  if Assigned(OnSetLoadParams) then
    OnSetLoadParams(Self, Handled);
  if not Handled then
    DisplayLoadParams(CanContinue);
  if CanContinue then
  begin
    DIB.BeginUpdate;
    InternalLoadFromStream(FileExt, Stream);
    DIB.EndUpdate;
  end;
end;

procedure TAbstractDIBFormat.Progress(BytesRead, TotalBytes: Integer);
begin
  if Assigned(OnProgress) then OnProgress(Self, BytesRead div TotalBytes * 100); 
end;

procedure TAbstractDIBFormat.SaveToFile(const Filename: string;
  Source: TAbstractSuperDIB);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(Filename, fmCreate);
  try
    SaveToStream(ExtractFileExt(Filename), FS, Source);
  finally
    FS.Free;
  end;
end;

procedure TAbstractDIBFormat.SaveToStream(FileExt: string; Stream: TStream;
  Source: TAbstractSuperDIB);
var
  CanContinue, Handled: Boolean;
begin
  FDIB := Source;
  Handled := False;
  CanContinue := True;
  if Assigned(OnSetSaveParams) then
    OnSetSaveParams(Self, Handled);
  if not Handled then
    DisplaySaveParams(CanContinue);
  if CanContinue then InternalSaveToStream(FileExt, Stream);
end;

initialization
  if FList = nil then FList := TList.Create;

end.
