unit DIBCompressorEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBCompressorEditor.PAS, released September 04, 2000.

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
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, cDIBCompressor,
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  cDIBSettings, StdCtrls, ExtCtrls, DIBOpenTools;

type
  TDIBCompressorProperty = class(TStringProperty)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;


  TfmSelectCompressor = class(TForm)
    lbCompressors: TListBox;
    Panel1: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    Panel2: TPanel;
    Label1: TLabel;
    memAbout: TMemo;
    Label2: TLabel;
    lblEmail: TLabel;
    Homepage: TLabel;
    lblHomepage: TLabel;
    lblAuthor: TLabel;
    procedure lbCompressorsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  COMObj;

{$R *.DFM}

{ TDIBCompressorProperty }

procedure TDIBCompressorProperty.Edit;
var
  OrigCompressor: TAbstractDIBCompressor;
  I: Integer;
begin
  OrigCompressor := DefaultCompressor;
  with TfmSelectCompressor.Create(Application) do
    try
      lbCompressors.Clear;
      lbCompressors.Items.Add('(none)');
      lbCompressors.ItemIndex := 0;
      for I := 0 to CompressorCount - 1 do 
      begin
        lbCompressors.Items.Add(Compressor(I).GetDisplayName);
        if Compressor(I) = DefaultCompressor then
          lbCompressors.ItemIndex := I + 1;
      end;
      lbCompressorsClick(nil);

      ShowModal;
      if ModalResult = mrOk then 
      begin
        if DefaultCompressor = nil then
          TDIBSettings(GetComponent(0)).DIBCompressor := ''
        else 
        begin
          TDIBSettings(GetComponent(0)).DIBCompressor :=
            GUIDToString(DefaultCompressor.GetGUID);
          LinkUnitToClass(GetComponent(0), DefaultCompressor.ClassType);
        end;
        
        Self.Designer.Modified;
      end 
      else
        DefaultCompressor := OrigCompressor;
    finally
      Free;
    end;
end;

function TDIBCompressorProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

function TDIBCompressorProperty.GetValue: string;
begin
  if DefaultCompressor <> nil then
    Result := DefaultCompressor.GetDisplayName
  else
    Result := '(none)';
end;


procedure TfmSelectCompressor.lbCompressorsClick(Sender: TObject);
begin
  if lbCompressors.ItemIndex <= 0 then 
  begin
    DefaultCompressor := nil;
    lblAuthor.Caption := '';
    lblEmail.Caption := '';
    lblHomepage.Caption := '';
    memAbout.Lines.Text := '';
  end 
  else 
  begin
    DefaultCompressor := Compressor(lbCompressors.ItemIndex - 1);
    with DefaultCompressor do 
    begin
      lblAuthor.Caption := GetAuthor;
      lblEmail.Caption := GetEmail;
      lblHomepage.Caption := GetURL;
      memAbout.Lines.Text := GetAboutText;
    end;
  end;
end;

end.
