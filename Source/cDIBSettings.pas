unit cDIBSettings;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBSettings.PAS, released September 04, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To allow design-time interaction to global variables hidden within forms.
The first example of this being the ability to set the DIBCompressor.

Contributor(s):
None as yet


Last Modified: September 04, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, cDIBCompressor;

type
  TDIBSettings = class(TComponent)
  private
    { Private declarations }
    procedure SetDIBCompressor(const Value: string);
    function GetDIBCompressor: string;
  protected
    { Protected declarations }
  public
    { Public declarations }
    destructor Destroy; override;
  published
    { Published declarations }
    property DIBCompressor: string read GetDIBCompressor write SetDIBCompressor;
  end;

implementation

uses
  ComOBJ;


{ TDIBSettings }

destructor TDIBSettings.Destroy;
begin
  DefaultCompressor := nil;
  inherited;
end;

function TDIBSettings.GetDIBCompressor: string;
begin
  if DefaultCompressor = nil then
    Result := ''
  else
    Result := GUIDToString(DefaultCompressor.GetGuid);
end;

procedure TDIBSettings.SetDIBCompressor(const Value: string);
begin
  DefaultCompressor := FindCompressor(Value);
end;

end.
