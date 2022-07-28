unit DIBWavEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBWavEditor.PAS, released September 04, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To allow selection of compressors at design time.

Contributor(s):
None as yet


Last Modified: September 04, 2000

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
  cDIBWavList, StdCtrls, jpeg, ExtCtrls, mmSystem, Buttons;

type
  TDIBWavProperty = class(TPropertyEditor)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
  end;

  TfmDIBWavEditor = class(TForm)
    Image1: TImage;
    btnLoad: TButton;
    btnClear: TButton;
    btnClose: TButton;
    odWav: TOpenDialog;
    sbPlay: TSpeedButton;
    sbStop: TSpeedButton;
    procedure btnLoadClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure sbPlayClick(Sender: TObject);
    procedure sbStopClick(Sender: TObject);
  private
    FWav: TDIBWav;
    {$IFDEF DFS_NO_DSGNINTF}
    FDesigner: IDesigner;
    {$ELSE}
    FDesigner: IFormDesigner;
    {$ENDIF}

  public
    procedure Edit(DIBWav: TDIBWav);
  end;

implementation

{$R *.DFM}

{ TDIBWavProperty }

procedure TDIBWavProperty.Edit;
begin
  with TfmDIBWavEditor.Create(Application) do
    try
      FDesigner := Self.Designer;
      Edit(TDIBWav(GetComponent(0)));
    finally
      Release;
    end;
end;

function TDIBWavProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;



function TDIBWavProperty.GetValue: string;
begin
  Result := TDIBWav(GetComponent(0)).DisplayName;
end;

procedure TDIBWavProperty.SetValue(const Value: string);
begin
  TDIBWav(GetComponent(0)).DisplayName := Value;
  Designer.Modified;
end;

{ TfmDIBWavEditor }

procedure TfmDIBWavEditor.Edit(DIBWav: TDIBWav);
begin
  FWav := DIBWav;
  ShowModal;
end;

procedure TfmDIBWavEditor.btnLoadClick(Sender: TObject);
begin
  if odWav.Execute then
    if FileExists(odWav.Filename) then
    begin
      FWav.LoadFromFile(odWav.Filename);
      FDesigner.Modified;
    end;
end;

procedure TfmDIBWavEditor.btnClearClick(Sender: TObject);
begin
  if MessageDlg('Are you sure ?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FWav.Clear;
    FDesigner.Modified;
  end;
end;

procedure TfmDIBWavEditor.sbPlayClick(Sender: TObject);
begin
  FWav.Play;
end;

procedure TfmDIBWavEditor.sbStopClick(Sender: TObject);
begin
  sndPlaySound('', SND_NODEFAULT or SND_MEMORY);
end;

end.
