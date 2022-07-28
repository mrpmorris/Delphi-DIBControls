unit DIBControlEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBControlEditor.PAS, released Sept 01, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To allow importing / exporting of templates at designtime.

Contributor(s):
None as yet


Last Modified: September 01, 2000

You may retrieve the latest version of this file from my home page
located at  http://www.droopyeyes.com


Known Issues:
To be updated !
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
  TYPInfo, cDIBControl;

type
  TDIBControlEditor = class(TComponentEditor)
  private
    { Private declarations }
    procedure LoadTemplate;
    procedure SaveTemplate;
  protected
    { Protected declarations }
  public
    { Public declarations }
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

implementation

{ TDIBControlEditor }

procedure TDIBControlEditor.ExecuteVerb(Index: Integer);
var
  BaseCount: Integer;
begin
  BaseCount := inherited GetVerbCount;
  if Index = BaseCount then
    LoadTemplate
  else if Index = BaseCount + 1 then
    SaveTemplate
  else
    inherited ExecuteVerb(Index);
end;

function TDIBControlEditor.GetVerb(Index: Integer): string;
var
  BaseCount: Integer;
begin
  BaseCount := inherited GetVerbCount;
  if Index = BaseCount then
    Result := '&Load template'
  else if Index = BaseCount + 1 then
    Result := '&Save template'
  else
    Result := inherited GetVerb(Index);
end;

function TDIBControlEditor.GetVerbCount: Integer;
begin
  Result := inherited GetVerbCount + 2;
end;

procedure TDIBControlEditor.LoadTemplate;
begin
  with TOpenDialog.Create(Application) do
    try
      DefaultExt := '*.dct';
      Filter := 'DIB Component Templates (*.dct)|*.DCT|Any File (*.*)|*.*';
      if Execute then
        TCustomDIBControl(Component).LoadTemplateFromFile(Filename);
      Designer.Modified;
    finally
      Free;
    end;
end;

procedure TDIBControlEditor.SaveTemplate;
begin
  with TSaveDialog.Create(Application) do
    try
      DefaultExt := '*.dct';
      Filter := 'DIB Component Templates (*.dct)|*.DCT|Any File (*.*)|*.*';
      if Execute then
        TCustomDIBControl(Component).SaveTemplateToFile(Filename);
    finally
      Free;
    end;
end;

end.
