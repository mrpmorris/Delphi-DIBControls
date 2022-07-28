unit DIBPNGFormat;

interface
uses
  Windows, Classes, cDIBCompressor, cDIB, cDIBFormat;

{$I dfs.inc}

{$IFNDEF DFS_COMPILER_2009}
type
  TDIBPNGFormat = class(TAbstractDIBFormat)
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
{$ENDIF}


implementation
{$IFNDEF DFS_COMPILER_2009}
uses
  SysUtils, ComObj, Graphics, PngImage;


type
  TAccessDIB = class(TAbstractSuperDIB);

{ TDIBPNGFormat }

function TDIBPNGFormat.CanLoadFormat(FileExt: string): Boolean;
begin
  Result := CompareText(FileExt, '.PNG') = 0;
end;

function TDIBPNGFormat.CanSaveFormat(FileExt: string): Boolean;
begin
  Result := CompareText(FileExt, '.PNG') = 0;
end;

function TDIBPNGFormat.GetDisplayName: string;
begin
  Result := 'PNG';
end;

procedure TDIBPNGFormat.GetExportFormats(const Result: TStrings);
begin
  Result.Add('PNG file (*.png)|*.png');
end;

procedure TDIBPNGFormat.GetImportFormats(const Result: TStrings);
begin
  Result.Add('PNG file (*.png)|*.png');
end;

procedure TDIBPNGFormat.InternalLoadFromStream(FileExt: string; Stream: TStream);
var
  AlphaData: Pointer;
  TempAlphaData: Pointer;
  PNGObject: TPngObject;
  TempDIB: TWinDIB;
begin
  TempAlphaData := nil;
  PNGObject := TPNGObject.Create;
  TempDIB := TWinDIB.Create;
  try
    PNGObject.LoadFromStream(Stream);
    TempDIB.ReSize(PNGObject.Width, PNGObject.Height);
    DIB.ReSize(PNGObject.Width, PNGObject.Height);

    AlphaData := PNGObject.AlphaScanline[0];
    if (AlphaData <> nil) then
    begin
      GetMem(TempAlphaData, PNGObject.Width * PNGObject.Height);
      VerticalFlipData(AlphaData, TempAlphaData, PNGObject.Width, PNGObject.Height);
    end;

    PNGObject.RemoveTransparency;
    TempDIB.SetMaskedValues(255);
    PNGObject.Draw(TempDIB.Canvas, Rect(0, 0, TempDIB.Width, TempDIB.Height));

    DIB.CopyPicture(TempDIB);
    if (TempAlphaData = nil) then
      TAccessDIB(DIB).Masked := False
    else
      DIB.ImportMask(TempAlphaData, PNGObject.Width, PNGObject.Height);
    TAccessDIB(DIB).Masked := True;
  finally
    if (TempAlphaData <> nil) then
      FreeMem(TempAlphaData);
    TempDIB.Free;
    PNGObject.Free;
  end;
end;

procedure TDIBPNGFormat.InternalSaveToStream(FileExt: string; Stream: TStream);
var
  PNGObject: TPNGObject;
  WinDIB: TWinDIB;
  BMP: TBitmap;
  TempAlphaData: Pointer;
begin
  BMP := TBitmap.Create;
  PNGObject := TPNGObject.Create;
  WinDIB := TWinDIB.Create;
  try
    //Set the size of the BMP
    BMP.PixelFormat := pf32bit;
    BMP.Width := DIB.Width;
    BMP.Height := DIB.Height;
    //Resize the WinDIB
    WinDIB.ReSize(DIB.Width, DIB.Height);
    //Copy the DIB to the WinDIB
    WinDIB.CopyPicture(DIB);
    //Copy the WinDIB to the BMP
    BitBlt(BMP.Canvas.Handle, 0, 0, DIB.Width, DIB.Height, WinDIB.Canvas.Handle, 0, 0, SRCCOPY);
    //Assign the PNG object
    PNGObject.Assign(BMP);
    //If masked then create an alpha layer
    if TAccessDIB(DIB).Masked then
    begin
      PNGObject.CreateAlpha;
      GetMem(TempAlphaData, DIB.Width * DIB.Height);
      try
        DIB.ExportMask(TempAlphaData);
        VerticalFlipData(TempAlphaData, PNGObject.AlphaScanline[0], DIB.Width, DIB.Height);
      finally
        FreeMem(TempAlphaData);
      end;
    end;
    PNGObject.SaveToStream(Stream);
  finally
    BMP.Free;
    WinDIB.Free;
    PNGObject.Free;
  end;
end;

initialization
  RegisterDIBFormat(TDIBPNGFormat.Create);

{$ENDIF}

end.
