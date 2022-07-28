unit DIBFeatureEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBFeatureEditor.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Property editor for DIBFeatures, allows access to the features published properties.

Contributor(s):
None as yet


Last Modified: August 31, 2000

You may retrieve the latest version of this file from my home page
located at  http://www.droopyeyes.com


Known Issues:
Needs to add the relevent unit to the USES clause of the form.


Date : Aug 31st 2000 :
By : PeteM
Changes
Made TxxxxxxEditor to TxxxxxxxProperty to comply with VCL standards.
Made sure all unit names start with DIB to avoice conflicts with other people's
component packs.

Date : Oct 28th, 2003:
By: PeteM
Changes
Removed paReadOnly from TFeatureClassProperty.GetAttributes

-----------------------------------------------------------------------------}


interface
{$i ..\OpenSource\dfs.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, cDIBFeatures,
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  TypInfo, DIBOpenTools;

type
  TFeatureClassProperty = class(TStringProperty)
  private
  protected
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  TFeatureParametersProperty = class(TClassProperty)
  private
  protected
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure Edit; override;
  end;

implementation

type
  THackPersistent = class(TPersistent);

  { TFeatureClassProperty }

function TFeatureClassProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList, paSortList];
end;

procedure TFeatureClassProperty.GetValues(Proc: TGetStrProc);
var
  X: Integer;
  Control: TPersistent;
begin
  Control := GetComponent(0);
  if not (Control is TControl) and (Control <> nil) then
    repeat
      Control := THackPersistent(Control).GetOwner;
    until (Control is TControl) or (Control = nil);

  for X := 0 to Length(cDIBFeatures.FeatureClasses) - 1 do
    with cDIBFeatures.FeatureClasses[X] do
      if CanApplyTo(Control) then Proc(ClassName);
end;

procedure TFeatureClassProperty.SetValue(const Value: string);
var
  FeatureClass: TDIBFeatureClass;
begin
  inherited;
  FeatureClass := ClassByName(Value);

  if (FeatureClass <> nil) then
    LinkUnitToClass(GetComponent(0), FeatureClass);
end;

{ TFeatureParametersProperty }

procedure TFeatureParametersProperty.Edit;
var
  TheItem: TDIBFeatureItem;
begin
  if (GetComponent(0) <> nil) and (GetComponent(0) is TDIBFeatureItem) then 
  begin
    TheItem := TDIBFeatureItem(GetComponent(0));
    if TheItem.DIBFeature <> nil then
      Designer.SelectComponent(TheItem.DIBFeature);
  end;
end;

function TFeatureParametersProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

function TFeatureParametersProperty.GetValue: string;
begin
  Result := '(FeatureParameters)';
end;

end.
