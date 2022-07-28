unit cDIBImageList;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBImageList.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
This list may hold many images + their alpha masks.  All components should make use
of a DIBImageList rather than having the graphic data stored within the component.
(To save on application size)

Contributor(s):
None as yet


Last Modified: Oct 15, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
To be updated !
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   April 6, 2001
By:     Peter Morris
Change: Added a fault property to TImageList;

Date:   April 6, 2001
By:     Peter Morris
Change: Added an ImageByName function

Date:   August 12, 2002
By:     Hans-Jürgen Schnorrenberg
Change: ListChanged modified in order to provide the ImageIndex of an image in deletion
        FOwner and SetOwner of TImages replaced by inherited Owner

Date:   August 20, 2002
By:     Hans-Jürgen Schnorrenberg
Change: Added ImageMoved to TDIBImageItem triggered by SetIndex;
        Added ImageMoved method to TDIBImages, TDIBImageList;

Date:   November 24, 2002
By:     Peter Morris
Change: Added TCustomDIBImageList.GetItemClass.  This will allow developers to
        create their own descendant of TCustomDIBImageList and specify their own
        descendant class of TDIBImagesItem to be used to hold images.

Date:   March 23, 2003
By:     Peter Morris
Change: Added the ability to store images outside of the exe's resource.
        You can now specify
        irInternal - Inside EXE
        irLoadOnStart - Load from file on app start
        irLoadOnDemand - Load from file when first used

Date:   October 15, 2003
By:     Peter Morris
Change: Added ItemByName and FindByName to DIBImageList
*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, cDIB;

type
  EDIBImageListError = class(Exception);
  TDIBOperation = (doRemove, doChange);
  TDIBImageRetrieval = (irInternal, irLoadOnStart, irLoadOnDemand);
  TDIBOperationEvent = procedure(Sender: TObject; Index: Integer;
    Operation: TDIBOperation) of object;
  TDIBTranslateImagePathEvent = procedure (Sender: TObject; var ImagePath: string) of object;

  TCustomDIBImageList = class;

  TDIBImagesItemClass = class of TDIBImagesItem;

  TDIBImagesItem = class(TCollectionItem)
  private
    FDIB: TMemoryDIB;
    FImportedFrom: string;
    FDisplayName: string;
    FDIBLoaded: Boolean;
    FImageRetrieval: TDIBImageRetrieval;
    FOnTranslateImagePath: TDIBTranslateImagePathEvent;
    procedure ImportImages;
    procedure ReadTemplateFilename(Reader: TReader);
    function GetDIB: TMemoryDIB;
    procedure SetDIB(const Value: TMemoryDIB);
    procedure WriteTemplateFilename(Writer: TWriter);
    procedure SetImageRetrieval(const Value: TDIBImageRetrieval);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function GetDIBClass: TMemoryDIBClass; virtual;
    function GetDisplayName: string; override;
    procedure ImageChanged(Sender: TObject); virtual;
    procedure SetDisplayName(const Value: string); override;
    procedure SetIndex(Value: Integer); override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property ImageRetrieval: TDIBImageRetrieval read FImageRetrieval write SetImageRetrieval default irInternal;
    property DIB: TMemoryDIB read GetDIB write SetDIB;
    property DisplayName;
    property OnTranslateImagePath: TDIBTranslateImagePathEvent read FOnTranslateImagePath write FOnTranslateImagePath;
  end;

  TDIBImages = class(TOwnedCollection)
  private
    { Private declarations }
    FOwner: TComponent;
    function GetItem(Index: Integer): TDIBImagesItem;
    procedure SetItem(Index: Integer; Value: TDIBImagesItem);
  protected
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); virtual;
    procedure ImageMoved(FromIndex, ToIndex: Integer); virtual;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TComponent; AClass: TDIBImagesItemClass);
    destructor Destroy; override;


    function Add: TDIBImagesItem;
    function AddTemplate(const GUID: string; const Index: Integer): TDIBImagesItem;
    function FindItemByName(AName: string): TDIBImagesItem;
    function ItemByName(AName: string): TDIBImagesItem;

    property Items[Index: Integer]: TDIBImagesItem read GetItem write SetItem; default;
  published
  end;

  TDIBImageLink = class(TPersistent)
  private
    FOwner: TComponent;
    FDIBImageList: TCustomDIBImageList;
    FDIBIndex: Integer;
    FOnImageChanged: TDIBOperationEvent;
    procedure UnlinkNotification;
    procedure SetDIBImageList(const Value: TCustomDIBImageList);
    procedure SetDIBImageIndex(const Value: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure ListChanged(Index: Integer; Operation: TDIBOperation); virtual;
  public
    constructor Create(AOwner: TComponent); virtual;
    destructor Destroy; override;

    function GetImage(var ResultPic: TMemoryDIB): Boolean;
    function Valid: Boolean;

    property OnImageChanged: TDIBOperationEvent read FOnImageChanged write FOnImageChanged;
  published
    property DIBImageList: TCustomDIBImageList read FDIBImageList write SetDIBImageList;
    property DIBIndex: Integer read FDIBIndex write SetDIBImageIndex;
  end;

  TCustomDIBImageList = class(TComponent)
  private
    { Private declarations }
    FDIBImages: TDIBImages;
    FLinkList: TList;
    FDuplicateDIB,
    FUniqueDIB: TMemoryDIB;
  protected
    { Protected declarations }
    procedure AddLink(Link: TDIBImageLink); virtual;
    function GetItemClass: TDIBImagesItemClass; dynamic;
    procedure ImageChanged(Sender: TObject; Index: Integer; Operation: TDIBOperation);
      virtual;
    procedure ImageMoved(FromIndex, ToIndex: Integer); virtual;
    procedure Loaded; override;
    procedure RemoveLink(Link: TDIBImageLink); virtual;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Get(Index: Integer): TMemoryDIB;
    function GetUnique(Index: Integer): TMemoryDIB;

    function GetImage(Index: Integer; var ResultPic: TMemoryDIB): Boolean;
    function ImageByName(DisplayName: string): TMemoryDIB;
    function IsIndexValid(Index: Integer): Boolean;

    property Image[Index: Integer]: TMemoryDIB read Get; default;
  published
    { Published declarations }
    property DIBImages: TDIBImages read FDIBImages write FDIBImages; 
  end;

  TDIBImageList = class(TCustomDIBImageList)
  published
  end;


implementation

type
  THackPropertyDIB = class(TMemoryDIB);

  { TDIBImagesItem }

constructor TDIBImagesItem.Create(Collection: TCollection);
begin
  inherited;
  FDIB := GetDIBClass.Create(1, 1);
  THackPropertyDIB(FDIB).OnChange := ImageChanged;
  FDisplayName := inherited GetDisplayName;
  FImportedFrom := '';
  FImageRetrieval := irInternal;
  FDIBLoaded := False;
end;

procedure TDIBImagesItem.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('TemplateFilename', ReadTemplateFilename,
    WriteTemplateFilename, (FImportedFrom <> ''));
end;

destructor TDIBImagesItem.Destroy;
var
  OldIndex: Integer;
  DIBImages: TDIBImages;
begin
  OldIndex := Self.Index;
  DIBImages := nil;
  if Collection <> nil then DIBImages := TDIBImages(Collection);
  FDIB.Free;
  inherited;

  if DIBImages <> nil then
    DIBImages.ImageChanged(OldIndex, doRemove);
end;

function TDIBImagesItem.GetDisplayName: string;
begin
  Result := FDisplayName;
end;

procedure TDIBImagesItem.ImageChanged(Sender: TObject);
begin
  if Collection <> nil then
    TDIBImages(Collection).ImageChanged(Self.Index, doChange);
end;

procedure TDIBImagesItem.ReadTemplateFilename(Reader: TReader);
begin
  FImportedFrom := Reader.ReadString;
end;

procedure TDIBImagesItem.SetDIB(const Value: TMemoryDIB);
begin
  FDIB.Assign(Value);
end;

procedure TDIBImagesItem.SetDisplayName(const Value: string);
begin
  FDisplayName := Value;
  inherited;
end;

procedure TDIBImagesItem.WriteTemplateFilename(Writer: TWriter);
begin
  Writer.WriteString(FImportedFrom);
end;

procedure TDIBImagesItem.SetIndex(Value: Integer);
var
  FromIndex: Integer;
begin
  FromIndex := Index;
  inherited;
  if Collection <> nil then
    TDIBImages(Collection).ImageMoved(FromIndex, Value);
end;

function TDIBImagesItem.GetDIB: TMemoryDIB;
begin
  Result := FDIB;
  if not FDIBLoaded then
    ImportImages;
end;

function TDIBImagesItem.GetDIBClass: TMemoryDIBClass;
begin
  Result := TMemoryDIB;
end;


procedure TDIBImagesItem.SetImageRetrieval(const Value: TDIBImageRetrieval);
begin
  FImageRetrieval := Value;
  FDIB.SaveImageData := (Value = irInternal);
end;

procedure TDIBImagesItem.ImportImages;
  function IncludeTrailingPathDelimiter(Path: string): string;
  begin
    if (Path = '') then
      Result := ''
    else
    begin
      if Path[Length(Path)] = '\' then
        Result := Path
      else
        Result := Path + '\';
    end;
  end;

  function GetFilename(const AFilename: string): string;
  var
    Path: string;
  begin
    Result := AFilename;
    if (Result <> '') and Assigned(FOnTranslateImagePath) then
    begin
      Path := ExtractFilePath(AFilename);
      FOnTranslateImagePath(Self, Path);
      if Path <> '' then
        Result := IncludeTrailingPathDelimiter(Path) + ExtractFilename(AFilename)
      else
        Result := ExtractFilename(AFilename);
    end;
  end;

var
  Filename: string;
begin
  if not FDIBLoaded then
  begin
    if ImageRetrieval = irInternal then
      FDIBLoaded := True
    else
    if FDIB.ImageFilename <> '' then
    try
      FDIB.BeginUpdate;
      Filename := GetFilename(FDIB.ImageFilename);
      FDIB.ImportPicture(Filename);
      if FDIB.MaskFilename <> '' then
      begin
        Filename := GetFilename(FDIB.MaskFilename);
        FDIB.ImportMask(Filename);
      end;
      FDIBLoaded := True;
    finally
      FDIB.EndUpdate;
    end;
  end;
end;

{ TDIBImages }

function TDIBImages.Add: TDIBImagesItem;
begin
  Result := TDIBImagesItem(inherited Add);
end;

function TDIBImages.AddTemplate(const GUID: string;
  const Index: Integer): TDIBImagesItem;
var
  I, Position: Integer;
  SearchString: string;
begin
  Position := -1;
  SearchString := GUID + ':' + IntToStr(Index);
  
  for I := 0 to Count - 1 do 
  begin
    if Items[I].FImportedFrom = SearchString then 
    begin
      Position := I;
      break;
    end;
  end;

  if Position > -1 then
    Result := Items[Position]
  else 
  begin
    Result := Add;
    Result.FImportedFrom := GUID + ':' + IntToStr(Index);
  end;
end;

constructor TDIBImages.Create(AOwner: TComponent; AClass: TDIBImagesItemClass);
begin
  inherited Create(AOwner, AClass);
  FOwner := AOwner;
end;

destructor TDIBImages.Destroy;
begin
  inherited;
end;

function TDIBImages.FindItemByName(AName: string): TDIBImagesItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if AnsiCompareText(Items[I].DisplayName, AName) = 0 then
    begin
      Result := Items[I];
      Break;
    end;
end;

function TDIBImages.GetItem(Index: Integer): TDIBImagesItem;
begin
  Result := TDIBImagesItem(inherited GetItem(Index));
end;

procedure TDIBImages.ImageChanged(Index: Integer; Operation: TDIBOperation);
begin
  if FOwner is TCustomDIBImageList then
    TCustomDIBImageList(FOwner).ImageChanged(Self, Index, Operation);
end;

procedure TDIBImages.ImageMoved(FromIndex, ToIndex: Integer);
begin
  if FOwner is TCustomDIBImageList then
    TCustomDIBImageList(FOwner).ImageMoved(FromIndex, ToIndex);
end;

function TDIBImages.ItemByName(AName: string): TDIBImagesItem;
begin
  Result := FindItemByName(AName);
  if Result = nil then
    raise EDIBImageListError.Create('Item ' + AName + ' not found');
end;

procedure TDIBImages.SetItem(Index: Integer; Value: TDIBImagesItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDIBImages.Update(Item: TCollectionItem);
begin
  inherited Update(Item);
end;

{ TCustomDIBImageList }

procedure TCustomDIBImageList.AddLink(Link: TDIBImageLink);
var
  Index: Integer;
begin
  if Link = nil then exit;
  if FLinkList.IndexOf(Link) < 0 then FLinkList.Add(Link);
  if DIBImages <> nil then
    for Index := 0 to DIBImages.Count - 1 do Link.ListChanged(Index, doChange);
end;

constructor TCustomDIBImageList.Create(AOwner: TComponent);
begin
  inherited;
  FDIBImages := TDIBImages.Create(Self, GetItemClass);
  FDuplicateDIB := TMemoryDIB.Create(1, 1);
  FUniqueDIB := TMemoryDIB.Create(1, 1);
  FLinkList := TList.Create;
end;

destructor TCustomDIBImageList.Destroy;
var
  X: Integer;
begin
  for X := FLinkList.Count - 1 downto 0 do
    TDIBImageLink(FLinkList[X]).UnlinkNotification;
  FDIBImages.Free;
  FLinkList.Free;
  FUniqueDIB.Free;
  FDuplicateDIB.Free;
  inherited;
end;

function TCustomDIBImageList.Get(Index: Integer): TMemoryDIB;
begin
  Result := FDuplicateDIB;
  Result.PointDataAt(DIBImages.Items[Index].DIB);
end;

function TCustomDIBImageList.GetUnique(Index: Integer): TMemoryDIB;
begin
  FUniqueDIB.Assign(DIBImages.Items[Index].DIB);
  Result := FUniqueDIB;
end;

procedure TCustomDIBImageList.ImageChanged(Sender: TObject; Index: Integer;
  Operation: TDIBOperation);
var
  X: Integer;
begin
  for X := 0 to FLinkList.Count - 1 do TDIBImageLink(FLinkList[X]).ListChanged(Index,
      Operation);
end;

procedure TCustomDIBImageList.ImageMoved(FromIndex, ToIndex: Integer);
var
  Index: Integer;
begin
  if FromIndex < ToIndex then
  begin
    for Index := 0 to FLinkList.Count - 1 do
      with TDIBImageLink(FLinkList[Index]) do
        if FDIBIndex = FromIndex then
          FDIBIndex := ToIndex
    else if (FromIndex < FDIBIndex) and (FDIBIndex <= ToIndex) then
      Dec(FDIBIndex);
  end
  else 
  begin
    for Index := 0 to FLinkList.Count - 1 do
      with TDIBImageLink(FLinkList[Index]) do
        if FDIBIndex = FromIndex then
          FDIBIndex := ToIndex
    else if (ToIndex <= FDIBIndex) and (FDIBIndex < FromIndex) then
      Inc(FDIBIndex);
  end;
end;

function TCustomDIBImageList.GetImage(Index: Integer;
  var ResultPic: TMemoryDIB): Boolean;
var
  TheDIB: TMemoryDIB;
begin
  Result := False;
  if Self = nil then exit;
  if (Index < 0) or (Index >= DIBImages.Count) then exit;
  TheDIB := DIBImages.Items[Index].DIB;
  if not TheDIB.Valid then exit;

  ResultPic := Get(Index);
  Result := True;
end;

function TCustomDIBImageList.IsIndexValid(Index: Integer): Boolean;
begin
  Result := False;
  if Self = nil then exit;
  if (Index < 0) or (Index >= DIBImages.Count) then exit;
  Result := True;
end;

procedure TCustomDIBImageList.RemoveLink(Link: TDIBImageLink);
var
  Index: Integer;
begin
  if Link = nil then exit;

  Index := FLinkList.IndexOf(Link);
  if Index >= 0 then 
  begin
    FLinkList.Delete(Index);
    //    if DIBImages <> nil then
    //      for Index := 0 to DIBImages.Count-1 do
    //        Link.ListChanged(Index, doRemove);
  end;
end;

function TCustomDIBImageList.ImageByName(DisplayName: string): TMemoryDIB;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to DIBImages.Count - 1 do
    if CompareText(DisplayName, DIBImages[I].DisplayName) = 0 then
    begin
      Result := DIBImages[I].DIB;
      Break;
    end;
end;

function TCustomDIBImageList.GetItemClass: TDIBImagesItemClass;
begin
  Result := TDIBImagesItem;
end;

procedure TCustomDIBImageList.Loaded;
var
  I: Integer;
begin
  inherited;
  for I := 0 to DIBImages.Count - 1 do
    if DIBImages[I].ImageRetrieval = irLoadOnStart then
      DIBImages[I].ImportImages;
end;

{ TDIBImageLink }

procedure TDIBImageLink.AssignTo(Dest: TPersistent);
begin
  if Dest is TDIBImageLink then with TDIBImageLink(Dest) do 
    begin
      DIBIndex := Self.DIBIndex;
      DIBImageList := Self.DIBImageList;
    end 
  else
    inherited;
end;

constructor TDIBImageLink.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FDIBIndex := -1;
end;

destructor TDIBImageLink.Destroy;
begin
  if DIBImageList <> nil then DIBImageList.RemoveLink(Self);
  inherited;
end;

function TDIBImageLink.GetImage(var ResultPic: TMemoryDIB): Boolean;
begin
  Result := False;
  if Self = nil then exit;
  //  if not Assigned(DIBImageList) then
  //    raise EDIBImageListError.Create('Image list has not been assigned');
  Result := DIBImageList.GetImage(DIBIndex, ResultPic);
end;

procedure TDIBImageLink.ListChanged(Index: Integer; Operation: TDIBOperation);
begin
  if (Operation = doChange) and (Index <> DIBIndex) then exit;
  if (Operation = doRemove) and (Index > DIBIndex) then exit;

  if FOwner <> nil then
    if csDestroying in FOwner.ComponentState then exit;

  //If removing a list item which is < this one, we don't need an update,
  //we just change our index number
  if Operation = doRemove then
    if Index < DIBIndex then 
    begin
      FDIBIndex := FDIBIndex - 1;
      exit;
    end;

  if Assigned(FOnImageChanged) then FOnImageChanged(Self, Index, Operation);
  if (Operation = doRemove) and (Index = DIBIndex) then FDIBIndex := -1;
end;

procedure TDIBImageLink.SetDIBImageIndex(const Value: Integer);
var
  OldIndex: Integer;
begin
  OldIndex := FDIBIndex;
  FDIBIndex := Value;
  if (OldIndex <> Value) then ListChanged(Value, doChange);
end;

procedure TDIBImageLink.SetDIBImageList(const Value: TCustomDIBImageList);
begin
  if FDIBImageList <> nil then FDIBImageList.RemoveLink(Self);
  FDIBImageList := Value;
  if FDIBImageList <> nil then FDIBImageList.AddLink(Self);
end;

procedure TDIBImageLink.UnlinkNotification;
begin
  DIBImageList := nil;
end;

function TDIBImageLink.Valid: Boolean;
begin
  Result := FDIBImageList.IsIndexValid(DIBIndex);
end;

end.
