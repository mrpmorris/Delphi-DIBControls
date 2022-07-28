unit cDIBPanel;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBPanl.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
The base class for DIBContainers.  All DIB components must be parented by a DIBContainer
of some sort.

Contributor(s):
azzaazza69@hotmail.com - www.azzasoft.com
RiceBall <riceb@nether.net>
Dave Parkinson 

Last Modified: April 9, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
To be updated !
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   December 22, 2000
By:     Azza
Change: WMPaint didn't set up the PaintRect area for a foreign device context
        (ie. anything other than itself).

Date:   May 2, 2001
By:     Peter Morris
Change: Added DIBBorder property

Date:   May 2, 2001
By:     Peter Morris
Change: Added BeforePaint and AfterPaint;

Date:   June 24, 2001
By:     RiceBall
Change: Overrode AlignControls to take into account DIBBorder

Date:   June 24, 2001
By:     Peter Morris
Change: Added a property to determine if the border is draw over or under its controls

Date:   August 24, 2001
By:     Peter Morris
Change: Changed BeforePaint and AfterPaint to DoBeforePaint and DoAfterPaint,
        added BeforePaint and AfterPaint events

Date:   April 9, 2003
By:     Dave Parkinson
Change: Fixed an AV which occurred when in 256 colours and no palette was provided.

Date:   September 19, 2003
By:     Paul Stohr
Change: Fixed issues with multi-monitor support

Date:   February 29, 2004
By:     Peter Morris
Change: Removed legacy code which repainted the whole container if the parent form
        was not the windows active form.  This causes a whole repaint when the
        form was used as part of a Cubase SX plugin, subsequently it used a lot
        of CPU.

Date:   August 28, 2004
By:     Peter Morris
Change: Removed unnecessary call to DefaultHandler in WM_PAINT which was causing
        artifacts on the canvas when another window was dragged over the parent form.

Date:   June 27, 2005
By:     Peter Morris
Change: Changed Before/After paint events to TNotifyEvent.  Since the DIB property
        is now public there is no need to pass an abstract DIB class as a parameter

Date:   June 27, 2005
By:     Peter Morris
Change: Fixed a Range Check Error in TCustomDIBContainer.PaintControls

*)


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, cDIB, JPeg, cDIBImageList, cDIBPalette, cDIBBorder;

type
  TBorderDrawPosition = (bdOverControls, bdUnderControls);

  TCustomDIBContainer = class(TCustomPanel)
  private
    { Private declarations }
    FOnActiveControlChange: TNotifyEvent;
    FBeforePaint: TNotifyEvent;
    FAfterPaint: TNotifyEvent;
    FTabbing: Boolean;
    FChangingFocus: Boolean;
    FAlteredRect: Boolean;
    FActiveControl: TControl;
    FTabList: TList;
    FChildDIB: TWinDIB;
    FDIB: TWinDIB;
    FDIBBorder: TDIBBorder;
    FUpdateRect: TRect;
    FPalette: TDIBPalette;
    FBorderDrawPosition: TBorderDrawPosition;

    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FocusChanged;
    procedure CNChar(var Message: TWMKey); message CN_Char;
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KeyDown;
    procedure CNKeyUp(var Message: TWMKeyUp); message CN_KeyUp;
    procedure WMEraseBkGnd(var Message: TMessage); message WM_EraseBkGnd;
    procedure WMGetDlgCode(var Message: TMessage); message WM_GetDlgCode;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMSetCursor(var Message: TMessage); message WM_SETCURSOR;
    procedure SetBorderDrawPosition(const Value: TBorderDrawPosition);
  protected
    { Protected declarations }
    //    procedure AlignControls(AControl: TControl; var Rect: TRect);override;
    procedure AdjustClientRect(var Rect: TRect); override;
    function ChildWantsKey(var Message: TWMKey): Boolean;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoAfterPaint; virtual;
    procedure DoBeforePaint; virtual;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoTabFixups; virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PaintControls(DC: HDC; First: TControl);
    procedure PaintHandler(var Message: TWMPaint);
    procedure SetDIBBorder(const Value: TDIBBorder); virtual;
    procedure WndProc(var Message: TMessage); override;

    //Focus routines
    function DIBGetFirst: TControl;
    function DIBGetPrior: TControl;
    function DIBGetNext: TControl;
    function DIBGetLast: TControl;
    function DIBGetIndex(aControl: TControl): Integer;

    function DIBSelectNext: Boolean;
    function DIBSelectPrior: Boolean;

    property AfterPaint: TNotifyEvent read FAfterPaint write FAfterPaint;
    property BeforePaint: TNotifyEvent read FBeforePaint write FBeforePaint;
    property BorderDrawPosition: TBorderDrawPosition 
      read FBorderDrawPosition write SetBorderDrawPosition;
    property ChildDIB: TWinDIB read FChildDIB;
    property DIBBorder: TDIBBorder read FDIBBorder write SetDIBBorder;
    property OnActiveControlChange: TNotifyEvent 
      read FOnActiveControlChange write FOnActiveControlChange;

  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    //Focus routines
    function DIBGetTabOrder(aControl: TControl): TTabOrder;
    procedure DIBSetTabOrder(aControl: TControl; NewIndex: TTabOrder);

    function DIBFindNext(aControl: TControl; aForward: Boolean): TControl;
    procedure DIBFocusControl(aControl: TControl); virtual;

    //Std
    procedure Paint; override;
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: Integer); override;

    property ActiveControl: TControl read FActiveControl write DIBFocusControl;
    property DIB: TWinDIB read FDIB;
    property UpdateRect: TRect read FUpdateRect;
  published
    { Published declarations }
  end;

  TDIBContainer = class(TCustomDIBContainer)
  private
  protected
  public
  published
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
    property DockSite;
    property DIBBorder;
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

  TTileMethod = (tmCenter, tmTile);
  TCustomDIBImageContainer = class(TCustomDIBContainer)
  private
    FIndexImage: TDIBImageLink;
    FTileMethod: TTileMethod;

    procedure DoImageChanged(Sender: TObject; ID: Integer; Operation: TDIBOperation);
    function GetDIBImageList: TCustomDIBImageList;
    procedure SetDIBImageList(const Value: TCustomDIBImageList);
    procedure SetTileMethod(const Value: TTileMethod);
  protected
    procedure ImageChanged(ID: Integer; Operation: TDIBOperation); virtual;
    procedure WndProc(var Message: TMessage); override;

    property DIBImageList: TCustomDIBImageList read GetDIBImageList write SetDIBImageList;
    property IndexImage: TDIBImageLink read FIndexImage write FIndexImage;
    property TileMethod: TTileMethod read FTileMethod write SetTileMethod;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Paint; override;
  published
  end;

  TDIBImageContainer = class(TCustomDIBImageContainer)
  published
    //New events / properties
    property DIBImageList;
    property IndexImage;
    property TileMethod;

    property OnActiveControlChange;

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
    property DockSite;
    property DIBBorder;
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

implementation

uses
  cDIBControl;

type
  EDIBContainerError = class(Exception);
  THackControl = class(TControl);
  THackWinControl = class(TWinControl);
  THackDIBControl = class(TCustomDIBControl);
  TBlitType = (btNormal, btNeedPalette, btLookup);

  { TCustomDIBContainer }

procedure TCustomDIBContainer.DoAfterPaint;
begin
  if BorderDrawPosition = bdOverControls then
    if DIBBorder <> nil then DIBBorder.DrawTo(DIB, ClientRect);
  if Assigned(FAfterPaint) then FAfterPaint(Self);
end;

(*
procedure TCustomDIBContainer.AlignControls(AControl: TControl;
  var Rect: TRect);
begin
  if DIBBorder <> nil then with DIBBorder do
  begin
    Rect.Top := Rect.Top + BorderTop.Size;
    Rect.Bottom := Rect.Bottom - BorderBottom.Size;
    Rect.Left := Rect.Left + BorderLeft.Size;
    Rect.Right := Rect.Right - BorderRight.Size;
  end;
  inherited;
end;
*)

procedure TCustomDIBContainer.DoBeforePaint;
begin
  if Assigned(FBeforePaint) then FBeforePaint(Self);
end;

function TCustomDIBContainer.ChildWantsKey(var Message: TWMKey): Boolean;
var
  DlgResult: Integer;
  Mask: Integer;
begin
  Result := False;
  if FActiveControl <> nil then with THackDIBControl(FActiveControl) do
    begin
      Message.Result := 1;
      if IsMenuKey(Message) then Exit;
      if not (csDesigning in ComponentState) then with Message do
        begin
          if Perform(CM_CHILDKEY, CharCode, Integer(Self)) <> 0 then exit;
          Mask := 0;
          case CharCode of
            VK_TAB:
              Mask := DLGC_WANTTAB;
            VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN:
              Mask := DLGC_WANTARROWS;
            VK_RETURN, VK_EXECUTE, VK_ESCAPE, VK_CANCEL:
              Mask := DLGC_WANTALLKEYS;
          end;
          if Mask <> 0 then 
          begin
            DlgResult := Perform(WM_GETDLGCODE, 0, 0);
            if DlgResult <> DLGC_WantAllKeys then 
            begin
              if Mask and DlgResult = 0 then exit
            end;
          end;
        end;
      Result := True;
    end;
end;

procedure TCustomDIBContainer.CMFocusChanged(var Message: TCMFocusChanged);
var
  KS: TKeyboardState;
begin
  if Message.Sender <> nil then
    if TWinControl(Message.Sender).Parent = Self then 
    begin
      DIBFocusControl(Message.Sender);
      exit;
    end;

  if (TWinControl(Message.Sender) = Self) then 
  begin
    if DIBGetLast is TWincontrol then 
    begin
      GetKeyboardState(KS);
      if KS[VK_SHIFT] and 128 = 128 then DIBSelectPrior;
    end;
  end 
  else
    DIBFocusControl(nil);
end;

procedure TCustomDIBContainer.CNChar(var Message: TWMKey);
begin
  if ChildWantsKey(Message) then 
  begin
    Message.Result := FActiveControl.Perform(WM_Char, TMessage(Message).WParam,
      TMessage(Message).LParam);
    exit;
  end;
end;

procedure TCustomDIBContainer.CNKeyDown(var Message: TWMKeyDown);
var
  KS: TKeyboardState;
  Handled: Boolean;
begin
  if ChildWantsKey(Message) then 
  begin
    Message.Result := FActiveControl.Perform(WM_KeyDown, TMessage(Message).WParam,
      TMessage(Message).LParam);
    exit;
  end;

  if (Screen.ActiveControl = DIBGetLast) then
  begin
    inherited;
    exit;
  end;

  Handled := False;
  if Message.CharCode = VK_TAB then
    try
      FTabbing := True;
      GetKeyboardState(KS);
      if KS[VK_SHIFT] and 128 = 128 then
        Handled := DIBSelectPrior
      else
        Handled := DIBSelectNext
      finally
        FTabbing := False;
    end;

  if not Handled then 
  begin
    inherited;
    if Screen.ActiveControl = Self then DoEnter;
  end;
end;

procedure TCustomDIBContainer.CNKeyUp(var Message: TWMKeyUp);
begin
  if ChildWantsKey(Message) then 
  begin
    Message.Result := FActiveControl.Perform(WM_KeyUp, TMessage(Message).WParam,
      TMessage(Message).LParam);
    exit;
  end;
end;

constructor TCustomDIBContainer.Create(AOwner: TComponent);
begin
  inherited;
  FTabList := TList.Create;
  ControlStyle := ControlStyle + [csAcceptsControls];
  FDIB := TWinDib.Create;
  FChildDIB := TWinDIB.Create;
  DoubleBuffered := True;
  TabStop := False;
  FActiveControl := nil;
  FChangingFocus := False;
  FTabbing := False;
  BorderWidth := 0;
  BorderStyle := bsNone;
  BevelOuter := bvNone;
  FPalette := nil;
  FAlteredRect := False;
  BorderStyle := bsNone;
end;

procedure TCustomDIBContainer.CreateParams(var Params: TCreateParams);
begin
  inherited;
end;

destructor TCustomDIBContainer.Destroy;
begin
  FTabList.Free;
  FChildDIB.Free;
  FDIB.Free;
  inherited;
end;

function TCustomDIBContainer.DIBFindNext(aControl: TControl;
  aForward: Boolean): TControl;
var
  I, StartIndex: Integer;
begin
  Result := nil;

  if FTabList.Count > 0 then 
  begin
    StartIndex := FTabList.IndexOf(aControl);
    if StartIndex = -1 then
      if aForward then
        StartIndex := FTabList.Count - 1
      else
        StartIndex := 0;

    I := StartIndex;
    repeat
      if aForward then 
      begin
        Inc(I);
        if I = FTabList.Count then I := 0;
      end 
      else 
      begin
        if I = 0 then I := FTabList.Count;
        Dec(I);
      end;

      aControl := FTabList[I];
      if aControl.Enabled then Result := aControl;
    until (Result <> nil) or (I = StartIndex);
  end;
end;

procedure TCustomDIBContainer.DIBFocusControl(aControl: TControl);
begin
  if FChangingFocus then exit;
  FChangingFocus := True;
  try
    if aControl <> FActiveControl then
      if FActiveControl <> nil then
        FActiveControl.Perform(WM_KillFocus, 0, 0);

    FActiveControl := aControl;
    if aControl <> nil then FActiveControl.Perform(WM_SetFocus, 0, 0);
    if Assigned(FOnActiveControlChange) then
      FOnActiveControlChange(Self);
  finally
    FChangingFocus := False;
  end;
end;

function TCustomDIBContainer.DIBGetFirst: TControl;
begin
  Result := nil;
  if FTabList.Count > 0 then Result := TControl(FTabList[0]);

  if Result = nil then 
  begin
    Result := FindNextControl(Self, True, True, True);
    if Result <> nil then
      if Result.Parent <> self then
        Result := nil;
  end;
end;

function TCustomDIBContainer.DIBGetIndex(aControl: TControl): Integer;
begin
  Result := -1;
  if aControl is TWinControl then 
  begin
    if aControl.Parent = Self then
      Result := TWinControl(aControl).TabOrder + ControlCount;
  end 
  else 
  begin
    Result := FTabList.IndexOf(aControl);
  end;
end;

function TCustomDIBContainer.DIBGetLast: TControl;
var
  OrderList: TList;
begin
  Result := nil;
  OrderList := TList.Create;
  try
    GetTabOrderList(OrderList);
    if OrderList.Count > 0 then
      Result := OrderList[OrderList.Count - 1]
    else if FTabList.Count > 0 then
      Result := FTabList[FTabList.Count - 1];
  finally
    OrderList.Free;
  end;
end;

function TCustomDIBContainer.DIBGetNext: TControl;
begin
  Result := nil;
  if not (FActiveControl is TWinControl) then 
  begin
    Result := DIBFindNext(FActiveControl, True);
    if DIBGetIndex(Result) < DIBGetIndex(FActiveControl) then Result := nil;
  end;

  if (FActiveControl is TWinControl) or (Result = nil) then 
  begin
    if Result = nil then
      Result := FindNextControl(Self, True, True, True)
    else
      Result := FindNextControl(TWinControl(FActiveControl), True, True, True);
    if Result <> nil then
      if (Result.Parent <> self) or (DIBGetIndex(Result) < DIBGetIndex(FActiveControl)) then
        Result := nil;
  end;

  if DIBGetIndex(Result) < DIBGetIndex(FActiveControl) then Result := nil;
end;

function TCustomDIBContainer.DIBGetPrior: TControl;
begin
  Result := nil;
  if (FActiveControl is TWinControl) or (Result = nil) then 
  begin
    //Look backwards
    Result := FindNextControl(TWinControl(FActiveControl), False, True, True);
    if Result <> nil then
      if (Result.Parent <> self) then Result := nil;
  end;

  if (DIBGetIndex(Result) > DIBGetIndex(FActiveControl)) or
    (DIBGetIndex(Result) = -1) then Result := nil;

  if not (FActiveControl is TWinControl) or (Result = nil) then 
  begin
    //Look backwards
    Result := DIBFindNext(FActiveControl, False);
    if (DIBGetIndex(Result) > DIBGetIndex(FActiveControl)) or
      (DIBGetIndex(Result) = -1) then Result := nil;
  end;

  if (DIBGetIndex(Result) > DIBGetIndex(FActiveControl)) or
    (DIBGetIndex(Result) = -1) then Result := nil;
end;

function TCustomDIBContainer.DIBGetTabOrder(aControl: TControl): TTabOrder;
begin
  Result := FTabList.IndexOf(aControl);
end;

function TCustomDIBContainer.DIBSelectNext: Boolean;
var
  NewControl, OldControl: TControl;
begin
  Result := False;
  OldControl := FActiveControl;

  NewControl := DIBGetNext;


  if NewControl <> nil then
    if DIBGetIndex(NewControl) > DIBGetIndex(OldControl) then
      Result := True;

  ActiveControl := NewControl;
end;

function TCustomDIBContainer.DIBSelectPrior: Boolean;
var
  NewControl, OldControl: TControl;
begin
  Result := False;
  OldControl := FActiveControl;

  NewControl := DIBGetPrior;


  if NewControl <> nil then
    if DIBGetIndex(NewControl) < DIBGetIndex(OldControl) then
      if DIBGetIndex(NewControl) <> -1 then
        Result := True;

  ActiveControl := NewControl;
end;

procedure TCustomDIBContainer.DIBSetTabOrder(aControl: TControl;
  NewIndex: TTabOrder);
var
  OldIndex: TTabOrder;
begin
  if aControl = nil then exit;
  OldIndex := FTabList.IndexOf(aControl);
  if OldIndex = NewIndex then exit;

  if (OldIndex >= 0) then FTabList.Delete(OldIndex);
  if NewIndex >= FTabList.Count then
    FTabList.Add(aControl)
  else if NewIndex >= 0 then
    FTabList.Insert(NewIndex, aControl);
  TabStop := FTabList.Count > 0;
end;

procedure TCustomDIBContainer.DoEnter;
var
  KS: TKeyboardState;
  NextControl: TControl;
begin
  if FActiveControl = nil then
    if FTabList.Count > 0 then 
    begin
      GetKeyboardState(KS);
      if (KS[VK_SHIFT] and 128) = 128 then
        NextControl := DIBGetLast
      else
        NextControl := DIBGetFirst;

      DIBFocusControl(NextControl);
      if Assigned(OnEnter) then OnEnter(Self);
    end 
    else
      inherited;
end;

procedure TCustomDIBContainer.DoExit;
begin
  DIBFocusControl(nil);
  inherited;
end;

procedure TCustomDIBContainer.DoTabFixups;
var
  List: array of Pointer;
  CC, X: Integer;
begin
  CC := ControlCount;
  SetLength(List, CC);
  for X := 0 to CC - 1 do List[X] := nil;
  for X := 0 to CC - 1 do
    if Controls[X] is TCustomDIBControl then
      with THackDIBControl(Controls[X]) do
        if FTabOrder <> -1 then
          if FTabOrder < CC then
            List[FTabOrder] := Controls[X]
      else 
      begin
        CC := FTabOrder + 1;
    SetLength(List, FTabOrder);
    List[FTabOrder] := Controls[X];
  end;

  for X := 0 to CC - 1 do
    if List[X] <> nil then DIBSetTabOrder(List[X], X);
end;

procedure TCustomDIBContainer.Loaded;
//var
//  R: TRect;
begin
  inherited;
  FDIB.Resize(Width, Height);
  DoTabFixups;
  //Following two lines cause problems with frames, why are they needed anyway?
//  R := ClientRect;
//  AlignControls(nil, R);
end;

procedure TCustomDIBContainer.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (AComponent = self) or (csDestroying in ComponentState) then exit;

  if aComponent is TDIBPalette then 
  begin
    if Operation = opInsert then
      FPalette := TDIBPalette(AComponent);
    if (Operation = opRemove) and (FPalette = AComponent) then
      FPalette := nil;
  end;
  if (Operation = opRemove) then
  begin
    if AComponent is TControl then DIBSetTabOrder(TControl(aComponent), - 1);
    if AComponent = DIBBorder then DIBBorder := nil;
  end;
end;

procedure TCustomDIBContainer.Paint;
begin
  if (FUpdateRect.Left = 0) and (FUpdateRect.Top = 0) and
    (FUpdateRect.Right = Width) and (FUpdateRect.Bottom = Height) then
    FDIB.QuickFill(ColorToRGB(Self.Color))
  else
    with FUpdateRect do
      FDIB.QuickFillRect(ColorToRGB(Self.Color), Left, Top, Right - Left, Bottom - Top);
end;

procedure TCustomDIBContainer.PaintControls(DC: HDC; First: TControl);
var
  CurrentControlIndex, FindControlIndex, SaveIndex: Integer;
  CurrentControl: TControl;
  FrameBrush: HBRUSH;
  D: TRect;
  CurrentClipRect: TRect;
begin
  if BorderDrawPosition = bdUnderControls then
    if DIBBorder <> nil then
      DIBBorder.DrawTo(DIB, ClientRect);
  if DockSite and UseDockManager and (DockManager <> nil) then
    DockManager.PaintSite(DC);
  if ControlCount > 0 then
  begin
    //Do non-wincontrols
    CurrentControlIndex := 0;
    if First <> nil then
      for FindControlIndex := ControlCount - 1 downto 0 do
        if Controls[FindControlIndex] = First then
        begin
          CurrentControlIndex := FindControlIndex;
          Break;
        end;

    for CurrentControlIndex := CurrentControlIndex to ControlCount - 1 do
    begin
      CurrentControl := Controls[CurrentControlIndex];

      Assert(CurrentControlIndex < ControlCount);
      if not (CurrentControl is TWinControl) then
        if IntersectRect(D, FUpdateRect, CurrentControl.BoundsRect) then
        begin
          with CurrentControl do
            if (Visible or (csDesigning in ComponentState) and
              not (csNoDesignVisible in ControlStyle)) and
              RectVisible(DC, Rect(Left, Top, Left + Width, Top + Height)) then
            begin
              if csPaintCopy in Self.ControlState then
                Self.ControlState := Self.ControlState + [csPaintCopy];
              SaveIndex := SaveDC(DC);
              MoveWindowOrg(DC, Left, Top);
              IntersectClipRect(DC, 0, 0, Width, Height);

              if CurrentControl is TCustomDIBControl then
              begin
                FChildDIB.ReSize(Width, Height);
                FChildDIB.ResetHeader;
                THackDIBControl(CurrentControl).ControlDIB := FChildDIB;
                CurrentClipRect := FDIB.ClipRect;
                OffsetRect(CurrentClipRect, -CurrentControl.Left, -CurrentControl.Top);
                FChildDIB.ClipRect := CurrentClipRect;
              end;

              Perform(WM_PAINT, Integer(DC), 0);
              RestoreDC(DC, SaveIndex);
              Self.ControlState := Self.ControlState - [csPaintCopy];
            end;
        end;
    end;

    //Now do WinControls (last)
    CurrentControlIndex := 0;
    if First <> nil then
      for FindControlIndex := ControlCount - 1 downto 0 do
        if Controls[FindControlIndex] = First then
        begin
          CurrentControlIndex := FindControlIndex;
          Break;
        end;

    for CurrentControlIndex := CurrentControlIndex to ControlCount - 1 do
    begin
      CurrentControl := Controls[CurrentControlIndex];

      Assert(CurrentControlIndex < ControlCount);
      if (CurrentControl is TWinControl) then
        if IntersectRect(D, FUpdateRect, CurrentControl.BoundsRect) then
        begin
          with THackWinControl(CurrentControl) do
          begin
            if Ctl3D and (csFramed in ControlStyle) and
              (Visible or (csDesigning in ComponentState) and
              not (csNoDesignVisible in ControlStyle)) then
            begin
              FrameBrush := CreateSolidBrush(ColorToRGB(clBtnShadow));
              FrameRect(DC, Rect(Left - 1, Top - 1, Left + Width, Top + Height),
                FrameBrush);
              DeleteObject(FrameBrush);
              FrameBrush := CreateSolidBrush(ColorToRGB(clBtnHighlight));
              FrameRect(DC, Rect(Left, Top, Left + Width + 1, Top + Height + 1),
                FrameBrush);
              DeleteObject(FrameBrush);
            end;
          end;
        end;
    end;
  end;
end;

procedure TCustomDIBContainer.PaintHandler(var Message: TWMPaint);
var
  I, Clip, SaveIndex: Integer;
  DC: HDC;
begin
  DC := Message.DC;
  if ControlCount = 0 then
    PaintWindow(DC)
  else 
  begin
    SaveIndex := SaveDC(DC);
    Clip := SimpleRegion;
    for I := 0 to ControlCount - 1 do
      with TControl(Controls[I]) do
        if (Visible or (csDesigning in ComponentState) and
          not (csNoDesignVisible in ControlStyle)) and
          (csOpaque in ControlStyle) then
        begin
          Clip := ExcludeClipRect(DC, Left, Top, Left + Width, Top + Height);
          if Clip = NullRegion then Break;
        end;
    if Clip <> NullRegion then PaintWindow(DC);
    RestoreDC(DC, SaveIndex);
  end;
  PaintControls(DC, nil);
end;

procedure TCustomDIBContainer.SetBorderDrawPosition(const Value: TBorderDrawPosition);
begin
  FBorderDrawPosition := Value;
  Invalidate;
end;

procedure TCustomDIBContainer.SetBounds(aLeft, aTop, aWidth, aHeight: Integer);
begin
  inherited;
  if (FDIB <> nil) and not (csLoading in ComponentState) then
    FDIB.Resize(aWidth, aHeight);
end;

procedure TCustomDIBContainer.SetDIBBorder(const Value: TDIBBorder);
begin
  if DIBBorder <> nil then DIBBorder.RemoveFreeNotification(Self);
  FDIBBorder := Value;
  if DIBBorder <> nil then DIBBorder.FreeNotification(Self);
  if AutoSize then AdjustSize;
  ReAlign;
  Invalidate;
end;

procedure TCustomDIBContainer.WMEraseBkGnd(var Message: TMessage);
begin
  Message.Result := 1;
end;

procedure TCustomDIBContainer.WMGetDlgCode(var Message: TMessage);
begin
  Message.Result := DLGC_WANTALLKEYS;
end;

procedure TCustomDIBContainer.WMPaint(var Message: TWMPaint);
var
  I: Integer;
  OrigDC, DC: HDC;
  PS: TPaintStruct;
  OldPal: HPalette;
  BlitType: TBlitType;
  CanSetDiBits: Boolean;
begin
  Message.Result := 0;
  if Message.DC = 0 then
    DC := BeginPaint(Handle, PS)
  else
    DC := Message.DC;
  try
    // painting to the control (the norm)
    if Message.DC = 0 then
      FUpdateRect := PS.rcPaint        // get the area we will be painting in
        // for painting to an alternate DC (non-owned canvas)
    else
    begin
      FAlteredRect := True;                    // stop height/width, etc checks
      GetClipBox(DC, FUpdateRect);    // get the area we will be painting in
    end;

    if not FAlteredRect then
    begin
      for I := 0 to ControlCount - 1 do
        if Controls[I] is TCustomDIBControl then
          THackDIBControl(Controls[I]).AlterUpdateRect(FUpdateRect);

      FUpdateRect.TopLeft := ClientToScreen(FUpdateRect.TopLeft);
      FUpdateRect.BottomRight := ClientToScreen(FUpdateRect.BottomRight);

      FUpdateRect.TopLeft := ScreenToClient(FUpdateRect.TopLeft);
      FUpdateRect.BottomRight := ScreenToClient(FUpdateRect.BottomRight);

      //For some reason, invalidating the whole form actually invalidates the height -2
      //so the next code is called endlessly.
      //Therefore I check if the difference in height is > 2
      if (FUpdateRect.Left <> PS.rcPaint.Left) or
        (FUpdateRect.Top <> PS.rcPaint.Top) or
        (FUpdateRect.Right <> PS.rcPaint.Right) or
        (abs(FUpdateRect.Bottom - PS.rcPaint.Bottom) > 2) then
      begin
        FAlteredRect := True;
        //Called in "Finally" block
        //        if Message.DC = 0 then
        //          EndPaint(handle, ps);
        ValidateRect(Handle, @PS.rcPaint);
        InvalidateRect(Handle, @FUpdateRect, False);
        Exit;
      end;
    end;
    FAlteredRect := False;

    FDIB.ClipRect := FUpdateRect;
    OrigDC := Message.DC;
    Message.DC := DIB.Handle;
    DoBeforePaint;
    PaintHandler(Message);
    DoAfterPaint;
    Message.DC := OrigDC;

    BlitType := btNormal;
    if not (csDesigning in ComponentState) then
      if GetDeviceCaps(DC, BITSPixel) = 8 then
      begin
        CanSetDiBits := (GetDeviceCaps(DC, RasterCaps) and RC_DIBToDEV) <> 0;
        if (FPalette <> nil) and (FPalette.UseTable) and (CanSetDiBits) then
          BlitType := btLookUp
        else
          BlitType := btNeedPalette
      end;

    case BlitType of
      btNormal:
        with FUpdateRect do
          BitBlt(DC, Left, Top, Right - Left, Bottom - Top, dib.handle, Left, Top, SrcCopy);

      btNeedPalette:
        begin
          if Assigned(FPalette) then  //Dave Parkinson
            OldPal := SelectPalette(DC, FPalette.palette, False)
          else
            OldPal := 0;
          with FUpdateRect do
            BitBlt(DC, Left, Top, Right - Left, Bottom - Top, dib.handle,
              Left, Top, SrcCopy);
          if OldPal <> 0 then
            SelectPalette(DC, OldPal, True);
        end;

      btLookup:
        begin
          OldPal := SelectPalette(DC, FPalette.palette, False);
          with FUpdateRect do
            dib.Render8Bit(DC, Left, Top, Right - Left, Bottom - Top,
              Left, Top, SrcCopy, FPalette);
          SelectPalette(DC, OldPal, True);
        end;
    end;
  finally
    if Message.DC = 0 then
      EndPaint(Handle, PS);
  end;
end;


procedure TCustomDIBContainer.WndProc(var Message: TMessage);
var
  CControl: TControl;
  ParentRect, CRect: TRect;
  CPos: TPoint;
  ParentControl: TWinControl;
begin
  if Message.Msg = WM_LButtonUp then
  begin
    CControl := GetCaptureControl;
    if (CControl <> nil) then 
    begin
      Windows.GetCursorPos(CPos);
      CRect.TopLeft := ClientToScreen(Point(CControl.Left, CControl.Top));
      CRect.BottomRight := Point(CRect.Left + CControl.Width, CRect.Top + CControl.Height);
      ParentRect := CRect;
      if not PtInRect(CRect, CPos) then 
      begin
        if THackControl(CControl).MouseCapture then
          if CControl <> Self then
            CControl.Perform(CM_MouseLeave, 0, 0);

        ParentControl := FindVCLWindow(CPos);
        if ParentControl <> nil then
        begin
          CRect.TopLeft := ParentControl.ScreenToClient(CPos);
          CControl := ParentControl.ControlAtPos(CRect.TopLeft, False);
          if CControl <> nil then CControl.Perform(CM_MouseEnter, 0, 0);
        end;
      end;
    end;
  end;

(*
  if FActiveControl is TCustomDIBControl then begin
    if not FindDIBChildMessage(Message.Msg) then
      inherited
    else begin
      FActiveControl.WindowProc(Message);
      if Message.Result <> 0 then
        inherited;
    end;
  end else
    inherited;
*)
  inherited;
end;

procedure TCustomDIBContainer.AdjustClientRect(var Rect: TRect);
begin
  inherited;
  if FDIBBorder <> nil then
    with DIBBorder do
    begin
      Inc(Rect.Top, BorderTop.Size);
      Dec(Rect.Bottom, BorderBottom.Size);
      Inc(Rect.Left, BorderLeft.Size);
      Dec(Rect.Right, BorderRight.Size);
    end;
end;

procedure TCustomDIBContainer.WMSetCursor(var Message: TMessage);
var
  Control: TControl;
  CursorPos: TPoint;
begin
  if csDesigning in ComponentState then
    inherited
  else 
  begin
    GetCursorPos(CursorPos);
    CursorPos := ScreenToClient(CursorPos);
    Control := ControlAtPos(CursorPos, False);
    if not (Assigned(Control)) or (Control.Perform(WM_SETCURSOR,
      Message.WParam, Message.LParam) <> 1) then
      inherited;
  end;
end;

{ TCustomDIBImageContainer }

constructor TCustomDIBImageContainer.Create(AOwner: TComponent);
begin
  inherited;
  FIndexImage := TDIBImageLink.Create(Self);
  FIndexImage.OnImageChanged := DoImageChanged;
end;

destructor TCustomDIBImageContainer.Destroy;
begin
  FIndexImage.Free;
  inherited;
end;

procedure TCustomDIBImageContainer.Paint;
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
            TheDIB.Width, TheDIB.Height, FDIB, 0, 0);
        end;
      tmTile:
        begin
          Y := FDIB.ClipRect.Top;
          if Y mod TheDIB.Height <> 0 then
            Y := Y - Y mod TheDIB.Height;
          while Y < FDIB.ClipRect.Bottom do
          begin
            X := FDIB.ClipRect.Left;
            if X mod TheDIB.Width <> 0 then
              X := X - X mod TheDIB.Width;
            while X < FDIB.ClipRect.Right do 
            begin
              if IntersectRect(R, FUpdateRect,
                Rect(X, Y, X + TheDIB.Width, Y + TheDIB.Height)) then
                TheDIB.Draw(X, Y, TheDIB.Width, TheDIB.Height, FDIB, 0, 0);
              Inc(X, TheDIB.Width);
            end;
            Inc(Y, TheDIB.Height);
          end;
        end;
    end;
  end;
end;

procedure TCustomDIBImageContainer.SetTileMethod(const Value: TTileMethod);
begin
  FTileMethod := Value;
  invalidate;
end;

procedure TCustomDIBImageContainer.WndProc(var Message: TMessage);
begin
  if (csDestroying in ComponentState) or
    (TileMethod <> tmTile) or
    (Message.msg <> WM_EraseBkGnd) then
    inherited;
end;

procedure TCustomDIBImageContainer.ImageChanged(ID: Integer; Operation: TDIBOperation);
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

function TCustomDIBImageContainer.GetDIBImageList: TCustomDIBImageList;
begin
  Result := FIndexImage.DIBImageList;
end;

procedure TCustomDIBImageContainer.SetDIBImageList(const Value: TCustomDIBImageList);
begin
  FIndexImage.DIBImageList := Value;
end;

procedure TCustomDIBImageContainer.DoImageChanged(Sender: TObject;
  ID: Integer; Operation: TDIBOperation);
begin
  ImageChanged(ID, Operation);
end;

end.
