unit cDIBButton;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBButton.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Animated buttons, may be used for Radio / checkboxes also

Contributor(s):
Sylane - sylane@excite.com
  Center property.
  Bug reports regarding timer being enabled when not needed.


Last Modified: March 23, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   September 16, 2001
Found:  Simon S <simons@email.si>
By:     Peter Morris
Change: Click would repeat if the OnClick code invoked Application.ProcessMessages
        moved the "inherited Click;" command to the end of AnimEnd.

Date:   March 23, 2003
By:     Peter Morris
Change: Added AbstractDIBButton, used CanAutoResize

Date:   June 19, 2005
By:     Peter Morris
Change: Excluded csDblClick from controlstyle

*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBControl, cDIBImageList, cDIBAnimMgr, cDIB, cDIBTimer;

type
  EDIBButtonError = class(EDIBError);
  
  TButtonState = (bsEnabled, bsMouseClick, bsDisabled, bsMouseOver, bsDown);
  TCurrentAnim = (caNone, caDisabled, caEnabled, caMouseEnter, caMouseOver,
    caMouseClick, caMouseLeave, caDown);
  TAnimMethod = (amForward, amBackward, amPingPong);

  TAbstractDIBButton = class(TCustomDIBControl)
  private
    FButtonState: TButtonState;
    FGroup: Integer;
    FDown: Boolean;
    FToggleDown: Boolean;
    procedure SetGroup(const Value: Integer);
    procedure SetOthersUp;
  protected
    procedure Click; override;
    procedure DoMouseEnter; override;
    procedure DoMouseLeave; override;
    function GetDown: Boolean;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SetButtonState(Value: TButtonState); virtual;
    procedure SetDown(const Value: Boolean); virtual;
    procedure SetEnabled(Value: Boolean); override;
    procedure UpdateButtonState; virtual;

    property ButtonState: TButtonState read FButtonState write SetButtonState;
    property Down: Boolean read FDown write SetDown default False;
    property Group: Integer read FGroup write SetGroup default 0;
    property ToggleDown: Boolean read FToggleDown write FToggleDown;
  public
    constructor Create(AOwner: TComponent); override;
  published
  end;

  TCustomDIBButtonAnim = class(TPersistent)
  private
    FAnimationLink: TDIBAnimationLink;
    FAnimDir,
    FFrame: Integer;
    FAnimMethod: TAnimMethod;
    FFrameDelay: Word;
    FOnAnimEnd: TNotifyEvent;
    FOnAnimationChanged: TNotifyEvent;
    function GetImage(var TheDIB: TMemoryDIB): Boolean;
    procedure DoAnimationChanged(Sender: TObject);
    function GetAnimation: TDIBAnimation;
    procedure SetAnimation(const Value: TDIBAnimation);
  protected
    procedure Animate;
  public
    constructor Create(AOwner: TComponent); virtual;
    destructor Destroy; override;

    function GetDimensions: TPoint;
    procedure Reset;
    function Valid: Boolean;

    property OnAnimationChanged: TNotifyEvent 
      read FOnAnimationChanged write FOnAnimationChanged;

    property AnimMethod: TAnimMethod read FAnimMethod write FAnimMethod;
    property Animation: TDIBAnimation read GetAnimation write SetAnimation;
    property FrameDelay: Word read FFrameDelay write FFrameDelay;
  published
  end;

  TDIBButtonAnim = class(TCustomDIBButtonAnim)
  published
    property AnimMethod;
    property Animation;
    property FrameDelay;
  end;

  TCustomDIBButton = class(TAbstractDIBButton)
  private
    { Private declarations }
    FAnimPic,
    FAnimEnabled,
    FAnimDisabled,
    FAnimMouseEnter,
    FAnimMouseOver,
    FAnimMouseClick,
    FAnimDown,
    FAnimMouseLeave: TDIBButtonAnim;
    FCenter: Boolean;
    FCurrentAnim: TCurrentAnim;
    FTimer: TDIBTimer;

    procedure SetAnimPic(const Value: TDIBButtonAnim);
    procedure SetCurrentAnim(const Value: TCurrentAnim);

    property AnimPic: TDIBButtonAnim read FAnimPic write SetAnimPic;
    property CurrentAnim: TCurrentAnim read FCurrentAnim write SetCurrentAnim;

    procedure DoAnimationChanged(Sender: TObject);
    procedure DoAnimEnd(Sender: TObject);
    procedure DoTimer(Sender: TObject);
  protected
    { Protected declarations }
    procedure Animate; virtual;
    procedure AnimationChanged; virtual;
    procedure AnimEnd; virtual;
    function CanAutoSize(var NewWidth: Integer; var NewHeight: Integer): Boolean; override;
    procedure DoAnyEnter; override;
    procedure DoAnyLeave; override;
    procedure Loaded; override;
    procedure Paint; override;
    procedure SetCenter(const Value: Boolean);
    procedure SetEnabled(Value: Boolean); override;
    procedure SetDown(const Value: Boolean); override;

    property AnimEnabled: TDIBButtonAnim read FAnimEnabled write FAnimEnabled;
    property AnimDown: TDIBButtonAnim read FAnimDown write FAnimDown;
    property AnimDisabled: TDIBButtonAnim read FAnimDisabled write FAnimDisabled;
    property AnimMouseEnter: TDIBButtonAnim read FAnimMouseEnter write FAnimMouseEnter;
    property AnimMouseOver: TDIBButtonAnim read FAnimMouseOver write FAnimMouseOver;
    property AnimMouseClick: TDIBButtonAnim read FAnimMouseClick write FAnimMouseClick;
    property AnimMouseLeave: TDIBButtonAnim read FAnimMouseLeave write FAnimMouseLeave;

    property Center: Boolean read FCenter write SetCenter;
    property Down: Boolean read GetDown write SetDown;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    { Published declarations }
  end;

  TDIBButton = class(TCustomDIBButton)
  private

  protected
  public
  published
    property AnimEnabled;
    property AnimDown;
    property AnimDisabled;
    property AnimMouseEnter;
    property AnimMouseOver;
    property AnimMouseClick;
    property AnimMouseLeave;
    property AutoSize;
    property Center;
    property DIBFeatures;
    property DIBTabOrder;
    property Down;
    property Group;
    property Opacity;
    property ToggleDown;

    {$I WINControlEvents.inc}
    property OnClick;
    property OnMouseEnter;
    property OnMouseLeave;
  end;


implementation

{ TAbstractDIBButton }

procedure TAbstractDIBButton.Click;
begin
  inherited;
  if ToggleDown then
    Down := not Down;
end;

constructor TAbstractDIBButton.Create(AOwner: TComponent);
begin
  inherited;
  FDown := False;
  FGroup := 0;
  FToggleDown := False;
  ControlStyle := ControlStyle - [csDoubleClicks];
end;

procedure TAbstractDIBButton.DoMouseEnter;
begin
  inherited;
  UpdateButtonState;
end;

procedure TAbstractDIBButton.DoMouseLeave;
begin
  inherited;
  UpdateButtonState;
end;

function TAbstractDIBButton.GetDown: Boolean;
begin
  Result := FDown;
end;

procedure TAbstractDIBButton.Loaded;
begin
  inherited;
  UpdateButtonState;
end;

procedure TAbstractDIBButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
    UpdateButtonState;
end;

procedure TAbstractDIBButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
    UpdateButtonState;
end;

procedure TAbstractDIBButton.SetButtonState(Value: TButtonState);
begin
  if Value <> FButtonState then
  begin
    FButtonState := Value;
    Changed;
    Invalidate;
  end;
end;

procedure TAbstractDIBButton.SetDown(const Value: Boolean);
begin
  FDown := Value;
  UpdateButtonState;
  if Down then
    SetOthersUp;
end;

procedure TAbstractDIBButton.SetEnabled(Value: Boolean);
begin
  inherited;
  UpdateButtonState;
end;

procedure TAbstractDIBButton.SetGroup(const Value: Integer);
begin
  if Group < 0 then
    raise EDIBButtonError.Create('Invalid group.');
  FGroup := Value;
  if (Value > 0) and Down then
    SetOthersUp;
end;

procedure TAbstractDIBButton.SetOthersUp;
var
  X: Integer;
begin
  if Owner = nil then exit;
  if Group = 0 then exit;

  for X := 0 to Owner.ComponentCount - 1 do
    if Owner.Components[X] is TAbstractDIBButton then
      if Owner.Components[X] <> Self then
        with TAbstractDIBButton(Owner.Components[X]) do
          if (Group = Self.Group) and Down then
            Down := False;
end;

procedure TAbstractDIBButton.UpdateButtonState;
begin
  if not Enabled then
    ButtonState := bsDisabled
  else
  if Down then
    ButtonState := bsDown
  else
  if MouseOver or Focused then
  begin
    if mbLeft in MouseButtons then
      ButtonState := bsMouseClick
    else
      ButtonState := bsMouseOver;
  end else
    ButtonState := bsEnabled;
end;

{ TCustomDIBButtonAnim }

procedure TCustomDIBButtonAnim.Animate;
begin
  if not Animation.Valid then
  begin
    if Assigned(FOnAnimEnd) then FOnAnimEnd(Self);
    Exit;
  end;

  case FAnimMethod of
    amForward:
      begin
        if FFrame + 1 >= Animation.Frames.Count then
        begin
          FFrame := 0;
          if Assigned(FOnAnimEnd) then FOnAnimEnd(Self);
        end 
        else
          FFrame := FFrame + 1;
      end;

    amBackward:
      begin
        if FFrame - 1 < 0 then
        begin
          FFrame := Animation.Frames.Count - 1;
          if Assigned(FOnAnimEnd) then FOnAnimEnd(Self);
        end 
        else
          FFrame := FFrame - 1;
      end;

    amPingPong:
      begin
        if FFrame + FAnimDir < 0 then
          if Assigned(FOnAnimEnd) then FOnAnimEnd(Self);

        if (FFrame + FAnimDir < 0) or (FFrame + FAnimDir >= Animation.Frames.Count) then
          FAnimDir := -FAnimDir;
        FFrame := FFrame + FAnimDir;
      end;
  end;
end;

constructor TCustomDIBButtonAnim.Create(AOwner: TComponent);
begin
  inherited Create;
  FAnimationLink := TDIBAnimationLink.Create;
  FAnimationLink.OnAnimationChanged := DoAnimationChanged;
  FFrameDelay := 100;
  FAnimDir := 1;
end;

destructor TCustomDIBButtonAnim.Destroy;
begin
  FAnimationLink.Free;
  inherited;
end;

procedure TCustomDIBButtonAnim.DoAnimationChanged(Sender: TObject);
begin
  if Assigned(FOnAnimationChanged) then FOnAnimationChanged(Self);
end;

function TCustomDIBButtonAnim.GetAnimation: TDIBAnimation;
begin
  Result := FAnimationLink.Animation;
end;

function TCustomDIBButtonAnim.GetDimensions: TPoint;
begin
  if Animation <> nil then
    Result := Animation.GetDimensions;
end;

function TCustomDIBButtonAnim.GetImage(var TheDIB: TMemoryDIB): Boolean;
begin
  Result := Animation.GetImage(FFrame, TheDIB);
end;

procedure TCustomDIBButtonAnim.Reset;
begin
  if FAnimMethod = amBackward then
    FFrame := Animation.Frames.Count - 1
  else
    FFrame := 0;
end;

procedure TCustomDIBButtonAnim.SetAnimation(const Value: TDIBAnimation);
begin
  FAnimationLink.Animation := Value;
  if Assigned(OnAnimationChanged) then FOnAnimationChanged(Self);
end;

function TCustomDIBButtonAnim.Valid: Boolean;
begin
  Result := False;
  if Animation <> nil then
    Result := Animation.Valid;
end;

{ TCustomDIBButton }


procedure TCustomDIBButton.Animate;
begin
  AnimPic.Animate;
  Invalidate;
end;

procedure TCustomDIBButton.AnimationChanged;
var
  OldAnim: TCurrentAnim;
begin
  if CurrentAnim = caNone then
    OldAnim := caEnabled
  else
    OldAnim := CurrentAnim;
  FCurrentAnim := caNone;
  CurrentAnim := OldAnim;
  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCustomDIBButton.AnimEnd;
begin
  case CurrentAnim of
    caMouseEnter: CurrentAnim := caMouseOver;
    caMouseLeave: CurrentAnim := caEnabled;
    caMouseClick:
      begin
        if ToggleDown then 
        begin
          FDown := not Down;
          if Down then
            CurrentAnim := caDown
          else
            CurrentAnim := caMouseOver;
        end 
        else 
        begin
          if Focused or MouseInControl then
            CurrentAnim := caMouseOver
          else
            CurrentAnim := caMouseLeave;
        end;
        inherited Click;
      end;
  end;
end;

function TCustomDIBButton.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
var
  NewSizes: TPoint;
begin
  if (AnimPic <> nil) and AnimPic.Valid then
  begin
    NewSizes := AnimPic.GetDimensions;
    NewWidth := NewSizes.X;
    NewHeight := NewSizes.Y;
    Result := True;
  end else
    Result := False;
end;

procedure TCustomDIBButton.Click;
begin
  if Enabled then CurrentAnim := caMouseClick;
end;

constructor TCustomDIBButton.Create(AOwner: TComponent);
begin
  inherited;
  FAnimEnabled := TDIBButtonAnim.Create(Self);
  FAnimDisabled := TDIBButtonAnim.Create(Self);
  FAnimMouseEnter := TDIBButtonAnim.Create(Self);
  FAnimMouseOver := TDIBButtonAnim.Create(Self);
  FAnimMouseClick := TDIBButtonAnim.Create(Self);
  FAnimDown := TDIBButtonAnim.Create(Self);
  FAnimMouseLeave := TDIBButtonAnim.Create(Self);

  FAnimEnabled.OnAnimationChanged := DoAnimationChanged;
  FAnimDisabled.OnAnimationChanged := DoAnimationChanged;
  FAnimMouseEnter.OnAnimationChanged := DoAnimationChanged;
  FAnimMouseOver.OnAnimationChanged := DoAnimationChanged;
  FAnimMouseClick.OnAnimationChanged := DoAnimationChanged;
  FAnimDown.OnAnimationChanged := DoAnimationChanged;
  FAnimMouseLeave.OnAnimationChanged := DoAnimationChanged;

  FTimer := TDIBTimer.Create(Self);
  FCurrentAnim := caNone;
  FTimer.OnTimer := DoTimer;
  AutoSize := True;
end;

destructor TCustomDIBButton.Destroy;
begin
  FTimer.Free;
  FAnimEnabled.Free;
  FAnimDisabled.Free;
  FAnimMouseEnter.Free;
  FAnimMouseOver.Free;
  FAnimMouseClick.Free;
  FAnimDown.Free;
  FAnimMouseLeave.Free;
  inherited;
end;

procedure TCustomDIBButton.DoAnimationChanged(Sender: TObject);
begin
  if not (csLoading in ComponentState) then AnimationChanged;
end;

procedure TCustomDIBButton.DoAnimEnd(Sender: TObject);
begin
  AnimEnd;
end;

procedure TCustomDIBButton.DoAnyEnter;
begin
  inherited;
  if CurrentAnim <> caMouseClick then
    if not Down then CurrentAnim := caMouseEnter;
end;

procedure TCustomDIBButton.DoAnyLeave;
begin
  if CurrentAnim <> caMouseClick then
    if not (MouseInControl or Focused) then CurrentAnim := caMouseLeave;
  inherited;
end;

procedure TCustomDIBButton.DoTimer(Sender: TObject);
begin
  Animate;
end;

procedure TCustomDIBButton.Loaded;
begin
  inherited;
  if Down then
    CurrentAnim := caDown
  else if Enabled then
    CurrentAnim := caEnabled
  else
    CurrentAnim := caDisabled;
end;

procedure TCustomDIBButton.Paint;
var
  TheDIB: TMemoryDIB;
begin
  if AnimPic <> nil then
    if AnimPic.GetImage(TheDIB) then
      if fCenter then
        TheDIB.Draw((Width - TheDIB.Width) div 2,
        (Height - TheDIB.Height) div 2,
          TheDIB.Width, TheDIB.Height, ControlDIB, 0, 0)
      else
        TheDIB.Draw(0, 0, TheDIB.Width, TheDIB.Height, ControlDIB, 0, 0);
end;

procedure TCustomDIBButton.SetAnimPic(const Value: TDIBButtonAnim);
var
  MinimumFrameCount: Integer;
begin
  if Value = AnimPic then exit;

  if CurrentAnim in [caEnabled, caDisabled, caDown, caMouseOver] then
    MinimumFrameCount := 2
  else
    MinimumFrameCount := 1;

  FAnimPic := Value;
  FAnimPic.FOnAnimEnd := DoAnimEnd;
  FAnimPic.Reset;
  FTimer.Enabled :=
    (not (csDesigning in ComponentState)) and
    (AnimPic.Animation.Valid) and
    (AnimPic.Animation.Frames.Count >= MinimumFrameCount);
  FTimer.Interval := AnimPic.FrameDelay;
  FTimer.OnTimer := DoTimer;
end;

procedure TCustomDIBButton.SetCenter(const Value: Boolean);
begin
  if Value <> FCenter then
  begin
    FCenter := Value;
    AnimationChanged;
  end;
end;

procedure TCustomDIBButton.SetCurrentAnim(const Value: TCurrentAnim);
var
  NewAnim: TDIBButtonAnim;
  IsValid: Boolean;
  Handled: Boolean;
begin
  if CurrentAnim = Value then exit;
  Handled := False;

  if not Enabled and FAnimDisabled.Valid then 
  begin
    AnimPic := FAnimDisabled;
    FCurrentAnim := caDisabled;
    Handled := True;
  end;

  if not Handled then
    if Down and FAnimDown.Valid and (Value <> caMouseClick) then 
    begin
      SetOthersUp;
      AnimPic := FAnimDown;
      FCurrentAnim := caDown;
      Handled := True;
    end;

  NewAnim := nil;
  if not Handled then 
  begin
    case Value of
      caDisabled: NewAnim := FAnimDisabled;
      caEnabled: NewAnim := FAnimEnabled;
      caMouseEnter: NewAnim := FAnimMouseEnter;
      caMouseOver: NewAnim := FAnimMouseOver;
      caMouseClick: NewAnim := FAnimMouseClick;
      caMouseLeave: NewAnim := FAnimMouseLeave;
      caDown: NewAnim := FAnimDown;
    end;

    IsValid := NewAnim.Valid;
    if (Value = caMouseOver) and not (MouseInControl or Focused) then IsValid := False;
    if not IsValid then 
    begin
      case Value of
        caEnabled: exit;
        caMouseClick:
          begin
            //If the click anim is not valid, we pretend it just ended
            FCurrentAnim := caMouseClick;
            AnimEnd;
          end;
        caMouseEnter: CurrentAnim := caMouseOver;
        caDisabled,
        caMouseOver,
        caMouseLeave,
        caDown: CurrentAnim := caEnabled;
      end;
    end
    else
    begin
      FCurrentAnim := Value;
      AnimPic := NewAnim;
    end;
  end;

  if AutoSize then AdjustSize;
  Invalidate;
end;

procedure TCustomDIBButton.SetDown(const Value: Boolean);
begin
  inherited;
  if Down then
    CurrentAnim := caDown
  else
    CurrentAnim := caMouseOver;
end;

procedure TCustomDIBButton.SetEnabled(Value: Boolean);
begin
  if Value = Enabled then exit;
  inherited;
  if not Value then
    CurrentAnim := caDisabled
  else
    CurrentAnim := caMouseOver;
end;

end.
