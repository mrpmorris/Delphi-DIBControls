unit DIBPaletteEditor;
{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBAnimContainerEditor.PAS, released April 04, 2001.

The Initial Developer of the Original Code is Sébastien Merle (sylane@excite.com)
Portions created by Sébastien Merle are Copyright (C) 2001 Sébastien Merle
All Rights Reserved.

Contributor(s):
None as yet


Last Modified: April 04, 2001

You may retrieve the latest version of this file from my home page
located at  http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}

interface
{$i ..\OpenSource\dfs.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  Buttons, ExtCtrls, StdCtrls, cDIBPalette;

type
  TfmDIBPaletteEditor = class(TForm)
    pnlPalette: TPanel;
    btnLoadFromBmp: TButton;
    pbPalette: TPaintBox;
    btnLoadFromRaw: TButton;
    BitBtn1: TBitBtn;
    btnCancel: TBitBtn;
    odRaw: TOpenDialog;
    odBitmap: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbPalettePaint(Sender: TObject);
    procedure btnLoadFromRawClick(Sender: TObject);
    procedure btnLoadFromBmpClick(Sender: TObject);
  private
    fLocalPalette: PLogPalette;
  public
    procedure setPalette(aPal: PLogPalette);
    procedure copyPalette(aPal: PLogPalette);

    property LocalPalette: PLogPalette read fLocalPalette;
  end;

  TDIBPaletteEditor = class(TComponentEditor)
  public
    {$IFDEF DFS_NO_DSGNINTF}
    constructor Create(AComponent: TComponent; ADesigner: IDesigner); override;
    {$ELSE}
    constructor Create(AComponent: TComponent; ADesigner: IFormDesigner); override;
    {$ENDIF}
    procedure Edit; override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

var
  fmDIBPaletteEditor: TfmDIBPaletteEditor;

implementation

{$R *.DFM}

uses Math;

{$IFDEF DFS_NO_DSGNINTF}
constructor TDIBPaletteEditor.Create(AComponent: TComponent; ADesigner: IDesigner);
  {$ELSE}
  constructor TDIBPaletteEditor.Create(AComponent: TComponent; ADesigner: IFormDesigner);
    {$ENDIF}
  begin
    inherited Create(AComponent, ADesigner);
  end;

  procedure TDIBPaletteEditor.Edit;
  begin
    ExecuteVerb(0);
  end;

  function TDIBPaletteEditor.GetVerb(Index: Integer): string;
  begin
    case Index of
      0: Result := 'Load Palette';
    end;
  end;

  function TDIBPaletteEditor.GetVerbCount: Integer;
  begin
    Result := 1;
  end;

  procedure TDIBPaletteEditor.ExecuteVerb(Index: Integer);
  begin
    case Index of
      0:
        begin
          with TfmDIBPaletteEditor.Create(Application) do
            try
              setPalette((Component as TDIBPalette).PAL);
              ShowModal;
              if ModalResult = mrOk then
              begin
                copyPalette((Component as TDIBPalette).PAL);
                (Component as TDIBPalette).UpdatePalette;
                Self.Designer.Modified;
              end;
            finally
              Release;
            end;
        end;
    end;
  end;


  procedure TfmDIBPaletteEditor.FormCreate(Sender: TObject);
  var
    lIndex: Integer;
  begin
    GetMem(fLocalPalette, 4 * 255);
    if fLocalPalette = nil then
      raise Exception.Create('Could not get enough memory for a palette.');

    fLocalPalette.palVersion := $300;
    fLocalPalette.palNumEntries := 235;
    for lIndex := 0 to 234 do 
    begin
      fLocalPalette.palPalEntry[lIndex].peRed := 0;
      fLocalPalette.palPalEntry[lIndex].peGreen := 0;
      fLocalPalette.palPalEntry[lIndex].peBlue := 0;
      fLocalPalette.palPalEntry[lIndex].peFlags := 0;
    end;
  end;

  procedure TfmDIBPaletteEditor.FormDestroy(Sender: TObject);
  begin
    FreeMem(fLocalPalette);
  end;

  procedure TfmDIBPaletteEditor.copyPalette(aPal: PLogPalette);
  begin
    if (aPal <> nil) then
      Move(fLocalPalette.palPalEntry[0], aPal.palPalEntry[0],
        4 * Min(fLocalPalette.palNumEntries, aPal.palNumEntries));
  end;

  procedure TfmDIBPaletteEditor.setPalette(aPal: PLogPalette);
  begin
    if (aPal <> nil) then
      Move(aPal.palPalEntry[0], fLocalPalette.palPalEntry[0],
        4 * Min(fLocalPalette.palNumEntries, aPal.palNumEntries));
  end;

  procedure TfmDIBPaletteEditor.pbPalettePaint(Sender: TObject);
  var
    x, y, i: Integer;
  begin
    with Sender as TPaintBox do
    begin
      i := 0;
      for y := 0 to 8 do
        for x := 0 to 23 do
        begin 
          Canvas.Brush.Color := RGB(fLocalPalette.palPalEntry[i].peRed,
            fLocalPalette.palPalEntry[i].peGreen,
            fLocalPalette.palPalEntry[i].peBlue);
          Canvas.FillRect(rect(x * 10, y * 10, (x + 1) * 10, (y + 1) * 10));
          inc(i);
        end;
      for x := 0 to 18 do
      begin
        Canvas.Brush.Color := RGB(fLocalPalette.palPalEntry[i].peRed,
          fLocalPalette.palPalEntry[i].peGreen,
          fLocalPalette.palPalEntry[i].peBlue);
        Canvas.FillRect(rect(x * 10, 90, (x + 1) * 10, 100));
        inc(i);
      end;
    end;
  end;


  procedure TfmDIBPaletteEditor.btnLoadFromRawClick(Sender: TObject);
  var
    lFile: file;
    lReadCount: Integer;
    lIndex: Integer;
    lBuffer: array [0..767] of Byte;
  begin
    if odRaw.Execute then
    begin
      assignFile(lFile, odRaw.FileName);
      reset(lFile, 1);
      BlockRead(lFile, lBuffer, 768, lReadCount);
      closeFile(lFile);
      if (lReadCount <> 768) then
        raise Exception.Create('Invalid Palette File');
      for lIndex := 0 to 234 do 
      begin
        fLocalPalette.palPalEntry[lIndex].peRed := lBuffer[3 * lIndex];
        fLocalPalette.palPalEntry[lIndex].peGreen := lBuffer[3 * lIndex + 1];
        fLocalPalette.palPalEntry[lIndex].peBlue := lBuffer[3 * lIndex + 2];
        fLocalPalette.palPalEntry[lIndex].peFlags := 0;
      end;
      pbPalette.Invalidate;
    end;
  end;

  procedure TfmDIBPaletteEditor.btnLoadFromBmpClick(Sender: TObject);
  var
    lBitmap: TBitmap;
  begin
    if odBitmap.Execute then
    begin
      lBitmap := TBitmap.Create;
      try
        lBitmap.LoadFromFile(odBitmap.FileName);
        if lBitmap.PixelFormat <> pf8bit then
          raise Exception.Create('Bitmap must be 8 bit.');
        GetPaletteEntries(lBitmap.Palette, 0, 235, fLocalPalette.palPalEntry[0]);
      finally
        lBitmap.Free;
      end;
      pbPalette.Invalidate;
    end;
  end;

  end.
