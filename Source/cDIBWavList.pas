unit cDIBWavList;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBWavList.PAS, released November 18, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To allow embedding of WAV files within an application and to enable the developer
to play those wav files.

Contributor(s):
None as yet


Last Modified: November 18, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  mmSystem;

type
  EDIBWavListError = class(Exception);
  
  TDIBWav = class(TCollectionItem)
  private
    FData: Pointer;
    FDataSize: Cardinal;
    FDisplayName: string;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure DefineProperties(Filer: TFiler); override;
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure Clear;
    procedure LoadFromFile(const Filename: string);
    procedure LoadFromStream(const Stream: TStream);
    procedure Play;
    procedure SaveToFile(const Filename: string);
    procedure SaveToStream(const Stream: TStream);
  published
    property DisplayName: string read GetDisplayName write FDisplayName;
  end;

  TDIBWavs = class(TOwnedCollection)
  private
    FOwner: TComponent;
    function GetItem(Index: Integer): TDIBWav;
    procedure SetItem(Index: Integer; const Value: TDIBWav);
  public
    constructor Create(AOwner: TComponent);

    function Add: TDIBWav;
    function Insert(Index: Integer): TDIBWav;

    property Items[Index: Integer]: TDIBWav read GetItem write SetItem; default;
  end;

  TDIBWavList = class(TComponent)
  private
    FWavs: TDIBWavs;
    function GetItem(Index: Integer): TDIBWav;
    procedure SetWavs(const Value: TDIBWavs);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Play(Index: Integer);
    procedure Stop;

    property Items[Index: Integer]: TDIBWav read GetItem; default;
  published
    property Wavs: TDIBWavs read FWavs write SetWavs;
  end;

implementation

{ TDIBWav }

procedure TDIBWav.AssignTo(Dest: TPersistent);
begin
  if Dest is TDIBWav then with TDIBWav(Dest) do
    begin
      Clear;
      DisplayName := Self.DisplayName;
      FDataSize := Self.FDataSize;
      GetMem(FData, FDataSize);
      Move(Self.FData^, FData^, FDataSize);
    end 
  else
    inherited;
end;

procedure TDIBWav.Clear;
begin
  if FDataSize = 0 then Exit;
  
  Freemem(FData);
  FData := nil;
  FDataSize := 0;
end;

constructor TDIBWav.Create(Collection: TCollection);
begin
  inherited;
  FDisplayName := inherited GetDisplayName;
end;

procedure TDIBWav.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('WavData', ReadData, WriteData, FDataSize <> 0);
end;

destructor TDIBWav.Destroy;
begin
  Clear;
  inherited;
end;

function TDIBWav.GetDisplayName: string;
begin
  Result := FDisplayName;
end;

procedure TDIBWav.LoadFromFile(const Filename: string);
var
  FS: TFileStream;
begin
  if not FileExists(Filename) then
    raise EDIBWavListError.Create('File does not exist.');

  FS := TFileStream.Create(Filename, fmOpenRead);
  try
    LoadFromStream(FS);        
  finally
    FS.Free;
  end;
end;

procedure TDIBWav.LoadFromStream(const Stream: TStream);
begin
  if Stream.Size = 0 then
    raise EDIBWavListError.Create('Invalid data format.');

  Clear;
  FDataSize := Stream.Size;
  GetMem(FData, FDataSize);
  Stream.Read(FData^, FDataSize);
end;

procedure TDIBWav.Play;
begin
  if FData = nil then Exit;
  sndPlaySound(PChar(FData), SND_MEMORY or SND_NODEFAULT or SND_ASYNC);
end;

procedure TDIBWav.ReadData(Stream: TStream);
begin
  Clear;
  Stream.Read(FDataSize, SizeOf(Cardinal));
  GetMem(FData, FDataSize);
  Stream.Read(FData^, FDataSize);
end;

procedure TDIBWav.SaveToFile(const Filename: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(Filename, fmCreate);
  try
    SaveToStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TDIBWav.SaveToStream(const Stream: TStream);
begin
  if FDataSize = 0 then
    raise EDIBWavListError.Create('No data to save.');

  Stream.Write(FData^, FDataSize);
end;

procedure TDIBWav.WriteData(Stream: TStream);
begin
  Stream.Write(FDataSize, SizeOf(Cardinal));
  Stream.Write(FData^, FDataSize);
end;

{ TDIBWavs }

function TDIBWavs.Add: TDIBWav;
begin
  Result := TDIBWav(inherited Add);
end;

constructor TDIBWavs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TDIBWav);
  FOwner := AOwner;
end;

function TDIBWavs.GetItem(Index: Integer): TDIBWav;
begin
  Result := TDIBWav(inherited GetItem(Index));
end;

function TDIBWavs.Insert(Index: Integer): TDIBWav;
begin
  Result := TDIBWav(inherited Insert(Index));
end;

procedure TDIBWavs.SetItem(Index: Integer; const Value: TDIBWav);
begin
  inherited SetItem(Index, Value);
end;

{ TDIBWavList }

constructor TDIBWavList.Create(AOwner: TComponent);
begin
  inherited;
  FWavs := TDIBWavs.Create(Self);
end;

destructor TDIBWavList.Destroy;
begin
  Stop;
  FWavs.Free;
  inherited;
end;

function TDIBWavList.GetItem(Index: Integer): TDIBWav;
begin
  Result := FWavs[Index];
end;

procedure TDIBWavList.Play(Index: Integer);
begin
  FWavs[Index].Play;
end;

procedure TDIBWavList.SetWavs(const Value: TDIBWavs);
begin
  FWavs.Assign(Value);
end;

procedure TDIBWavList.Stop;
begin
  sndPlaySound('', SND_NODEFAULT or SND_MEMORY); 
end;

end.
