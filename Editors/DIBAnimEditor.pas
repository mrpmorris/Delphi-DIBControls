unit DIBAnimEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBAnimEditor.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Property editor for animations.

Contributor(s):
Sylane - sylane@excite.com


Last Modified: March 02, 2001

You may retrieve the latest version of this file from my home page
located at  http://www.droopyeyes.com


Known Issues:
 Sylane: It's not possible to edit or rename the last node of the tree
         with dblclick or shortcut ! ! !

Data : 02 - Mar, 2001 :
By: Sylane - sylane@excite.com
Changes:
- Added a TDIBPalette component, otherwise the editor wouldn't work
	in 256 colors mode.
-	Added Shortcut for adding editing and deleting Animations/Frames
	Fixed a Bug occuring when Animations are deleted...
  	(The probleme may be much deeper but no more time available :)
- Added context menus to the TTreeView for convenience.


Date : 31 - Aug, 2000 :
By :support@droopyeyes.com
Changes
Made TxxxxxxEditor to TxxxxxxxProperty to comply with VCL standards.
Made sure all unit names start with DIB to avoice conflicts with other people's
component packs.

-----------------------------------------------------------------------------}


interface

{$I ..\OpenSource\dfs.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  TypInfo, cDIBAnimMgr, ExtCtrls, ComCtrls, Menus, cDIB,
  cDIBControl, cDIBImage, cDIBPanel, StdCtrls, cDIBFadeLabel, Spin,
  cDIBSlider, cDIBDial, cDIBImageList, cDIBPalette;

type
  TfmAnimEditor = class(TForm)
    dicRender: TDIBImageContainer;
    diRender: TDIBImage;
    pnlControl: TDIBImageContainer;
    btnOK: TButton;
    pnlProperties: TPanel;
    tvAnimations: TTreeView;
    dflOpacity: TDIBFadeLabel;
    edOpacity: TEdit;
    dflScale: TDIBFadeLabel;
    edScale: TEdit;
    dflAngle: TDIBFadeLabel;
    edAngle: TEdit;
    mnMain: TMainMenu;
    Item1: TMenuItem;
    N2: TMenuItem;
    miDelete: TMenuItem;
    DIBFadeLabel1: TDIBFadeLabel;
    cbImageList: TComboBox;
    Animation1: TMenuItem;
    Frame1: TMenuItem;
    miNewAnimation: TMenuItem;
    miRenameAnimation: TMenuItem;
    miNewFrame: TMenuItem;
    miEditFrame: TMenuItem;
    dibPalette: TDIBPalette;
    pmAnimPop: TPopupMenu;
    miAnimNewFrame: TMenuItem;
    miAnimDeleteAnim: TMenuItem;
    miAnimRename: TMenuItem;
    pmFramePop: TPopupMenu;
    ChoseImage1: TMenuItem;
    DeleteFrame1: TMenuItem;
    pmBackPop: TPopupMenu;
    miBackNewAnim: TMenuItem;
    udOpacity: TUpDown;
    udScale: TUpDown;
    udAngle: TUpDown;
    procedure miDeleteClick(Sender: TObject);
    procedure tvAnimationsChange(Sender: TObject; Node: TTreeNode);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure edOpacityChange(Sender: TObject);
    procedure edScaleChange(Sender: TObject);
    procedure edAngleChange(Sender: TObject);
    procedure Item1Click(Sender: TObject);
    procedure miRenameAnimationClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbImageListChange(Sender: TObject);
    procedure miNewAnimationClick(Sender: TObject);
    procedure miNewFrameClick(Sender: TObject);
    procedure miEditFrameClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tvAnimationsDblClick(Sender: TObject);
    procedure tvAnimationsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tvAnimationsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure tvAnimationsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure tvAnimationsDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
  private
    { Private declarations }
    {$IFDEF DFS_NO_DSGNINTF}
    Designer: IDesigner;
    {$ELSE}
    Designer: IFormDesigner;
    {$ENDIF}
    FAnimations: TDIBAnimMgrList;
    FInternalUpdate: Boolean;

    procedure AddImageListItem(const S: string);
    procedure SetAnimations(const Value: TDIBAnimMgrList);
    procedure SetData;
    procedure UpdateNames;
  protected
  public
    { Public declarations }
    procedure UpdateDisplay;

    property Animations: TDIBAnimMgrList read FAnimations write SetAnimations;
  end;

  TDIBAnimMgrListProperty = class(TClassProperty)
  private
  protected
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

  TDIBFrameListProperty = class(TClassProperty)
  private
  protected
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
  end;

var
  fmAnimEditor: TfmAnimEditor;

implementation

uses 
  DIBImageIndexEditor;

{$R *.DFM}

{ TDIBAnimMgrListProperty }

procedure TDIBAnimMgrListProperty.Edit;
begin
  fmAnimEditor := TfmAnimEditor.Create(Application);

  with fmAnimEditor do
    try
      Designer := Self.Designer;
      Animations := TDIBAnimMgrList(Self.GetOrdValue);
      UpdateDisplay;
      ShowModal;
    finally
      fmAnimEditor.Release;
      fmAnimEditor := nil;
    end;
end;

function TDIBAnimMgrListProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

function TDIBAnimMgrListProperty.GetValue: string;
begin
  Result := '(Animations)';
end;

{ TDIBFrameListProperty }

procedure TDIBFrameListProperty.Edit;
begin
end;

function TDIBFrameListProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly];
end;

function TDIBFrameListProperty.GetValue: string;
begin
  Result := 'USE EDITOR';
end;

{ TfmAnimEditor }

procedure TfmAnimEditor.SetAnimations(const Value: TDIBAnimMgrList);
begin
  FAnimations := Value;
end;

procedure TfmAnimEditor.UpdateDisplay;
var
  Main, Child: Integer;
  Item: TTreeNode;
begin
  tvAnimations.Items.Clear;
  for Main := 0 to FAnimations.Count - 1 do with FAnimations[Main].Animation do 
    begin
      Item := tvAnimations.Items.AddObject(nil, Name, FAnimations[Main].Animation);
      for Child := 0 to Frames.Count - 1 do
        tvAnimations.Items.AddChildObject(Item, Frames[Child].DisplayName, Frames[Child]);
    end;
end;

procedure TfmAnimEditor.miDeleteClick(Sender: TObject);
var
  NeedNameUpdate: Boolean;
  {Sylane 2/03/2001}
  lIndex: Integer;
  {End Sylane 2/03/2001}
begin
  if tvAnimations.Selected = nil then Exit;
  NeedNameUpdate := TObject(tvAnimations.Selected.Data) is TDIBFrameItem;
  {Sylane 2/03/2001}
  //  TObject(tvAnimations.Selected.Data).Free;
  if tvAnimations.Selected.Parent = nil then
  begin
    for lIndex := 0 to (fAnimations.Count - 1) do
      if fAnimations[lIndex].Animation = TDIBAnimation(tvAnimations.Selected.Data) then
      begin
        fAnimations.Delete(lIndex);
        break;
      end;
  end
  else
    TObject(tvAnimations.Selected.Data).Free;
  {End Sylane 2/03/2001}
  tvAnimations.Items.Delete(tvAnimations.Selected);

  if NeedNameUpdate then UpdateNames;
end;

procedure TfmAnimEditor.tvAnimationsChange(Sender: TObject;
  Node: TTreeNode);
var
  Animation: TDIBAnimation;
begin
  if tvAnimations.Selected = nil then exit;

  if TObject(Node.Data) is TDIBFrameItem then with TDIBFrameItem(Node.Data) do 
    begin
      FInternalUpdate := True;
      try
        cbImageList.Enabled := False;
        cbImageList.ItemIndex := -1;
        diRender.IndexMain.Assign(IndexImage);
        udOpacity.Position := Opacity;
        udScale.Position := Trunc(Scale);
        udAngle.Position := Trunc(Angle);
      finally
        FInternalUpdate := False;
      end;
    end 
  else 
  begin
    Animation := TDIBAnimation(TObject(tvAnimations.Selected.Data));
    cbImageList.Enabled := True;
    cbImageList.ItemIndex :=
      cbImageList.Items.IndexOf(Designer.GetComponentName(TComponent(Animation.DIBImageList)));
    diRender.IndexMain.DIBIndex := -1;
  end;
end;

procedure TfmAnimEditor.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfmAnimEditor.FormDestroy(Sender: TObject);
begin
  fmAnimEditor := nil;
end;

procedure TfmAnimEditor.edOpacityChange(Sender: TObject);
begin
  diRender.Opacity := udOpacity.Position;
  SetData;
end;

procedure TfmAnimEditor.edScaleChange(Sender: TObject);
begin
  diRender.Scale := udScale.Position;
  SetData;
end;

procedure TfmAnimEditor.edAngleChange(Sender: TObject);
begin
  diRender.Angle := udAngle.Position;
  SetData;
end;

procedure TfmAnimEditor.SetData;
begin
  if FInternalUpdate then Exit;
  if tvAnimations.Selected = nil then Exit;
  if TObject(tvAnimations.Selected.Data) is TDIBFrameItem then
    with TDIBFrameItem(tvAnimations.Selected.Data) do 
    begin
      Opacity := udOpacity.Position;
      Scale := udScale.Position;
      Angle := udAngle.Position;
    end;
end;

procedure TfmAnimEditor.Item1Click(Sender: TObject);
begin
  miNewFrame.Enabled := (tvAnimations.Selected <> nil);
  miEditFrame.Enabled := (tvAnimations.Selected <> nil) and
    (TObject(tvAnimations.Selected.Data) is TDIBFrameItem);
  miRenameAnimation.Enabled := (tvAnimations.Selected <> nil) and
    (TObject(tvAnimations.Selected.Data) is TDIBAnimation);
  miDelete.Enabled := (tvAnimations.Selected <> nil);
end;

procedure TfmAnimEditor.miRenameAnimationClick(Sender: TObject);
var
  NewName: string;
  Animation: TDIBAnimation;
begin
  if tvAnimations.Selected=nil then Exit;
  Animation := TDIBAnimation(TObject(tvAnimations.Selected.Data));
  NewName := InputBox('Enter a new animation name', 'Name', Animation.Name);
  if (NewName <> '') then 
  begin
    Animation.Name := NewName;
    tvAnimations.Selected.Text := NewName;
  end;
end;

procedure TfmAnimEditor.UpdateNames;
var
  X: Integer;
  Item: TObject;
begin
  with tvAnimations do
    for X := 0 to Items.Count - 1 do 
    begin
      Item := TObject(Items[X].Data);
      if Item is TDIBAnimation then
        Items[X].Text := TDIBAnimation(Item).Name
      else if Item is TDIBFrameItem then
        Items[X].Text := TDIBFrameItem(Item).DisplayName;
    end;
end;

procedure TfmAnimEditor.AddImageListItem(const S: string);
var
  List: TComponent;
begin
  List := Designer.GetComponent(S);
  cbImageList.Items.AddObject(S, List);
end;

procedure TfmAnimEditor.FormShow(Sender: TObject);
var
  TypeData: PTypeData;
begin
  TypeData := GetTypeData(TypeInfo(TCustomDIBImageList));
  Designer.GetComponentNames(TypeData, AddImageListItem);
  cbImageList.Sorted := True;
end;

procedure TfmAnimEditor.cbImageListChange(Sender: TObject);
var
  Animation: TDIBAnimation;
begin
  if tvAnimations.Selected = nil then 
  begin
    cbImageList.Enabled := False;
    Exit;
  end;

  if TObject(tvAnimations.Selected.Data) is TDIBAnimation then 
  begin
    Animation := TDIBAnimation(TObject(tvAnimations.Selected.Data));
    Animation.DIBImageList := TCustomDIBImageList(cbImageList.Items.Objects
      [cbImageList.ItemIndex]);
  end;
end;

procedure TfmAnimEditor.miNewAnimationClick(Sender: TObject);
var
  NewNode: TTreeNode;
begin
  with FAnimations.Add do 
  begin
    {$IFDEF DFS_NO_DSGNINTF}
    Animation :=
      TDIBAnimation(Designer.CreateComponent(TDIBAnimation, Designer.GetRoot, 0, 0, 32, 32));
    {$ELSE}
    Animation :=
      TDIBAnimation(Designer.CreateComponent(TDIBAnimation, Designer.Form, 0, 0, 32, 32));
    {$ENDIF}
    NewNode := tvAnimations.Items.AddObject(nil, Animation.Name, Animation);
    tvAnimations.Selected := NewNode;
    Designer.SelectComponent(FAnimations.Manager);
  end;
end;

procedure TfmAnimEditor.miNewFrameClick(Sender: TObject);
var
  CurrentAnim: TDIBAnimation;
  NewFrame: TDIBFrameItem;
  CurrentNode, NewNode: TTreeNode;
begin
  FInternalUpdate := True;
  try
    CurrentNode := tvAnimations.Selected;
    if CurrentNode.Parent <> nil then CurrentNode := CurrentNode.Parent;
    CurrentAnim := TDIBAnimation(CurrentNode.Data);
    NewFrame := CurrentAnim.Frames.Add;
    NewNode := tvAnimations.Items.AddChildObject(CurrentNode,
      NewFrame.DisplayName, NewFrame);
    tvAnimations.Selected := NewNode;
  finally
    FInternalUpdate := False;
  end;
end;

procedure TfmAnimEditor.miEditFrameClick(Sender: TObject);
var
  FrameItem: TDIBFrameItem;
begin
  FrameItem := TDIBFrameItem(TObject(tvAnimations.Selected.Data));
  if FrameItem.IndexImage.DIBImageList = nil then 
  begin
    ShowMessage('No image list has been set.');
    Exit;
  end;

  with TfmImageIndexEditor.Create(Application) do
    try
      DIBImageLink := FrameItem.IndexImage;
      ShowModal;
      {Sylane 2/03/2001}
      tvAnimationsChange(tvAnimations, tvAnimations.Selected);
      {End Sylane 2/03/2001}
    finally
      Free;
    end;
end;

procedure TfmAnimEditor.FormCreate(Sender: TObject);
begin
  FInternalUpdate := False;
end;

procedure TfmAnimEditor.tvAnimationsDblClick(Sender: TObject);
begin
  if tvAnimations.Selected = nil then Exit;
  if TObject(tvAnimations.Selected.Data) is TDIBAnimation then
    miRenameAnimation.Click
  else
    miEditFrame.Click;
end;

{Sylane 2/03/2001}
procedure TfmAnimEditor.tvAnimationsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      if TObject(tvAnimations.Selected.Data) is TDIBFrameItem then
        miEditFrame.Click
      else
        miRenameAnimation.Click;
      VK_INSERT:
      if ssShift in Shift then
        miNewAnimation.Click
      else
        miNewFrame.Click;
      VK_DELETE:
      miDelete.Click;
  end;
end;


procedure TfmAnimEditor.tvAnimationsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  lNode: TTreeNode;
  lPoint: TPoint;
begin
  if Button <> mbRight then
    Exit;

  lNode := tvAnimations.GetNodeAt(X, Y);
  lPoint := tvAnimations.ClientToScreen(Point(X, Y));

  if lNode = nil then
    pmBackPop.Popup(lPoint.X, lPoint.Y)
  else
  begin
    tvAnimations.Selected := lNode;
    if lNode.Parent = nil then
      pmAnimPop.Popup(lPoint.X, lPoint.Y)
    else
      pmFramePop.Popup(lPoint.X, lPoint.Y);
  end;
end;
{End Sylane 2/03/2001}

procedure TfmAnimEditor.tvAnimationsDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var SourceNode,Dest_Node   : TTreeNode;
begin
 SourceNode:=(Source As TTreeView).Selected;
 Dest_Node:=(Sender As TTreeView).GetNodeAt(X,Y);
 if  SourceNode.Level=Dest_Node.Level then
  if SourceNode.AbsoluteIndex < Dest_Node.AbsoluteIndex then
   if Dest_Node.getNextSibling <> Nil
    then SourceNode.MoveTo(Dest_Node.getNextSibling,naInsert)
    else SourceNode.MoveTo(Dest_Node,naInsert)
   else SourceNode.MoveTo(Dest_Node,naInsert);
end;

procedure TfmAnimEditor.tvAnimationsDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var SourceNode,Dest_Node   : TTreeNode;
begin
 Accept:=False;
 if (Source<>nil) and (Sender<>nil) then
  if Source is TTreeView then
   if (Source As TTreeView)<> nil then
    begin
     SourceNode:=(Source As TTreeView).Selected;
     if SourceNode = nil then Exit;
     Dest_Node:=(Sender As TTreeView).GetNodeAt(X,Y);
     if Dest_Node=nil then Exit;
     if SourceNode.Level=Dest_Node.Level then
      if SourceNode.Parent=Dest_Node.Parent then Accept := True;
    end;
end;

end.
