unit cDIBAnimMgr;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBAnimMgr.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Manages animations.  Uses a DIBImageList and specifies multiple images to use in an
animation.  Used for DIBAnimButton etc

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
  cDIBImageList, cDIB;

type
  TDIBAnimManager = class;
  TDIBAnimMgrItem = class;
  TDIBAnimMgrList = class;
  TDIBAnimation = class;
  TDIBFrameList = class;
  TDIBAnimationLink = class;

  TDIBFrameItem = class(TCollectionItem)
  private
    FAnimation: TDIBAnimation;
    FCollection: TDIBFrameList;

    FAngle: Extended;
    FAutoSize: Boolean;
    FIndexImage: TDIBImageLink;
    FOpacity: Byte;
    FScale: Extended;

    procedure DoImageChanged(Sender: TObject; Index: Integer; Operation: TDIBOperation);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    function GetImage(var TheDIB: TMemoryDIB): Boolean;
    property DisplayName;
  published
    property AutoSize: Boolean read FAutoSize write FAutoSize;
    property Angle: Extended read FAngle write FAngle;
    property IndexImage: TDIBImageLink read FIndexImage write FIndexImage;
    property Opacity: Byte read FOpacity write FOpacity;
    property Scale: Extended read FScale write FScale;
  end;

  TDIBFrameList = class(TOwnedCollection)
  private
    FAnimation: TDIBAnimation;
  protected
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function Add: TDIBFrameItem;
    function GetItem(Index: Integer): TDIBFrameItem;
    procedure SetItem(Index: Integer; Value: TDIBFrameItem);

    property Items[Index: Integer]: TDIBFrameItem read GetItem write SetItem; default;
  published
  end;

  TDIBAnimation = class(TComponent)
  private
    FManager: TDIBAnimManager;
    FFrames: TDIBFrameList;
    FNotifyList: TList;

    FDIBImageList: TCustomDIBImageList;
    procedure SetDIBImageList(const Value: TCustomDIBImageList);
  protected
    procedure AddLink(Item: TDIBAnimationLink);
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); virtual;
    procedure RemoveLink(Item: TDIBAnimationLink);
    procedure Notification(Component: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetDimensions: TPoint;
    function GetImage(const Frame: Integer; var TheDIB: TMemoryDIB): Boolean;
    function Valid: Boolean;

  published
    property DIBImageList: TCustomDIBImageList read FDIBImageList write SetDIBImageList;
    property Frames: TDIBFrameList read FFrames write FFrames;
  end;

  TDIBAnimationLink = class(TPersistent)
  private
    FAnimation: TDIBAnimation;
    FOnAnimationChanged: TNotifyEvent;

    procedure DoAnimationChanged(Sender: TObject; Index: Integer;
      Operation: TDIBOperation);
    procedure SetAnimation(const Value: TDIBAnimation);
    procedure UnlinkNotification;
  protected
    procedure AnimationChanged; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  published
    property Animation: TDIBAnimation read FAnimation write SetAnimation;
    property OnAnimationChanged: TNotifyEvent 
      read FOnAnimationChanged write FOnAnimationChanged;
  end;


  TDIBAnimMgrItem = class(TCollectionItem)
  private
    FAnimation: TDIBAnimation;
    FManager: TDIBAnimManager;
    FCollection: TDIBAnimMgrList;

    procedure SetAnimation(const Value: TDIBAnimation);
  protected
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property Animation: TDIBAnimation read FAnimation write SetAnimation;
  end;

  TDIBAnimMgrList = class(TOwnedCollection)
  private
    { Private declarations }
    FManager: TDIBAnimManager;
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;

    function Add: TDIBAnimMgrItem;
    function GetItem(Index: Integer): TDIBAnimMgrItem;
    procedure SetItem(Index: Integer; Value: TDIBAnimMgrItem);

    property Items[Index: Integer]: TDIBAnimMgrItem read GetItem write SetItem; default;

    property Manager: TDIBAnimManager read FManager;
  published
    { Published declarations }
  end;

  TDIBAnimManager = class(TComponent)
  private
    FAnimations: TDIBAnimMgrList;
  protected
    procedure Notification(Component: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Animations: TDIBAnimMgrList read FAnimations write FAnimations;
  end;

implementation

{ TDIBFrameItem }

constructor TDIBFrameItem.Create(Collection: TCollection);
begin
  inherited;
  FIndexImage := TDIBImageLink.Create(FAnimation);
  FIndexImage.OnImageChanged := DoImageChanged;
  FCollection := (Collection as TDIBFrameList);
  FAnimation := FCollection.FAnimation;
  FIndexImage.DIBImageList := FAnimation.DIBImageList;
  FAutoSize := False;
  FOpacity := 255;
  FAngle := 0;
  FScale := 100;
end;

destructor TDIBFrameItem.Destroy;
var
  OldAnimation: TDIBAnimation;
  OldIndex: Integer;
begin
  OldAnimation := FAnimation;
  OldIndex := Index;

  FIndexImage.Free;
  inherited;

  if OldAnimation <> nil then OldAnimation.ImageChanged(OldIndex, doRemove);
end;

procedure TDIBFrameItem.DoImageChanged(Sender: TObject; Index: Integer;
  Operation: TDIBOperation);
begin
  if FAnimation <> nil then FAnimation.ImageChanged(Self.Index, Operation);
end;

function TDIBFrameItem.GetDisplayName: string;
begin
  Result := 'Frame ' + IntToStr(Index +1);
end;

function TDIBFrameItem.GetImage(var TheDIB: TMemoryDIB): Boolean;
begin
  Result := IndexImage.GetImage(TheDIB);
  TheDIB.Opacity := Opacity;
  TheDIB.ScaleX := Scale;
  TheDIB.ScaleY := Scale;
  TheDIB.Angle := Angle;
end;


{ TDIBFrameList }

function TDIBFrameList.Add: TDIBFrameItem;
begin
  Result := TDIBFrameItem(inherited Add);
end;

constructor TDIBFrameList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TDIBFrameItem);
  FAnimation := (AOwner as TDIBAnimation);
end;

destructor TDIBFrameList.Destroy;
begin
  inherited;
end;

function TDIBFrameList.GetItem(Index: Integer): TDIBFrameItem;
begin
  Result := TDIBFrameItem(inherited GetItem(Index));
end;

procedure TDIBFrameList.SetItem(Index: Integer; Value: TDIBFrameItem);
begin
  inherited SetItem(Index, Value);
end;

{ TDIBAnimation }

procedure TDIBAnimation.AddLink(Item: TDIBAnimationLink);
begin
  if FNotifyList.IndexOf(Item) = -1 then
    FNotifyList.Add(Item);
end;

constructor TDIBAnimation.Create(AOwner: TComponent);
begin
  inherited;
  FFrames := TDIBFrameList.Create(Self);
  FNotifyList := TList.Create;
end;

destructor TDIBAnimation.Destroy;
var
  X: Integer;
begin
  for X := FNotifyList.Count - 1 downto 0 do
    TDIBAnimationLink(FNotifyList[X]).UnlinkNotification;
  FNotifyList.Free;
  FFrames.Free;
  inherited;
end;

function TDIBAnimation.GetDimensions: TPoint;
var
  X: Integer;
  Sizes: TPoint;
  TheDIB: TMemoryDIB;
begin
  Result := Point(0, 0);
  if Valid then
    for X := 0 to Frames.Count - 1 do 
    begin
      Frames[X].GetImage(TheDIB);
      Sizes := GetRotatedSize(TheDIB.Width, TheDIB.Height, TheDIB.Angle,
        TheDIB.ScaleX, TheDIB.ScaleY);
      if Sizes.X > Result.X then Result.X := Sizes.X;
      if Sizes.Y > Result.Y then Result.Y := Sizes.Y;
    end;
end;

function TDIBAnimation.GetImage(const Frame: Integer;
  var TheDIB: TMemoryDIB): Boolean;
begin
  Result := False;
  if (Self = nil) or (Frame < 0) or (Frame >= Frames.Count) then exit;
  Result := Frames[Frame].GetImage(TheDIB);
end;

procedure TDIBAnimation.ImageChanged(Index: Integer;
  Operation: TDIBOperation);
var
  X: Integer;
begin
  for X := 0 to FNotifyList.Count - 1 do
    TDIBAnimationLink(FNotifyList[X]).DoAnimationChanged(Self, Index, Operation);
end;

procedure TDIBAnimation.Notification(Component: TComponent;
  Operation: TOperation);
begin
  inherited;
  if csDestroying in ComponentState then Exit;
  if Component = FManager then Free;
end;

procedure TDIBAnimation.RemoveLink(Item: TDIBAnimationLink);
var
  Index: Integer;
begin
  Index := FNotifyList.IndexOf(Item);
  if Index >-1 then FNotifyList.Delete(Index);
end;

procedure TDIBAnimation.SetDIBImageList(const Value: TCustomDIBImageList);
var
  X: Integer;
begin
  FDIBImageList := Value;
  for X := 0 to Frames.Count - 1 do
    Frames[X].FIndexImage.DIBImageList := Value;
end;

function TDIBAnimation.Valid: Boolean;
begin
  Result := (Self <> nil) and (Frames.Count > 0);
end;

{ TDIBAnimMgrItem }

constructor TDIBAnimMgrItem.Create(Collection: TCollection);
begin
  inherited;
  FCollection := (Collection as TDIBAnimMgrList);
  FManager := FCollection.FManager;

  if not (csDesigning in FManager.ComponentState) and not
    (csLoading in FManager.ComponentState) then
    FAnimation := TDIBAnimation.Create(FManager);
end;

destructor TDIBAnimMgrItem.Destroy;
begin
  //Animation.Owner = FManager means that we created the item at runtime not with Designer
  //not csDestroying means that we are deleting an item but the form is not freeing
  if (FAnimation <> nil) and
    ((FAnimation.Owner = FManager) or not (csDestroying in FManager.Owner.ComponentState)) then
    FAnimation.Free;
  inherited;
end;

procedure TDIBAnimMgrItem.SetAnimation(const Value: TDIBAnimation);
begin
  FAnimation := Value;
end;

{ TDIBAnimMgrList }

function TDIBAnimMgrList.Add: TDIBAnimMgrItem;
begin
  Result := TDIBAnimMgrItem(inherited Add);
end;

constructor TDIBAnimMgrList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TDIBAnimMgrItem);
  FManager := (AOwner as TDIBAnimManager);
end;

destructor TDIBAnimMgrList.Destroy;
begin
  inherited;
end;

{ TAnimManager }

constructor TDIBAnimManager.Create(AOwner: TComponent);
begin
  inherited;
  FAnimations := TDIBAnimMgrList.Create(Self);
end;

destructor TDIBAnimManager.Destroy;
begin
  FAnimations.Free;
  inherited;
end;

function TDIBAnimMgrList.GetItem(Index: Integer): TDIBAnimMgrItem;
begin
  Result := TDIBAnimMgrItem(inherited GetItem(Index));
end;

procedure TDIBAnimMgrList.SetItem(Index: Integer; Value: TDIBAnimMgrItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDIBAnimManager.Notification(Component: TComponent;
  Operation: TOperation);
var
  X: Integer;
begin
  inherited;
  if Component is TDIBAnimation then
    case Operation of
      opRemove:
        for X := Animations.Count - 1 downto 0 do
          if Animations[X].Animation = Component then 
          begin
            Animations[X].Animation := nil;
            break;
          end;
      opInsert:
        Component.FreeNotification(Self);
    end;
end;

{ TDIBAnimationLink }

procedure TDIBAnimationLink.AnimationChanged;
begin
  if Assigned(FOnAnimationChanged) then FOnAnimationChanged(Self);
end;

constructor TDIBAnimationLink.Create;
begin
  inherited;
end;

destructor TDIBAnimationLink.Destroy;
begin
  if FAnimation <> nil then FAnimation.RemoveLink(Self);
  inherited;
end;

procedure TDIBAnimationLink.DoAnimationChanged(Sender: TObject;
  Index: Integer; Operation: TDIBOperation);
begin
  AnimationChanged;
end;

procedure TDIBAnimationLink.SetAnimation(const Value: TDIBAnimation);
begin
  if FAnimation <> nil then FAnimation.RemoveLink(Self);
  FAnimation := Value;
  if FAnimation <> nil then FAnimation.AddLink(Self);
  AnimationChanged;
end;

procedure TDIBAnimationLink.UnlinkNotification;
begin
  FAnimation := nil;
end;

initialization
  RegisterClass(TDIBAnimation);
end.
