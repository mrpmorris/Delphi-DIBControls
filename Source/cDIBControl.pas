unit cDIBControl;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBControl.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
The main base component for all DIB components

Contributor(s):
None as yet


Last Modified: May 23, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
Would have been good if we could have derived this component from TCustomControl
instead.  If anyone can work out how to get this stuff to work just as well from
a TCustomControl I would love to hear from you !!!
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   April 6, 2001
By:     Peter Morris
Change: Added HelpContext property, does nothing yet.

Date:   April 7, 2001
By:     Peter Morris
Change: Added OnPaint

Date:   April 7, 2001
By:     Peter Morris
Change: Moved the ControlDIB property to PUBLIC area

Date:   April 7, 2001
By:     Peter Morris
Change: Added a MousePosition property (TPoint)

Date:   April 16, 2001
By:     Peter Morris
Change: Added support for sub properties in template files (such as FONT)

Date:   May 2, 2001
By:     Peter Morris
Change: Added a new base control called TCustomDIBFramedControl

Date:   May 2, 2001
By:     Peter Morris
Change: Added BeforePaint and AfterPaint methods

Date:   August 19, 2001
By:     Peter Morris
Change: Removed the line of code in the constructor which automatically sets
        the parent of the DIBControl.  This causes many messages to occur
        such as CM_FONTCHANGED which can cause code to be executed before the
        constructor has completed.

Date:   August 24, 2001
By:     Peter Morris
Change: Moved "inherited" to the top of the Notification method in
        TCustomDIBControl, which was causing an endless loop when destroying
        in Delphi 6.

Date:   January 1, 2002 (Happy new year)
By:     Peter Morris
Change: Altered the SetTabOrder procedure, was causing an AV sometimes.

Date:   August 18, 2002
By:     Hans-Jürgen Schnorrenberg
Change: Intorduced method CMEnabledChanged, in order to kill focus, when disabled.
        WMSetFocus calls DoEnter, only when Enabled.

Date:   March 23, 2003
By:     Peter Morris
Change: Removed MouseDownButton and replaced with a set instead MouseButtons.

Date:   January 9, 2005
By:     Peter Morris
Change: Added TPointProperty

Date:   June 19, 2005
By:     Peter Morris
Change: Fixed WM_LBUTTONUP code in WndProc which was sending too many CM_MOSUELEAVE
        messages.
*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, cDIB,
  cDIBPanel, cDIBFeatures, ExtCtrls, Consts, Menus, cDIBTimer, cDIBImageList, TypInfo,
  cDIBCompressor, cDIBBorder;

type
  EDIBControlError = class(Exception);
  TWantedKey = (wkTab, wkArrows, wkAll);
  TWantedKeys = set of TWantedKey;

  TDIBDrawEvent = procedure(Sender: TObject; var Handled: Boolean) of object;
  TDIBMeasureEvent = procedure(Sender: TObject; var Size: Integer) of object;
  TDIBBackgroundStyle = (bsDrawSolid, bsDrawTransparent);

  TPointProperty = class(TPersistent)
  private
    FX: Integer;
    FY: Integer;
    FOnChanged: TNotifyEvent;
    procedure SetX(const Value: Integer);
    procedure SetY(const Value: Integer);
  protected
    procedure DoChanged;
  public
    constructor Create; virtual;
    procedure AssignTo(Dest: TPersistent); override;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  published
    property X: Integer read FX write SetX default 0;
    property Y: Integer read FY write SetY default 0;
  end;

  TCustomDIBControl = class(TControl)
  private
    { Private declarations }
    FLastInvalidateTime: DWORD;
    FPropertyList: TList;
    FDIBImageList: TCustomDIBImageList;
    FCanvas: TCanvas;
    FControlDIB: TWinDIB;
    FHelpContext: THelpContext;
    FAccelerator: Char;
    FCreating: Boolean;
    FFocused: Boolean;
    FStoppingRepeat: Boolean;
    FAlreadyMoving: Boolean;
    FChildren: TControlList;
    FMouseRepeat: Boolean;
    FMouseRepeatInterval: Integer;
    FMouseXPos: Integer;
    FMouseYPos: Integer;
    FShiftState: TShiftState;
    FTimer: TDIBTimer;
    FLastMouse: TMessage;
    FRealMouseInControl: Boolean;
    FMouseInControl: Boolean;
    FOnPaint,
    FOnEnter,
    FOnExit,
    FOnMouseEnter,
    FOnMouseLeave: TNotifyEvent;
    FDIBFeatures: TDIBFeatures;
    FOpacity: Byte;
    FOnKeyDown: TKeyEvent;
    FOnKeyUp: TKeyEvent;
    FOnKeyPress: TKeyPressEvent;
    FOnPaintStart: TNotifyEvent;
    FOnPaintEnd: TNotifyEvent;
    FMovingOnly: Boolean;
    FMouseButtons: TMouseButtons;

    //For streaming of properties to templates
    FPropertyNames: TStringList;
    procedure ReadProperties(S: TStream);
    procedure WriteProperties(S: TStream);

    procedure DoImageChanged(Sender: TObject; Index: Integer; Operation: TDIBOperation);
    function GetContainer: TCustomDIBContainer;
    function GetTabOrder: TTabOrder;
    procedure SetOpacity(const Value: Byte);
    procedure SetTabOrder(const Value: TTabOrder);
    procedure RepeatMessage(Sender: TObject);

    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DialogChar;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    // ** Hans-Jürgen
    procedure WMChar(var Message: TWMKey); message WM_Char;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GetDlgCode;
    procedure WMKeyDown(var Message: TWMKey); message WM_KeyDown;
    procedure WMKeyUp(var Message: TWMKey); message WM_KeyUp;
    procedure WMKillFocus(var Message: TMessage); message WM_KillFocus;
    procedure WMPAINT(var Message: TWMPaint); message WM_Paint;
    procedure WMSetFocus(var Message: TMessage); message WM_SetFocus;
    procedure SetDIBImageList(const Value: TCustomDIBImageList);
    function GetMousePosition: TPoint;
  protected
    { Protected declarations }
    FTabOrder: TTabOrder;
    WantedKeys: TWantedKeys;

    procedure AddTemplateProperty(const Name: string);
    procedure AfterPaint; virtual;
    procedure AlterUpdateRect(var R: TRect); virtual;
    procedure AddIndexProperty(var Index: TDIBImageLink);
    procedure BeforePaint; virtual;
    procedure ClearDefaultPopupMenu(const PopupMenu: TPopupMenu); dynamic;
    procedure Click; override;
    procedure DoAnyEnter; virtual;
    procedure DoAnyLeave; virtual;
    procedure DoDefaultPopupMenu(const PopupMenu: TPopupMenu); dynamic;
    procedure DoEnter; virtual;
    procedure DoExit; virtual;
    function DoKeyDown(var Message: TWMKey): Boolean; virtual;
    function DoKeyPress(var Message: TWMKey): Boolean; virtual;
    function DoKeyUp(var Message: TWMKey): Boolean; virtual;
    procedure DoMouseEnter; virtual;
    procedure DoMouseLeave; virtual;
    function GetPopupMenu: TPopupMenu; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); dynamic;
    procedure KeyUp(var Key: Word; Shift: TShiftState); dynamic;
    procedure KeyPress(var Key: Char); dynamic;
    procedure ImageChanged(Index: Integer; Operation: TDIBOperation); virtual;
    function IsMenuKey(var Message: TWMKey): Boolean; virtual;
    function IsMouseRepeating: Boolean;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Paint; virtual;
    procedure SetParent(AParent: TWinControl); override;
    procedure StopRepeating; virtual;
    procedure WndProc(var Message: TMessage); override;

    property Accelerator: Char read FAccelerator write FAccelerator;
    property Canvas: TCanvas read FCanvas;
    property Children: TControlList read FChildren write FChildren;
    property Creating: Boolean read FCreating;
    property DIBFeatures: TDIBFeatures read FDIBFeatures write FDIBFeatures;
    property DIBImageList: TCustomDIBImageList read FDIBImageList write SetDIBImageList;
    property HelpContext: THelpContext read FHelpContext write FHelpContext default 0;
    property LastMouse: TMessage read FLastMouse;
    property MouseButtons: TMouseButtons read FMouseButtons;
    property MouseRepeat: Boolean read FMouseRepeat write FMouseRepeat;
    property MouseRepeatInterval: Integer read FMouseRepeatInterval
      write FMouseRepeatInterval;
    property Opacity: Byte read FOpacity write SetOpacity;
    property ShiftState: TShiftState read FShiftState write FShiftState;
    property DIBTabOrder: TTabOrder read GetTabOrder write SetTabOrder;

    property LastInvalidateTime: DWORD read FLastInvalidateTime;
    property MouseCaptured: Boolean read FMouseInControl;
//    property MouseDownButton: TMouseDownButton read FMouseDownButton;
    property MouseOver: Boolean read FRealMouseInControl;
    property MouseXPos: Integer read FMouseXPos;
    property MouseYPos: Integer read FMouseYPos;
    property MovingOnly: Boolean read FMovingOnly;

    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;
    property OnKeyUp: TKeyEvent read FOnKeyUp write FOnKeyUp;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
    property OnPaintStart: TNotifyEvent read FOnPaintStart write FOnPaintStart;
    property OnPaintEnd: TNotifyEvent read FOnPaintEnd write FOnPaintEnd;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Invalidate; override;
    procedure LoadTemplateFromFile(const Filename: TFilename);
    procedure LoadTemplateFromStream(const S: TStream); virtual;
    procedure SaveTemplateToFile(const Filename: TFilename);
    procedure SaveTemplateToStream(const S: TStream); virtual;

    procedure SetBounds(aLeft, aTop, aWidth, aHeight: Integer); override;
    procedure SetFocus;

    property Container: TCustomDIBContainer read GetContainer;
    property ControlDIB: TWinDIB read FControlDIB write FControlDIB;
    property Focused: Boolean read FFocused;
    property MouseInControl: Boolean read FMouseInControl;
    property MousePosition: TPoint read GetMousePosition;

  published
    { Published declarations }
  end;

  TCustomDIBFramedControl = class(TCustomDIBControl)
  private
    FBackgroundStyle: TDIBBackgroundStyle;
    FDIBBorder: TDIBBorder;
    FOnDrawBackground: TDIBDrawEvent;
    FOnDrawBorder: TDIBDrawEvent;
    FOnMeasureBottomBorder: TDIBMeasureEvent;
    FOnMeasureLeftBorder: TDIBMeasureEvent;
    FOnMeasureRightBorder: TDIBMeasureEvent;
    FOnMeasureTopBorder: TDIBMeasureEvent;
    procedure SetBackgroundStyle(const Value: TDIBBackgroundStyle);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    procedure AfterPaint; override;
    procedure BeforePaint; override;
    procedure DrawBackground; virtual;
    procedure DrawBorder; virtual;
    function GetBottomBorderSize: Integer; virtual;
    function GetLeftBorderSize: Integer; virtual;
    function GetRightBorderSize: Integer; virtual;
    function GetTopBorderSize: Integer; virtual;
    procedure SetDIBBorder(const Value: TDIBBorder); virtual;

    property BackgroundStyle: TDIBBackgroundStyle 
      read FBackgroundStyle write SetBackgroundStyle default bsDrawSolid;
    property DIBBorder: TDIBBorder read FDIBBorder write SetDIBBorder;
    property OnDrawBackground: TDIBDrawEvent read FOnDrawBackground write FOnDrawBackground;
    property OnDrawBorder: TDIBDrawEvent read FOnDrawBorder write FOnDrawBorder;
    property OnMeasureBottomBorder: TDIBMeasureEvent
      read FOnMeasureBottomBorder write FOnMeasureBottomBorder;
    property OnMeasureLeftBorder: TDIBMeasureEvent
      read FOnMeasureLeftBorder write FOnMeasureLeftBorder;
    property OnMeasureRightBorder: TDIBMeasureEvent
      read FOnMeasureRightBorder write FOnMeasureRightBorder;
    property OnMeasureTopBorder: TDIBMeasureEvent
      read FOnMeasureTopBorder write FOnMeasureTopBorder;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
  end;

  //procedure AddDIBChildMessage(const Message : DWord);
  //function  FindDIBChildMessage(const Message : DWord) : Boolean;
  //procedure RemoveDIBChildMessage(const Message : DWord);

function GetPropertyName(aInstance: TComponent; aObject: TPersistent): string;

implementation

uses
  ActiveX, COMObj;

var
  GDefaultPopupMenu: TPopupMenu = nil;

type
  THackContainer = class(TCustomDIBContainer);
  THackFeatures = class(TDIBFeatures);
  THackControl = class(TControl);
  THackAbstractSuperDIB = class(TAbstractSuperDIB);
  THackWinControl = class(TWinControl);

  TDIBWrapper = class(TComponent)
  private
    FDIB: TMemoryDIB;
  published
    property DIB: TMemoryDIB read FDIB write FDIB;
  end;

  TPersistentWrapper = class(TComponent)
  private
    FPersistent: TPersistent;
  published
    property Persistent: TPersistent read FPersistent write FPersistent;
  end;

function GetPropertyName(aInstance: TComponent; aObject: TPersistent): string;
var
  TI: PTypeInfo;
  PI: PPropInfo;
  Cnt: Integer;
  Props: PPropList;
begin
  Result := '';

  TI := aInstance.ClassInfo;
  Cnt := GetTypeData(TI)^.PropCount;
  GetMem(Props, Cnt * SizeOf(PPropInfo));
  Cnt := GetPropList(TI, [tkClass], Props);
  for Cnt := Cnt - 1 downto 0 do
  begin
    PI := GetPropInfo(TI, string(Props[Cnt].Name));
    if GetOrdProp(aInstance, PI) = LongInt(aObject) then
    begin
      Result := string(Props[Cnt].Name);
      break;
    end;
  end;
  FreeMem(Props);
end;

{ TPointProperty }

procedure TPointProperty.AssignTo(Dest: TPersistent);
begin
  if (Dest is TPointProperty) then
  begin
    TPointProperty(Dest).X := X;
    TPointProperty(Dest).Y := Y;
  end else
    inherited;
end;

constructor TPointProperty.Create;
begin
  inherited Create;
  FX := 0;
  FY := 0;
end;

procedure TPointProperty.DoChanged;
begin
  if Assigned(OnChanged) then
    OnChanged(Self);
end;

procedure TPointProperty.SetX(const Value: Integer);
begin
  FX := Value;
  DoChanged;
end;

procedure TPointProperty.SetY(const Value: Integer);
begin
  FY := Value;
  DoChanged;
end;

{ TCustomDIBControl }

constructor TCustomDIBControl.Create(AOwner: TComponent);
var
  X: Integer;
  P: TWinControl;
begin
  P := nil;
  if AOwner = nil then raise Exception.Create('Owner cannot be nil');

  if AOwner is TCustomDIBContainer then
    P := TWinControl(AOwner)
  else
    for X := 0 to AOwner.ComponentCount - 1 do
      if AOwner.Components[X] is TCustomDIBContainer then 
      begin
        P := TWinControl(AOwner.Components[X]);
        Break;
      end;

  if P = nil then raise Exception.Create('Parent must be a TDIBContainer');
  FCreating := True;
  inherited;
  FPropertyList := TList.Create;
  FPropertyNames := TStringList.Create;
  FCanvas := TCanvas.Create;
  FAlreadyMoving := False;
  FStoppingRepeat := False;
  FChildren := TControlList.Create(Self);
  //This causes CM_FONTCHANGE which triggers methods before the constructor has
  //been completed.
  //  Parent := P;
  SetBounds(0, 0, 32, 32);
  FDIBFeatures := TDIBFeatures.Create(Self);
  FOpacity := 255;
  FMouseInControl := False;
  FRealMouseInControl := False;
  FTimer := TDIBTimer.Create(nil);
  FTimer.OnTimer := RepeatMessage;
  FTimer.Enabled := False;
//  FMouseDownButton := mdNone;
  FMouseRepeat := False;
  FMouseRepeatInterval := 250;
  FTabOrder := -1;
  WantedKeys := [wkArrows];
  AddTemplateProperty('Width');
  AddTemplateProperty('Height');
end;

destructor TCustomDIBControl.Destroy;
begin
  FPropertyNames.Free;
  FTimer.Free;
  FChildren.Free;
  FDIBFeatures.Free;
  FCanvas.Free;
  FPropertyList.Free;
  inherited;
end;

procedure TCustomDIBControl.Loaded;
begin
  FCreating := False;
  inherited;
  THackFeatures(FDIBFeatures).Loaded;
  DIBTabOrder := FTabOrder;
end;

function TCustomDIBControl.IsMenuKey(var Message: TWMKey): Boolean;
var
  Control: TControl;
  Form: TCustomForm;
begin
  Result := True;
  if not (csDesigning in ComponentState) then
  begin
    Control := Self;
    while Control <> nil do
    begin
      if Assigned(PopupMenu) and (PopupMenu.WindowHandle <> 0) and
        PopupMenu.IsShortCut(Message) then Exit;
      Control := Control.Parent;
    end;
    Form := GetParentForm(Self);
    if (Form <> nil) and Form.IsShortCut(Message) then Exit;
  end;
  with Message do
    if SendAppMessage(CM_APPKEYDOWN, CharCode, KeyData) <> 0 then Exit;
  Result := False;
end;

procedure TCustomDIBControl.SetBounds(aLeft, aTop, aWidth, aHeight: Integer);
var
  X, XDelta, YDelta: Integer;
begin
  if FAlreadyMoving then exit;
  //  if (aLeft=Left) and (aTop=Top) and (aWidth=Width) and (aHeight=Height) then exit;

  FMovingOnly := (aWidth = Width) and (aHeight = Height);
  try
    FAlreadyMoving := True;
    XDelta := aLeft - Left;
    YDelta := aTop - Top;

    inherited;

    //Move any dependent children
    if (XDelta <> 0) or (YDelta <> 0) then
      for X := 0 to FChildren.Count - 1 do
        if FChildren[X].Control <> nil then with FChildren[X].Control do
            SetBounds(Left + XDelta, Top + YDelta, Width, Height);
  finally
    FAlreadyMoving := False;
    FMovingOnly := False;
  end;
end;

procedure TCustomDIBControl.SetParent(AParent: TWinControl);
var
  X: Integer;
begin
  if aParent <> nil then 
  begin
    if not (AParent is TCustomDIBContainer) then
      for X := 0 to AParent.ComponentCount - 1 do
        if AParent.Components[X] is TCustomDIBContainer then 
        begin
          AParent := TWinControl(AParent.Components[X]);
          Break;
        end;
    if not (AParent is TCustomDIBContainer) then
      raise Exception.Create('Parent must be a TDIBContainer');
  end;
  inherited;
  DIBTabOrder := FTabOrder;
end;

procedure TCustomDIBControl.WMPAINT(var Message: TWMPaint);
var
  SrcX, SrcY, DstX, DstY: Integer;
begin
  FCanvas.Lock;
  try
    try
      DstX := 0;
      DstY := 0;
      SrcX := Left;
      SrcY := Top;

      if SrcX < 0 then
      begin
        DstX := Abs(SrcX);
        SrcX := 0;
      end;
      if SrcY < 0 then
      begin
        DstY := Abs(SrcY);
        SrcY := 0;
      end;

      TCustomDIBContainer(Parent).DIB.Draw(DstX, DstY, Width, Height,
        ControlDIB, SrcX, SrcY);
      Canvas.Handle := FControlDIB.handle;
      BeforePaint;
      Paint;
      AfterPaint;

      if csDesigning in ComponentState then with canvas do 
      begin
        Pen.color := clBlack;
        Pen.Style := psDash;
        Brush.Style := bsClear;
        Rectangle(0, 0, Width, Height);
      end;

      with THackAbstractSuperDIB(ControlDIB) do 
      begin
        Opacity := Self.Opacity;
        Draw(Self.Left, Self.Top, Width, Height, TCustomDIBContainer(Parent).DIB, 0, 0);
      end;
    finally
      FCanvas.Handle := 0;
    end;
  finally
    FCanvas.Unlock;
  end;
end;

function TCustomDIBControl.GetContainer: TCustomDIBContainer;
begin
  Result := TCustomDIBContainer(Parent);
end;

procedure TCustomDIBControl.WndProc(var Message: TMessage);
var
  Handled: Boolean;
begin
  if (csDesigning in ComponentState) then 
  begin
    inherited;
    exit;
  end;

  if Assigned(FDIBFeatures) then 
  begin
    Handled := False;
    FDIBFeatures.WndProc(Message, Handled);
  end;

  if Message.Msg = WM_LButtonDown then 
  begin
    FLastMouse := Message;
    if MouseRepeat and not FTimer.Enabled then 
    begin
      FTimer.Interval := MouseRepeatInterval;
      FTimer.Enabled := True;
    end;
  end;


  if Message.Msg = WM_MouseMove then 
  begin
    FLastMouse.WParam := Message.WParam;
    FLastMouse.LParam := Message.LParam;
    FMouseXPos := TWMMouse(Message).XPos;
    FMouseYPos := TWMMouse(Message).YPos;
    if FRealMouseInControl and not MouseInControl then
      Perform(CM_MouseEnter, 0, 0);
  end;

  if Message.Msg = WM_LButtonUp then
  begin
    FTimer.Enabled := False;
    if FMouseInControl and not FRealMouseInControl then
      Perform(CM_MouseLeave, 0, 0);
  end;

  if Message.Msg = CM_MouseEnter then
  begin
    DoMouseEnter;
    if MouseCapture and MouseRepeat then
      FTimer.Enabled := True;
    if MouseCapture then
      Exit;
  end;

  if Message.Msg = CM_MouseLeave then
  begin
    FTimer.Enabled := False;
    DoMouseLeave;
  end;

  if not Handled then inherited;
end;

procedure TCustomDIBControl.SetOpacity(const Value: Byte);
begin
  if Value = FOpacity then exit;
  FOpacity := Value;
  Invalidate;
end;

procedure TCustomDIBControl.Paint;
begin
  if Assigned(OnPaint) then OnPaint(Self);
end;

procedure TCustomDIBControl.RepeatMessage(Sender: TObject);
begin
  if FStoppingRepeat then 
  begin
    FStoppingRepeat := False;
    FTimer.Enabled := False;
  end 
  else
    with FLastMouse do
      Perform(Msg, WParam, lParam);
end;

procedure TCustomDIBControl.Notification(AComponent: TComponent;
  Operation: TOperation);
var
  X: Integer;
begin
  inherited;
  if (AComponent = Self) or (csDestroying in ComponentState) then exit;
  if Operation = opRemove then
    for X := Children.Count - 1 downto 0 do
      if Children[X].Control = AComponent then
        FChildren[X].Free;
end;

procedure TCustomDIBControl.DoMouseEnter;
var
  NeedEnter: Boolean;
begin
  NeedEnter := not (Focused or MouseInControl);

  FRealMouseInControl := True;
  FMouseInControl := True;
  if NeedEnter then DoAnyEnter;
  if Assigned(FOnMouseEnter) then FOnMouseEnter(Self);
end;

procedure TCustomDIBControl.DoMouseLeave;
begin
  FRealMouseInControl := False;
  if MouseCapture then exit;
  FMouseInControl := False;
  if Assigned(FOnMouseLeave) then FOnMouseLeave(Self);

  if not (Focused or MouseInControl) then DoAnyLeave;
end;

procedure TCustomDIBControl.StopRepeating;
begin
  FStoppingRepeat := True;
end;

procedure TCustomDIBControl.AlterUpdateRect(var R: TRect);
begin
end;

procedure TCustomDIBControl.SetTabOrder(const Value: TTabOrder);
begin
  if (Container = nil) or (csLoading in ComponentState) then
    FTabOrder := Value
  else 
  begin
    Container.DIBSetTabOrder(Self, Value);
    FTabOrder := GetTabOrder;
  end;
end;


function TCustomDIBControl.GetTabOrder: TTabOrder;
begin
  Result := Container.DIBGetTabOrder(Self);
end;

procedure TCustomDIBControl.SetFocus;
begin
  Perform(WM_SetFocus, 0, 0);
end;

procedure TCustomDIBControl.WMKillFocus(var Message: TMessage);
begin
  DoExit;
end;

procedure TCustomDIBControl.WMSetFocus(var Message: TMessage);
begin
  if Enabled and not Focused then DoEnter;
end;

procedure TCustomDIBControl.DoEnter;
var
  NeedEnter: Boolean;
begin
  NeedEnter := not (Focused or MouseInControl);

  FFocused := True;
  Container.DIBFocusControl(Self);
  Container.SetFocus;
  if NeedEnter then DoAnyEnter;
  if Assigned(FOnEnter) then FOnEnter(Self);
end;

procedure TCustomDIBControl.DoExit;
begin
  FFocused := False;
  if Assigned(FOnExit) then FOnExit(Self);
  if not (Focused or MouseInControl) then DoAnyLeave;
end;

procedure TCustomDIBControl.WMKeyDown(var Message: TWMKey);
begin
  if not DoKeyDown(Message) then inherited;
end;

procedure TCustomDIBControl.WMKeyUp(var Message: TWMKey);
begin
  if not DoKeyUp(Message) then inherited;
end;

function TCustomDIBControl.DoKeyDown(var Message: TWMKey): Boolean;
var
  Form: TCustomForm;
begin
  Result := True;
  Form := GetParentForm(Self);
  if (Form <> nil) and Form.KeyPreview and
    THackWinControl(Form).DoKeyDown(Message) then Exit;
  with Message do
  begin
    FShiftState := KeyDataToShiftState(KeyData);
    if not (csNoStdEvents in ControlStyle) then
    begin
      KeyDown(CharCode, FShiftState);
      if CharCode = 0 then Exit;
    end;
  end;
  Result := False;
end;

function TCustomDIBControl.DoKeyPress(var Message: TWMKey): Boolean;
var
  Form: TCustomForm;
  Ch: Char;
begin
  Result := True;
  Form := GetParentForm(Self);
  if (Form <> nil) and Form.KeyPreview and
    THackWinControl(Form).DoKeyPress(Message) then Exit;
  if not (csNoStdEvents in ControlStyle) then
    with Message do
    begin
      Ch := Char(CharCode);
      KeyPress(Ch);
      CharCode := Word(Ch);
      if Char(CharCode) = #0 then Exit;
    end;
  Result := False;
end;

function TCustomDIBControl.DoKeyUp(var Message: TWMKey): Boolean;
var
  Form: TCustomForm;
begin
  Result := True;
  Form := GetParentForm(Self);
  if (Form <> nil) and Form.KeyPreview and
    THackWinControl(Form).DoKeyUp(Message) then Exit;
  with Message do
  begin
    FShiftState := KeyDataToShiftState(KeyData);
    if not (csNoStdEvents in ControlStyle) then
    begin
      KeyUp(CharCode, FShiftState);
      if CharCode = 0 then Exit;
    end;
  end;
  Result := False;
end;

procedure TCustomDIBControl.WMChar(var Message: TWMKey);
begin
  if not DoKeyPress(Message) then inherited;
end;

procedure TCustomDIBControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Assigned(FOnKeyDown) then FOnKeyDown(Self, Key, Shift);
end;

procedure TCustomDIBControl.KeyPress(var Key: Char);
begin
  if Assigned(FOnKeyPress) then FOnKeyPress(Self, Key);
end;

procedure TCustomDIBControl.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if Assigned(FOnKeyUp) then FOnKeyUp(Self, Key, Shift);
end;

procedure TCustomDIBControl.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  with Message do 
  begin
    Result := 0;
    if wkAll in WantedKeys then
      Result := DLGC_WANTALLKEYS
    else 
    begin
      if wkTab in WantedKeys then Result := Result or DLGC_WANTTab;
      if wkArrows in WantedKeys then Result := Result or DLGC_WANTArrows;
    end;
  end;
end;

procedure TCustomDIBControl.CMDialogChar(var Message: TCMDialogChar);
begin
  FShiftState := KeyDataToShiftState(Message.KeyData);

  if (Message.CharCode = Word(FAccelerator)) and
    Enabled and Visible and (ssAlt in FShiftState) and Parent.CanFocus then
  begin
    Click;
    Message.Result := 0;
  end 
  else
    inherited;
end;

procedure TCustomDIBControl.DoAnyEnter;
begin
end;

procedure TCustomDIBControl.DoAnyLeave;
begin
end;

procedure TCustomDIBControl.Click;
begin
  inherited;
  if (DIBTabOrder > -1) and not Focused then SetFocus;
end;

procedure TCustomDIBControl.DoImageChanged(Sender: TObject; Index: Integer;
  Operation: TDIBOperation);
begin
  if not (csDestroying in ComponentState) then
    ImageChanged(Index, Operation);
end;

procedure TCustomDIBControl.ImageChanged(Index: Integer; Operation: TDIBOperation);
begin
end;

function TCustomDIBControl.IsMouseRepeating: Boolean;
begin
  Result := FTimer.Enabled;
end;

procedure TCustomDIBControl.AddIndexProperty(var Index: TDIBImageLink);
begin
  Index := TDIBImageLink.Create(Self);
  FPropertyList.Add(Index);
  Index.OnImageChanged := DoImageChanged;
end;

procedure TCustomDIBControl.SetDIBImageList(const Value: TCustomDIBImageList);
var
  X: Integer;
begin
  if FDIBImageList <> nil then FDIBImageList.RemoveFreeNotification(Self);
  FDIBImageList := Value;
  for X := 0 to FPropertyList.Count - 1 do
    TDIBImageLink(FPropertyList[X]).DIBImageList := Value;
  if Value <> nil then
    Value.FreeNotification(Self);
end;


{
The format for a template should be
GUID
NumberOfImages : Integer;
NumberOfProperties : Integer;
-for each image-
  LengthOfDisplayName : Integer;
  DisplayName : PChar;
  LengthOfPropertyName : Integer;
  PropertyName : PChar;
  DIB.SaveDataToStream
-end--
-for each property-
  NewIndexNumber : Integer;
-end--
NumberOfClassProperties : Integer;
--for each property--
  LengthOfPropName : Integer;
  PropName : PChar;
  SkipSize : Integer;  //if this property does not exist
  Data : Binary
--end--
CUSTOM DATA GOES HERE

}

procedure TCustomDIBControl.LoadTemplateFromFile(const Filename: TFilename);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(Filename, fmOpenRead);
  try
    LoadTemplateFromStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TCustomDIBControl.LoadTemplateFromStream(const S: TStream);
var
  I, Index, DisplayLen, PropLen, PropertyCount, ImageCount: Integer;
  DisplayName, PropName: string;

  GUID: TGUID;
  GUIDStr: string;

  FIndexes: TList;
  DIBWrapper: TDIBWrapper;
  AddedItem: TDIBImagesItem;
begin
  FIndexes := TList.Create;
  DIBWrapper := TDIBWrapper.Create(Self);
  try
    S.Read(GUID, SizeOf(TGUID));

    S.Read(ImageCount, SizeOf(Integer));
    if (ImageCount > 0) and not Assigned(DIBImageList) then
      raise EDIBControlError.Create('No DIB image list has been assigned.');

    S.Read(PropertyCount, SizeOf(Integer));
    GUIDStr := GUIDToString(GUID);

    for I := 0 to ImageCount - 1 do 
    begin
      AddedItem := DIBImageList.DIBImages.AddTemplate(GUIDStr, I);
      begin
        DIBWrapper.DIB := AddedItem.DIB;
        S.ReadComponent(DIBWrapper);
        FIndexes.Add(Pointer(AddedItem.Index));
      end;
    end;

    for I := 0 to PropertyCount - 1 do 
    begin
      //Get the property name
      S.Read(PropLen, SizeOf(Integer));
      SetLength(PropName, PropLen);
      S.Read(PropName[1], PropLen);

      //Get the display name
      DisplayName := '';
      S.Read(DisplayLen, SizeOf(Integer));
      if DisplayLen > 0 then 
      begin
        SetLength(DisplayName, DisplayLen);
        S.Read(DisplayName[1], DisplayLen);
      end;

      S.Read(Index, SizeOf(Integer));
      if IsPublishedProp(Self, PropName) then 
      begin
        Index := Integer(FIndexes[Index]);
        with TDIBImageLink(GetOrdProp(Self, PropName)) do 
        begin
          DIBIndex := Index;
          if DisplayName <> '' then
            DIBImageList.DIBImages[Index].DisplayName := DisplayName;
        end;
      end;
    end;
    ReadProperties(S);
    Loaded;
  finally
    DIBWrapper.Free;
    FIndexes.Free;
  end;
end;


procedure TCustomDIBControl.SaveTemplateToFile(const Filename: TFilename);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(Filename, fmCreate);
  try
    SaveTemplateToStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TCustomDIBControl.SaveTemplateToStream(const S: TStream);
var
  I, PropertyCount, ImageCount, DisplayLen, PropLen, NewIndex, Index: Integer;

  DisplayName, PropName: string;
  FIndexes: TList;

  GUID: TGUID;

  PropertyStream, ImageStream: TMemoryStream;

  DIBWrapper: TDIBWrapper;

  OrigCompressor: TAbstractDIBCompressor;
begin
  //  if DIBImageList = nil then exit;

  if CoCreateGUID(GUID) <> S_OK then
    raise EDIBControlError.Create('Could not create a GUID for your new template.');

  FIndexes := TList.Create;
  PropertyStream := TMemoryStream.Create;
  ImageStream := TMemoryStream.Create;
  DIBWrapper := TDIBWrapper.Create(Self);

  //Don't compress templates for compatibility reasons
  //other users may not have the correct decompressor
  OrigCompressor := DefaultCompressor;
  try
    DefaultCompressor := nil;

    PropertyCount := 0;
    ImageCount := 0;

    for I := 0 to FPropertyList.Count - 1 do 
    begin
      //Get the name of the property, and the INDEX
      PropName := GetPropertyName(Self, FPropertyList[I]);
      Index := TDIBImageLink(FPropertyList[I]).DIBIndex;

      if (PropName <> '') and (DIBImageList.IsIndexValid(Index)) then 
      begin
        //If it is published, and has a valid pic, we need it
        Inc(PropertyCount);

        //Write length of the property name
        PropLen := Length(PropName);
        PropertyStream.Write(PropLen, SizeOf(Integer));
        //Write the property name
        PropertyStream.Write(PropName[1], PropLen);

        //Write the length of the display name
        DisplayName := TDIBImageLink(FPropertyList[I]).DIBImageList.DIBImages
          [Index].DisplayName;
        DisplayLen := Length(DisplayName);
        PropertyStream.Write(DisplayLen, SizeOf(Integer));
        if DisplayLen > 0 then
          PropertyStream.Write(DisplayName[1], DisplayLen);

        //See if we have already written this index
        NewIndex := FIndexes.IndexOf(Pointer(Index));
        //If not, we write it
        if NewIndex = -1 then 
        begin
          Inc(ImageCount);
          NewIndex := FIndexes.add(Pointer(Index));
          DIBWrapper.DIB := DIBImageList.DIBImages[Index].DIB;
          ImageStream.WriteComponent(DIBWrapper);
        end;

        //Now write out the remapped index (NOT the original index)
        PropertyStream.Write(NewIndex, SizeOf(Integer));
      end;
    end;

    //Now we have build a property list (with remapped index) and
    //an image list, we stick it all together
    PropertyStream.Seek(0, soFromBeginning);
    ImageStream.Seek(0, soFromBeginning);

    S.Write(GUID, SizeOf(TGUID));

    S.Write(ImageCount, SizeOf(Integer));
    S.Write(PropertyCount, SizeOf(Integer));
    S.CopyFrom(ImageStream, ImageStream.Size);
    S.CopyFrom(PropertyStream, PropertyStream.Size);
    WriteProperties(S);
  finally
    DefaultCompressor := OrigCompressor;
    DIBWrapper.Free;
    PropertyStream.Free;
    ImageStream.Free;
    FIndexes.Free;
  end;
end;


procedure TCustomDIBControl.AddTemplateProperty(const Name: string);
begin
  if not IsPublishedProp(Self, Name) then
    raise EDIBControlError.Create('Class ' + ClassName + ' is trying to register ' +
      Name +' as a template property, and that property does not exist.');
      
  if not (PropType(Self, Name) in
    [tkSet, tkInteger, tkEnumeration, tkInt64, tkChar, tkString, tkWChar,
    tkLString, tkWString, tkFloat, tkClass]) then
    raise EDIBControlError.Create('Attempting to template an invalid property type.');

  if PropType(Self, Name) = tkClass then
    if TObject(GetOrdProp(Self, Name)) is TComponent then
      raise EDIBControlError.Create('Attempting to template an invalid property type.');

  FPropertyNames.Add(Name);
end;

procedure TCustomDIBControl.ReadProperties(S: TStream);
var
  nProp, I: Integer;
  FloatVal: Extended;
  SkipSize, StrSize, PropSize, OrdVal: Longint;
  PropName, StrVal: string;
  PersistentWrapper: TPersistentWrapper;
begin
  S.Read(nProp, SizeOf(Integer));

  for I := 0 to nProp - 1 do 
  begin
    //Read the property name
    S.Read(PropSize, SizeOf(Integer));
    SetLength(PropName, PropSize);
    S.Read(PropName[1], PropSize);

    //Now the skip size
    S.Read(SkipSize, SizeOf(Longint));

    if not IsPublishedProp(Self, PropName) then
      S.Seek(SkipSize, soFromCurrent)
    else
      //Now the value
      case PropType(Self, PropName) of
        tkSet,
        tkInteger,
        tkEnumeration,
        tkInt64:
          begin
            S.Read(OrdVal, SizeOf(LongInt));
            SetOrdProp(Self, PropName, OrdVal);
          end;

        tkChar,
        tkString,
        tkWChar,
        tkLString,
        tkWString:
          begin
            S.Read(StrSize, SizeOf(Integer));
            SetLength(StrVal, StrSize);
            if StrSize > 0 then
              S.Read(StrVal[1], StrSize);
            SetStrProp(Self, PropName, StrVal);
          end;

        tkFloat:
          begin
            S.Read(FloatVal, SizeOf(Extended));
            SetFloatProp(Self, PropName, FloatVal);
          end;

        tkClass:
          begin
            PersistentWrapper := TPersistentWrapper.Create(Self);
            try
              PersistentWrapper.Persistent := TPersistent(GetOrdProp(Self, PropName));
              S.ReadComponent(PersistentWrapper);
              PersistentWrapper.Persistent := nil;
            finally
              PersistentWrapper.Free;
            end;
          end;
      end;
  end;
end;

procedure TCustomDIBControl.WriteProperties(S: TStream);
var
  I: Integer;
  FloatVal: Extended;
  StrSize, PropSize, OrdVal: Longint;
  PropName, StrVal: string;
  TempStream: TMemoryStream;
  PersistentWrapper: TPersistentWrapper;
begin
  I := FPropertyNames.Count;
  S.Write(I, SizeOf(Integer));

  for I := 0 to FPropertyNames.Count - 1 do 
  begin
    PropName := FPropertyNames[I];
    PropSize := Length(PropName);

    //Write the property name first
    S.Write(PropSize, SizeOf(Integer));
    S.Write(PropName[1], PropSize);

    //Now the value
    case PropType(Self, PropName) of
      tkSet,
      tkInteger,
      tkEnumeration,
      tkInt64:
        begin
          //Skip size in case this property does not exist
          OrdVal := SizeOf(Longint);
          S.Write(OrdVal, SizeOf(LongInt));

          //The value
          OrdVal := GetOrdProp(Self, PropName);
          S.Write(OrdVal, SizeOf(Longint));
        end;

      tkChar,
      tkString,
      tkWChar,
      tkLString,
      tkWString:
        begin
          //Get the string value
          StrVal := GetStrProp(Self, PropName);
          StrSize := Length(StrVal);

          //Skip size in case this property does not exist
          OrdVal := SizeOf(Longint) + StrSize;
          S.Write(OrdVal, SizeOf(LongInt));

          //Write the string size + data
          S.Write(StrSize, SizeOf(Integer));
          if StrSize > 0 then
            S.Write(StrVal[1], StrSize);
        end;

      tkFloat:
        begin
          //Write the skip size
          OrdVal := SizeOf(Extended);
          S.Write(OrdVal, SizeOf(Longint));

          //Write the property value
          FloatVal := GetFloatProp(Self, PropName);
          S.Write(FloatVal, SizeOf(Extended));
        end;

      tkClass:
        begin
          TempStream := TMemoryStream.Create;
          PersistentWrapper := TPersistentWrapper.Create(Self);
          try
            PersistentWrapper.Persistent := TPersistent(GetOrdProp(Self, PropName));
            TempStream.WriteComponent(PersistentWrapper);
            PersistentWrapper.Persistent := nil;

            //Write the skip size
            OrdVal := TempStream.Size;
            S.Write(OrdVal, SizeOf(LongInt));

            //Write the data
            TempStream.Seek(0, soFromBeginning);
            S.CopyFrom(TempStream, TempStream.Size);
          finally
            TempStream.Free;
            PersistentWrapper.Free;
          end;
        end;
    end;
  end;
end;

function TCustomDIBControl.GetMousePosition: TPoint;
begin
  Result := Point(FMouseXPos, FMouseYPos);
end;

procedure TCustomDIBControl.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FShiftState := Shift;
  Include(FMouseButtons, Button);
  if DIBTabOrder >= 0 then SetFocus;
  inherited;
end;

procedure TCustomDIBControl.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FShiftState := Shift;
  Exclude(FMouseButtons, Button);
  inherited;
  if (Button = mbLeft) and (FMouseInControl) and not (FRealMouseInControl) then
    DoMouseLeave;
end;

procedure TCustomDIBControl.AfterPaint;
begin
  if Assigned(FOnPaintEnd) then FOnPaintEnd(Self);
end;

procedure TCustomDIBControl.BeforePaint;
begin
  if Assigned(FOnPaintStart) then FOnPaintStart(Self);
end;

procedure TCustomDIBControl.Invalidate;
begin
  inherited;
  if not FMovingOnly then
    FLastInvalidateTime := GetTickCount;
end;

procedure TCustomDIBControl.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if not (Enabled) and FFocused then
    DoExit;
end;

procedure TCustomDIBControl.DoDefaultPopupMenu(const PopupMenu: TPopupMenu);
begin
end;

procedure TCustomDIBControl.ClearDefaultPopupMenu(const PopupMenu: TPopupMenu);
begin
  PopupMenu.Items.Clear;
end;

function TCustomDIBControl.GetPopupMenu: TPopupMenu;
begin
  Result := inherited GetPopupMenu;
  if Result = nil then
  begin
    ClearDefaultPopupMenu(GDefaultPopupMenu);
    DoDefaultPopupMenu(GDefaultPopupMenu);
    if GDefaultPopupMenu.Items.Count > 0 then
      Result := GDefaultPopupMenu;
  end;
end;

{ TCustomDIBFramedControl }

procedure TCustomDIBFramedControl.AfterPaint;
begin
  inherited;
  DrawBorder;
end;

procedure TCustomDIBFramedControl.BeforePaint;
begin
  inherited;
  DrawBackground;
end;

constructor TCustomDIBFramedControl.Create(AOwner: TComponent);
begin
  inherited;
  FBackgroundStyle := bsDrawSolid;
end;

destructor TCustomDIBFramedControl.Destroy;
begin
  inherited;
end;

procedure TCustomDIBFramedControl.DrawBackground;
var
  Handled: Boolean;
begin
  if BackgroundStyle = bsDrawSolid then
  begin
    Handled := False;
    if Assigned(OnDrawBackground) then OnDrawBackground(Self, Handled);
    if not Handled then ControlDIB.QuickFill(Color);
  end;
end;

procedure TCustomDIBFramedControl.DrawBorder;
var
  Handled: Boolean;
begin
  Handled := False;
  if Assigned(OnDrawBorder) then OnDrawBorder(Self, Handled);
  if not Handled and Assigned(DIBBorder) then DIBBorder.DrawTo(ControlDIB, ClientRect);
end;

function TCustomDIBFramedControl.GetBottomBorderSize: Integer;
begin
  Result := 0;
  if Assigned(OnMeasureBottomBorder) then
    OnMeasureBottomBorder(Self, Result)
  else if Assigned(DIBBorder) then Result := DIBBorder.BorderBottom.Size;
end;

function TCustomDIBFramedControl.GetLeftBorderSize: Integer;
begin
  Result := 0;
  if Assigned(OnMeasureLeftBorder) then
    OnMeasureLeftBorder(Self, Result)
  else if Assigned(DIBBorder) then Result := DIBBorder.BorderLeft.Size;
end;

function TCustomDIBFramedControl.GetRightBorderSize: Integer;
begin
  Result := 0;
  if Assigned(OnMeasureRightBorder) then
    OnMeasureRightBorder(Self, Result)
  else if Assigned(DIBBorder) then Result := DIBBorder.BorderRight.Size;
end;

function TCustomDIBFramedControl.GetTopBorderSize: Integer;
begin
  Result := 0;
  if Assigned(OnMeasureTopBorder) then
    OnMeasureTopBorder(Self, Result)
  else if Assigned(DIBBorder) then Result := DIBBorder.BorderTop.Size;
end;

procedure TCustomDIBFramedControl.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = DIBBorder) then DIBBorder := nil;
end;

procedure TCustomDIBFramedControl.SetBackgroundStyle(const Value: TDIBBackgroundStyle);
begin
  FBackgroundStyle := Value;
  Invalidate;
end;

procedure TCustomDIBFramedControl.SetDIBBorder(const Value: TDIBBorder);
begin
  if DIBBorder <> nil then DIBBorder.RemoveFreeNotification(Self);
  FDIBBorder := Value;
  if DIBBorder <> nil then DIBBorder.FreeNotification(Self);
  Invalidate;
end;

initialization
  GDefaultPopupMenu := TPopupMenu.Create(nil);
finalization
  FreeAndNil(GDefaultPopupMenu);
end.
