unit cDIBAnimContainer;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBWavList.PAS, released November 18, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
To allow the user to take "SnapShots" of the properties of all of its controls,
and then "morph" between SnapShots over a given period of time.

Contributor(s):
None as yet


Last Modified: May 2, 2001

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   April 4, 2000
By:     Peter Morris
Change: Added OnFrame event (0 = start, 255 = end) for TCustomDIBAnimContainer

Date:   April 4, 2000
By:     Peter Morris
Change: Added PauseControl and UnpauseControl to TCustomDIBAnimContainer.
        This allows you to exclude a control from the animation at runtime,
        you could then quite easily use the OnFrame event to Unpause the control
        and let it catch up with the other controls.

Date:   May 2, 2001
By:     Peter Morris
Change: Added DIBBorder property

Date:   June 24, 2001
By:     Peter Morris
Change: Added BorderDrawPosition;

Date:   August 24, 2001
By:     Peter Morris
Change: Added BeforePaint / AfterPaint events.
*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, cDIBPanel, cDIBTimer, cDIBImageList, cDIB, TypInfo;

type
  PDIBPropertyMorpher = ^TDIBPropertyMorpher;
  TDIBPropertyMorpher = function(Info: PTypeInfo; StartValue, EndValue: Variant;
    Position: Byte): Variant;
  TFrameEvent = procedure(Sender: TObject; Position: Byte) of object;

  TDIBSnapShotControls = class;  

  TDIBControlProperty = class(TCollectionItem)
  private
    FPropName: string;
    FValue: string;
    Owner: TComponent;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property PropName: string read FPropName write FPropName;
    property Value: string read FValue write FValue;
  end;

  TDIBControlProperties = class(TOwnedCollection)
  private
    Owner: TComponent;
    function GetItem(Index: Integer): TDIBControlProperty;
    procedure SetItem(Index: Integer; const Value: TDIBControlProperty);
  protected
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function Add: TDIBControlProperty;
    function Insert(Index: Integer): TDIBControlProperty;
    procedure MakeSnapShot(const Control: TControl);
    property Items[Index: Integer]: TDIBControlProperty read GetItem write SetItem;
      default;
  published
  end;

  TDIBSnapShotControl = class(TCollectionItem)
  private
    Owner: TComponent;
    FControl: TControl;
    FProperties: TDIBControlProperties;
    procedure MorphTo(Dest: TDIBSnapShotControl; Position: Byte);
    procedure SetProperties(const Value: TDIBControlProperties);
    procedure SetControl(const Value: TControl);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure MakeSnapShot;
    function FindProperty(const PropName: string): TDIBControlProperty;
  published
    property Control: TControl read FControl write SetControl;
    property Properties: TDIBControlProperties read FProperties write SetProperties;
  end;

  TDIBSnapShotControls = class(TOwnedCollection)
  private
    Owner: TComponent;
    function GetItem(Index: Integer): TDIBSnapShotControl;
    procedure SetItem(Index: Integer; const Value: TDIBSnapShotControl);
  protected
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function Add: TDIBSnapShotControl;
    function Insert(Index: Integer): TDIBSnapShotControl;
    property Items[Index: Integer]: TDIBSnapShotControl read GetItem write SetItem;
      default;
  published
  end;

  TDIBContainerSnapShot = class(TCollectionItem)
  private
    FDisplayName: string;
    Owner: TComponent;
    FControls: TDIBSnapShotControls;
    procedure SetControls(const Value: TDIBSnapShotControls);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function GetDisplayName: string; override;
    procedure Notification(AComponent: TComponent); 
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    function FindControl(Control: TControl): TDIBSnapShotControl;
    procedure MakeSnapShot;
    procedure MorphTo(Dest: TDIBContainerSnapShot; Position: Byte;
      PausedControls: TList);
  published
    property Controls: TDIBSnapShotControls read FControls write SetControls;
    property DisplayName: string read GetDisplayName write FDisplayName;
  end;

  TDIBContainerSnapShots = class(TOwnedCollection)
  private
    Owner: TComponent;
    function GetItem(Index: Integer): TDIBContainerSnapShot;
    procedure SetItem(Index: Integer; const Value: TDIBContainerSnapShot);
  protected
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function Add: TDIBContainerSnapShot;
    function Insert(Index: Integer): TDIBContainerSnapShot;
    property Items[Index: Integer]: TDIBContainerSnapShot read GetItem write SetItem;
      default;
  published
  end;

  TCustomDIBAnimContainer = class(TCustomDIBContainer)
  private
    { Private declarations }
    FPausedControls: TList;
    FCurrentPosition,
    FPositionInc: Extended;
    FEndSnapShot: TDIBContainerSnapShot;
    FSnapShots: TDIBContainerSnapShots;
    FTempSnapShots: TDIBContainerSnapShots;
    FTimer: TDIBTimer;
    FOnAnimEnd: TNotifyEvent;
    FOnAnimStart: TNotifyEvent;
    FOnFrame: TFrameEvent;
    procedure DoAnimateSnapShot(Sender: TObject);
    procedure SetSnapShots(const Value: TDIBContainerSnapShots);
    function GetIsAnimating: Boolean;
  protected
    { Protected declarations }
    procedure AssignTo(Dest: TPersistent); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    property PausedControls: TList read FPausedControls;
    property OnAnimEnd: TNotifyEvent read FOnAnimEnd write FOnAnimEnd;
    property OnAnimStart: TNotifyEvent read FOnAnimStart write FOnAnimStart;
    property OnFrame: TFrameEvent read FOnFrame write FOnFrame;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AnimateToSnapShot(Index: Integer; MilliSeconds: Cardinal);
    procedure GoToSnapShot(Index: Integer);
    procedure PauseControl(Control: TControl);
    procedure Stop;
    procedure UnpauseControl(Control: TControl);

    property IsAnimating: Boolean read GetIsAnimating; 
  published
    { Published declarations }
    property SnapShots: TDIBContainerSnapShots read FSnapShots write SetSnapShots;
  end;

  TDIBAnimContainer = class(TCustomDIBAnimContainer)
  public
  published
    //New properties / events
    property OnAnimEnd;
    property OnAnimStart;
    property OnFrame;

    //inherited
    property AfterPaint;
    property Align;
    property Anchors;
    property AutoSize;
    property BeforePaint;
    property BiDiMode;
    property BorderDrawPosition;
    property Color;
    property Constraints;
    property Cursor;
    property DIBBorder;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Height;
    property HelpContext;
    property Hint;
    property Left;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property Tag;
    property Top;
    property UseDockManager;
    property Visible;
    property Width;

    property OnActiveControlChange;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;

  TCustomDIBImageAnimContainer = class(TCustomDIBAnimContainer)
  private
    FIndexImage: TDIBImageLink;
    FTileMethod: TTileMethod;

    procedure DoImageChanged(Sender: TObject; ID: Integer; Operation: TDIBOperation);
    function GetDIBImageList: TCustomDIBImageList;
    procedure SetDIBImageList(const Value: TCustomDIBImageList);
    procedure SetTileMethod(const Value: TTileMethod);
    procedure ImageChanged(ID: Integer; Operation: TDIBOperation); virtual;

    property DIBImageList: TCustomDIBImageList read GetDIBImageList write SetDIBImageList;
    property IndexImage: TDIBImageLink read FIndexImage write FIndexImage;
    property TileMethod: TTileMethod read FTileMethod write SetTileMethod;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Paint; override;
  published
  end;

  TDIBImageAnimContainer = class(TCustomDIBImageAnimContainer)
  public
  published
    //New properties / events
    property DIBImageList;
    property IndexImage;
    property TileMethod;

    //inherited
    property OnAnimEnd;
    property OnAnimStart;
    property OnFrame;
    property AfterPaint;
    property Align;
    property Anchors;
    property AutoSize;
    property BeforePaint;
    property BiDiMode;
    property BorderDrawPosition;
    property Color;
    property Constraints;
    property Cursor;
    property DIBBorder;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Height;
    property HelpContext;
    property Hint;
    property Left;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property Tag;
    property Top;
    property UseDockManager;
    property Visible;
    property Width;

    property OnActiveControlChange;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;

  end;


procedure AddPropertyMorpher(ATypeInfo: PTypeInfo; MorpherProc: PDIBPropertyMorpher;
  UnitName: string);
procedure RequiredUnits(Result: TStrings);

implementation

const
  cMaxAnimSpeed = 50;

  cSupportedProperties: TTypeKinds =
    [tkInteger, tkChar, tkFloat, tkString, tkWChar, tkLString, tkWString,
    tkInt64];

type
  TDIBPropertyMap = class
  private
    FPropertyMorpherList: TList;
    FTypeInfoList: TStringList;
    FUnitNames: TStringList;
  protected
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddPropertyMorpher(ATypeInfo: PTypeInfo; MorpherProc: PDIBPropertyMorpher;
      UnitName: string);
    function MorphPropertyValue(Instance: TComponent; const PropName: string;
      StartValue, EndValue: Variant; Position: Byte): Variant;
  end;

var
  DIBPropertyMap: TDIBPropertyMap;

procedure RequiredUnits(Result: TStrings);
begin
  if Result <> nil then Result.Assign(DIBPropertyMap.FUnitNames);
end;

procedure AddPropertyMorpher(ATypeInfo: PTypeInfo;
  MorpherProc: PDIBPropertyMorpher; UnitName: string);
begin
  DIBPropertyMap.AddPropertyMorpher(ATypeInfo, MorpherProc, UnitName);
end;

function MorphAngle(Info: PTypeInfo; StartValue, EndValue: Variant;
  Position: Byte): Variant;
begin
  if (StartValue + 359) - EndValue <= Abs(EndValue - StartValue) then
    StartValue := StartValue + 359;

  Result := StartValue + ((EndValue - StartValue) * Position div 255);
  if Result > 359 then Result := Result - 359;
end;

function MorphInteger(Info: PTypeInfo; StartValue, EndValue: Variant;
  Position: Byte): Variant;
begin
  Result := StartValue + ((EndValue - StartValue) * Position div 255);
end;

function MorphExtended(Info: PTypeInfo; StartValue, EndValue: Variant;
  Position: Byte): Variant;
begin
  Result := StartValue + ((EndValue - StartValue) * Position / 255);
end;


function MorphColor(Info: PTypeInfo; StartValue, EndValue: Variant;
  Position: Byte): Variant;
var
  SourceCol, DestCol, ResultCol: TColor;
  I: Integer;
  SourceBytes, DestBytes, ResultBytes: PByteArray;
begin
  SourceCol := ColorToRGB(StartValue);
  DestCol := ColorToRGB(EndValue);
  SourceBytes := @SourceCol;
  DestBytes := @DestCol;
  ResultBytes := @ResultCol;
  for I := 0 to 3 do
    ResultBytes[I] := SourceBytes[I] + (DestBytes[I] - SourceBytes[I]) * Position div 255;
  Result := ResultCol;
end;

{ TDIBPropertyMap }

procedure TDIBPropertyMap.AddPropertyMorpher(ATypeInfo: PTypeInfo;
  MorpherProc: PDIBPropertyMorpher; UnitName: string);
begin
  if FTypeInfoList.Count = 0 then
  begin
    FTypeInfoList.Add(string(ATypeInfo^.Name));
    FPropertyMorpherList.Add(MorpherProc);
  end 
  else
  begin
    FTypeInfoList.Insert(0, string(ATypeInfo^.Name));
    FPropertyMorpherList.Insert(0, MorpherProc);
  end;
  if (UnitName <> '') and (FUnitNames.IndexOf(UnitName) < 0) then
    FUnitNames.Add(UnitName);
end;

constructor TDIBPropertyMap.Create;
begin
  FPropertyMorpherList := TList.Create;
  FTypeInfoList := TStringList.Create;
  FUnitNames := TStringList.Create;
end;

destructor TDIBPropertyMap.Destroy;
begin
  FUnitNames.Free;
  FPropertyMorpherList.Free;
  FTypeInfoList.Free;
  inherited;
end;

function TDIBPropertyMap.MorphPropertyValue(Instance: TComponent;
  const PropName: string; StartValue, EndValue: Variant; Position: Byte): Variant;
var
  PInfo: PPropInfo;
  Index: Integer;
  FProc: TDIBPropertyMorpher;
begin
  if Position > 128 then
    Result := EndValue
  else
    Result := StartValue;

  PInfo := GetPropInfo(Instance, PropName, cSupportedProperties);
  Index := FTypeInfoList.IndexOf(string(PInfo.PropType^.Name));
  if Index >= 0 then
  begin
    FProc := TDIBPropertyMorpher(FPropertyMorpherList[Index]);
    if Assigned(FProc) then
      Result := FProc(PInfo.PropType^, StartValue, EndValue, Position);
  end;
end;
(*
var
  PInfo: PPropInfo;
  Index: Integer;
  FProc: TDIBPropertyMorpher;
  NewValue: Variant;
begin
  PInfo := GetPropInfo(Instance, PropName, cSupportedProperties);
  Index := FTypeInfoList.IndexOf(PInfo.PropType^.Name);
  if Index >= 0 then
  begin
    FProc := TDIBPropertyMorpher(FPropertyMorpherList[Index]);
    if Assigned(FProc) then
    begin
      NewValue := FProc(PInfo.PropType^, StartValue, EndValue, Position);
      if GetPropValue(Instance, PropName) <> NewValue then
        SetPropValue(Instance, PropName, NewValue);
    end;
  end;

end;
*)

{ TDIBControlProperty }

procedure TDIBControlProperty.AssignTo(Dest: TPersistent);
begin
  if Dest is TDIBControlProperty then with TDIBControlProperty(Dest) do
    begin
      PropName := Self.PropName;
      Value := Self.Value;
    end;
end;

constructor TDIBControlProperty.Create(Collection: TCollection);
begin
  inherited;
  if Collection <> nil then
    Owner := TDIBControlProperties(Collection).Owner;
end;

destructor TDIBControlProperty.Destroy;
begin
  inherited;
end;

{ TDIBControlProperties }

function TDIBControlProperties.Add: TDIBControlProperty;
begin
  Result := TDIBControlProperty(inherited Add);
end;

constructor TDIBControlProperties.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TDIBControlProperty);
  Owner := AOwner;
end;

destructor TDIBControlProperties.Destroy;
begin
  inherited;
end;

function TDIBControlProperties.GetItem(Index: Integer): TDIBControlProperty;
begin
  Result := TDIBControlProperty(inherited GetItem(Index));
end;

function TDIBControlProperties.Insert(Index: Integer): TDIBControlProperty;
begin
  Result := TDIBControlProperty(inherited Insert(Index));
end;

procedure TDIBControlProperties.MakeSnapShot(const Control: TControl);
var
  I, Count: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
  Prop: TDIBControlProperty;
begin
  Clear;

  Count := GetTypeData(Control.ClassInfo).PropCount;
  if Count > 0 then
  begin
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      GetPropInfos(Control.ClassInfo, PropList);
      for I := 0 to Count - 1 do
      begin
        PropInfo := PropList[I];
        if (PropInfo^.PropType^.Kind in cSupportedProperties) and
          (DIBPropertyMap.FTypeInfoList.IndexOf(string(PropInfo^.PropType^.Name)) >= 0) then
        begin
          if (CompareText(string(PropInfo^.Name), 'Name') <> 0) and
            (CompareText(string(PropInfo^.Name), 'Tag') <> 0) and
            (PropInfo^.Name <> '') then
          begin
            Prop := Add;
            Prop.PropName := string(PropInfo^.Name);
            case PropInfo^.PropType^.Kind of
              tkChar, tkInteger:
                Prop.Value := IntToStr(GetOrdProp(Control, Prop.PropName));
              tkInt64:
                Prop.Value := IntToStr(GetInt64Prop(Control, Prop.PropName));
              tkString, tkWChar, tkLString, tkWString:
                Prop.Value := GetStrProp(Control, Prop.PropName);
              tkFloat:
                Prop.Value := FloatToStr(GetFloatProp(Control, Prop.PropName));
            end;
          end;
        end;
      end;
    finally
      FreeMem(PropList, Count * SizeOf(Pointer));
    end;
  end;
end;

procedure TDIBControlProperties.SetItem(Index: Integer;
  const Value: TDIBControlProperty);
begin
  inherited SetItem(Index, Value);
end;

{ TDIBSnapShotControl }

procedure TDIBSnapShotControl.AssignTo(Dest: TPersistent);
begin
  if Dest is TDIBSnapShotControl then with TDIBSnapShotControl(Dest) do
    begin
      Control := Self.Control;
      Properties.Assign(Self.Properties);
    end 
  else
    inherited;
end;

constructor TDIBSnapShotControl.Create(Collection: TCollection);
begin
  inherited;
  if Collection <> nil then
    Owner := TDIBSnapShotControls(Collection).Owner;
  FProperties := TDIBControlProperties.Create(Owner);
end;

destructor TDIBSnapShotControl.Destroy;
begin
  FProperties.Free;
  inherited;
end;

function TDIBSnapShotControl.FindProperty(const PropName: string): TDIBControlProperty;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Properties.Count - 1 do
    if CompareText(PropName, Properties[I].PropName) = 0 then
    begin
      Result := Properties[I];
      Break;
    end;
end;

procedure TDIBSnapShotControl.MakeSnapShot;
begin
  Properties.MakeSnapShot(Control);
  if (Control is TWinControl) and not (Control is TCustomDIBAnimContainer) then
    with TWinControl(Control) do
      Self.Properties.MakeSnapShot(Control);
  if (Properties.Count = 0) then Free;
end;

procedure TDIBSnapShotControl.MorphTo(Dest: TDIBSnapShotControl; Position: Byte);
var
  I: Integer;
  DestProp: TDIBControlProperty;
  NewValue: Variant;
  BR: TRect;
begin
  BR := Control.BoundsRect;
  for I := 0 to Properties.Count - 1 do
  begin
    DestProp := Dest.FindProperty(Properties[I].PropName);
    if DestProp <> nil then with Properties[I] do
      begin
        NewValue := DIBPropertyMap.MorphPropertyValue(Control, PropName,
          Value, DestProp.Value, Position);
        if CompareText(PropName, 'LEFT') = 0 then
        begin
          BR.Left := NewValue;
          BR.Right := BR.Right + NewValue;
        end 
        else if CompareText(PropName, 'TOP') = 0 then
        begin
          BR.Top := NewValue;
          BR.Bottom := BR.Bottom + NewValue;
        end 
        else if CompareText(PropName, 'WIDTH') = 0 then
          BR.Right := BR.Left + NewValue
        else if CompareText(PropName, 'HEIGHT') = 0 then
          BR.Bottom := BR.Top + NewValue
        else if GetPropValue(Control, PropName) <> NewValue then
          SetPropValue(Control, PropName, NewValue);
      end;
  end;

  with Control.BoundsRect do
    if (BR.Left <> Left) or (BR.Right <> Right) or (BR.Right <> Right) or
      (BR.Bottom <> Bottom) then
      case Control.Align of
        alNone: Control.BoundsRect := BR;
        alTop: Control.Height := BR.Bottom - BR.Top;
        alLeft: Control.Width := BR.Right - BR.Left;
        alRight: with Control do BoundsRect := Rect(BR.Left, Top, BR.Right, Top + Height);
        alBottom: with Control do BoundsRect := Rect(Left, BR.Top, Left + Width, BR.Bottom);
      end;


  if (Control <> Owner) and (Control is TWinControl) then Control.Repaint;
end;

procedure TDIBSnapShotControl.SetControl(const Value: TControl);
begin
  if Value <> Control then
  begin
    if Assigned(FControl) then
      FControl.RemoveFreeNotification(Owner);
    FControl := Value;
    if Assigned(FControl) then
      FControl.FreeNotification(Owner);
  end;
end;

procedure TDIBSnapShotControl.SetProperties(const Value: TDIBControlProperties);
begin
  FProperties.Assign(Value);
end;

{ TDIBSnapShotControls }

function TDIBSnapShotControls.Add: TDIBSnapShotControl;
begin
  Result := TDIBSnapShotControl(inherited Add);
end;

constructor TDIBSnapShotControls.Create(AOwner: TComponent);
begin
  inherited Create(Owner, TDIBSnapShotControl);
  Owner := AOwner;
end;

destructor TDIBSnapShotControls.Destroy;
begin
  inherited;
end;

function TDIBSnapShotControls.GetItem(Index: Integer): TDIBSnapShotControl;
begin
  Result := TDIBSnapShotControl(inherited GetItem(Index));
end;

function TDIBSnapShotControls.Insert(Index: Integer): TDIBSnapShotControl;
begin
  Result := TDIBSnapShotControl(inherited Insert(Index));
end;

procedure TDIBSnapShotControls.SetItem(Index: Integer; const Value: TDIBSnapShotControl);
begin
  inherited SetItem(Index, Value);
end;

{ TDIBContainerSnapShot }

procedure TDIBContainerSnapShot.AssignTo(Dest: TPersistent);
begin
  if Dest is TDIBContainerSnapShot then with TDIBContainerSnapShot(Dest) do
      Controls.Assign(Self.Controls)
  else
    inherited;
end;

constructor TDIBContainerSnapShot.Create(Collection: TCollection);
begin
  inherited;
  if Collection <> nil then
    Owner := TDIBContainerSnapShots(Collection).Owner;
  FControls := TDIBSnapShotControls.Create(Owner);
  FDisplayName := 'Snapshot #' + IntToStr(ID);
end;

destructor TDIBContainerSnapShot.Destroy;
begin
  FControls.Free;
  inherited;
end;

function TDIBContainerSnapShot.FindControl(Control: TControl): TDIBSnapShotControl;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Controls.Count - 1 do
    if Controls[I].Control = Control then
    begin
      Result := Controls[I];
      Break;
    end;
end;

function TDIBContainerSnapShot.GetDisplayName: string;
begin
  Result := FDisplayName;
end;

procedure TDIBContainerSnapShot.MakeSnapShot;
var
  I: Integer;
begin
  if Owner = nil then Exit;
  Controls.Clear;
  if Owner is TControl then with Controls.Add do
    begin
      Control := TControl(Owner);
      Properties.MakeSnapShot(Control);
    end;

  with TWinControl(Owner) do
    for I := 0 to ControlCount - 1 do
      with Self.Controls.Add do
      begin
        Control := TWinControl(Owner).Controls[I];
        MakeSnapShot;
      end;
end;

procedure TDIBContainerSnapShot.MorphTo(Dest: TDIBContainerSnapShot; Position: Byte;
  PausedControls: TList);
var
  I: Integer;
  DestControl: TDIBSnapShotControl;
begin
  for I := 0 to Controls.Count - 1 do
  begin
    if (PausedControls = nil) or (PausedControls.IndexOf(Controls[I].Control) = -1) then
    begin
      DestControl := Dest.FindControl(Controls[I].Control);
      if DestControl <> nil then Controls[I].MorphTo(DestControl, Position);
    end;
  end;
end;

procedure TDIBContainerSnapShot.Notification(AComponent: TComponent);
var
  I: Integer;
begin
  for I := Controls.Count - 1 downto 0 do
    if Controls[I].Control = AComponent then
      Controls[I].Free;

  if Controls.Count = 0 then Free;
end;

procedure TDIBContainerSnapShot.SetControls(const Value: TDIBSnapShotControls);
begin
  FControls.Assign(Value);
end;

{ TDIBContainerSnapShots }

function TDIBContainerSnapShots.Add: TDIBContainerSnapShot;
begin
  Result := TDIBContainerSnapShot(inherited Add);
  //  Result.MakeSnapShot;
end;

constructor TDIBContainerSnapShots.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TDIBContainerSnapShot);
  Owner := AOwner;
end;

destructor TDIBContainerSnapShots.Destroy;
begin
  inherited;
end;

function TDIBContainerSnapShots.GetItem(Index: Integer): TDIBContainerSnapShot;
begin
  Result := TDIBContainerSnapShot(inherited GetItem(Index));
end;

function TDIBContainerSnapShots.Insert(Index: Integer): TDIBContainerSnapShot;
begin
  Result := TDIBContainerSnapShot(inherited Insert(Index));
end;


procedure TDIBContainerSnapShots.SetItem(Index: Integer;
  const Value: TDIBContainerSnapShot);
begin
  inherited SetItem(Index, Value);
end;

{ TCustomDIBAnimContainer }

procedure TCustomDIBAnimContainer.AnimateToSnapShot(Index: Integer;
  MilliSeconds: Cardinal);
var
  Interval: Integer;
begin
  if (FTimer.Enabled) then Stop;

  if Assigned(OnAnimStart) then OnAnimStart(Self);

  FEndSnapShot := SnapShots[Index];

  FTempSnapShots.Clear;
  FTempSnapShots.Add;
  FTempSnapShots[0].MakeSnapShot;

  FCurrentPosition := 0;
  FPositionInc := 1;
  Interval := Milliseconds div 255;
  if Interval < cMaxAnimSpeed then
  begin
    Interval := cMaxAnimSpeed;
    FPositionInc := cMaxAnimSpeed / (Milliseconds / 255);
  end;
  FTimer.Interval := Interval;
  FTimer.Enabled := True;
end;

procedure TCustomDIBAnimContainer.AssignTo(Dest: TPersistent);
begin
  if Dest is TCustomDIBAnimContainer then with TCustomDIBAnimContainer(Dest) do
      SnapShots.Assign(Self.SnapShots);
  inherited;
end;

constructor TCustomDIBAnimContainer.Create(AOwner: TComponent);
begin
  inherited;
  FSnapShots := TDIBContainerSnapShots.Create(Self);
  FTempSnapShots := TDIBContainerSnapShots.Create(Self);
  FTimer := TDIBTimer.Create(Self);
  FPausedControls := TList.Create;
  FTimer.OnTimer := DoAnimateSnapShot;
end;

destructor TCustomDIBAnimContainer.Destroy;
begin
  FTimer.Free;
  FPausedControls.Free;
  FTempSnapShots.Free;
  FSnapShots.Free;
  inherited;
end;

procedure TCustomDIBAnimContainer.DoAnimateSnapShot(Sender: TObject);
begin
  FCurrentPosition := FCurrentPosition + FPositionInc;
  if Trunc(FCurrentPosition) > 255 then FCurrentPosition := 255;
  if Assigned(OnFrame) then OnFrame(Self, Trunc(FCurrentPosition));
  FTempSnapShots[0].MorphTo(FEndSnapShot, Trunc(FCurrentPosition), FPausedControls);
  if FCurrentPosition = 255 then Stop;
end;

function TCustomDIBAnimContainer.GetIsAnimating: Boolean;
begin
  Result := FTimer.Enabled;
end;

procedure TCustomDIBAnimContainer.GoToSnapShot(Index: Integer);
begin
  SnapShots[Index].MorphTo(SnapShots[Index], 255, nil);
end;

procedure TCustomDIBAnimContainer.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  I: Integer;
begin
  inherited;
  if (Operation = opRemove) and (AComponent is TControl) then
    for I := SnapShots.Count - 1 downto 0 do
    begin
      SnapShots[I].Notification(AComponent);
    end;
end;

procedure TCustomDIBAnimContainer.PauseControl(Control: TControl);
begin
  if PausedControls.IndexOf(Control) = -1 then PausedControls.Add(Control);
end;

procedure TCustomDIBAnimContainer.SetSnapShots(const Value: TDIBContainerSnapShots);
begin
  FSnapShots.Assign(Value);
end;

procedure TCustomDIBAnimContainer.Stop;
begin
  FTimer.Enabled := False;
  if Assigned(OnAnimEnd) then OnAnimEnd(Self);
end;

procedure TCustomDIBAnimContainer.UnpauseControl(Control: TControl);
var
  I: Integer;
  TempControl: TDIBSnapShotControl;
begin
  I := FPausedControls.IndexOf(Control);
  if I >= 0 then
  begin
    FPausedControls.Delete(I);
    TempControl := FTempSnapShots[0].FindControl(Control);
    if TempControl <> nil then TempControl.MakeSnapShot;
  end;
end;

{ TCustomDIBImageAnimContainer }

constructor TCustomDIBImageAnimContainer.Create(AOwner: TComponent);
begin
  inherited;
  FIndexImage := TDIBImageLink.Create(Self);
  FIndexImage.OnImageChanged := DoImageChanged;
end;

destructor TCustomDIBImageAnimContainer.Destroy;
begin
  FIndexImage.Free;
  inherited;
end;

procedure TCustomDIBImageAnimContainer.Paint;
var
  X, Y: Integer;
  R: TRect;
  TheDIB: TMemoryDIB;
begin
  if not FIndexImage.GetImage(TheDIB) then 
  begin
    inherited;
    exit;
  end;

  if TileMethod <> tmTile then
    if (TheDIB.Width <> Width) or (TheDIB.Height <> Height) then
      inherited;

  if TheDIB.Height > 0 then 
  begin
    case TileMethod of
      tmCenter:
        begin
          TheDIB.Draw(Width div 2 - (TheDIB.Width div 2),
            Height div 2 - (TheDIB.Height div 2),
            TheDIB.Width, TheDIB.Height, DIB, 0, 0);
        end;
      tmTile:
        begin
          Y := 0;
          while Y < Height do 
          begin
            X := 0;
            while X < Width do 
            begin
              if IntersectRect(R, UpdateRect,
                Rect(X, Y, X + TheDIB.Width, Y + TheDIB.Height)) then
                TheDIB.Draw(X, Y, TheDIB.Width, TheDIB.Height, DIB, 0, 0);
              Inc(X, TheDIB.Width);
            end;
            Inc(Y, TheDIB.Height);
          end;
        end;
    end;
  end;
end;

procedure TCustomDIBImageAnimContainer.SetTileMethod(const Value: TTileMethod);
begin
  FTileMethod := Value;
  invalidate;
end;

procedure TCustomDIBImageAnimContainer.WndProc(var Message: TMessage);
begin
  if (csDestroying in ComponentState) or
    (TileMethod <> tmTile) or
    (Message.msg <> WM_EraseBkGnd) then
    inherited;
end;

procedure TCustomDIBImageAnimContainer.ImageChanged(ID: Integer;
  Operation: TDIBOperation);
begin
  case Operation of
    doRemove:
      if ID = IndexImage.DIBIndex then
        IndexImage.DIBIndex := -1
      else
        if ID < IndexImage.DIBIndex then
          IndexImage.DIBIndex := IndexImage.DIBIndex - 1;
      doChange: if ID = IndexImage.DIBIndex then Invalidate;
  end;
end;

function TCustomDIBImageAnimContainer.GetDIBImageList: TCustomDIBImageList;
begin
  Result := FIndexImage.DIBImageList;
end;

procedure TCustomDIBImageAnimContainer.SetDIBImageList(const Value: TCustomDIBImageList);
begin
  FIndexImage.DIBImageList := Value;
end;

procedure TCustomDIBImageAnimContainer.DoImageChanged(Sender: TObject;
  ID: Integer; Operation: TDIBOperation);
begin
  ImageChanged(ID, Operation);
end;



initialization
  DIBPropertyMap := TDIBPropertyMap.Create;
  AddPropertyMorpher(TypeInfo(Byte), @MorphInteger, '');
  AddPropertyMorpher(TypeInfo(Char), @MorphInteger, '');
  AddPropertyMorpher(TypeInfo(Integer), @MorphInteger, '');
  AddPropertyMorpher(TypeInfo(Extended), @MorphAngle, '');
  AddPropertyMorpher(TypeInfo(TColor), @MorphColor, '');
  AddPropertyMorpher(TypeInfo(Extended), @MorphExtended, '');
  AddPropertyMorpher(TypeInfo(Real), @MorphExtended, '');

finalization
  DIBPropertyMap.Free;
end.
