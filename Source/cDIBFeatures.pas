unit cDIBFeatures;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBFeatures.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Allows component subclassing at design-time.  You can apply various descendents of
TDIBFeature to any DIB component, allowing it to move at runtime, highlight when the
mouse enters, or any other custom functionality a person designs.
New features are added by calling the RegisterDIBFeature command.

Contributor(s):
None as yet


Last Modified: August 28, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
To be updated !
-----------------------------------------------------------------------------}


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIB;

type
  TAllowFeatureEvent = procedure(Sender: TObject; Control: TControl; var Allow: Boolean) of
  object;
  TMouseButtons = set of TMouseButton;

  TControlItem = class(TCollectionItem)
  private
    FControl: TControl;
    procedure SetControl(const Value: TControl);
  protected
  public
    procedure AssignTo(Dest: TPersistent); override;
    function GetDisplayName: string; override;
  published
    property Control: TControl read FControl write SetControl;
  end;

  TControlList = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TControlItem;
    procedure SetItem(Index: Integer; Value: TControlItem);
  protected
  public
    constructor Create(AOwner: TComponent);

    function Add: TControlItem;
    property Items[Index: Integer]: TControlItem read GetItem write SetItem; default;
  published
  end;

  TDIBFeature = class(TComponent)
  private
    FControl: TControl;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    property Control: TControl read FControl;
  public
    class function CanApplyTo(aComponent: TPersistent): Boolean; virtual;
    class function GetDisplayName: string; virtual;
    function GetOwner: TPersistent; override;
    procedure WndProc(var Message: TMessage; var Handled: Boolean); virtual; abstract;
  published
  end;

  TDIBFeatureItem = class(TCollectionItem)
  private
    FSubPropertiesSize: Integer;
    FSubProperties: Pointer;
    FFeatureParameters: string;
    FDIBFeature: TDIBFeature;
    FEnabled: Boolean;
    FFeatureClassName: string;
    procedure ReadParams(S: TStream);
    procedure SetFeatureClassName(const Value: string);
    procedure WriteParams(S: TStream);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure Loaded; virtual;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    function GetDisplayName: string; override;
    procedure WndProc(var Message: TMessage; var Handled: Boolean); virtual;

    property DIBFeature: TDIBFeature read FDIBFeature write FDIBFeature;

  published
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property FeatureClassName: string read FFeatureClassName write SetFeatureClassName;
    property FeatureParameters: string read FFeatureParameters write FFeatureParameters;
  end;

  TDIBFeatures = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TDIBFeatureItem;
    procedure SetItem(Index: Integer; Value: TDIBFeatureItem);
  protected
    procedure Loaded; virtual;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TComponent);

    function Add: TDIBFeatureItem;
    procedure WndProc(var Message: TMessage; var Handled: Boolean); virtual;

    property Items[Index: Integer]: TDIBFeatureItem read GetItem write SetItem; default;
  published
  end;

  TDIBFeatureClass = class of TDIBFeature;

  TMoveableDIB = class(TDIBFeature)
  private
    FMoving: Boolean;
    FOrigX,
    FOrigY,
    FX,
    FY: Integer;
    FAllowVertical: Boolean;
    FAllowHorizontal: Boolean;
    FBorderSize,
    FSnapSize: Byte;
    FMouseButtons: TMouseButtons;
    FMouseButton: TMouseButton;

    procedure DoKeyDown(Message: TWMKey);
    procedure DoMouseDown(Message: TMessage);
    procedure DoMouseUp;
    procedure DoMouseMove(Message: TMessage);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    class function GetDisplayName: string; override;
    procedure WndProc(var Message: TMessage; var Handled: Boolean); override;

  published
    property AllowHorizontal: Boolean read FAllowHorizontal write FAllowHorizontal;
    property AllowVertical: Boolean read FAllowVertical write FAllowVertical;
    property BorderSize: Byte read FBorderSize write FBorderSize;
    property MouseButtons: TMouseButtons read FMouseButtons write FMouseButtons;
    property SnapSize: Byte read FSnapSize write FSnapSize;
  end;

  THighlightDIB = class(TDIBFeature)
  private
    FOrigOpacity: Byte;
    FHighlightOpacity: Byte;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    class function CanApplyTo(aComponent: TPersistent): Boolean; override;
    class function GetDisplayName: string; override;
    procedure WndProc(var Message: TMessage; var Handled: Boolean); override;
  published
    property HighlightOpacity: Byte read FHighlightOpacity write FHighlightOpacity;
  end;

  TShapeableDIB = class(TDIBFeature)
  private
    FRegion: HRGN;
    FTransparentColor: TColor;
    FTransparentMode: TTransparentMode;
    FMaskLevel: Byte;
    FControlInvalidateTime: DWORD;
    procedure CalculateRegion;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function CanApplyTo(aComponent: TPersistent): Boolean; override;
    class function GetDisplayName: string; override;
    procedure WndProc(var Message: TMessage; var Handled: Boolean); override;
  published
    property TransparentColor: TColor read FTransparentColor write FTransparentColor;
    property TransparentMode: TTransparentMode read FTransparentMode write FTransparentMode;
    property MaskLevel: Byte read FMaskLevel write FMaskLevel;
  end;

function ClassByName(Value: string): TDIBFeatureClass;
procedure RegisterDIBFeature(aClass: TDIBFeatureClass);
var
  FeatureClasses: array of TDIBFeatureClass;

implementation

uses
  CDIBControl;

type
  EFeatureError = class(Exception);
  THackDIBControl = class(TCustomDIBControl);

function ClassByName(Value: string): TDIBFeatureClass;
var
  X: Integer;
begin
  Result := nil;
  for X := Length(FeatureClasses) - 1 downto 0 do 
  begin
    if CompareText(FeatureClasses[X].ClassName, Value) = 0 then 
    begin
      Result := FeatureClasses[X];
      Break;
    end;
  end;
end;

procedure RegisterDIBFeature(aClass: TDIBFeatureClass);
begin
  Classes.RegisterClass(aClass);
  Setlength(FeatureClasses, Length(FeatureClasses) + 1);
  FeatureClasses[Length(FeatureClasses) - 1] := aClass;
end;

{ TControlList }

function TControlList.Add: TControlItem;
begin
  Result := TControlItem(inherited Add);
end;

constructor TControlList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TControlItem);
end;



function TControlList.GetItem(Index: Integer): TControlItem;
begin
  Result := TControlItem(inherited GetItem(Index));
end;

procedure TControlList.SetItem(Index: Integer; Value: TControlItem);
begin
  inherited SetItem(Index, Value);
end;

{ TDIBFeatureItem }
constructor TDIBFeatureItem.Create(Collection: TCollection);
begin
  inherited;
  FEnabled := True;
  FSubProperties := nil;
end;

procedure TDIBFeatureItem.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('DIBFeatureParameters', ReadParams, WriteParams,
  (FDIBFeature <> nil));
end;

destructor TDIBFeatureItem.Destroy;
begin
  if FSubProperties <> nil then Freemem(FSubProperties);
  if FDIBFeature <> nil then FDIBFeature.Free;
  inherited;
end;


function TDIBFeatureItem.GetDisplayName: string;
begin
  if FDIBFeature = nil then
    Result := 'DIB feature'
  else
    Result := FDIBFeature.GetDisplayName;
end;

procedure TDIBFeatureItem.ReadParams(S: TStream);
begin
  if S.Size > 0 then 
  begin
    FSubPropertiesSize := S.Size;
    Getmem(FSubProperties, S.Size);
    S.Read(FSubProperties^, S.Size);
  end 
  else
    FSubPropertiesSize := 0;
end;
(*
var
  Reader            : TReader;
begin
  Reader := TReader.Create(S, 4096);
  try
    Reader.IgnoreChildren := False;
    //This will create our DIBFeature item
    FeatureClassName := Reader.ReadString;
    Reader.ReadRootComponent(FDIBFeature);
  finally
    Reader.Free;
  end;
end;*)

procedure TDIBFeatureItem.Loaded;
var
  MS: TMemoryStream;
  Reader: TReader;
begin
  inherited;
  if FSubProperties <> nil then 
  begin
    MS := TMemoryStream.Create;
    try
      MS.SetSize(FSubPropertiesSize);
      move(FSubProperties^, MS.Memory^, MS.Size);

      Reader := TReader.Create(MS, 4096);
      try
        //This will create our DIBFeature item
        Reader.IgnoreChildren := False;
        FeatureClassName := Reader.ReadString;
        Reader.ReadRootComponent(FDIBFeature);
      finally
        Reader.Free;
      end;
    finally
      MS.Free;
    end;
  end;
end;


procedure TDIBFeatureItem.SetFeatureClassName(const Value: string);
var
  TheClass: TDIBFeatureClass;
begin
  TheClass := nil;
  if Value <> '' then 
  begin
    TheClass := ClassByName(Value);
    if TheClass = nil then
      raise eFeatureError.Create(Value + ' has not been registered');
  end;

  if FDIBFeature <> nil then 
  begin
    FDIBFeature.Free;
    FDIBFeature := nil;
  end;
  FFeatureClassName := Value;
  if TheClass <> nil then 
  begin
    FDIBFeature := TheClass.Create(TControl(TDIBFeatures(Collection).GetOwner));
    FDIBFeature.FControl := TControl(TDIBFeatures(Collection).GetOwner);
  end;
end;

procedure TDIBFeatureItem.WndProc(var Message: TMessage;
  var Handled: Boolean);
begin
  if Enabled then
    if FDIBFeature <> nil then
      FDIBFeature.WndProc(Message, Handled);
end;

procedure TDIBFeatureItem.WriteParams(S: TStream);
var
  Writer: TWriter;
begin
  Writer := TWriter.Create(S, 4096);
  try
    Writer.IgnoreChildren := False;
    Writer.WriteString(FFeatureClassName);
    Writer.WriteRootComponent(FDIBFeature);
  finally
    Writer.Free;
  end;
end;

procedure TDIBFeatureItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TDIBFeatureItem then
    with TDIBFeatureItem(Dest) do
    begin
      Enabled := Self.Enabled;
      FeatureClassName := Self.FeatureClassName;
      FDIBFeature.Assign(Self.FDIBFeature);
    end
  else
    inherited;
end;

{ TDIBFeatures }

function TDIBFeatures.Add: TDIBFeatureItem;
begin
  Result := TDIBFeatureItem(inherited Add);
end;

constructor TDIBFeatures.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TDIBFeatureItem);
end;

function TDIBFeatures.GetItem(Index: Integer): TDIBFeatureItem;
begin
  Result := TDIBFeatureItem(inherited GetItem(Index));
end;

procedure TDIBFeatures.Loaded;
var
  X: Integer;
begin
  for X := 0 to Count - 1 do Items[X].Loaded;
end;

procedure TDIBFeatures.SetItem(Index: Integer; Value: TDIBFeatureItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDIBFeatures.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
end;

procedure TDIBFeatures.WndProc(var Message: TMessage;
  var Handled: Boolean);
var
  X: Integer;
begin
  for X := 0 to Count - 1 do 
  begin
    with Items[X] do
      WndProc(Message, Handled);
    if Handled then break;
  end;
end;

{ TMoveableDIB }

procedure TMoveableDIB.AssignTo(Dest: TPersistent);
begin
  if Dest is TMoveableDIB then
    with TMoveableDIB(Dest) do
    begin
      AllowHorizontal := Self.AllowHorizontal;
      AllowVertical := Self.AllowVertical;
      BorderSize := Self.BorderSize;
      MouseButtons := Self.MouseButtons;
      SnapSize := Self.SnapSize;
    end;
  inherited;
end;

constructor TMoveableDIB.Create(AOwner: TComponent);
begin
  inherited;
  AllowVertical := True;
  AllowHorizontal := True;
  SnapSize := 1;
  MouseButtons := [mbLeft];
end;

procedure TMoveableDIB.DoKeyDown(Message: TWMKey);
begin
  with Message, Control do 
  begin
    case CharCode of
      VK_UP: if AllowVertical then Top := Top - SnapSize;
      VK_DOWN: if AllowVertical then Top := Top + SnapSize;
      VK_Left: if AllowHorizontal then Left := Left - SnapSize;
      VK_RIGHT: if AllowHorizontal then Left := Left + SnapSize;
    end;
  end;
end;

procedure TMoveableDIB.DoMouseDown(Message: TMessage);
begin
  if Control = nil then exit;
  with TWMMouse(Message) do 
  begin
    if ((FX >= BorderSize) or
      (FX <= Control.Width - BorderSize)) and
      ((FY >= BorderSize) or
      (FY <= Control.Height - BorderSize)) then
    begin
      FMoving := True;
      FX := XPos;
      FY := YPos;
    end;
  end;
  with Control do 
  begin
    FOrigX := Left;
    FOrigY := Top;
  end;
end;

procedure TMoveableDIB.DoMouseMove(Message: TMessage);
var
  DX, DY: Integer;
begin
  if FMoving then with TWMMouse(Message) do 
    begin
      if AllowHorizontal then
        DX := (XPos - FX)
      else
        DX := 0;
      if AllowVertical then
        DY := (YPos - FY)
      else
        DY := 0;
      if SnapSize > 1 then 
      begin
        DX := DX div SnapSize * SnapSize;
        DY := DY div SnapSize * SnapSize;
      end;
      if Control <> nil then with Control do 
        begin
          SetBounds(Left + DX, Top + DY, Width, Height);
        end;
    end;
end;

procedure TMoveableDIB.DoMouseUp;
begin
  FMoving := False;
end;

class function TMoveableDIB.GetDisplayName: string;
begin
  Result := 'Moveable DIB';
end;

procedure TMoveableDIB.WndProc(var Message: TMessage;
  var Handled: Boolean);
begin
  if Message.Msg = WM_KeyDown then DoKeyDown(TWMKey(Message));
  if FMoving then
    case Message.Msg of
      WM_MouseMove: DoMouseMove(Message);
      WM_RButtonUp: if FMouseButton = mbRight then DoMouseUp;
      WM_LButtonUp: if FMouseButton = mbLeft then DoMouseUp;
      WM_MButtonUp: if FMouseButton = mbMiddle then DoMouseUp;
    end
  else if (Message.Msg = WM_LButtonDown) or (Message.Msg = WM_MButtonDown) or
    (Message.Msg = WM_RButtonDown) then
  begin
    case Message.Msg of
      WM_LButtonDown: FMouseButton := mbLeft;
      WM_MButtonDown: FMouseButton := mbMiddle;
      WM_RButtonDown: FMouseButton := mbRight;
    end;
    if FMouseButton in MouseButtons then DoMouseDown(Message);
  end;
end;
{ TDIBFeature }

procedure TDIBFeature.AssignTo(Dest: TPersistent);
begin
  if not (Dest is TDIBFeature) then inherited;
end;

class function TDIBFeature.CanApplyTo(aComponent: TPersistent): Boolean;
begin
  Result := True;
end;

class function TDIBFeature.GetDisplayName: string;
begin
  Result := 'Unknown feature';
end;

function TDIBFeature.GetOwner: TPersistent;
begin
  Result := FControl;
end;

{ THighlightDIB }

procedure THighlightDIB.AssignTo(Dest: TPersistent);
begin
  if Dest is THighlightDIB then
    with THighlightDIB(Dest) do
    begin
      HighlightOpacity := Self.HighlightOpacity;
    end;
  inherited;
end;

class function THighlightDIB.CanApplyTo(aComponent: TPersistent): Boolean;
begin
  Result := (aComponent is TCustomDIBControl);
end;

constructor THighlightDIB.Create(AOwner: TComponent);
begin
  inherited;
  FHighlightOpacity := 255;
end;

class function THighlightDIB.GetDisplayName: string;
begin
  Result := 'Highlight dib';
end;

procedure THighlightDIB.WndProc(var Message: TMessage;
  var Handled: Boolean);
begin
  if Control is TCustomDIBControl then with THackDIBControl(Control) do 
    begin
      case Message.Msg of
        WM_SetFocus: if not Focused and not MouseInControl then
          begin
            FOrigOpacity := Opacity;
            Opacity := HighlightOpacity;
          end;

        WM_KillFocus: if Focused and not MouseInControl then
          begin
            Opacity := FOrigOpacity;
          end;

        CM_MouseEnter: if not Focused then
          begin
            if MouseCapture then exit;
            FOrigOpacity := Opacity;
            Opacity := HighlightOpacity;
          end;

        WM_LButtonUp:
          begin
            MouseCapture := False;
          end;

        CM_MouseLeave: if not Focused then
          begin
            if MouseCapture then exit;
            Opacity := FOrigOpacity;
          end;
      end;
    end;
end;


{ TControlItem }

procedure TControlItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TControlItem then
    TControlItem(Dest).Control := FControl
  else
    inherited;
end;

function TControlItem.GetDisplayName: string;
begin
  if Control = nil then
    Result := inherited GetDisplayName
  else if Control.Name <> '' then
    Result := Control.Name
  else if Control.ClassName <> '' then
    Result := Control.ClassName
  else
    Result := inherited GetDisplayName;
end;

procedure TControlItem.SetControl(const Value: TControl);
var
  X: Integer;
begin
  if Value = nil then
    raise EFeatureError.Create('You cannot set Control to nil');
  for X := 0 to Collection.Count - 1 do
    if (TControlList(Collection).Items[X].Control = Value) and
      (Collection.Items[X] <> Self) then
      raise EFeatureError.Create('Control already exists in list.');
  FControl := Value;
end;

{ TShapeableDIB }

procedure TShapeableDIB.AssignTo(Dest: TPersistent);
begin
  if Dest is TShapeableDIB then
    with TShapeableDIB(Dest) do
    begin
      TransparentColor := Self.TransparentColor;
      TransparentMode := Self.TransparentMode;
      MaskLevel := Self.MaskLevel;
    end;
  inherited;
end;

procedure TShapeableDIB.CalculateRegion;
var
  CurrentView: TWinDIB;
  TransCol: TColor;
begin
  CurrentView := TWinDIB.Create(Control.Width, Control.Height);
  try
    CurrentView.QuickFill($00000000);
    THackDIBControl(Control).ControlDIB := CurrentView;
    THackDIBControl(Control).Paint;
    if FRegion <> 0 then DeleteObject(FRegion);
    if MaskLevel > 0 then
      FRegion := CurrentView.MakeRGN(MaskLevel)
    else
    begin
      if TransparentMode = tmAuto then
        TransCol := CurrentView.Canvas.Pixels[0, Control.Height - 1]
      else
        TransCol := TransparentColor;
      FRegion := CurrentView.MakeRGNFromColor(TransCol);
    end;
    FControlInvalidateTime := THackDIBControl(Control).LastInvalidateTime;
  finally
    CurrentView.Free;
    THackDIBControl(Control).ControlDIB := nil;
  end;
end;

class function TShapeableDIB.CanApplyTo(aComponent: TPersistent): Boolean;
begin
  Result := AComponent is TCustomDIBControl;
end;

constructor TShapeableDIB.Create(AOwner: TComponent);
begin
  inherited;
  FControlInvalidateTime := 1234;
  FRegion := 0;
end;

destructor TShapeableDIB.Destroy;
begin
  if FRegion <> 0 then DeleteObject(FRegion);
  inherited;
end;

class function TShapeableDIB.GetDisplayName: string;
begin
  Result := 'Shapeable DIB';
end;

procedure TShapeableDIB.WndProc(var Message: TMessage;
  var Handled: Boolean);
begin
  case Message.Msg of
    CM_HITTEST:
      begin
        Handled := True;
        if FControlInvalidateTime <> THackDIBControl(Control).LastInvalidateTime then
          CalculateRegion;
        with TCMHITTEST(Message) do
          if (FRegion = 0) or (PtInRegion(FRegion, XPos, YPos)) then
            Message.Result := HTCLIENT
        else
          Message.Result := HTNOWHERE;
      end;
  end;
end;

initialization
  RegisterDIBFeature(TMoveableDIB);
  RegisterDIBFeature(THighlightDIB);
  RegisterDIBFeature(TShapeableDIB);
end.
