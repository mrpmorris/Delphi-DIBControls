unit DIBEditor;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: DIBEditor.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
Editor for DIBs, load / save / import mask etc.

Contributor(s):
None as yet


Last Modified: August 31, 2000

You may retrieve the latest version of this file from my home page
located at  http://www.droopyeyes.com


Known Issues:
Add an Eyedropper for chosing transparent colour.
Status bar does not reflect actual display name.


Date : 31 - Aug, 2000 :
By :support@droopyeyes.com
Changes
Made TxxxxxxEditor to TxxxxxxxProperty to comply with VCL standards.
Made sure all unit names start with DIB to avoice conflicts with other people's
component packs.

Date : 14 NOV 2001
By   : NthDominion@Earthlink.net (CAM Moorman)
Removed:
  unused TImageList.
Add:
  Work around for bug in spin edit, if user removes all text in editor
  Reworked tools UI to be much like Adobe/Corel rollups
  Toolbox window, Image Properties, and Export Functionality
  Scrollbars when needed for large images.
  Added Dropper Transparent Color selector
  Coolbar is required to allow the Toolbar images to behave properly on a white background
  Added Image from Clipboard. (Mask cannot be handled this way)
-----------------------------------------------------------------------------}

interface

{$i ..\OpenSource\dfs.inc}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIBControl, cDIBImage, StdCtrls, cDIBPanel, ExtCtrls, Menus, ExtDlgs,
  {$IFDEF DFS_NO_DSGNINTF}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF}
  Spin, jpeg, ComCtrls, TypInfo, cDIB, cDIBImageList,
  Buttons, ActnList, cDIBSlider, cDIBFormShaper, cDIBDial, ImgList, ToolWin;

type
  TAbstractSuperDIBProperty = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  TScale = 1..1000;
  TImageTransparencyMode = (itmNone, itmAuto, itmFixed);

  TfmDIBEditor = class(TForm)
    opd1: TOpenPictureDialog;
    cdColor: TColorDialog;
    DIBImageList1: TDIBImageList;
    dicRender: TDIBImageContainer;
    DIBImage1: TDIBImage;
    stbStatus: TStatusBar;
    spd1: TSavePictureDialog;
    pmImgOpt: TPopupMenu;
    Actions: TActionList;
    actImageFromFile: TAction;
    actMaskFromFile: TAction;
    actExportImage: TAction;
    actCloseOK: TAction;
    pmOpenImage: TMenuItem;
    pmExportImage: TMenuItem;
    DIBILParts: TDIBImageList;
    DIBImageOptions: TDIBImageContainer;
    ScaleSlider: TDIBSlider;
    OpacitySlider: TDIBSlider;
    cbTransparentMode: TComboBox;
    shTransparentColor: TShape;
    cbMasked: TCheckBox;
    lblColor: TLabel;
    Skinner: TDIBFormShaper;
    sbTransparent: TSpeedButton;
    sbAngle: TSpeedButton;
    sbScale: TSpeedButton;
    sbOpacity: TSpeedButton;
    lblTransMode: TLabel;
    lblMasked: TLabel;
    udScale: TUpDown;
    lblScale: TLabel;
    udAngle: TUpDown;
    lblAngle: TLabel;
    udOpacity: TUpDown;
    lblOpacity: TLabel;
    AngleDial: TDIBDial;
    actImageFromClipboard: TAction;
    pmAcquireImage: TMenuItem;
    FromClipboard1: TMenuItem;
    pmAcquireMask: TMenuItem;
    actCloseCancel: TAction;
    actExportMask: TAction;
    pmExport: TMenuItem;
    pmExportMask: TMenuItem;
    actRevertImage: TAction;
    VScroller: TDIBSlider;
    HScroller: TDIBSlider;
    sbDropper: TSpeedButton;
    tbMain: TToolBar;
    ilTBAlive: TImageList;
    tbLoad: TToolButton;
    tbLoadClipboard: TToolButton;
    tbLoadMask: TToolButton;
    ToolButton6: TToolButton;
    tbUndo: TToolButton;
    ToolButton8: TToolButton;
    tbCancel: TToolButton;
    tbAccept: TToolButton;
    ToolButton11: TToolButton;
    ilTBDead: TImageList;
    cbMain: TCoolBar;
    ToolButton12: TToolButton;
    tbSave: TToolButton;
    tbSaveMask: TToolButton;
    edScale: TEdit;
    edOpacity: TEdit;
    edAngle: TEdit;
    procedure cbMaskedClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbTransparentModeChange(Sender: TObject);
    procedure shTransparentColorMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnImageImportClick(Sender: TObject);
    procedure btnMaskImportClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure DIBImageOptionsMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure OpacitySliderChange(Sender: TObject);
    procedure ScaleSliderChange(Sender: TObject);
    procedure AngleDialChange(Sender: TObject);
    procedure stbStatusResize(Sender: TObject);
    procedure Resized(Sender: TObject);
    procedure ToolBoxButtonClick(Sender: TObject);
    procedure actExportImageExecute(Sender: TObject);
    procedure actCloseCancelExecute(Sender: TObject);
    procedure actExportMaskExecute(Sender: TObject);
    procedure actExportMaskUpdate(Sender: TObject);
    procedure actExportImageUpdate(Sender: TObject);
    procedure actMaskFromFileUpdate(Sender: TObject);
    procedure actCloseOKUpdate(Sender: TObject);
    procedure stbStatusDrawPanel(StatusBar: TStatusBar;
      Panel: TStatusPanel; const Rect: TRect);
    procedure HScrollerChange(Sender: TObject);
    procedure NeedScrollbars(Sender: TObject);
    procedure VScrollerChange(Sender: TObject);
    procedure sbDropperClick(Sender: TObject);
    procedure actRevertImageExecute(Sender: TObject);
    procedure actRevertImageUpdate(Sender: TObject);
    procedure actImageFromClipboardExecute(Sender: TObject);
    procedure actImageFromClipboardUpdate(Sender: TObject);
    procedure DIBImage1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DIBImage1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DIBImage1MouseLeave(Sender: TObject);
    procedure udAngleChanging(Sender: TObject; var AllowChange: Boolean);
    procedure udOpacityChanging(Sender: TObject; var AllowChange: Boolean);
    procedure udScaleChanging(Sender: TObject; var AllowChange: Boolean);
  private
    fModified: Boolean;
    { Private declarations }
    procedure UpdateStatusBar;
    function GetImageAngle: Extended;
    function GetImageOpacity: Byte;
    function GetImageScale: TScale;
    procedure SetImageAngle(const Value: Extended);
    procedure SetImageOpacity(const Value: Byte);
    procedure SetImageScale(const Value: TScale);
    function GetImageMasked: Boolean;
    function GetTransColor: TColor;
    function GetTransMode: TImageTransparencyMode;
    procedure SetImageMasked(const Value: Boolean);
    procedure SetTransColor(const Value: TColor);
    procedure SetTransMode(const Value: TImageTransparencyMode);
    procedure SetModified(const Value: Boolean);
    procedure ToolboxEnable(State: Boolean);
    procedure UpdateGUI;
  protected
    property ImageOpacity: Byte read GetImageOpacity write SetImageOpacity;
    property ImageScale: TScale read GetImageScale write SetImageScale;
    property ImageAngle: Extended read GetImageAngle write SetImageAngle;
    property ImageMasked: Boolean read GetImageMasked write SetImageMasked;
    property ImageTransparencyMode: TImageTransparencyMode 
      read GetTransMode write SetTransMode;
    property ImageTransparentColor: TColor read GetTransColor write SetTransColor;
    property Modified: Boolean read fModified write SetModified;
  public
    { Public declarations }
    FCurrentImage: TMemoryDIB;
  end;

implementation

uses
  DIBPNGFormat,
  ClipBrd;
{$R *.DFM}
const
  crDropper = 10;

  { TAbstractSuperDIBProperty }

procedure TAbstractSuperDIBProperty.Edit;
var
  EdForm: TfmDIBEditor;
begin
  EdForm := TfmDIBEditor.Create(Application);
  with EdForm do
    try
      FCurrentImage := DIBImageList1.DIBImages[0].DIB;
      FCurrentImage.Assign(TAbstractSuperDIB(GetOrdValue));
      UpdateStatusBar;
      ShowModal;

      if ModalResult = mrOk then
        with TAbstractSuperDIB(GetOrdValue) do
        begin
          Assign(FCurrentImage);
          Self.Designer.Modified;
        end
      else
        Self.Revert;
    finally
      EdForm.Release;
    end;
end;

function TAbstractSuperDIBProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paReadOnly, paDialog];
end;

{ TfmDIBEditor }

procedure TfmDIBEditor.UpdateStatusBar;
const
  MODTXT: array[Boolean] of String = ('', 'Modified');
begin
  with stbStatus do
  begin
    Panels[0].Text := MODTXT[fModified];
    if (FCurrentImage.Height > 1) and (FCurrentImage.Width > 1) then
      Panels[2].Text := IntToStr(FCurrentImage.Width) + ' X ' + IntToStr(FCurrentImage.Height)
    else
      Panels[2].Text := 'No Image Selected';
    Invalidate;  //force the OwnerDraw Panels
  end;
end;

procedure TfmDIBEditor.FormCreate(Sender: TObject);
begin
  try
    Screen.Cursors[crDropper] := LoadCursor(HInstance, 'DROPPER');
  except
  end;
  fModified := False;
  FCurrentImage := DIBImageList1.DIBImages[0].DIB;
  DIBImage1.DIBImageList := DIBImageList1;
  DIBImage1.IndexMain.DIBIndex := 0;
  // AZZA
  UpdateStatusBar;
end;

// AZZA
procedure TfmDIBEditor.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Ord(Key) = VK_ESCAPE) then
    Close;
end;

procedure TfmDIBEditor.cbMaskedClick(Sender: TObject);
begin
  ImageMasked := cbMasked.Checked;
end;

procedure TfmDIBEditor.cbTransparentModeChange(Sender: TObject);
begin
  ImageTransparencyMode := TImageTransparencyMode(cbTransparentMode.ItemIndex);
end;

procedure TfmDIBEditor.shTransparentColorMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if ImageTransparencyMode <> itmNone then
    if cdColor.Execute then ImageTransparentColor := cdColor.Color;
end;

procedure TfmDIBEditor.btnImageImportClick(Sender: TObject);
begin
  with opd1 do
  begin
    Title := 'Open Image';
    if Execute then
    begin
      FCurrentImage.LoadPicture(opd1.FileName);
      Modified := True;
    end;
  end;
end;

procedure TfmDIBEditor.btnMaskImportClick(Sender: TObject);
begin
  with opd1 do
  begin
    Title := 'Open Image Mask';
    if Execute then
    begin
      FCurrentImage.ImportMask(Filename);
      Modified := True;
    end;
  end;
end;

procedure TfmDIBEditor.btnOkClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfmDIBEditor.DIBImageOptionsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
const
  MinMaxBtnRect: TRect = (Left: 180 - 12; Top: 0; Right: 180; Bottom: 12);
  TitleBarRect: TRect = (Left: 0; Top: 0; Right: 180; Bottom: 12);
begin
  if (Button <> mbLeft) then Exit;

  //Min/Max button?
  if PtInRect(MinMaxBtnRect, Point(X, Y)) then
  begin
    Skinner.Active := not Skinner.Active;
    Exit;
  end;
  //Title Bar?
  if PtInRect(TitleBarRect, Point(X, Y)) then
  begin
    ReleaseCapture;
    (Sender as TControl).Perform(WM_SYSCOMMAND, $F012, 0);
  end;
end;

function TfmDIBEditor.GetImageAngle: Extended;
begin
  Result := FCurrentImage.Angle;
end;

function TfmDIBEditor.GetImageOpacity: Byte;
begin
  Result := FCurrentImage.Opacity;
end;

function TfmDIBEditor.GetImageScale: TScale;
begin
  Result := Trunc(FCurrentImage.Scale);
end;

procedure TfmDIBEditor.SetImageAngle(const Value: Extended);
begin
  if Value <> FCurrentImage.Angle then
  begin
    FCurrentImage.Angle := Value;
    DIBImage1.Angle := Value;
    udAngle.Position := Trunc(Value);
    AngleDial.Position := Trunc(Value);
    Modified := True;
  end;
end;

procedure TfmDIBEditor.SetImageOpacity(const Value: Byte);
begin
  if Value <> FCurrentImage.Opacity then
  begin
    FCurrentImage.Opacity := Value;
    DIBImage1.Opacity := Value;
    udOpacity.Position := Value;
    OpacitySlider.Position := Value;
    Modified := True;
  end;
end;

procedure TfmDIBEditor.SetImageScale(const Value: TScale);
begin
  if Value <> FCurrentImage.Scale then
  begin
    FCurrentImage.Scale := Value;
    DIBImage1.Scale := Value;
    udScale.Position := Value;
    ScaleSlider.Position := Value;
    Modified := True;
  end;
end;

procedure TfmDIBEditor.OpacitySliderChange(Sender: TObject);
begin
  ImageOpacity := OpacitySlider.Position;
end;

procedure TfmDIBEditor.ScaleSliderChange(Sender: TObject);
begin
  ImageScale := ScaleSlider.Position;
end;

procedure TfmDIBEditor.AngleDialChange(Sender: TObject);
begin
  ImageAngle := AngleDial.Position;
end;

procedure TfmDIBEditor.stbStatusResize(Sender: TObject);
const
  //this is the panel index you want to take up the extra space
  PNL = 1;
var
  P, W: Integer;
begin
  with stbStatus do
  begin
    W := 0;
    for P := 0 to Panels.Count - 1 do
      if P <> PNL then W := W + Panels[P].Width;
    Panels[PNL].Width := ClientWidth - W;
  end;
end;

function TfmDIBEditor.GetImageMasked: Boolean;
begin
  Result := FCurrentImage.Masked;
end;

function TfmDIBEditor.GetTransColor: TColor;
begin
  Result := FCurrentImage.TransparentColor;
end;

function TfmDIBEditor.GetTransMode: TImageTransparencyMode;
const
  XMode: array [TTransparentMode] of TImageTransparencyMode =
    (itmAuto, itmFixed);
begin
  if not FCurrentImage.Transparent then
    Result := itmNone
  else
    Result := XMode[FCurrentImage.TransparentMode];
end;

procedure TfmDIBEditor.SetImageMasked(const Value: Boolean);
begin
  if Value <> FCurrentImage.Masked then
  begin
    FCurrentImage.Masked := Value;
    Modified := True;
  end;
end;

procedure TfmDIBEditor.SetTransColor(const Value: TColor);
begin
  FCurrentImage.TransparentColor := Value;
  shTransparentColor.Brush.Color := Value;
  Modified := True;
end;

procedure TfmDIBEditor.SetTransMode(const Value: TImageTransparencyMode);
const
  XMode: array [TImageTransparencyMode] of TTransparentMode =
    (tmAuto, tmAuto, tmFixed);
begin
  cbTransparentMode.ItemIndex := Ord(Value);
  with FCurrentImage do
  begin
    Transparent := (Value <> itmNone);
    if Transparent then TransparentMode := XMode[Value];
    //update the transparent color (Fixed to auto may change values)
    ImageTransparentColor := FCurrentImage.TransparentColor;
  end;
  Modified := True;
end;

procedure TfmDIBEditor.Resized(Sender: TObject);
var
  DIB: TMemoryDIB;
begin
  //Ensure we can still see the toolbox
  UpdateGUI;
  with DIBImageOptions do
  begin
    Left := DICRender.ClientWidth - (Width + 4);
    Top := 4;
  end;
  DIBImage1.Left := 0;
  DIBImage1.Top := 0;
  //do we need scrollbars?
  NeedScrollbars(Sender);
  DIB := DIBImageList1.DIBImages[0].DIB;
  if (DIB.Width = 1) and (DIB.Height = 1) then
    tbLoad.Click;
end;

procedure TfmDIBEditor.ToolBoxButtonClick(Sender: TObject);
var
  C: Integer;
  T: Integer;
begin
  //should not happen, but....
  if not (Sender is TSpeedButton) then Exit;
  T := Abs((Sender as TComponent).Tag);

  with DIBImageOptions do
    for C := 0 to ControlCount - 1 do
      if Controls[C].Tag > 0 then
        Controls[C].Visible := (T = Controls[C].Tag);
end;

procedure TfmDIBEditor.actExportImageExecute(Sender: TObject);
begin
  with spd1 do
  begin
    Title := 'Export Image';
    if Execute then
    begin
      FCurrentImage.SavePicture(spd1.FileName);
      Modified := True;
    end;
  end;
end;

procedure TfmDIBEditor.actCloseCancelExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfmDIBEditor.actExportMaskExecute(Sender: TObject);
begin
  with spd1 do
  begin
    Title := 'Export Image Mask';
    if Execute then
    begin
      FCurrentImage.ExportMask(Filename);
      Modified := True;
    end;
  end;
end;

procedure TfmDIBEditor.actExportMaskUpdate(Sender: TObject);
begin
  actExportMask.Enabled := FCurrentImage.Masked and
    (FCurrentImage.Height > 1) and (FCurrentImage.Width > 1);
end;

procedure TfmDIBEditor.actExportImageUpdate(Sender: TObject);
begin
  actExportImage.Enabled := (FCurrentImage.Height > 1) and (FCurrentImage.Width > 1);
end;

procedure TfmDIBEditor.actMaskFromFileUpdate(Sender: TObject);
begin
  actMaskFromFile.Enabled := (FCurrentImage.Height > 1) and (FCurrentImage.Width > 1);
  ToolboxEnable(actMaskFromFile.Enabled);
end;

procedure TfmDIBEditor.actCloseOKUpdate(Sender: TObject);
begin
  actCloseOK.Enabled := fModified and
    (FCurrentImage.Height > 1) and (FCurrentImage.Width > 1);
end;

procedure TfmDIBEditor.stbStatusDrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
var
  R: TRect;

  procedure DrawIcon(Icon: TBitmap);
  begin
    //think square
    R := Bounds(0, 0, Rect.Bottom - Rect.Top, Rect.Bottom - Rect.Top);
    OffSetRect(R, Rect.Left, Rect.Top);
    InflateRect(R, - 1, - 1);
    //draw the icon
    StatusBar.Canvas.BrushCopy(R, Icon,
      Bounds(0, 0, Icon.Width, Icon.Height), Icon.TransparentColor);
  end;

  procedure DoText(Text: string);
  begin
    with StatusBar.Canvas do
    begin
      Brush.Style := bsClear;
      OffsetRect(R, (R.Right - R.Left) + 2, 0);
      R.Right := Rect.Right;
      DrawText(Handle, PChar(Text), Length(Text), R,
        DT_VCENTER or DT_LEFT or DT_SINGLELINE);
    end;
  end;

  procedure DoXMode;
  const
    XMode: array [TImageTransparencyMode] of String = ('None', 'Auto', 'Fixed');
  begin
    DrawIcon(sbTransparent.Glyph);
    with StatusBar.Canvas do
    begin
      //draw the transparent color cube
      CopyMode := cmSrcCopy;
      OffsetRect(R, (R.Right - R.Left) + 2, 0);
      InflateRect(R, - 1, - 1);
      if FCurrentImage.Transparent then
      begin
        { TODO : Is there a fix for the quirky inverted colors? }
        Brush.Color := shTransparentColor.Brush.Color;
        Pen.Color := clBtnHighlight;
      end
      else
      begin
        Brush.Color := clWhite;
        Pen.Color := clBlack;
      end;
      RoundRect(R.Left, R.Top, R.Right, R.Bottom, 5, 5);

      //cross out the none transparent Display
      if not FCurrentImage.Transparent then
      begin
        MoveTo(R.Left, R.Top);
        LineTo(R.Right, R.Bottom);
      end;

      DoText(XMode[ImageTransparencyMode]);
    end;
  end;
begin
  case Panel.Index of
    0:;  //image modified panel
    1:;  //dead space
    2:;  //image size panel
    3:;  //Cursor Position panel
    4: DoXMode;  //Transparency Panel
    5: //Opaque Panel
      begin
        DrawIcon(sbOpacity.Glyph);
        DoText(IntToStr(ImageOpacity));
      end;
    6: //Angle Panel
      begin
        DrawIcon(sbAngle.Glyph);
        DoText(FloatToStr(ImageAngle));
      end;
    7:   //Scale Panel
      begin
        DrawIcon(sbScale.Glyph);
        DoText(IntToStr(ImageScale));
      end;
    8:;  //dead space
  end;
end;

procedure TfmDIBEditor.SetModified(const Value: Boolean);
begin
  fModified := Value;
  UpdateGUI;
  UpdateStatusBar;
end;

procedure TfmDIBEditor.ToolboxEnable(State: Boolean);
var 
  C: Integer;
begin
  with DIBImageOptions do
    for C := 0 to ControlCount - 1 do
      Controls[C].Enabled := State;
end;

procedure TfmDIBEditor.NeedScrollbars(Sender: TObject);
var 
  M: Integer;
begin
  with HScroller do
  begin
    Visible := DIBImage1.Width > (dicRender.Width - VScroller.Width);
    M := Round(DIBImage1.Width / dicRender.Width);
    if M = 0 then Max := 1 
    else 
      Max := M;
  end;
  with VScroller do
  begin
    Visible := DIBImage1.Height > (dicRender.Height - HScroller.Height);
    M := (DIBImage1.Height div dicRender.Height);
    if M = 0 then Max := 1 
    else 
      Max := M;
  end;
end;

procedure TfmDIBEditor.HScrollerChange(Sender: TObject);
begin
  with HScroller do
    if Position = 0 then
      DIBImage1.Left := 0
  else
    DIBImage1.Left := ((DIBImage1.Width - dicRender.Width) div Max) * -Position;
end;

procedure TfmDIBEditor.VScrollerChange(Sender: TObject);
begin
  with VScroller do
    if Position = 0 then
      DIBImage1.Top := 0
  else
    DIBImage1.Top := ((DIBImage1.Height - dicRender.Height) div Max) * -Position;
end;

procedure TfmDIBEditor.sbDropperClick(Sender: TObject);
const
  CSR: array[Boolean] of TCursor = (crDefault, crDropper);
begin
  if ImageTransparencyMode <> itmNone then
    DIBImage1.Cursor := CSR[sbDropper.Down]
  else
  begin
    sbDropper.Down := False;
    DIBImage1.Cursor := crDefault;
  end;
end;

procedure TfmDIBEditor.actRevertImageExecute(Sender: TObject);
begin
  //could use FCurrentImage.ResetHeader here, but we want the side effects of our properties
  ImageScale := 100;
  ImageOpacity := 255;
  ImageAngle := 0;
  ImageMasked := False;
  ImageTransparencyMode := itmNone;
end;

procedure TfmDIBEditor.actRevertImageUpdate(Sender: TObject);
begin
  actRevertImage.Enabled := (FCurrentImage.Height > 1) and (FCurrentImage.Width > 1) and fModified;
end;

procedure TfmDIBEditor.actImageFromClipboardExecute(Sender: TObject);
var
  BMP: TBitmap;
  HdlData, HdlPalette: THandle;
  WinDIB: TWinDIB;
  R: TRect;
begin
  BMP := TBitmap.Create;
  WinDIB := TWinDIB.Create;
  try
    //get the clipboard data. palette is unused
    HdlPalette := 0;    //shut the compiler up.
    HdlData := Clipboard.GetAsHandle(CF_BITMAP);
    BMP.LoadFromClipboardFormat(CF_BITMAP, HdlData, HdlPalette);
    with WinDIB do
    begin
      //transfer the image to the WinDIB
      Width := BMP.Width;
      Height := BMP.Height;
      R := Rect(0, 0, Width, Height);
      ClipRect := R;
      WinDIB.Canvas.CopyRect(R, BMP.Canvas, R);
    end;
    //Transfer the DIB to the running image
    FCurrentImage.Assign(WinDIB);
    Modified := True;
  finally
    BMP.Free;
    WinDIB.Free;
  end;
end;

procedure TfmDIBEditor.actImageFromClipboardUpdate(Sender: TObject);
begin
  actImageFromClipboard.Enabled := Clipboard.HasFormat(CF_BITMAP);
end;

procedure TfmDIBEditor.DIBImage1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  //if the dropper is active, then select the color under the pixel
  if DIBImage1.Cursor = crDropper then
  begin
    ImageTransparentColor := Pixel32ToColor(FCurrentImage.Pixels[X, Y]);
  end;
end;

procedure TfmDIBEditor.DIBImage1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  stbStatus.Panels[3].Text := Format('X:%D Y:%D', [X, Y]);
end;

procedure TfmDIBEditor.DIBImage1MouseLeave(Sender: TObject);
begin
  stbStatus.Panels[3].Text := 'X:0 Y:0';
end;

procedure TfmDIBEditor.UpdateGUI;
begin
  if Assigned(FCurrentImage) then
    with FCurrentImage do
    begin
      udAngle.Position := Trunc(Angle);
      AngleDial.Position := Trunc(Angle);
      udOpacity.Position := Opacity;
      OpacitySlider.Position := Opacity;
      udScale.Position := Round(Scale);
      ScaleSlider.Position := udScale.Position;
      cbMasked.Checked := Masked;
      // CHANGED AZZA
      if (not Transparent) then
        cbTransparentMode.ItemIndex := 0
      else
        cbTransparentMode.ItemIndex := 1 + Ord(TransparentMode);
      shTransparentColor.Brush.Color := TransparentColor;
    end;
end;

procedure TfmDIBEditor.udAngleChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  //CAM: Workaround for spin edit bug
  if edAngle.Text <> '' then
    ImageAngle := udAngle.Position;
end;

procedure TfmDIBEditor.udOpacityChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  //CAM: Workaround for spin edit bug
  if edOpacity.Text <> '' then
    ImageOpacity := udOpacity.Position;
end;

procedure TfmDIBEditor.udScaleChanging(Sender: TObject;
  var AllowChange: Boolean);
begin
  //CAM: Workaround for spin edit bug
  if edScale.Text <> '' then
    ImageScale := udScale.Position;
end;

end.
