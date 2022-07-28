unit DIBImageIndexEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: ImageIndexEditor.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (pete@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Property editor for ImageIndexes, visual representation of selecting an image.

Contributor(s):
None as yet


Last Modified: August 31, 2000

You may retrieve the latest version of this file at the Project JEDI home page,
located at http://www.delphi-jedi.org
or at http://www.stuckindoors.com/dib

Known Issues:
To be updated !

Date : 31 - Aug, 2000 :
By :pete@droopyeyes.com
Changes
Made TxxxxxxEditor to TxxxxxxxProperty to comply with VCL standards.
Made sure all unit names start with DIB to avoice conflicts with other people's
component packs.
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
  StdCtrls, ExtCtrls, TypInfo, cDIBImageList, cDIB, cDIBControl,
  cDIBImage, cDIBPanel;

type
  TfmImageIndexEditor = class(TForm)
    pnlControl: TPanel;
    lbNames: TListBox;
    btnOk: TButton;
    btnCancel: TButton;
    dicRender: TDIBImageContainer;
    diRender: TDIBImage;
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure lbNamesClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    DIBImageLink: TDIBImageLink;
  end;

  TDIBImageIndexProperty = class(TClassProperty)
  private
  protected
  public
    function AllEqual: Boolean; override;
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

implementation

{$R *.DFM}

{ TDIBImageIndexProperty }

function TDIBImageIndexProperty.AllEqual: Boolean;
begin
  Result := True;
end;

procedure TDIBImageIndexProperty.Edit;
begin
  if TDIBImageLink(GetOrdValue).DIBImageList = nil then 
  begin
    ShowMessage('No image list has been set.');
    Exit;
  end;

  with TfmImageIndexEditor.Create(Application) do
    try
      DIBImageLink := TDIBImageLink(GetOrdValue);
      ShowModal;
      if ModalResult = mrOk then Self.Designer.Modified;
    finally
      Release;
    end;
end;

function TDIBImageIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly, paDialog];
end;


function TDIBImageIndexProperty.GetValue: string;
begin
  Result := '(none)'; 
  if GetOrdValue = 0 then exit;
  with TDIBImageLink(GetOrdValue) do
    if DIBImageList.IsIndexValid(DIBIndex) then
      Result := DIBImageList.DIBImages[DIBIndex].DisplayName;
end;

procedure TfmImageIndexEditor.FormShow(Sender: TObject);
var
  X: Integer;
begin
  lbNames.Clear;
  lbNames.Items.Add('(None)');
  with DIBImageLink.DIBImageList do
    for X := 0 to DIBImages.Count - 1 do lbNames.Items.Add(DIBImages[X].DisplayName);

  if DIBImageLink.DIBIndex < (lbNames.Items.Count - 1) then
    lbNames.ItemIndex := DIBImageLink.DIBIndex + 1
  else
    lbNames.ItemIndex := 0;
    
  diRender.IndexMain.Assign(DIBImageLink);
end;

procedure TfmImageIndexEditor.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfmImageIndexEditor.btnOkClick(Sender: TObject);
begin
  DIBImageLink.DIBIndex := diRender.IndexMain.DIBIndex;
  ModalResult := mrOk; 
end;

procedure TfmImageIndexEditor.lbNamesClick(Sender: TObject);
begin
  diRender.IndexMain.DIBIndex := lbNames.ItemIndex - 1;
end;

end.
