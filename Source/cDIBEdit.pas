unit cDIBEdit;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBEdit.PAS, released April 6, 2001.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2001 Peter Morris.
All Rights Reserved.

Purpose of file:
Provide an abstract class for creating a TEdit like component

Contributor(s):
RiceBall


Last Modified: March 23, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   April 9, 2001
By:     Peter Morris
Change: Handled the MaxLength property

Date:   April 16, 2001
By:     Peter Morris
Change: Fixed an exception bug which raised when the edit is clicked while the
        Text property = ''

Date:   May 2, 2001
By:     Peter Morris
Change: Descended from TCustomDIBBorderControl instead of TCustomDIBControl

Date:   May 28, 2001
By:     Riceball
Change: MBCS Chars Supported.

Date:   August 12, 2002
By:     Peter Morris
Change: Normal keypresses were not triggering an OnChange event

Date:   August 14, 2002
By:     Peter Morris
Change: SetSelText wasn't positioning the cursor position properly

Date:   November 9, 2002
By:     Peter Morris
Change: Default popup menu.
        CTRL+Insert, CTRL+Delete.

Date:   March 23, 2003
By:     Peter Morris
Change: CanAutoSize used
*)

{$DEFINE MBCSSUPPORT}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBControl, StdCtrls, cDIBTimer, cDIBBorder, Menus;

type
  TAbstractDIBEdit = class(TCustomDIBFramedControl)
  private
    FAutoSelect: Boolean;
    FBorderStyle: TBorderStyle;
    FCharCase: TEditCharCase;
    FCursorPos: Integer;
    FCursorShowing: Boolean;
    FCursorTimer: TDIBTimer;
    FHideSelection: Boolean;
    FFirstDisplayChar: Integer;
    FMaxLength: Integer;
    FPasswordChar: Char;
    FReadOnly: Boolean;
    FSelPoint1: Integer;
    FSelPoint2: Integer;
    FText: string;
    FOnChange: TNotifyEvent;
    procedure DoBlink(Sender: TObject);
    function GetCanUndo: Boolean;
    function GetModified: Boolean;
    procedure MenuEvent(Sender: TObject);
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetCharCase(const Value: TEditCharCase);
    procedure SetHideSelection(const Value: Boolean);
    procedure SetModified(const Value: Boolean);
    procedure SetPasswordChar(const Value: Char);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetSelText(const Value: string);
    procedure SetCursorPos(Value: Integer);

    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    //Abstract methods
    procedure DrawCursor(XPos: Integer; CurrentChar: Char); virtual; abstract;
    procedure DrawText(XPos, YPos: Integer; Value: string; Selected: Boolean);
      virtual; abstract;
    function GetTextHeight: Integer; virtual; abstract;
    function GetTextWidth(Value: string): Integer; virtual; abstract;

    //Normal methods
    function CanAutoSize(var NewWidth: Integer; var NewHeight: Integer): Boolean; override;
    procedure CalcFirstDisplayChar; virtual;
    procedure Change; dynamic;
    procedure DoDefaultPopupMenu(const PopupMenu: TPopupMenu); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure SetMaxLength(Value: Integer); virtual;
    function GetSelLength: Integer; virtual;
    function GetSelStart: Integer; virtual;
    function GetSelText: string; virtual;
    function HitTest(XPos, YPos: Integer): TPoint; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure Paint; override;
    procedure SetDIBBorder(const Value: TDIBBorder); override;
    procedure SetSelLength(Value: Integer); virtual;
    procedure SetSelStart(Value: Integer); virtual;
    procedure SetText(Value: string); virtual;

    property AutoSelect: Boolean read FAutoSelect write FAutoSelect default True;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle
      default bsSingle;
    property CharCase: TEditCharCase read FCharCase write SetCharCase default ecNormal;
    property Color default clWindow;
    property CursorPos: Integer read FCursorPos write SetCursorPos;
    property FirstDisplayChar: Integer read FFirstDisplayChar;
    property HideSelection: Boolean read FHideSelection write SetHideSelection default False;
    property MaxLength: Integer read FMaxLength write SetMaxLength default 0;
    property PasswordChar: Char read FPasswordChar write SetPasswordChar default #0;
    property ParentColor default False;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
    property Text: string read FText write SetText;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear; virtual;
    procedure ClearSelection;
    procedure CopyToClipboard;
    procedure CutToClipboard;
    procedure PasteFromClipboard;
    procedure Undo;
    procedure ClearUndo;
    function GetSelTextBuf(Buffer: PChar; BufSize: Integer): Integer; virtual;
    procedure SelectAll;
    procedure SetSelTextBuf(Buffer: PChar);
    property CanUndo: Boolean read GetCanUndo;
    property Modified: Boolean read GetModified write SetModified;
    property SelLength: Integer read GetSelLength write SetSelLength;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelText: string read GetSelText write SetSelText;
  end;

  TEditDrawCursorEvent = procedure(Sender: TObject; XPos: Integer;
    CurrentChar: Char; var Handled: Boolean) of object;
  TEditDrawTextEvent = procedure(Sender: TObject; XPos, YPos: Integer;
    Value: string; Selected: Boolean; var Handled: Boolean) of object;
  TEditMeasureTextEvent = procedure(Sender: TObject; var TextWidth, TextHeight: Integer) of
  object;

  TCustomDIBEdit = class(TAbstractDIBEdit)
  private
    FOnDrawCursor: TEditDrawCursorEvent;
    FOnDrawText: TEditDrawTextEvent;
    FOnMeasureText: TEditMeasureTextEvent;
  protected
    procedure DrawBorder; override;
    procedure DrawCursor(XPos: Integer; CurrentChar: Char); override;
    procedure DrawText(XPos, YPos: Integer; Value: string; Selected: Boolean); override;

    procedure Loaded; override;

    property OnDrawCursor: TEditDrawCursorEvent read FOnDrawCursor write FOnDrawCursor;
    property OnDrawText: TEditDrawTextEvent read FOnDrawText write FOnDrawText;
    property OnMeasureText: TEditMeasureTextEvent read FOnMeasureText write FOnMeasureText;
  public
    function GetBottomBorderSize: Integer; override;
    function GetLeftBorderSize: Integer; override;
    function GetRightBorderSize: Integer; override;
    function GetTopBorderSize: Integer; override;
    function GetTextHeight: Integer; override;
    function GetTextWidth(Value: string): Integer; override;
  end;

  TDIBEdit = class(TCustomDIBEdit)
  published
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property BackgroundStyle;
    property BorderStyle;
    property CharCase;
    property Children;
    property Color;
    property Constraints;
    property Cursor;
    property DIBBorder;
    property DIBFeatures;
    property DIBTabOrder;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HelpContext;
    property HideSelection;
    property Hint;
    property MaxLength;
    property Opacity;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property Text;
    property Visible;

    //Custom drawing
    property OnDrawBackground;
    property OnDrawBorder;
    property OnDrawCursor;
    property OnDrawText;
    property OnMeasureTopBorder;
    property OnMeasureBottomBorder;
    property OnMeasureLeftBorder;
    property OnMeasureRightBorder;
    property OnMeasureText;

    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    {$I WinControlEvents.inc}
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnPaint;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  ClipBrd;

const
  cMenuUndo = 1;
  cMenuCut = 2;
  cMenuCopy = 3;
  cMenuPaste = 4;
  cMenuDelete = 5;
  cMenuSelectAll = 6;

{ TAbstractDIBEdit }

constructor TAbstractDIBEdit.Create(AOwner: TComponent);
begin
  inherited;
  FCursorTimer := TDIBTimer.Create(Self);
  with FCursorTimer do
  begin
    Enabled := False;
    Interval := 500;
    OnTimer := DoBlink;
  end;
  FAutoSelect := True;
  AutoSize := True;
  FBorderStyle := bsSingle;
  FCharCase := ecNormal;
  FHideSelection := False;
  FMaxLength := 0;
  FPasswordChar := #0;
  ParentColor := False;
  FReadOnly := False;
  FText := Name;
  FCursorPos := 0;
  FFirstDisplayChar := 1;
  FSelPoint1 := 0;
  FSelPoint2 := 0;
  Color := clWindow;
  DIBTabOrder := 32767;
  Width := 100;
  Cursor := crIBeam;
  AddTemplateProperty('AutoSelect');
  AddTemplateProperty('AutoSize');
  AddTemplateProperty('BackgroundStyle');
  AddTemplateProperty('BorderStyle');
  AddTemplateProperty('CharCase');
  AddTemplateProperty('Color');
  AddTemplateProperty('Font');
  AddTemplateProperty('HideSelection');
  AddTemplateProperty('Opacity');
  AddTemplateProperty('PasswordChar');
end;

destructor TAbstractDIBEdit.Destroy;
begin
  FCursorTimer.Free;
  inherited;
end;

procedure TAbstractDIBEdit.Change;
begin
  FCursorTimer.Enabled := False;
  FCursorShowing := True;
  FCursorTimer.Enabled := True;
  Invalidate;
  if Assigned(OnChange) then OnChange(Self);
end;

procedure TAbstractDIBEdit.Clear;
begin
  Text := '';
end;

procedure TAbstractDIBEdit.ClearSelection;
begin
  SelText := '';
end;

procedure TAbstractDIBEdit.ClearUndo;
begin
end;

procedure TAbstractDIBEdit.CopyToClipboard;
begin
  if SelLength > 0 then Clipboard.AsText := SelText;
end;

procedure TAbstractDIBEdit.CutToClipboard;
begin
  if ReadOnly then Exit;
  CopyToClipboard;
  SelText := '';
end;

procedure TAbstractDIBEdit.SetMaxLength(Value: Integer);
begin
  if Value < 0 then Value := 0;
  FMaxLength := Value;
  if Length(Text) > Value then Text := Copy(Text, 1, Value);
end;

function TAbstractDIBEdit.GetCanUndo: Boolean;
begin
  Result := False;
end;

function TAbstractDIBEdit.GetModified: Boolean;
begin
  Result := False;
end;

function TAbstractDIBEdit.GetSelLength: Integer;
begin
  if FSelPoint1 > FSelPoint2 then
    Result := FSelPoint1 - FSelPoint2
  else
    Result := FSelPoint2 - FSelPoint1;
end;

function TAbstractDIBEdit.GetSelStart: Integer;
begin
  if FSelPoint1 < FSelPoint2 then
    Result := FSelPoint1
  else
    Result := FSelPoint2;
end;

function TAbstractDIBEdit.GetSelText: string;
begin
  Result := '';
  if SelLength > 0 then Result := Copy(FText, SelStart, SelLength);
end;

function TAbstractDIBEdit.GetSelTextBuf(Buffer: PChar;
  BufSize: Integer): Integer;
begin
  if SelLength > BufSize then Result := BufSize 
  else 
    Result := SelLength;
  if SelLength > 0 then Move(SelText[1], Buffer^, Result);
end;

procedure TAbstractDIBEdit.PasteFromClipboard;
begin
  SelText := Clipboard.AsText;
end;

procedure TAbstractDIBEdit.SelectAll;
begin
  SelStart := 0;
  SelLength := Length(FText);
end;

procedure TAbstractDIBEdit.SetBorderStyle(const Value: TBorderStyle);
begin
  FBorderStyle := Value;
end;

procedure TAbstractDIBEdit.SetCharCase(const Value: TEditCharCase);
begin
  FCharCase := Value;
end;

procedure TAbstractDIBEdit.SetHideSelection(const Value: Boolean);
begin
  FHideSelection := Value;
end;

procedure TAbstractDIBEdit.SetModified(const Value: Boolean);
begin
end;

procedure TAbstractDIBEdit.SetPasswordChar(const Value: Char);
begin
  FPasswordChar := Value;
  Invalidate;
end;

procedure TAbstractDIBEdit.SetReadOnly(const Value: Boolean);
begin
  FReadOnly := Value;
end;

procedure TAbstractDIBEdit.SetSelLength(Value: Integer);
begin
  if ReadOnly then Exit;
  if FSelPoint2 > FSelPoint1 then
    FSelPoint2 := FSelPoint1 + Value
  else
    FSelPoint1 := FSelPoint2 + Value;
  if SelLength + SelStart > Length(Text) then
    SelLength := Length(Text) - SelStart;
  if SelLength < 0 then SelLength := 0;
  Invalidate;
end;

procedure TAbstractDIBEdit.SetSelStart(Value: Integer);
begin
  if Value < 0 then Value := 0;
  if Value > Length(Text) then Value := Length(Text);
  FSelPoint1 := Value;
  FSelPoint2 := Value;
  Invalidate;
end;

procedure TAbstractDIBEdit.SetSelText(const Value: string);
begin
  if ReadOnly then Exit;
  if SelLength = 0 then
  begin
    Insert(Value, FText, CursorPos + 1);
    CursorPos := SelStart + Length(Value);
  end 
  else
  begin
    Delete(FText, SelStart + 1, SelLength);
    Insert(Value, FText, SelStart + 1);
    CursorPos := SelStart + Length(Value);
  end;
  FSelPoint1 := CursorPos;
  FSelPoint2 := FSelPoint1;
  if MaxLength > 0 then FText := Copy(FText, 1, MaxLength);
  Change;
end;

procedure TAbstractDIBEdit.SetSelTextBuf(Buffer: PChar);
begin
end;

procedure TAbstractDIBEdit.SetText(Value: string);
begin
  if MaxLength > 0 then
    FText := Copy(Value, 1, MaxLength)
  else
    FText := Value;
  SelLength := 0;
  SelStart := 0;
  CursorPos := Length(Text);
  CalcFirstDisplayChar;
  Change;
  Invalidate;
end;

procedure TAbstractDIBEdit.Undo;
begin
end;

procedure TAbstractDIBEdit.Paint;
var
  C: {$ifdef MBCSSUPPORT} String {$else} Char {$endif};
  I: Integer;
  CursorXPos, XPos, YPos, RightBorder: Integer;
begin
  YPos := GetTopBorderSize;
  XPos := GetLeftBorderSize;
  CursorXPos := GetLeftBorderSize;
  RightBorder := Width - GetRightBorderSize;
  I := FFirstDisplayChar;
  while I <= Length(Text) do
  //for I := FFirstDisplayChar to Length(Text) do
  begin
    if PasswordChar = #0 then C := Text[I] 
    else 
      C := PasswordChar;
    {$ifdef MBCSSUPPORT}
    if ByteType(C, 1) <> mbSingleByte then
    begin
      C := C + Text[I + 1];
    end;
    {$endif}
    DrawText(XPos, YPos, C, not HideSelection and (SelLength > 0) and
    (I > SelStart) and (I <= SelStart + SelLength));
    //if I = CursorPos then CursorXPos := XPos;
    Inc(XPos, GetTextWidth(C));
    if XPos >= RightBorder then Break;
    //Minor Changed by Riceball.
    Inc(I, Length(C));
  end;
  //Added by Riceball.
  if CursorPos > 0 then
    CursorXPos := CursorXPos + GetTextWidth(Copy(FText, FFirstDisplayChar,
      CursorPos - FFirstDisplayChar));

  if Focused and FCursorShowing then
    if (Text = '') or (CursorPos = 0) then
      DrawCursor(CursorXPos, #0)
    else if PasswordChar = #0 then
      DrawCursor(CursorXPos, Text[CursorPos])
    else
      DrawCursor(CursorXPos, PasswordChar);
  DrawBorder;

  if Assigned(OnPaint) then OnPaint(Self);
end;

procedure TAbstractDIBEdit.KeyDown(var Key: Word; Shift: TShiftState);
var
  OrigCursorPos: Integer;
begin
  inherited;
  case Key of
    VK_Home: CursorPos := 0;
    VK_Left:
      begin
        repeat
          OrigCursorPos := CursorPos;
          {$IFDEF MBCSSUPPORT}
          if ByteType(FText, CursorPos) = mbTrailByte then
            CursorPos := CursorPos - 2
          else
            CursorPos := CursorPos - 1;
          {$ELSE}
          CursorPos := CursorPos - 1;
          {$ENDIF}
        until (CursorPos = OrigCursorPos) or not (ssCTRL in Shift) or
          (Copy(FText, CursorPos, 1) = ' ');
      end;

    VK_Right:
      begin
        repeat
          OrigCursorPos := CursorPos;
          {$IFDEF MBCSSUPPORT}
          if ByteType(FText, CursorPos + 1) = mbLeadByte then
            CursorPos := CursorPos + 2
          else
            CursorPos := CursorPos + 1;
          {$ELSE}
          CursorPos := CursorPos + 1;
          {$ENDIF}
        until (CursorPos = OrigCursorPos) or not (ssCTRL in Shift) or
          (Copy(FText, CursorPos, 1) = ' ');
      end;

    VK_End: CursorPos := Length(Text);

    VK_Back:
      if not ReadOnly then
      begin
        if SelLength > 0 then
          SelText := ''
        else
        begin
          {$IFDEF MBCSSUPPORT}
          if ByteType(FText, CursorPos) = mbTrailByte then
          begin
            Delete(FText, CursorPos - 1, 2);
            CursorPos := CursorPos - 2;
          end
          else
          begin
            Delete(FText, CursorPos, 1);
            CursorPos := CursorPos - 1;
          end;
          {$ELSE}
          Delete(FText, CursorPos, 1);
          CursorPos := CursorPos - 1;
          {$ENDIF}
          Change;
        end;
      end;

    VK_Delete:
      if not ReadOnly then
      begin
        if ssCTRL in Shift then
          CutToClipboard
        else
        if SelLength > 0 then
          SelText := ''
        else
        if CursorPos < Length(Text) then
        begin
          {$IFDEF MBCSSUPPORT}
          if ByteType(FText, CursorPos + 1) = mbLeadByte then
            Delete(FText, CursorPos + 1, 2)
          else
            Delete(FText, CursorPos + 1, 1);
          {$ELSE}
          Delete(FText, CursorPos + 1, 1);
          {$ENDIF}
          Change;
        end;
      end;

    VK_Insert: if ssCTRL in Shift then PasteFromClipboard;

    Ord('x'), Ord('X'): if ssCTRL in Shift then CutToClipboard;
    Ord('c'), Ord('C'): if ssCTRL in Shift then CopyToClipboard;
    Ord('v'), Ord('V'): if ssCTRL in Shift then PasteFromClipboard;
  end;
end;

procedure TAbstractDIBEdit.KeyPress(var Key: Char);
begin
  if ReadOnly then Exit;
  if Key < #32 then Exit;
  if (MaxLength > 0) and (Length(Text) = MaxLength) then Exit;
  case CharCase of
    ecNormal: SelText := Key;
    ecUpperCase: SelText := Upcase(Key);
    ecLowerCase: SelText := LowerCase(Key)[1];
  end;
  Change;
end;

procedure TAbstractDIBEdit.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited;
end;

procedure TAbstractDIBEdit.DoEnter;
begin
  inherited;
  FCursorShowing := True;
  FCursorTimer.Enabled := True;
  SelStart := 0;
  if AutoSelect then
    SelLength := Length(Text)
  else
    SelLength := 0;
  Invalidate;
end;

procedure TAbstractDIBEdit.DoExit;
begin
  inherited;
  FCursorTimer.Enabled := False;
  SelStart := 0;
  SelLength := 0;
  Invalidate;
end;

procedure TAbstractDIBEdit.CalcFirstDisplayChar;
var
  Value: string;
begin
  if PasswordChar = #0 then
    Value := Text
  else
    Value := StringOfChar(PasswordChar, Length(Text));
  if CursorPos < FFirstDisplayChar then FFirstDisplayChar := CursorPos - 5;
  while GetTextWidth(Copy(Value, FFirstDisplayChar, FCursorPos - FFirstDisplayChar + 1)) >=
    (Width - GetLeftBorderSize - GetRightBorderSize) do
    Inc(FFirstDisplayChar, 5);
  if FFirstDisplayChar > Length(Value) then FFirstDisplayChar := Length(Value) - 5;
  if FFirstDisplayChar <= 0 then FFirstDisplayChar := 1;
end;

procedure TAbstractDIBEdit.SetCursorPos(Value: Integer);
var
  OldCursorPos, Distance: Integer;
begin
  if Value < 0 then Value := 0;
  if Value > Length(Text) then Value := Length(Text);
  FCursorTimer.Enabled := False;
  FCursorShowing := True;
  FCursorTimer.Enabled := True;

  OldCursorPos := CursorPos;
  FCursorPos := Value;

  if not (ssShift in ShiftState) and not (mbLeft in MouseButtons) then
  begin
    FSelPoint1 := CursorPos;
    FSelPoint2 := CursorPos;
    SelStart := CursorPos;
  end 
  else
  begin
    Distance := Value - OldCursorPos;
    if OldCursorPos = FSelPoint2 then
      Inc(FSelPoint2, Distance)
    else
      Inc(FSelPoint1, Distance);
  end;

  CalcFirstDisplayChar;
  Invalidate;
end;

procedure TAbstractDIBEdit.CMFontChanged(var Message: TMessage);
begin
  if AutoSize then AdjustSize;
  Change;
end;

procedure TAbstractDIBEdit.DoBlink(Sender: TObject);
begin
  FCursorShowing := not FCursorShowing;
  Invalidate;
end;

procedure TAbstractDIBEdit.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    {$ifdef MBCSSUPPORT}
    X := HitTest(X, Y).X;
    if ByteType(FText, X + 1) = mbTrailByte then
      CursorPos := X + 1
    else
      CursorPos := X;
    {$else}
    CursorPos := HitTest(X, Y).X;
    {$endif}
    SelStart := CursorPos;
    SelLength := 0;
  end;
end;

procedure TAbstractDIBEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if mbLeft in MouseButtons then
  {$ifdef MBCSSUPPORT}
  begin
    X := HitTest(X, Y).X;
    if ByteType(FText, X + 1) = mbTrailByte then
      CursorPos := X + 1
    else 
      CursorPos := X;
  end;
  {$else}
  CursorPos := HitTest(X, Y).X;
  {$endif}
end;

procedure TAbstractDIBEdit.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
end;

function TAbstractDIBEdit.HitTest(XPos, YPos: Integer): TPoint;
var
  I, CurrentX, RightBorderEdge, CharWidth: Integer;
begin
  Result.X := -1;
  Result.Y := 0;
  if Length(Text) = 0 then Exit;

  CurrentX := GetLeftBorderSize;
  RightBorderEdge := Width - GetRightBorderSize;
  for I := FirstDisplayChar - 1 to Length(Text) do
  begin
    if PasswordChar <> #0 then
      CharWidth := GetTextWidth('*')
    else
      CharWidth := GetTextWidth(Text[I]);
    if CurrentX + CharWidth + (CharWidth shr 1) >= XPos then
    begin
      Result.X := I;
      Break;
    end;

    Inc(CurrentX, CharWidth);
    if CurrentX >= (RightBorderEdge) then Break;
  end;
  if Result.X < 0 then Result.X := Length(Text);
end;

procedure TAbstractDIBEdit.SetDIBBorder(const Value: TDIBBorder);
begin
  inherited;
  if AutoSize then AdjustSize;
end;

procedure TAbstractDIBEdit.DoDefaultPopupMenu(const PopupMenu: TPopupMenu);
  function AddMenu(const Caption: string; Enabled: Boolean): TMenuItem;
  begin
    Result := TMenuItem.Create(Self);
    Result.Caption := Caption;
    Result.Enabled := Enabled;
    Result.OnClick := MenuEvent;
    PopupMenu.Items.Add(Result);
  end;

begin
  inherited;
  with AddMenu('Undo', CanUndo) do Tag := cMenuUndo;
  AddMenu('-', False);
  with AddMenu('Cut', not ReadOnly) do Tag := cMenuCut;
  with AddMenu('Copy', SelLength > 0) do Tag := cMenuCopy;
  with AddMenu('Paste', (not ReadOnly) and (Clipboard.AsText <> '')) do Tag := cMenuPaste;
  with AddMenu('Delete', (not ReadOnly) and (SelLength > 0)) do Tag := cMenuDelete;
  AddMenu('-', False);
  with AddMenu('Select All', Length(FText) > 0) do Tag := cMenuSelectAll;
end;

procedure TAbstractDIBEdit.MenuEvent(Sender: TObject);
begin
  case (Sender as TMenuItem).Tag of
    cMenuUndo: Undo;
    cMenuCut: CutToClipboard;
    cMenuCopy: CopyToClipboard;
    cMenuPaste: PasteFromClipboard;
    cMenuDelete: ClearSelection;
    cMenuSelectAll:
      begin
        SelStart := 0;
        SelLength := Length(FText);
      end;
  end;
end;

function TAbstractDIBEdit.CanAutoSize(var NewWidth,
  NewHeight: Integer): Boolean;
begin
  NewHeight := GetTopBorderSize + GetTopBorderSize + GetTextHeight;
  Result := NewHeight > 0;
end;

{ TCustomDIBEdit }
                                        
procedure TCustomDIBEdit.DrawBorder;
var
  Handled: Boolean;
begin
  if Assigned(DIBBorder) then
  begin
    inherited;
    Exit;
  end;

  if BorderStyle = bsSingle then
  begin
    Handled := False;
    if Assigned(OnDrawBorder) then OnDrawBorder(Self, Handled);
    if not Handled then with Canvas do
      begin
        Pen.Style := psSolid;
        Pen.Color := clBtnShadow;
        Pen.Width := 4;

        MoveTo(0, Height);
        LineTo(0, 0);
        LineTo(Width, 0);

        Pen.Width := 1;
        Pen.Color := clBtnHighlight;
        MoveTo(0, Height - 1);
        LineTo(Width - 1, Height - 1);
        LineTo(Width - 1, 0);

        Pen.Color := clBtnFace;
        MoveTo(2, Height - 2);
        LineTo(Width - 2, Height - 2);
        LineTo(Width - 2, 1);
      end;
  end;
end;

procedure TCustomDIBEdit.DrawCursor(XPos: Integer; CurrentChar: Char);
var
  Handled: Boolean;
  CharWidth, LineHeight: Integer;
begin
  Handled := False;
  if Assigned(OnDrawCursor) then OnDrawCursor(Self, XPos, CurrentChar, Handled);
  if not Handled then with Canvas do
    begin
      Font.Assign(Self.Font);
      if CurrentChar <> #0 then
        CharWidth := TextWidth(CurrentChar) + 1
      else
        CharWidth := 0;
      Pen.Color := Self.Font.Color;
      Pen.Style := psSolid;
      Pen.Width := 2;

      LineHeight := GetTextHeight;
      if LineHeight > Height - GetBottomBorderSize - 1 then
        LineHeight := Height - GetBottomBorderSize - 1;
      MoveTo(XPos + CharWidth, GetTopBorderSize);
      LineTo(XPos + CharWidth, GetTopBorderSize + LineHeight);
    end;
end;

procedure TCustomDIBEdit.DrawText(XPos, YPos: Integer; Value: string; Selected: Boolean);
var
  Handled: Boolean;
begin
  Handled := False;
  if Assigned(OnDrawText) then OnDrawText(Self, XPos, YPos, Value, Selected, Handled);

  if not Handled then with Canvas do
    begin
      Font.Assign(Self.Font);
      if Selected then
      begin
        Canvas.Brush.Style := Graphics.bsSolid;
        Canvas.Brush.Color := clHighlight;
        Font.Color := clHighlightText;
      end 
      else
        Canvas.Brush.Style := bsClear;
      TextOut(XPos, YPos, Value);
    end;
end;

function TCustomDIBEdit.GetBottomBorderSize: Integer;
begin
  if Assigned(DIBBorder) then
  begin
    Result := inherited GetBottomBorderSize;
    Exit;
  end;

  if BorderStyle <> bsSingle then
    Result := 0
  else
  begin
    Result := 3;
    if Assigned(OnMeasureBottomBorder) then OnMeasureBottomBorder(Self, Result);
  end;
end;

function TCustomDIBEdit.GetLeftBorderSize: Integer;
begin
  if Assigned(DIBBorder) then
  begin
    Result := inherited GetLeftBorderSize;
    Exit;
  end;

  if BorderStyle <> bsSingle then
    Result := 0
  else
  begin
    Result := 3;
    if Assigned(OnMeasureLeftBorder) then OnMeasureLeftBorder(Self, Result);
  end;
end;

function TCustomDIBEdit.GetRightBorderSize: Integer;
begin
  if Assigned(DIBBorder) then
  begin
    Result := inherited GetRightBorderSize;
    Exit;
  end;

  if BorderStyle <> bsSingle then
    Result := 0
  else
  begin
    Result := 3;
    if Assigned(OnMeasureRightBorder) then OnMeasureRightBorder(Self, Result);
  end;
end;

function TCustomDIBEdit.GetTopBorderSize: Integer;
begin
  if Assigned(DIBBorder) then
  begin
    Result := inherited GetTopBorderSize;
    Exit;
  end;

  if BorderStyle <> bsSingle then
    Result := 0
  else
  begin
    Result := 3;
    if Assigned(OnMeasureTopBorder) then OnMeasureTopBorder(Self, Result);
  end;
end;

function TCustomDIBEdit.GetTextHeight: Integer;
var
  TxtWidth: Integer;
begin
  Result := 0;
  if Parent = nil then Exit;
  with TControlCanvas.Create do
    try
      Control := Parent;
      Font.Assign(Self.Font);
      Result := TextHeight('Wg');
      if Assigned(OnMeasureText) then
      begin
        TxtWidth := TextWidth('G');
        OnMeasureText(Self, TxtWidth, Result);
      end;
    finally
      Free;
    end;
end;

function TCustomDIBEdit.GetTextWidth(Value: string): Integer;
var
  TxtHeight: Integer;
begin
  Result := 0;
  if Parent = nil then Exit;
  with TControlCanvas.Create do
    try
      Control := Parent;
      Font.Assign(Self.Font);
      Result := TextWidth(Value);
      if Assigned(OnMeasureText) then
      begin
        //Minor Changed by Riceball.
        TxtHeight := TextHeight('Wg');
        OnMeasureText(Self, Result, TxtHeight);
      end;
    finally
      Free;
    end;
end;

procedure TCustomDIBEdit.Loaded;
begin
  inherited;
  CursorPos := 0;
end;

end.
