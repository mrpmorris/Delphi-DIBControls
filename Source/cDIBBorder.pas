unit cDIBBorder;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIBBorder.PAS, released May 2, 2001.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2001 Peter Morris.
All Rights Reserved.

Purpose of file:
Allows you to define graphics for the border of a control, this is used by
TCustomDIBFramedControl.

Contributor(s):
None as yet


Last Modified: August 21, 2001

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
To be updated !
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   August 21, 2001
By:     Peter Morris
Change: Added MakeRGN method
*)
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  cDIB, cDIBImageList;

type
  TDIBBorderKind = (bkLeft, bkRight, bkTop, bkBottom);
  TDIBBorderDrawStyle = (dsTile, dsStretch);

  TDIBBorderEdge = class(TPersistent)
  private
    FAutoCalcSize: Boolean;
    FBorderKind: TDIBBorderKind;
    FDrawStyle: TDIBBorderDrawStyle;
    FImageFirst: TDIBImageLink;
    FImageLast: TDIBImageLink;
    FImageMiddle: TDIBImageLink;
    FSize: Integer;
    function GetDIBImage: TCustomDIBImageList;
    procedure SetDIBImage(const Value: TCustomDIBImageList);
    function GetSize: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure DrawTo(Dest: TAbstractSuperDIB; DestRect: TRect);
    function GetImageFirst: TDIBImageLink;
    function GetImageLast: TDIBImageLink;
    function GetImageMiddle: TDIBImageLink;
    function InternalGetSize: Integer;
    procedure SetImageFirst(const Value: TDIBImageLink);
    procedure SetImageLast(const Value: TDIBImageLink);
    procedure SetImageMiddle(const Value: TDIBImageLink);
    property DIBImageList: TCustomDIBImageList read GetDIBImage write SetDIBImage;
  public
    constructor Create(ABorderKind: TDIBBorderKind); virtual;
    destructor Destroy; override;

    procedure MakeRGN(ARect: TRect; var Result: HRGN);

    property BorderKind: TDIBBorderKind read FBorderKind;
  published
    property AutoCalcSize: Boolean read FAutoCalcSize write FAutoCalcSize default True;
    property DrawStyle: TDIBBorderDrawStyle read FDrawStyle write FDrawStyle default dsTile;
    property Size: Integer read GetSize write FSize;
  end;

  TDIBHorzBorderEdge = class(TDIBBorderEdge)
  private
  protected
  public
  published
    property ImageLeft: TDIBImageLink read GetImageFirst write SetImageFirst;
    property ImageMiddle: TDIBImageLink read GetImageMiddle write SetImageMiddle;
    property ImageRight: TDIBImageLink read GetImageLast write SetImageLast;
  end;

  TDIBVertBorderEdge = class(TDIBBorderEdge)
  private
  protected
  public
  published
    property ImageTop: TDIBImageLink read GetImageFirst write SetImageFirst;
    property ImageMiddle: TDIBImageLink read GetImageMiddle write SetImageMiddle;
    property ImageBottom: TDIBImageLink read GetImageLast write SetImageLast;
  end;

  TDIBBorder = class(TComponent)
  private
    { Private declarations }
    FBorderBottom: TDIBHorzBorderEdge;
    FBorderLeft: TDIBVertBorderEdge;
    FBorderRight: TDIBVertBorderEdge;
    FBorderTop: TDIBHorzBorderEdge;
    FDIBImageList: TCustomDIBImageList;
    procedure SetDIBImageList(const Value: TCustomDIBImageList);
  protected
    { Protected declarations }
    procedure AssignTo(Dest: TPersistent); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure DrawTo(Dest: TAbstractSuperDIB; DestRect: TRect);
    function MakeRGN(ARect: TRect): HRGN;
  published
    { Published declarations }
    property BorderBottom: TDIBHorzBorderEdge read FBorderBottom write FBorderBottom;
    property BorderLeft: TDIBVertBorderEdge read FBorderLeft write FBorderLeft;
    property BorderRight: TDIBVertBorderEdge read FBorderRight write FBorderRight;
    property BorderTop: TDIBHorzBorderEdge read FBorderTop write FBorderTop;
    property DIBImageList: TCustomDIBImageList read FDIBImageList write SetDIBImageList;
  end;

implementation

type
  THackDIB = class(TAbstractSuperDIB);

  { TDIBBorderEdge }

procedure TDIBBorderEdge.AssignTo(Dest: TPersistent);
begin
  inherited;
end;

constructor TDIBBorderEdge.Create(ABorderKind: TDIBBorderKind);
begin
  inherited Create;
  FBorderKind := ABorderKind;
  FImageFirst := TDIBImageLink.Create(nil);
  FImageLast := TDIBImageLink.Create(nil);
  FImageMiddle := TDIBImageLink.Create(nil);
  FDrawStyle := dsTile;
  FAutoCalcSize := True;
  FSize := 32;
end;

destructor TDIBBorderEdge.Destroy;
begin
  FImageMiddle.Free;
  FImageLast.Free;
  FImageFirst.Free;
  inherited;
end;

procedure TDIBBorderEdge.DrawTo(Dest: TAbstractSuperDIB; DestRect: TRect);
var
  XPos, YPos, SizeLeft: Integer;
  D: TMemoryDIB;
  TempDIB: TMemoryDIB;
begin
  if not (FImageFirst.Valid or FImageMiddle.Valid or FImageLast.Valid) then Exit;

  case BorderKind of
    bkLeft, bkRight:
      begin
        SizeLeft := DestRect.Bottom - DestRect.Top;
        YPos := DestRect.Top;
        if FImageFirst.GetImage(D) then
        begin
          Inc(YPos, D.Height);
          Dec(SizeLeft, D.Height);
        end;
        if FImageLast.GetImage(D) then Dec(SizeLeft, D.Height);
        if FImageMiddle.GetImage(D) then
        begin
          if BorderKind = bkLeft then XPos := DestRect.Left 
          else 
            XPos := DestRect.Right - D.Width;
          if DrawStyle = dsTile then
          begin
            while SizeLeft > 0 do
            begin
              D.Draw(XPos, YPos, D.Width, SizeLeft, Dest, 0, 0);
              Inc(YPos, D.Height);
              Dec(SizeLeft, D.Height);
            end;
          end 
          else
          begin
            TempDIB := TMemoryDIB.Create(D.Width, SizeLeft);
            try
              TempDIB.StretchCopyPicture(D);
              TempDIB.Draw(XPos, YPos, D.Width, SizeLeft, Dest, 0, 0);
            finally
              TempDIB.Free;
            end;
          end;
        end;

        if FImageFirst.GetImage(D) then
        begin
          if BorderKind = bkLeft then XPos := DestRect.Left 
          else 
            XPos := DestRect.Right - D.Width;
          D.Draw(XPos, DestRect.Top, D.Width, D.Height, Dest, 0, 0);
        end;
        if FImageLast.GetImage(D) then
        begin
          if BorderKind = bkLeft then XPos := DestRect.Left 
          else 
            XPos := DestRect.Right - D.Width;
          D.Draw(XPos, DestRect.Bottom - D.Height, D.Width, D.Height, Dest, 0, 0);
        end;
      end;

    bkTop, bkBottom:
      begin
        SizeLeft := DestRect.Right - DestRect.Left;
        XPos := DestRect.Left;
        if FImageFirst.GetImage(D) then
        begin
          Inc(XPos, D.Width);
          Dec(SizeLeft, D.Width);
        end;
        if FImageLast.GetImage(D) then Dec(SizeLeft, D.Width);
        if FImageMiddle.GetImage(D) then
        begin
          if BorderKind = bkTop then YPos := DestRect.Top 
          else 
            YPos := DestRect.Bottom - D.Height;
          if DrawStyle = dsTile then
          begin
            while SizeLeft > 0 do
            begin
              D.Draw(XPos, YPos, SizeLeft, D.Height, Dest, 0, 0);
              Inc(XPos, D.Width);
              Dec(SizeLeft, D.Width);
            end;
          end 
          else
          begin
            TempDIB := TMemoryDIB.Create(SizeLeft, D.Height);
            try
              TempDIB.StretchCopyPicture(D);
              TempDIB.Draw(XPos, YPos, SizeLeft, D.Height, Dest, 0, 0);
            finally
              TempDIB.Free;
            end;
          end;
        end;

        if FImageFirst.GetImage(D) then
        begin
          if BorderKind = bkTop then YPos := DestRect.Top 
          else 
            YPos := DestRect.Bottom - D.Height;
          D.Draw(DestRect.Left, YPos, D.Width, D.Height, Dest, 0, 0);
        end;
        if FImageLast.GetImage(D) then
        begin
          if BorderKind = bkTop then YPos := DestRect.Top 
          else 
            YPos := DestRect.Bottom - D.Height;
          D.Draw(DestRect.Right - D.Width, YPos, D.Width, D.Height, Dest, 0, 0);
        end;
      end;
  end;
end;

function TDIBBorderEdge.GetDIBImage: TCustomDIBImageList;
begin
  Result := FImageFirst.DIBImageList;
end;

function TDIBBorderEdge.GetImageFirst: TDIBImageLink;
begin
  Result := FImageFirst;
end;

function TDIBBorderEdge.GetImageLast: TDIBImageLink;
begin
  Result := FImageLast;
end;

function TDIBBorderEdge.GetImageMiddle: TDIBImageLink;
begin
  Result := FImageMiddle;
end;

function TDIBBorderEdge.GetSize: Integer;
begin
  if AutoCalcSize then Result := InternalGetSize 
  else 
    Result := FSize;
end;

function TDIBBorderEdge.InternalGetSize: Integer;
  procedure CheckSize(ImageLink: TDIBImageLink);
  var
    D: TAbstractSuperDIB;
  begin
    D := ImageLink.DIBImageList[ImageLink.DIBIndex];
    if BorderKind in [bkLeft, bkRight] then
    begin
      if D.Width > Result then Result := D.Width;
    end 
    else if D.Height > Result then Result := D.Height;
  end;
begin
  Result := 0;
  if FImageFirst.Valid then CheckSize(FImageFirst);
  if FImageMiddle.Valid then CheckSize(FImageMiddle);
  if FImageLast.Valid then CheckSize(FImageLast);
end;

procedure TDIBBorderEdge.MakeRGN(ARect: TRect; var Result: HRGN);
  procedure AddDIB(DIB: TMemoryDIB; X, Y: Integer);
  var
    RGN: HRGN;
  begin
    if DIB.Masked then
      RGN := DIB.MakeRGN(32)
    else if DIB.Transparent then
      RGN := DIB.MakeRGNFromColor(DIB.TransparentColor)
    else
      RGN := CreateRectRGN(0, 0, DIB.Width, DIB.Height);

    OffsetRGN(RGN, X, Y);
    if CombineRGN(Result, Result, RGN, RGN_OR) = ERROR then
      raise Exception.Create('Error creating region');
    DeleteObject(RGN);
  end;
var
  X, Y, XInc, YInc: Integer;
  FirstSize, LastSize: Integer;
  DIB, LongDIB: TMemoryDIB;
begin
  XInc := 0;
  YInc := 0;
  X := ARect.Left;
  Y := ARect.Top;
  LongDIB := TMemoryDIB.Create;
  try
    FirstSize := 0;
    LastSize := 0;

    if FImageFirst.GetImage(DIB) then
    begin
      AddDIB(DIB, X, Y);
      case BorderKind of
        bkTop, bkBottom: FirstSize := DIB.Width;
        bkLeft, bkRight: FirstSize := DIB.Height;
      end;
    end;
    if FImageLast.GetImage(DIB) then
      case BorderKind of
        bkTop, bkBottom:
          begin
            LastSize := DIB.Width;
            AddDIB(DIB, ARect.Right - DIB.Width, Y);
          end;
        bkLeft, bkRight:
          begin
            LastSize := DIB.Height;
            AddDIB(DIB, X, ARect.Bottom - DIB.Height);
          end;
      end;

    if FImageMiddle.GetImage(DIB) then
    begin
      DIB.AssignHeaderTo(LongDIB);
      case BorderKind of
        bkTop, bkBottom:
          begin
            LongDIB.Width := (ARect.Right - ARect.Left) - FirstSize - LastSize;
            LongDIB.Height := DIB.Height;
            X := ARect.Left + FirstSize;
            Y := 0;
            XInc := DIB.Width;
            YInc := 0;
          end;
        bkLeft, bkRight:
          begin
            LongDIB.Height := (ARect.Bottom - ARect.Top) - FirstSize - LastSize;
            LongDIB.Width := DIB.Width;
            Y := ARect.Top + FirstSize;
            X := 0;
            XInc := 0;
            YInc := DIB.Height;
          end;
      end;
      while (X <= LongDIB.Width) and (Y <= LongDIB.Height) do
      begin
        DIB.DrawAll(X, Y, DIB.Width, DIB.Height, LongDIB, 0, 0);
        Inc(X, XInc);
        Inc(Y, YInc);
      end;
      case BorderKind of
        bkTop: AddDIB(LongDIB, ARect.Left + FirstSize, 0);
        bkBottom: AddDIB(LongDIB, ARect.Left + FirstSize, ARect.Bottom - LongDIB.Height);
        bkLeft: AddDIB(LongDIB, 0, FirstSize);
        bkRight: AddDIB(LongDIB, ARect.Right - DIB.Width, FirstSize);
      end;
    end;
  finally
    LongDIB.Free;
  end;
end;

procedure TDIBBorderEdge.SetDIBImage(const Value: TCustomDIBImageList);
begin
  FImageFirst.DIBImageList := Value;
  FImageLast.DIBImageList := Value;
  FImageMiddle.DIBImageList := Value;
end;

procedure TDIBBorderEdge.SetImageFirst(const Value: TDIBImageLink);
begin
  FImageFirst.Assign(Value);
end;

procedure TDIBBorderEdge.SetImageLast(const Value: TDIBImageLink);
begin
  FImageLast.Assign(Value);
end;

procedure TDIBBorderEdge.SetImageMiddle(const Value: TDIBImageLink);
begin
  FImageMiddle.Assign(Value);
end;

{ TDIBBorder }

procedure TDIBBorder.AssignTo(Dest: TPersistent);
begin
  inherited;
end;

constructor TDIBBorder.Create(AOwner: TComponent);
begin
  inherited;
  FBorderBottom := TDIBHorzBorderEdge.Create(bkBottom);
  FBorderLeft := TDIBVertBorderEdge.Create(bkLeft);
  FBorderRight := TDIBVertBorderEdge.Create(bkRight);
  FBorderTop := TDIBHorzBorderEdge.Create(bkTop);
end;

destructor TDIBBorder.Destroy;
begin
  FBorderTop.Free;
  FBorderRight.Free;
  FBorderLeft.Free;
  FBorderBottom.Free;
  inherited;
end;

procedure TDIBBorder.DrawTo(Dest: TAbstractSuperDIB; DestRect: TRect);
begin
  FBorderLeft.DrawTo(Dest, DestRect);
  FBorderRight.DrawTo(Dest, DestRect);
  DestRect.Left := DestRect.Left + FBorderLeft.InternalGetSize;
  DestRect.Right := DestRect.Right - FBorderRight.InternalGetSize;
  FBorderTop.DrawTo(Dest, DestRect);
  FBorderBottom.DrawTo(Dest, DestRect);
end;

function TDIBBorder.MakeRGN(ARect: TRect): HRGN;
begin
  Result := CreateRectRgn(BorderLeft.Size, BorderTop.Size,
    ARect.Right - BorderRight.Size, ARect.Bottom - BorderBottom.Size);
  BorderLeft.MakeRGN(ARect, Result);
  BorderRight.MakeRGN(Rect(ARect.Right - BorderRight.Size, ARect.Left,
    ARect.Right, ARect.Bottom), Result);
  BorderTop.MakeRGN(Rect(ARect.Left + BorderLeft.Size, ARect.Top,
    ARect.Right - BorderRight.Size, ARect.Bottom), Result);
  BorderBottom.MakeRGN(Rect(ARect.Left + BorderLeft.Size,
    ARect.Bottom - BorderBottom.Size, ARect.Right - BorderRight.Size, ARect.Bottom), Result);
end;

procedure TDIBBorder.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = DIBImageList) then
    DIBImageList := nil;
end;

procedure TDIBBorder.SetDIBImageList(const Value: TCustomDIBImageList);
begin
  if DIBImageList <> nil then DIBImageList.RemoveFreeNotification(Self);
  FDIBImageList := Value;
  if Value <> nil then Value.FreeNotification(Self);

  FBorderBottom.DIBImageList := Value;
  FBorderLeft.DIBImageList := Value;
  FBorderRight.DIBImageList := Value;
  FBorderTop.DIBImageList := Value;
end;

end.
