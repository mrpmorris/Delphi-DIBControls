unit cDIBTimer;
{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBTimer.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
TDIBTimer does not allocate a HWND unless the timer is being used,
this way we can ensure less resource useage and better performance for
the application as a whole.

Contributor(s):
None as yet


Last Modified: August 28, 2000

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
To be updated !
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   August 22, 2002
By:     Peter Morris
Change: Enabled property's default value was TRUE but it was set to FALSE in
        the constructor.  This meant that the timer never started automatically
        when it should.
*)

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, consts;

type
  TDIBTimer = class(TComponent)
  private
    FInterval: Cardinal;
    FWindowHandle: HWND;
    FOnTimer: TNotifyEvent;
    FEnabled: Boolean;
    procedure CreateHandle;
    procedure DestroyHandle;
    procedure UpdateTimer;
    procedure SetEnabled(Value: Boolean);
    procedure SetInterval(Value: Cardinal);
    procedure SetOnTimer(Value: TNotifyEvent);
    procedure WndProc(var Msg: TMessage);
  protected
    procedure Timer; dynamic;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    property Interval: Cardinal read FInterval write SetInterval default 1000;
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
  end;

implementation

{ TDIBTimer }

constructor TDIBTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEnabled := False;
  FInterval := 1000;
end;

destructor TDIBTimer.Destroy;
begin
  FEnabled := False;
  UpdateTimer;
  DestroyHandle;
  inherited Destroy;
end;

procedure TDIBTimer.WndProc(var Msg: TMessage);
begin
  with Msg do
    if Msg = WM_TIMER then
      try
        Timer;
      except
        Application.HandleException(Self);
      end
  else
    Result := DefWindowProc(FWindowHandle, Msg, wParam, lParam);
end;

procedure TDIBTimer.UpdateTimer;
begin
  KillTimer(FWindowHandle, 1);
  DestroyHandle;
  try
    if (FInterval <> 0) and FEnabled and Assigned(FOnTimer) then 
    begin
      CreateHandle;
      if SetTimer(FWindowHandle, 1, FInterval, nil) = 0 then
        raise EOutOfResources.Create(SNoTimers);
    end;
  except
    FEnabled := False;
    DestroyHandle;
  end;
end;

procedure TDIBTimer.SetEnabled(Value: Boolean);
begin
  if Value <> FEnabled then
  begin
    FEnabled := Value;
    UpdateTimer;
  end;
end;

procedure TDIBTimer.SetInterval(Value: Cardinal);
begin
  if Value <> FInterval then
  begin
    FInterval := Value;
    UpdateTimer;
  end;
end;

procedure TDIBTimer.SetOnTimer(Value: TNotifyEvent);
begin
  FOnTimer := Value;
  UpdateTimer;
end;

procedure TDIBTimer.Timer;
begin
  if Assigned(FOnTimer) then FOnTimer(Self);
end;


procedure TDIBTimer.CreateHandle;
begin
  if FWindowHandle = 0 then FWindowHandle := AllocateHWnd(WndProc);
end;

procedure TDIBTimer.DestroyHandle;
begin
  if FWindowHandle <> 0 then DeallocateHWnd(FWindowHandle);
  FWindowHandle := 0;
end;

end.
