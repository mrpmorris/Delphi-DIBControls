unit cDIBStandardFilters;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBStandardFilters.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
This file contains a list of standard 3*3 filter matrices, and provides the functionality
to add additional filters in other units by using the global variable DIBStandardFilters

Contributor(s):
None as yet


Last Modified: August 28, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
To be updated !
-----------------------------------------------------------------------------}


interface

uses
  cDib, Classes, Sysutils;

type
  TDIBFilterList = class(TObject)
  private
    FNames: TStringList;
    FList: TList;
  protected
    function GetFilter(Index: Integer): TDIBFilter;
    function GetName(Index: Integer): string;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    function Add(const aCompanyName, aFilterName: string): TDIBFilter;
    function Count: Integer;
    procedure Delete(Index: Integer);
    function FilterByName(const aName: string): TDIBFilter;

    property Names[Index: Integer]: string read GetName;
    property Filters[Index: Integer]: TDIBFilter read GetFilter; default;
  end;

var
  DIBStandardFilters: TDIBFilterList;

implementation

type
  EFilterError = class(Exception);


  { TDIBFilterList }

function TDIBFilterList.Add(const aCompanyName, aFilterName: string): TDIBFilter;
begin
  if FNames.IndexOf(aCompanyName + '.' + aFilterName) >= 0 then
    raise EFilterError.Create('Filter ' + aCompanyName + '.' + aFilterName +
      ' already exists.');
  FNames.Add(aCompanyName + '.' + aFilterName);
  Result := TDIBFilter.Create;
  FList.Add(Result);
end;

function TDIBFilterList.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TDIBFilterList.Create;
begin
  inherited;
  FList := TList.Create;
  FNames := TStringList.Create;
end;

procedure TDIBFilterList.Delete(Index: Integer);
begin
  FNames.Delete(Index);
  Filters[Index].Free;
  FList.Delete(Index);
end;

destructor TDIBFilterList.Destroy;
begin
  while Count > 0 do
    Delete(0);
  inherited;
end;

function TDIBFilterList.FilterByName(const aName: string): TDIBFilter;
var
  Index: Integer;
begin
  Result := nil;
  Index := FNames.IndexOf(aName);
  if Index > -1 then Result := Filters[Index];
end;

function TDIBFilterList.GetFilter(Index: Integer): TDIBFilter;
begin
  Result := TDIBFilter(FList[Index]);
end;

function TDIBFilterList.GetName(Index: Integer): string;
begin
  Result := FNames[Index];
end;

function AddedFilter(const aCompanyName, aFilterName: string): TDIBFilter;
begin
  Result := DIBStandardFilters.Add(aCompanyName, aFilterName);
end;








initialization
  DIBStandardFilters := TDIBFilterList.Create;

  //Start of standard filters

  //Burn
  with AddedFilter('DIB', 'Burn') do 
  begin
    Data[0] := 10; 
    Data[1] := 9; 
    Data[2] := -4;
    Data[3] := 9; 
    Data[4] := 10; 
    Data[5] := -9;
    Data[6] := 4; 
    Data[7] := -9; 
    Data[8] := 10;
    Factor := 8;
  end;

  //Cold
  with AddedFilter('DIB', 'Cold') do 
  begin
    Data[0] := 2; 
    Data[1] := 2; 
    Data[2] := 2;
    Data[3] := 2; 
    Data[2] := 0; 
    Data[5] := -2;
    Data[6] := -2; 
    Data[7] := -2; 
    Data[8] := -2;
    Factor := 4;
    RedBias := 1000;
    GreenBias := 1000;
    BlueBias := 1000;
  end;

  //Forge
  with AddedFilter('DIB', 'Forge') do 
  begin
    Data[0] := 4; 
    Data[1] := 4; 
    Data[2] := 4;
    Data[3] := 4; 
    Data[4] := 0; 
    Data[5] := -4;
    Data[6] := -4; 
    Data[7] := -4; 
    Data[8] := -4;
    Factor := 4;
    RedBias := 196;
    GreenBias := 128;
    BlueBias := 128;
  end;

  //Pencil
  with AddedFilter('DIB', 'Pencil') do 
  begin
    Data[0] := -1; 
    Data[1] := -1; 
    Data[2] := -1;
    Data[3] := -1; 
    Data[4] := 8; 
    Data[5] := -1;
    Data[6] := -1; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 0;
    RedBias := 255;
    GreenBias := 255;
    BlueBias := 255;
  end;

  //Red wax
  with AddedFilter('DIB', 'Red wax') do 
  begin
    Data[0] := 4; 
    Data[1] := 4; 
    Data[2] := 4;
    Data[3] := 4; 
    Data[4] := 0; 
    Data[5] := -4;
    Data[6] := -4; 
    Data[7] := -4; 
    Data[8] := -4;
    Factor := 2;
    RedBias := 196;
  end;

  //Wallpaper
  with AddedFilter('DIB', 'Wallpaper') do 
  begin
    Data[0] := 4; 
    Data[1] := 4; 
    Data[2] := 4;
    Data[3] := 4; 
    Data[4] := 0; 
    Data[5] := -4;
    Data[6] := -4; 
    Data[7] := -4; 
    Data[8] := -4;
    Factor := 4;
    RedBias := 1000;
    GreenBias := 1000;
    BlueBias := 1000;
  end;



{
==============================================================================
All of the following filter matrices were created by, and used with the kind
permission of

New Wave Inc (France),
urbanlegend@world-of-newave.com
http://www.world-of-newave.com/
==============================================================================
}

  //Base relief
  (*long BasRelief    [] = { 6, 1, -1, 1, -4, 1, -1, 1, - 6 }; *)
  with AddedFilter('New wave', 'Base relief') do 
  begin
    Data[0] := 6; 
    Data[1] := 1; 
    Data[2] := -1;
    Data[3] := 1; 
    Data[4] := -4; 
    Data[5] := 1;
    Data[6] := -1; 
    Data[7] := 1; 
    Data[8] := -6;
    Factor := 1;
  end;

  //Rise
  (*long Rise         [] = { 2, 1, 0, 1, 1, -1, 0, -1, - 2 }; *)
  with AddedFilter('New wave', 'Rise') do 
  begin
    Data[0] := 2; 
    Data[1] := 1; 
    Data[2] := 0;
    Data[3] := 1; 
    Data[4] := 1; 
    Data[5] := -1;
    Data[6] := 0; 
    Data[7] := -1; 
    Data[8] := -2;
    Factor := 1;
  end;

  //Focused
  (*long Focused      [] = { -1, 0, -1, 0, 6, 0, -1, 0, - 1 }; *)
  with AddedFilter('New wave', 'Focused') do 
  begin
    Data[0] := 2; 
    Data[1] := 1; 
    Data[2] := 0;
    Data[3] := 1; 
    Data[4] := 1; 
    Data[5] := -1;
    Data[6] := 0; 
    Data[7] := -1; 
    Data[8] := -2;
    Factor := 2;
  end;

  //Gaussian
  (*long Gaussian     [] = { 1, 2, 1, 2, 4, 2, 1, 2, 1 }; *)
  with AddedFilter('New wave', 'Gaussian') do 
  begin
    Data[0] := 1; 
    Data[1] := 2; 
    Data[2] := 1;
    Data[3] := 2; 
    Data[4] := 4; 
    Data[5] := 2;
    Data[6] := 1; 
    Data[7] := 2; 
    Data[8] := 1;
    Factor := 16;
  end;

  //Offset
  (*long Offset       [] = { 1, 0, 0, 0, -1, 0, 0, 0, 1 }; *)
  with AddedFilter('New wave', 'Offset') do 
  begin
    Data[0] := 1; 
    Data[1] := 0; 
    Data[2] := 0;
    Data[3] := 0; 
    Data[4] := -1; 
    Data[5] := 0;
    Data[6] := 0; 
    Data[7] := 0; 
    Data[8] := 1;
    Factor := 1;
  end;


  //Enhance
  (*long Enhance      [] = { 1, 1, 0, 1, 1, -1, 0, -1, - 1 }; *)
  with AddedFilter('New wave', 'Enhance') do 
  begin
    Data[0] := 1; 
    Data[1] := 1; 
    Data[2] := 0;
    Data[3] := 1; 
    Data[4] := 1; 
    Data[5] := -1;
    Data[6] := 0; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 1;
  end;

  //Emboss
  (*long Emboss       [] = { 1, 1, 0, 1, 0, -1, 0, -1, - 1 }; *)
  with AddedFilter('New wave', 'Emboss') do 
  begin
    Data[0] := 1; 
    Data[1] := 1; 
    Data[2] := 0;
    Data[3] := 1; 
    Data[4] := 0; 
    Data[5] := -1;
    Data[6] := 0; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 1;
  end;

  //Edge grow
  (*long EdgeGrow     [] = { 10, 9, -4, 9, 10, -9, 4, -9, -10 }; *)
  with AddedFilter('New wave', 'Edge grow') do 
  begin
    Data[0] := 10; 
    Data[1] := 9; 
    Data[2] := -4;
    Data[3] := 9; 
    Data[4] := 10; 
    Data[5] := -9;
    Data[6] := 4; 
    Data[7] := -9; 
    Data[8] := 10;
    Factor := 10;
  end;

  //Drawing
  (*long Drawing      [] = { 2, 5, 2, 5,-28, 5, 2, 5, 2 }; *)
  with AddedFilter('New wave', 'Drawing') do 
  begin
    Data[0] := 2; 
    Data[1] := 5; 
    Data[2] := 2;
    Data[3] := 5; 
    Data[4] := -28; 
    Data[5] := 5;
    Data[6] := 2; 
    Data[7] := 5; 
    Data[8] := 2;
    Factor := 1;
  end;

  //Crayon
  (*long Crayon       [] = { 5, 5, -5, 10, 0,-20, 5, 5, -5 }; *)
  with AddedFilter('New wave', 'Crayon') do 
  begin
    Data[0] := 5; 
    Data[1] := 5; 
    Data[2] := -5;
    Data[3] := 10; 
    Data[4] := 0; 
    Data[5] := -20;
    Data[6] := 5; 
    Data[7] := 5; 
    Data[8] := -5;
    Factor := 1;
  end;

  //Big sharpen
  (*long BigSharpen   [] = { 1, 2, 1, 2, 4, 2, 1, 2, 1 }; *)
  with AddedFilter('New wave', 'Big sharpen') do 
  begin
    Data[0] := 1; 
    Data[1] := 2; 
    Data[2] := 1;
    Data[3] := 2; 
    Data[4] := 4; 
    Data[5] := 2;
    Data[6] := 1; 
    Data[7] := 2; 
    Data[8] := 1;
    Factor := 0;
  end;

  //Blur
  (*long Blur        [] = { 1, 1, 1, 1, 1, 1, 1, 1, 1 }; *)
  with AddedFilter('New wave', 'Blur') do 
  begin
    Data[0] := 1; 
    Data[1] := 1; 
    Data[2] := 1;
    Data[3] := 1; 
    Data[4] := 1; 
    Data[5] := 1;
    Data[6] := 1; 
    Data[7] := 1; 
    Data[8] := 1;
    Factor := 0;
  end;

  //East
  (*long East         [] = { -1, 1, 1, -1, -1, 1, -1, 1, 1 }; *)
  with AddedFilter('New wave', 'East') do 
  begin
    Data[0] := -1; 
    Data[1] := 1; 
    Data[2] := 1;
    Data[3] := -1; 
    Data[4] := -1; 
    Data[5] := 1;
    Data[6] := -1; 
    Data[7] := 1; 
    Data[8] := 1;
    Factor := 0;
  end;

  //Horizontal
  (*long Horizontal   [] = { -1, -1, -1, 2, 3, 2, -1, -1, -1 }; *)
  with AddedFilter('New wave', 'Horizontal') do 
  begin
    Data[0] := -1; 
    Data[1] := -1; 
    Data[2] := -1;
    Data[3] := 2; 
    Data[4] := 3; 
    Data[5] := 2;
    Data[6] := -1; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 0;
  end;

  //Laplacian
  (*long Laplacian    [] = { -1, -1, -1, -1, 8, -1, -1, -1, -1 }; *)
  with AddedFilter('New wave', 'Laplacian') do 
  begin
    Data[0] := -1; 
    Data[1] := -1; 
    Data[2] := -1;
    Data[3] := -1; 
    Data[4] := 8; 
    Data[5] := -1;
    Data[6] := -1; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 0;
  end;

  //Left right
  (*long LR           [] = { -1, -1, 2, -1, 3, -1, 2, -1, -1 }; *)
  with AddedFilter('New wave', 'Left right') do 
  begin
    Data[0] := -1; 
    Data[1] := -1; 
    Data[2] := 2;
    Data[3] := -1; 
    Data[4] := 3; 
    Data[5] := -1;
    Data[6] := 2; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 0;
  end;

  //North
  (*long North        [] = { 1, 1, 1, 1, -1, 1, -1, -1, -1 }; *)
  with AddedFilter('New wave', 'North') do 
  begin
    Data[0] := 1; 
    Data[1] := 1; 
    Data[2] := 1;
    Data[3] := 1; 
    Data[4] := -1; 
    Data[5] := 1;
    Data[6] := -1; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 0;
  end;

  //North East
  (*long NorthEast    [] = { 1, 1, 1, -1, -1, 1, -1, -1, 1 }; *)
  with AddedFilter('New wave', 'North East') do 
  begin
    Data[0] := 1; 
    Data[1] := 1; 
    Data[2] := 1;
    Data[3] := 1; 
    Data[4] := -1; 
    Data[5] := -1;
    Data[6] := -1; 
    Data[7] := -1; 
    Data[8] := 1;
    Factor := 0;
  end;

  //North West
  (*long NorthWest    [] = { 1, 1, 1, 1, -1, -1, 1, -1, -1 }; *)
  with AddedFilter('New wave', 'North West') do 
  begin
    Data[0] := 1; 
    Data[1] := 1; 
    Data[2] := 1;
    Data[3] := 1; 
    Data[4] := -1; 
    Data[5] := -1;
    Data[6] := 1; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 0;
  end;

  //Right left
  (*long RL          [] = { 2, -1, -1, -1, 3, -1, -1, -1, 2 }; *)
  with AddedFilter('New wave', 'Right left') do 
  begin
    Data[0] := 2; 
    Data[1] := -1; 
    Data[2] := -1;
    Data[3] := -1; 
    Data[4] := 3; 
    Data[5] := -1;
    Data[6] := -1; 
    Data[7] := -1; 
    Data[8] := 2;
    Factor := 0;
  end;

  //Sharpen medium
  (*long SharpenMedium[] = { -1, -1, -1, -1, 9, -1 -1, -1, -1 }; *)
  with AddedFilter('New wave', 'Sharpen medium') do 
  begin
    Data[0] := -1; 
    Data[1] := -1; 
    Data[2] := -1;
    Data[3] := -1; 
    Data[4] := 9; 
    Data[5] := -1;
    Data[6] := -1; 
    Data[7] := -1; 
    Data[8] := -1;
    Factor := 0;
  end;

  //Sharpen small
  (*long SharpenSmall [] = { 0, -1, 0, -1, 5, -1, 0, -1, 0 }; *)
  with AddedFilter('New wave', 'Sharpen small') do 
  begin
    Data[0] := 0; 
    Data[1] := -1; 
    Data[2] := 0;
    Data[3] := -1; 
    Data[4] := 5; 
    Data[5] := -1;
    Data[6] := 0; 
    Data[7] := -1; 
    Data[8] := 0;
    Factor := 0;
  end;

  //Sharpen huge
  (*long SharpenHuge [] = { -1, -2, -1, -2, 16, -2, -1, -2, -1 }; *)
  with AddedFilter('New wave', 'Sharpen huge') do 
  begin
    Data[0] := -1; 
    Data[1] := -2; 
    Data[2] := -1;
    Data[3] := -2; 
    Data[4] := 16; 
    Data[5] := -2;
    Data[6] := -1; 
    Data[7] := -2; 
    Data[8] := -1;
    Factor := 0;
  end;

  //South
  (*long South        [] = { -1, -1, -1, 1, -1, 1, 1, 1, 1 }; *)
  with AddedFilter('New wave', 'South') do 
  begin
    Data[0] := -1; 
    Data[1] := -1; 
    Data[2] := -1;
    Data[3] := 1; 
    Data[4] := -1; 
    Data[5] := -1;
    Data[6] := 1; 
    Data[7] := 1; 
    Data[8] := 1;
    Factor := 0;
  end;

  //South East
  (*long SouthEast    [] = { -1, -1, 1, -1, -1, 1, 1, 1, 1 }; *)
  with AddedFilter('New wave', 'South East') do 
  begin
    Data[0] := -1; 
    Data[1] := -1; 
    Data[2] := 1;
    Data[3] := -1; 
    Data[4] := -1; 
    Data[5] := 1;
    Data[6] := 1; 
    Data[7] := 1; 
    Data[8] := 1;
    Factor := 0;
  end;

  //South West
  (*long SouthWest    [] = { 1, -1, -1, 1, -1, -1, 1, 1, 1 }; *)
  with AddedFilter('New wave', 'South West') do 
  begin
    Data[0] := 1; 
    Data[1] := -1; 
    Data[2] := -1;
    Data[3] := 1; 
    Data[4] := -1; 
    Data[5] := -1;
    Data[6] := 1; 
    Data[7] := 1; 
    Data[8] := 1;
    Factor := 0;
  end;

  //Speckle
  (*long Speckle      [] = { 1, -2, 1, -2, 5, -2, 1, -2, 1 }; *)
  with AddedFilter('New wave', 'Speckle') do 
  begin
    Data[0] := 1; 
    Data[1] := -2; 
    Data[2] := 1;
    Data[3] := -2; 
    Data[4] := 5; 
    Data[5] := -2;
    Data[6] := 1; 
    Data[7] := -2; 
    Data[8] := 1;
    Factor := 0;
  end;

  //Vertical
  (*long Vertical     [] = { -1, 2, -1, -1, 3, -1, -1, 2, -1 }; *)
  with AddedFilter('New wave', 'Vertical') do 
  begin
    Data[0] := -1; 
    Data[1] := 2; 
    Data[2] := -1;
    Data[3] := -1; 
    Data[4] := 3; 
    Data[5] := -1;
    Data[6] := -1; 
    Data[7] := 2; 
    Data[8] := -1;
    Factor := 0;
  end;

  //West
  (*long West         [] = { 1, 1, -1, 1, -1, -1, 1, 1, 1 }; *)
  with AddedFilter('New wave', 'West') do 
  begin
    Data[0] := 1; 
    Data[1] := 1; 
    Data[2] := -1;
    Data[3] := 1; 
    Data[4] := -1; 
    Data[5] := -1;
    Data[6] := 1; 
    Data[7] := 1; 
    Data[8] := 1;
    Factor := 0;
  end;

  //Woodcut
  (*long WoodCut      [] = { -2, 0, 0, 0, 5, 0, 0, 0, -2 }; *)
  with AddedFilter('New wave', 'Woodcut') do 
  begin
    Data[0] := -2; 
    Data[1] := 0; 
    Data[2] := 0;
    Data[3] := 0; 
    Data[4] := 5; 
    Data[5] := 0;
    Data[6] := 0; 
    Data[7] := 0; 
    Data[8] := -2;
    Factor := 0;
  end;





finalization
  DIBStandardFilters.Free;
end.
