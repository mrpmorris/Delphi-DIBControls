unit cDIB;

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: cDIB.PAS, released August 28, 2000.

The Initial Developer of the Original Code is Peter Morris (support@droopyeyes.com),
Portions created by Peter Morris are Copyright (C) 2000 Peter Morris.
All Rights Reserved.

Purpose of file:
This is the main drawing engine.

Contributor(s):
RiceBall <riceb@nether.net>
Hans-Jürgen Schnorrenberg

Last Modified: March 31, 2003

You may retrieve the latest version of this file at http://www.droopyeyes.com


Known Issues:
-----------------------------------------------------------------------------}
//Modifications
(*
Date:   October 14, 2000
By:     Peter Morris
Change: Made SCANLINE property public to TWINDIB and TMemoryDIB

Date:   October 14, 2000
By:     Peter Morris
Change: Added a PIXELS property

Date:   November 7, 2000
By:     Peter Morris
Change: Made the Region created by MakeRGN* more accurate

Date:   November 10, 2000
By:     Peter Morris
Change: Rotated RGB TColor to ABGR in SetTransparentColor

Date:   November 18, 2000
By:     Peter Morris
Change: Added LoadPicture(+FromStream) and SavePicture(+ToStream) for custom
        picture formatting

Date:   November 21, 2000
By:     Peter Morris
Change: LoadDataFromStream and SaveDataToStream moved to PUBLIC section

Date:   November 30, 2000
By:     Peter Morris
Change: Made SCANLINE property public in TAbstractSuperDIB instead

Date:   December 2, 2000
By:     Peter Morris
Change: Made Width / Height public properties

Date:   June 24, 2001
By:     RiceBall
Change: Added TAbstractSuperDIB.DrawTiled

Date:   August 21, 2001
By:     Peter Morris
Change: Added DrawAll method

Date:   August 23, 2001
By:     Peter Morris
Change: Fixed a bug in GetTransparentColor

Date:   Nov 15, 2001
By:     CAM Moorman  (nthdominion@earthlink.net)
Change: Added Export routines for Image and Mask

Date:   Aug 11, 2002
By:     Peter Morris
Change: Added support for 32bit bitmaps in ImportPicture (Red, Green, Blue, Alpha)

Date:   August 12, 2002
By:     Hans-Jürgen Schnorrenberg
Change: Removed byte-swapping in SetTransparentColor

Date:   March 27, 2003
By:     Peter Morris
Change: Improved GetRotatedSizes + DIB.Draw so that rotated / zoomed dibs
        do not "wobble"

Date:   March 31, 2003
By:     Peter Morris
Change: DrawGlyph and DrawGlyphTween added.

Date:   March 18, 2004
By:     Peter Morris
Change: Opacity blit routines altered so that the transparent colour is preserved
        when drawing.

Date:   Jan 3, 2005
By:     Peter Morris
Change: RotoZoom was not scaling correctly

Date:   Jan 3, 2005
By:     Peter Morris
Change: Changed the SIN/COS table to be multiplied by 65536 instead of 256, this
        gives far better precision, and removes the "jitter" experienced when
        rotating/zooming an image.  It does mean however that images are now
        limited to 65535 by 65535.

*)


{$O-} //This is needed as some routines are called implicitly, and will be omitted
      //by the compiler
{$A+} //This is default anyway, but we need alignment for DIBS, and it wont hurt.

interface

uses
  Classes, Windows, SysUtils, Graphics, Math, JPeg, Dialogs, cDIBPalette;

type
//  TAngle = 0..359;
  TDIBFilter = class;
  EDIBError = class(Exception);

  //For getting / settings the Pixels property
  TPixel32 = packed record
    Blue,
    Green,
    Red,
    Alpha: Byte;
  end;

  TAbstractSuperDIB = class;
  TAbstractSuperDIBClass = class of TAbstractSuperDIB;

  //A blitter proc is a routine which copies data from 1 DIB to another.
  //New blitter procs may be written.  To activate the blitter proc you will
  //need to override ChangeBlitter.
  TBlitterProc = procedure(SourceData, DestData: Pointer;
    SourceModulo, DestModulo: DWord;
    NoPixels, NoLines: Integer) of object;

  //The main class that all DIBs are created from, this holds all functions for
  //manipulating the data, but does not actually create any data
  TAbstractSuperDIB = class(TPersistent)
  private
    FAngle: Extended;
    FAutoSize: Boolean;
    FClipRect: TRect;
    FHeight: Word;
    FMasked: Boolean;
    FOpacity: Byte;
    FOwnedData: Boolean;
    FScaleX,
    FScaleY: Extended;
    FTransparent: Boolean;
    FTransparentColor: TPixel32;
    FTransparentMode: TTransparentMode;
    FUpdateCount: DWord;
    FWidth: Word;
    FOnChange: TNotifyEvent;

    procedure FreeTheData;
    procedure CreateTheData;
    //Can't see why you would want to override these property routines !
    function GetScanline(Row: Integer): Pointer;
    procedure SetClipRect(const aRect: TRect);
    procedure SetTransparent(const Value: Boolean);
    procedure SetTransparentColor(Value: TColor);
    procedure SetTransparentMode(const Value: TTransparentMode);
    function GetTransparentColor: TColor;
    function GetPixel(X, Y: Integer): TPixel32;
    procedure SetPixel(X, Y: Integer; Value: TPixel32);
  protected
    //Which blitter routine to use for drawing
    FBlitter: TBlitterProc;
    FData: Pointer;

    //Abstract method which MUST be overridden
    procedure CreateData; virtual; abstract;
    procedure FreeData; virtual; abstract;

    //Streaming
    procedure DefineProperties(Filer: TFiler); override;

    //OnChange notification, and an opportunity to alter the blitter proc
    procedure Changed; virtual;
    procedure ChangeBlitter; virtual;

    //Blitter routines
    procedure BlitMaskAsGrayScale(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;
    //Only blit the mask
    procedure BlitMaskOnly(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;
    //Copy the bytes, no special effects
    procedure SolidBlit(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;
    procedure SolidBlitO(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;
    //Copy the bytes, take into account the Mask value
    procedure MaskedBlit(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;
    procedure MaskedBlitO(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;
    //Blit the image, but not Transparent Colors
    procedure TransparentBlit(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;
    procedure TransparentBlitO(SourceData, DestData: Pointer;
      SourceModulo, DestModulo: DWord;
      NoPixels, NoLines: Integer); virtual;


    //property routines
    procedure SetAngle(const Value: Extended); virtual;
    procedure SetAutoSize(const Value: Boolean); virtual;
    procedure SetHeight(const aValue: Word); virtual;
    procedure SetMasked(const Value: Boolean); virtual;
    procedure SetOpacity(const Value: Byte); virtual;
    procedure SetScale(const Value: Extended); virtual;
    procedure SetScaleX(const Value: Extended); virtual;
    procedure SetScaleY(const Value: Extended); virtual;
    procedure SetWidth(const aValue: Word); virtual;

    property Angle: Extended read FAngle write SetAngle;
    property AutoSize: Boolean read FAutoSize write SetAutoSize;
    property ClipRect: TRect read FClipRect write SetClipRect;
    property Masked: Boolean read FMasked write SetMasked;
    property Opacity: Byte read FOpacity write SetOpacity;
    property Pixels[X, Y: Integer]: TPixel32 read GetPixel write SetPixel;
    property Scale: Extended read FScaleX write SetScale;
    property ScaleX: Extended read FScaleX write SetScaleX;
    property ScaleY: Extended read FScaleY write SetScaleY;
    property Transparent: Boolean read FTransparent write SetTransparent;
    property TransparentColor: TColor read GetTransparentColor write SetTransparentColor;
    property TransparentMode: TTransparentMode 
      read FTransparentMode write SetTransparentMode;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    //Standard create routines
    constructor Create; overload; virtual;
    constructor Create(aWidth, aHeight: Word); overload; virtual;
    //This constructor creates a new header for manipulation, but points FData
    //at existing data from another DIB.  This allows 2 DIBs to Share data.
    //There will be a problem if the source DIB is freed !
    constructor CreateReplicaOf(aSource: TAbstractSuperDIB); virtual;
    destructor Destroy; override;

    //Updates stuff
    procedure BeginUpdate;
    procedure EndUpdate;

    //Formatted loading / saving
    procedure LoadDataFromStream(S: TStream); virtual;
    procedure LoadPicture(const Filename: string);
    procedure LoadPictureFromStream(FileExt: string; Stream: TStream);
    procedure SaveDataToStream(S: TStream); virtual;
    procedure SavePicture(const Filename: string);
    procedure SavePictureToStream(FileExt: string; Stream: TStream);

    //Apply a 3x3 matrix
    procedure ApplyFilter(AFilter: TDIBFilter); virtual;
    //Like AssignTo, but ONLY for header information, not data
    procedure AssignHeaderTo(Dest: TPersistent); virtual;
    procedure AssignTo(Dest: TPersistent); override;
    //Like AssignTo, but ONLY the data, not the header
    procedure CopyPicture(Source: TAbstractSuperDIB);
    procedure StretchCopyPicture(Source: TAbstractSuperDIB);

    //Draw will calculate the parameters for the BlitterProc, and then call
    //the current Blitter routine
    procedure Draw(DestX, DestY: Integer;
      DestWidth, DestHeight: Integer;
      Dest: TAbstractSuperDIB;
      SrcX, SrcY: Word); virtual;
    //Will just do a solidblit ignoring mask / transparency etc
    procedure DrawAll(DestX, DestY: Integer;
      DestWidth, DestHeight: Integer;
      Dest: TAbstractSuperDIB;
      SrcX, SrcY: Word); virtual;
    //This will draw part of an image, as a TSpeedButton draws its Glyph property
    procedure DrawGlyph(DestX, DestY, GlyphIndex, NumGlyphs: Integer; Dest: TAbstractSuperDIB);
    //This will draw a mix between two Glyphs (similar to above)
    procedure DrawGlyphTween(DestX, DestY, NumGlyphs: Integer; Dest: TAbstractSuperDIB;
      Min, Max, Position: Integer; LoopFrames: Boolean);
    //This will copy the mask only, not RGB values, it uses BlitMaskOnly
    procedure DrawMask(DestX, DestY: Integer;
      DestWidth, DestHeight: Integer;
      Dest: TAbstractSuperDIB;
      SrcX, SrcY: Word); virtual;
    procedure DrawMaskAsGrayScale(DestX, DestY: Integer;
      DestWidth, DestHeight: Integer;
      Dest: TAbstractSuperDIB;
      SrcX, SrcY: Word); virtual;
    procedure DrawTiled(DestRect: TRect; Dest: TAbstractSuperDIB);

    //Import a mask from a file.  The file MUST be 8bit GreyScale
    procedure ImportMask(AFilename: string); overload; dynamic;
    //Import a mask from a chunk of memory, must be 1 byte per pixel
    procedure ImportMask(Source: Pointer; Width, Height: Integer); overload;
    //Import a picture from any supported file
    procedure ImportPicture(AFilename: string); dynamic;
    //Export a mask to a file.
    procedure ExportMask(AFilename: string); overload;
    //Export mask to a chunk of memory, memory must be the size of Width * Height
    procedure ExportMask(Destination: Pointer); overload;
    //Import a picture from any supported file
    procedure ExportPicture(AFilename: string);
    //Converts the DIB to a RGN by using the MASK
    function MakeRGN(const AMasklevel: Byte): HRGN;
    //Converts the DIB to a RGN by using a TColor
    function MakeRGNFromColor(ATransparentColor: TColor): HRGN;
    //Destroys the current data, and references an existing DIB's data
    procedure PointDataAt(aSource: TAbstractSuperDIB); virtual;
    //Fill the DIB with a color
    procedure QuickFill(aColor: TColor); virtual;
    //Fill a sub-rect of the DIB with a color
    procedure QuickFillRect(aColor: TColor; aLeft, aTop, aWidth, aHeight: Integer);
      virtual;
    //Render8BIT will render to an 8BIT dc using a DIBPalette with UseTable=True
    procedure Render8Bit(DestDC: HDC; X, Y, aWidth,
      aHeight: Integer; XSrc, YSrc: Word; ROP: Cardinal;
      Palette: TDIBPalette); virtual;
    //Override ResetHeader in child classes if you add new properties
    procedure ResetHeader; virtual;
    procedure ReSize(aWidth, aHeight: Word); virtual;
    //This routine handles Rotate AND Zoom at the same time, Good eh ?
    procedure RotoZoom(D: TAbstractSuperDIB); virtual;
    //Set all the masked values in the DIB to Opacity
    procedure SetMaskedValues(const Opacity: Byte);
    //Is the DIB drawable or not
    function Valid: Boolean; virtual;

    property Height: Word read FHeight write SetHeight;
    property ScanLine[Row: Integer]: Pointer read GetScanLine;
    property Width: Word read FWidth write SetWidth;
  published
  end;

  TCustomWinDIB = class(TAbstractSuperDIB)
  private
    FDC: HDC;
    FBitmap: HBitmap;
    FOldBitmap: HBitmap;
    FCanvas: TCanvas;
    procedure DoCanvasChanged(Sender: TObject);
  protected
    procedure CreateData; override;
    procedure FreeData; override;

    property Canvas: TCanvas read FCanvas;
    property Handle: HDC read FDC;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
  end;

  TWinDIB = class(TCustomWinDIB)
  private
  protected
  public
    property ClipRect;
    property Data: Pointer read FData;
    property ScaleX;
    property ScaleY;
    property ScanLine;
    property Pixels;
  published
    property Angle;
    property AutoSize;
    property Canvas;
    property Handle;
    property Height;
    property Masked;
    property Opacity;
    property Scale;
    property Transparent;
    property TransparentColor;
    property TransparentMode;
    property Width;
  end;

  //A MemoryDIB uses the GlobalHeap to store its data.
  //(No handles for example)
  TCustomMemoryDIB = class(TAbstractSuperDIB)
  private
    FImageFilename: string;
    FMaskFilename: string;
    FSaveImageData: Boolean;
    procedure ReadImageFilename(Reader: TReader);
    procedure ReadMaskFilename(Reader: TReader);
    procedure WriteImageFilename(Writer: TWriter);
    procedure WriteMaskFilename(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure CreateData; override;
    procedure FreeData; override;
  public
    constructor Create; override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure ImportMask(AFilename: string); override;
    procedure ImportPicture(AFilename: string); override;
    procedure LoadDataFromStream(S: TStream); override;
    procedure SaveDataToStream(S: TStream); override;

    property ImageFilename: string read FImageFilename;
    property SaveImageData: Boolean read FSaveImageData write FSaveImageData;
    property MaskFilename: string read FMaskFilename;
  published
  end;

  TMemoryDIB = class;
  TMemoryDIBClass = class of TMemoryDIB;
  TMemoryDIB = class(TCustomMemoryDIB)
  private
  protected
  public
    property ClipRect;
    property ScaleX;
    property ScaleY;
    property ScanLine;
    property Pixels;
  published
    property Angle;
    property AutoSize;
    property Height;
    property Masked;
    property Opacity;
    property Scale;
    property Transparent;
    property TransparentColor;
    property TransparentMode;
    property Width;
  end;

  //A DIBFilter will apply a 3x3 matrix to a DIB.  Simple !
  TDIBFilter = class(TPersistent)
  private
    FRedBias,
    FGreenBias,
    FBlueBias: Smallint;
    FOpacity: Byte;
    FFactor: Integer;
  protected
  public
    Data: array[0..8] of SmallInt;
    constructor Create; virtual;
    class function GetDisplayName: string;

  published
    property BlueBias: Smallint read FBlueBias write FBlueBias;
    property GreenBias: Smallint read FGreenBias write FGreenBias;
    property Factor: Integer read FFactor write FFactor;
    property Opacity: Byte read FOpacity write FOpacity;
    property RedBias: Smallint read FRedBias write FRedBias;
  end;



function GetRotatedPoint(X, Y, Radius, Angle: Extended): TPoint;
function GetRotatedSize(Width, Height: Word; Angle: Extended;
  ScaleX, ScaleY: Extended): TPoint;
function Largest(A, B: Integer): Integer;
function RelativeAngle(X1, Y1, X2, Y2: Integer): Extended;
function SafeAngle(Angle: Extended): Extended;
function Smallest(A, B: Integer): Integer;


function ColorToPixel32(const AColor: TColor): TPixel32; register;
function Pixel32ToColor(const APixel32: TPixel32): TColor; register;
function CosTable1(Angle: Extended): Integer;
function CosTable2(Angle: Extended): Integer;
function SinTable1(Angle: Extended): Integer;
function SinTable2(Angle: Extended): Integer;
procedure VerticalFlipData(Source, Destination: Pointer; BytesPerLine, Height: Integer);

const
  cNullPixel32: TPixel32 = (Blue:0; Green:0; Red:0; Alpha:0);

implementation

uses
  cDIBFormat, cDIBCompressor;

const
  cRectAllocs = 400;
  cMaxRectChunks = 2000;
  CSinCosTablePrecision = 1000;

var
  GSinTable1, GCosTable1, GSinTable2, GCosTable2: array[0..(360 * CSinCosTablePrecision) - 1] of Integer;

type
  PByte = ^Byte;
  PDWord = ^DWord;


procedure VerticalFlipData(Source, Destination: Pointer; BytesPerLine, Height: Integer);
var
  LineNumber: Integer;
  MoveSource: PChar;
  MoveDestination: PChar;
  MoveDestinationBase: PChar;
begin
  MoveDestinationBase := PChar(Destination) + ( (Height -1) * BytesPerLine);
  for LineNumber := 0 to Height - 1 do
  begin
    MoveSource := PChar(Source) + (LineNumber * BytesPerLine);
    MoveDestination := MoveDestinationBase - (LineNumber * BytesPerLine);
    Move(MoveSource^, MoveDestination^, BytesPerLine);
  end;
end;

function CosTable1(Angle: Extended): Integer;
begin
  Result := GCosTable1[Trunc(Angle * CSinCosTablePrecision)];
end;

function CosTable2(Angle: Extended): Integer;
begin
  Result := GCosTable2[Trunc(Angle * CSinCosTablePrecision)];
end;


function SinTable1(Angle: Extended): Integer;
begin
  Result := GSinTable1[Trunc(Angle * CSinCosTablePrecision)];
end;


function SinTable2(Angle: Extended): Integer;
begin
  Result := GSinTable2[Trunc(Angle * CSinCosTablePrecision)];
end;

function LastError: string;
var
  OutputMessage: PChar;
begin
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ALLOCATE_BUFFER,
    nil,
    GetLastError,
    0, @OutputMessage,
    0,
    nil);

  Result := string(OutputMessage);
end;

function ColorToPixel32(const AColor: TColor): TPixel32; register;
asm
  Call ColorToRGB
  bswap EAX
  SHR   EAX, 8
end;

function Pixel32ToColor(const APixel32: TPixel32): TColor; register;
asm
    shl     EAX, 8
    bswap   EAX
end;

function GetRotatedPoint(X, Y, Radius, Angle: Extended): TPoint;
var
  Radians: Extended;
begin
  Assert((Angle >= 0) and (Angle < 360));
  Radians := DegToRad(Angle - 90);
  Result.X := Ceil(Cos(Radians) * Radius + X);
  Result.Y := Ceil(Sin(Radians) * Radius + Y);
end;

function GetRotatedSize(Width, Height: Word; Angle: Extended;
  ScaleX, ScaleY: Extended): TPoint;
var
  Radians: Extended;
  ScaledWidth, ScaledHeight: Extended;
begin
  Assert((Angle >= 0) and (Angle < 360));
  Radians := DegToRad(-Angle);
  ScaledWidth := Width * ScaleX / 100;
  ScaledHeight := Height * ScaleY / 100;

  Result := Point(Ceil(Abs(ScaledWidth * Cos(Radians)) + Abs(ScaledHeight * Sin(Radians))),
    Ceil(Abs(ScaledWidth * Sin(Radians)) + Abs(ScaledHeight * Cos(Radians))));

  Result.X := Result.X - (Result.X mod 2);
  Result.Y := Result.Y - (Result.Y mod 2);
end;

function Largest(A, B: Integer): Integer;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;

function RelativeAngle(X1, Y1, X2, Y2: Integer): Extended;
var
  Theta: Extended;
  XDist, YDist: Integer;
begin
  Result := 0;

  //arctan((y2-y1)/(x2-x1))
  XDist := X2 - X1;
  YDist := Y1 - Y2;
  if (XDist = 0) and (YDist = 0) then exit;

  if YDist = 0 then
    Theta := arctan((X2 - X1))
  else
    Theta := arctan((X2 - X1) / (Y1 - Y2));

  Result := RadToDeg(Theta);
  if (X2 >= X1) and (Y2 >= Y1) then //Quadrant = 2
    Result := 90 + (90 - Abs(Result))
  else if (X2 <= X1) and (Y2 >= Y1) then //Quadrant = 3
    Result := 180 + Abs(Result)
  else if (X2 <= X1) and (Y2 <= Y1) then //Quadrant = 4
    Result := 270 + (90 - Abs(Result));
end;

function SafeAngle(Angle: Extended): Extended;
begin
  while Angle < 0 do
    Angle := Angle + 360;
  while Angle >= 360 do
    Angle := Angle - 360;
  Result := Angle;
end;

function Smallest(A, B: Integer): Integer;
begin
  if A < B then
    Result := A
  else
    Result := B;
end;


{ TDIBFilter }

constructor TDIBFilter.Create;
begin
  inherited;
  Opacity := 255;
  RedBias := 0;
  GreenBias := 0;
  BlueBias := 0;
  Factor := 0;
end;

class function TDIBFilter.GetDisplayName: string;
begin
  Result := '(Unknown)';
end;

{ TAbstractSuperDIB }

procedure TAbstractSuperDIB.ApplyFilter(AFilter: TDIBFilter);
var
  Dest: TWinDIB;
  RedAv, GreenAv, BlueAv: SmallInt;
  AvModulo, MatrixOffset, LineSize, NoLines, PixelsPerLine: DWord;
  Factor: Integer;
  MData, SourceData, DestData: Pointer;
  NewData: array[0..8] of SmallInt;
  RB, GB, BB: Smallint;
begin
  Dest := TWinDIB.Create(Width, Height);
  LineSize := Width * 4;
  NoLines := Height - 2;
  PixelsPerLine := Width - 2;
  AvModulo := LineSize - 12;

  with AFilter do 
  begin
    //Row 1
    NewData[0] := Data[6];
    NewData[1] := Data[7];
    NewData[2] := Data[8];
    //Row 2
    NewData[3] := Data[3];
    NewData[4] := Data[4];
    NewData[5] := Data[5];
    //Row 3
    NewData[6] := Data[0];
    NewData[7] := Data[1];
    NewData[8] := Data[2];
  end;
  if AFilter.Factor > 0 then
    Factor := AFilter.Factor
  else 
  begin
    Factor :=
      NewData[0] + NewData[1] + NewData[2] +
      NewData[3] + NewData[4] + NewData[5] +
      NewData[6] + NewData[7] + NewData[8];
  end;

  MData := @NewData[0];


  MatrixOffset := LineSize + 4;
  SourceData := Pointer(DWord(FData) + MatrixOffset);
  DestData := Pointer(DWord(Dest.FData) + MatrixOffset);

  //Bias
  RB := AFilter.RedBias;
  GB := AFilter.GreenBias;
  BB := AFilter.BlueBias;
  asm
    push  ESI
    push  EDI
    push  EBX

    mov   ESI, SourceData
    mov   EDI, DestData
    mov   ECX, NoLines
  @VLoop:
    push  ECX
    mov   ECX, PixelsPerLine
  @HLoop:
    call  @CalcPixels

    //Mask
    mov   al, [ESI+3]
    shl   EAX, 8
    //Red
    mov   BX, RedAv
    lea   EAX, [EAX+EBX]
    shl   EAX, 8
    //Green
    mov   BX, GreenAv
    lea   EAX, [EAX+EBX]
    shl   EAX,8
    //Blue
    mov   BX, BlueAv
    lea   EAX, [EAX+EBX]

    //Store the pixel color
    mov   [EDI], EAX
    lea   EDI, [EDI+4]
    lea   ESI, [ESI+4]



    dec   ECX
    jnz   @HLoop

    lea   EDI, [EDI+8]
    lea   ESI, [ESI+8]

    pop   ECX
    dec   ECX
    jnz   @VLoop

  @TheEnd:
    pop   EBX
    pop   EDI
    pop   ESI
    jmp   @Exit

    //==================== CALC PIXELS =========================//
  @CalcPixels:
    push  ESI
    push  EDI

    sub   ESI, MatrixOffset
    mov   EDI, MData

  @AvVLoop:
    //==================== LINE 1 =========================//
    //Pixel1
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    mov   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    mov   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    mov   RedAV, AX

    lea   EDI,[EDI+2]

    //Pixel2
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    Add   RedAv, AX

    lea   EDI,[EDI+2]

    //Pixel3
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    Add   RedAv, AX

    lea   EDI,[EDI+2]

    add   ESI, AvModulo

    //==================== LINE 2 =========================//
    //Pixel1

    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    Add   RedAv, AX

    lea   EDI,[EDI+2]

    //Pixel2
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    Add   RedAv, AX

    lea   EDI,[EDI+2]

    //Pixel3
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    Add   RedAv, AX

    lea   EDI,[EDI+2]

    add   ESI, AvModulo

    //==================== LINE 3 =========================//
    //Pixel1
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    Add   RedAv, AX

    lea   EDI,[EDI+2]

    //Pixel2
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    lea   ESI, [ESI+2]
    imul  bx
    Add   RedAv, AX


    lea   EDI,[EDI+2]

    //Pixel3
    mov   bx,  [EDI] //Get filter value

    //BLUE
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   BlueAv, AX

    //GREEN
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    inc   ESI
    imul  bx
    Add   GreenAv, AX

    //RED
    xor   EAX, EAX
    mov   al,  [ESI] //Get pixel values
    imul  bx
    Add   RedAv, AX

    //Now add the RGBM Bias
//    xor  EAX, EAX
    mov  AX, BB
    Add  BlueAv, AX
    mov  AX, GB
    Add  GreenAv, AX
    mov  AX, RB
    Add  RedAv, AX


    //Now divide by the factor
    mov   EBX, Factor
    cmp   EBX, 0
    jz    @NoDivide

    //BLUE
    mov   AX, BlueAv
    cwd
    idiv  BX
    mov   BlueAv, AX

    //GREEN
    mov   AX, GreenAv
    cwd
    idiv  BX
    mov   GreenAv, AX

    //RED
    mov   AX, RedAv
    cwd
    idiv  BX
    mov   RedAv, AX

  @NoDivide:

    //Put RED into 0..255 range
    cmp   RedAv, 255
    jl    @RedLT255
    mov   RedAv, 255
  @RedLT255:
    cmp   RedAv, 0
    jg    @RedGT0
    mov   RedAv, 0
  @RedGt0:

    //Put Green into 0..255 range
    cmp   GreenAv, 255
    jl    @GreenLT255
    mov   GreenAv, 255
  @GreenLT255:
    cmp   GreenAv, 0
    jg    @GreenGT0
    mov   GreenAv, 0
  @GreenGt0:

    //Put Blue into 0..255 range
    cmp   BlueAv, 255
    jl    @BlueLT255
    mov   BlueAv, 255
  @BlueLT255:
    cmp   BlueAv, 0
    jg    @BlueGT0
    mov   BlueAv, 0
  @BlueGt0:

    pop   EDI
    pop   ESI

    ret

  @Exit:

  end;

  Dest.Opacity := AFilter.Opacity;
  Dest.Draw(0, 0, Width, Height, Self, 0, 0);
  Dest.Free;
end;

procedure TAbstractSuperDIB.AssignHeaderTo(Dest: TPersistent);
begin
  if Dest is TAbstractSuperDIB then
  begin
    TAbstractSuperDIB(Dest).FAngle := Self.FAngle;
    TAbstractSuperDIB(Dest).FAutoSize := Self.FAutoSize;
    TAbstractSuperDIB(Dest).FMasked := Self.FMasked;
    TAbstractSuperDIB(Dest).FOpacity := Self.FOpacity;
    TAbstractSuperDIB(Dest).FScaleX := Self.FScaleX;
    TAbstractSuperDIB(Dest).FScaleY := Self.FScaleY;
    TAbstractSuperDIB(Dest).FTransparent := Self.FTransparent;
    TAbstractSuperDIB(Dest).FTransparentColor := Self.FTransparentColor;
    TAbstractSuperDIB(Dest).FTransparentMode := Self.FTransparentMode;
    TAbstractSuperDIB(Dest).FBlitter := Self.FBlitter;
    if not TAbstractSuperDIB(Dest).FOwnedData then
    begin
      TAbstractSuperDIB(Dest).FWidth := Self.Width;
      TAbstractSuperDIB(Dest).FHeight := Self.Height;
    end;
  end 
  else
    raise EDIBError.Create('Cannot assign a TAbstractDIB to a ' + Dest.ClassName);
end;

procedure TAbstractSuperDIB.AssignTo(Dest: TPersistent);
begin
  if Dest is TAbstractSuperDIB then 
  begin
    TAbstractSuperDIB(Dest).CopyPicture(Self);
    AssignHeaderTo(Dest);
    TAbstractSuperDIB(Dest).Changed;
  end 
  else
    inherited;
end;

procedure TAbstractSuperDIB.ChangeBlitter;
begin
  if Opacity = 255 then 
  begin
    if Masked then
      FBlitter := MaskedBlit
    else if Transparent then
      FBlitter := TransparentBlit
    else
      FBlitter := SolidBlit;
  end 
  else
  begin
    if Masked then
      FBlitter := MaskedBlitO
    else if Transparent then
      FBlitter := TransparentBlitO
    else
      FBlitter := SolidBlitO;
  end;
end;

procedure TAbstractSuperDIB.Changed;
begin
  ChangeBlitter;
  if FUpdateCount = 0 then
    if Assigned(FOnChange) then FOnChange(Self);
end;

constructor TAbstractSuperDIB.Create;
begin
  inherited;
  FUpdateCount := 0;
  FData := nil;
  FBlitter := SolidBlit;
  FOwnedData := True;
  ResetHeader;
end;

procedure TAbstractSuperDIB.CopyPicture(Source: TAbstractSuperDIB);
begin
  Resize(Source.Width, Source.Height);
  if (Source.Width > 0) and (Source.Height > 0) then
    Move(Source.FData^, FData^, Width * Height * 4);
  Changed;
end;

constructor TAbstractSuperDIB.Create(aWidth, aHeight: Word);
begin
  Create;
  Resize(aWidth, aHeight);
  ClipRect := Rect(0, 0, aWidth, aHeight);
end;

constructor TAbstractSuperDIB.CreateReplicaOf(aSource: TAbstractSuperDIB);
begin
  inherited Create;
  PointDataAt(aSource);
end;

procedure TAbstractSuperDIB.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('Data', LoadDataFromStream, SaveDataToStream, FData <> nil);
end;



procedure TAbstractSuperDIB.Draw(DestX, DestY, DestWidth,
  DestHeight: Integer; Dest: TAbstractSuperDIB; SrcX, SrcY: Word);
var
  FirstPixel, LastPixel, FirstLine, LastLine: Integer;
  NoPixels, NoLines: Integer;
  SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord;

  Result: TWinDib;
  RotSizes: TPoint;
begin
  //if drawn at an angle, we need to handle this first.
  if (Angle <> 0) or (ScaleX <> 100) or (ScaleY <> 100) then
  begin
    if FAutoSize then
    begin
      if Angle <> 0 then
        RotSizes := GetRotatedSize(DestWidth, DestHeight, Angle, ScaleX, ScaleY)
      else
      begin
        RotSizes.X := Ceil(DestWidth * ScaleX / 100);
        RotSizes.Y := Ceil(DestHeight * ScaleY / 100);
      end;
      Result := TWinDib.Create(RotSizes.X, RotSizes.Y);
    end
    else
    begin
      Result := TWinDib.Create(DestWidth, DestHeight);
    end;

    try
      Result.Masked := Masked;
      Result.Opacity := Opacity;
      Result.Transparent := Transparent;
      Result.TransparentMode := tmFixed;
      Result.TransparentColor := TransparentColor;

      if Angle = 0 then
        Result.StretchCopyPicture(Self)
      else
        RotoZoom(Result);

      if Transparent then
      begin
        Result.Transparent := True;
        Result.TransparentMode := tmFixed;
        Result.TransparentColor := TransparentColor;
      end;
      Result.FBlitter := FBlitter;
      Result.Draw(DestX, DestY, Result.Width, Result.Height, Dest, 0, 0);
    finally
      Result.Free;
    end;
    exit;
  end;

  SrcX := Abs(Srcx);

  if DestX < Dest.ClipRect.Left then
  begin
    DestWidth := DestWidth - (Dest.ClipRect.Left - DestX);
    SrcX := SrcX + (Dest.ClipRect.Left - DestX);
    DestX := Dest.ClipRect.Left;
  end;

  if DestY < Dest.ClipRect.Top then
  begin
    DestHeight := DestHeight - (Dest.ClipRect.Top - DestY);
    SrcY := SrcY + (Dest.ClipRect.Top - DestY);
    DestY := Dest.ClipRect.Top;
  end;

  if DestX + DestWidth > Dest.ClipRect.Right then
  begin
    Dec(DestWidth, (DestX + DestWidth) - Dest.ClipRect.Right - 1);
  end;

  if DestY + DestHeight > Dest.ClipRect.Bottom then
  begin
    Dec(DestHeight, (DestY + DestHeight) - Dest.ClipRect.Bottom - 1);
  end;

  if DestWidth + SrcX > Width then DestWidth := Width - SrcX;
  if DestHeight + SrcY > Height then DestHeight := Height - SrcY;
  if DestHeight <= 0 then exit;
  if DestWidth <= 0 then exit;

  if DestX > Dest.Width then exit;
  if DestY > Dest.Height then exit;
  if DestX + Width < 0 then exit;
  if DestY + Height < 0 then exit;

  if DestWidth + DestX > Dest.Width then
    DestWidth := Dest.Width - DestX;
  if DestHeight + DestY > Dest.Height then
    DestHeight := Dest.Height - DestY;

  //FirstPixel
  FirstPixel := SrcX;
  if DestX < 0 then
  begin
    FirstPixel := FirstPixel + Abs(DestX);
    Dec(DestWidth, FirstPixel);
    if DestWidth < 1 then exit;
    DestX := 0;
  end;

  //LastPixel
  LastPixel := FirstPixel + DestWidth;
  if LastPixel > Width then LastPixel := Width;

  //No of pixels per line
  NoPixels := LastPixel - FirstPixel;
  if NoPixels < 1 then exit;

  //First line
  FirstLine := SrcY;
  if DestY < 0 then
  begin
    FirstLine := FirstLine + Abs(DestY);
    Dec(DestHeight, FirstLine);
    if Destheight < 1 then exit;
    DestY := 0;
  end;



  //Last line
  LastLine := FirstLine + DestHeight;
  if LastLine > Height then LastLine := Height;

  //No of lines
  NoLines := LastLine - FirstLine;
  if NoLines < 1 then exit;

  //DIBS are upside down !
  FirstLine := (Height - 1) - FirstLine;
  DestY := (Dest.Height - 1) - DestY;

  //Work out memory addresses of the first pixel, in source and dest
  SourceData := Pointer(Integer(FData) + (FirstLine * Width * 4) + (FirstPixel * 4));
  DestData := Pointer(Integer(Dest.FData) + (DestY * Dest.Width * 4) + (DestX * 4));

  //Work out the modulos
  SourceModulo := (NoPixels * 4) + (Width * 4);
  DestModulo := (NoPixels * 4) + (Dest.Width * 4);

  FBlitter(SourceData, DestData, SourceModulo, DestModulo, NoPixels, NoLines);
  Dest.Changed;
end;

procedure TAbstractSuperDIB.DrawAll(DestX, DestY, DestWidth,
  DestHeight: Integer; Dest: TAbstractSuperDIB; SrcX, SrcY: Word);
var
  OrigBlitter: TBlitterProc;
  OrigAngle: Extended;
  OrigScaleX: Extended;
  OrigScaleY: Extended;
begin
  OrigBlitter := FBlitter;
  OrigAngle := FAngle;
  OrigScaleX := FScaleX;
  OrigScaleY := FScaleY;
  try
    FBlitter := SolidBlit;
    FAngle := 0;
    FScaleX := 100;
    FScaleY := 100;
    Draw(DestX, DestY, DestWidth, DestHeight, Dest, SrcX, SrcY);
  finally
    FBlitter := OrigBlitter;
    FAngle := OrigAngle;
    FScaleX := OrigScaleX;
    FScaleY := OrigScaleY;
  end;
end;

procedure TAbstractSuperDIB.DrawMask(DestX, DestY, DestWidth,
  DestHeight: Integer; Dest: TAbstractSuperDIB; SrcX, SrcY: Word);
var
  OrigBlitter: TBlitterProc;
begin
  OrigBlitter := FBlitter;
  try
    FBlitter := BlitMaskOnly;
    Draw(DestX, DestY, DestWidth, DestHeight, Dest, SrcX, SrcY);
  finally
    FBlitter := OrigBlitter;
  end;
end;

function TAbstractSuperDIB.GetTransparentColor: TColor;
begin
  if TransparentMode = tmFixed then
    Result := Pixel32ToColor(FTransparentColor)
  else
    Result := Pixel32ToColor(TPixel32(FData^));
//    Result := TColor(FData^) and $00FFFFFF + $01000000;
end;

procedure TAbstractSuperDIB.ImportMask(AFilename: string);
var
  PixelCount: Cardinal;
  Source1, Source2: TWinDIB;
  SrcData, DestData: Pointer;
begin
  if (Width = 0) or (Height = 0) then
    raise EDIBError.Create('You cannot import a mask until you have an image.');

  Source1 := TWinDib.Create;
  Source2 := TWinDib.Create(Width, Height);
  SrcData := Source2.FData;
  DestData := FData;
  PixelCount := Width * Height;
  try
    Source1.ImportPicture(AFilename);
    StretchBlt(Source2.Handle, 0, 0, Width, Height, Source1.Handle, 0,
      0, Source1.Width, Source1.Height, SrcCopy);
    asm
          push EDI
          push ESI

          mov  ESI, SrcData
          mov  EDI, DestData
          mov  ECX, PixelCount

    @Loop:
          Mov  al, [ESI]
          mov  [EDI+3], cl
          lea  ESI, [ESI+4]
          lea  EDI, [EDI+4]
          dec  ECX
          jnz  @Loop

          pop  ESI
          pop  EDI
    end;
  finally
    Source1.Free;
    Source2.Free;
  end;
  FMasked := True;
  Changed;
end;

procedure TAbstractSuperDIB.ImportPicture(AFilename: string);
var
  Pic: TPicture;
  WinDIB: TWinDIB;
begin
  Pic := TPicture.Create;
  WinDIB := TWinDib.Create;
  try
    Pic.LoadFromFile(AFilename);
    Resize(Pic.Width, Pic.Height);
    WinDIB.ReSize(Width, Height);
    WinDib.Canvas.Draw(0, 0, Pic.Graphic);
    CopyPicture(WinDIB);
    if (Pic.Bitmap = nil) or (Pic.Bitmap.PixelFormat <> pf32Bit) then
      SetMaskedValues(255)
    else
      Masked := True;
  finally
    WinDIB.Free;
    Pic.Free;
  end;
  Changed;
end;

procedure TAbstractSuperDIB.LoadDataFromStream(S: TStream);
var
  W, H: Word;
  MS: TMemoryStream;
  DecompressedDirectlyToDIB: Boolean;
begin
  MS := TMemoryStream.Create;
  try
    Decompress(Self, S, MS, DecompressedDirectlyToDIB);
    if not DecompressedDirectlyToDIB then
    begin
      MS.Seek(0, soFromBeginning);
      MS.Read(W, SizeOf(W));
      MS.Read(H, SizeOf(H));
      Resize(W, H);
      MS.Read(FData^, Width * Height * 4);
    end;
    Changed;
  finally
    MS.Free;
  end;
end;

procedure TAbstractSuperDIB.MaskedBlit(SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord; NoPixels, NoLines: Integer);
begin
  asm
          push EDI
          push ESI
          push EBX

          mov  ESI, SourceData
          mov  EDI, DestData
          xor  EDX, EDX

  @VLoop:
          mov  ECX, NoPixels
  @HLoop:
          mov  bh, [ESI+3]
          mov  bl, [ESI+3]
          not bh

  @StartGreen:
          //Green
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX

          Xor  Ah, Ah
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
//          inc  Al
          StoSB
          
          //Blue
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX

          Xor  Ah, Ah
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
//          Inc  Al
          StoSB
          
          //Red
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX

          Xor  Ah, Ah
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
//          Inc  Al
          StoSB
          mov  AL, [ESI]
          Inc  ESI
//          mov  [EDI], AL
          cmp  [EDI], AL
          ja   @DontCopyMask
          mov  [EDI], AL
  @DontCopyMask:
          Inc  EDI

          dec  ECX
          jnz  @HLoop

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  NoLines
          jnz  @VLoop
  @TheEnd:
          pop  EBX
          pop  ESI
          pop  EDI
  end;
end;

procedure TAbstractSuperDIB.MaskedBlitO(SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord; NoPixels, NoLines: Integer);
var
  Opacity: Byte;
begin
  Opacity := FOpacity;
  asm
          push EDI
          push ESI
          push EBX

          mov  ESI, SourceData
          mov  EDI, DestData

          xor  EDX, EDX
  @VLoop:
          mov  ECX, NoPixels
  @HLoop:
          mov  bl, Opacity
          mov  al, [ESI+3]
          mul  bl
          mov  bh, ah
          mov  bl, ah
          not  bh

  @StartGreen:
          //Green
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB

          //Blue
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB

          //Red
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
//          Inc  Al
          StoSB
          mov  AL, [ESI]
          cmp  [EDI], AL
          ja   @DontCopyMask
          mov  [EDI], AL
  @DontCopyMask:
//          mov  [EDI], AL
          Inc  EDI

          dec  ECX
          jnz  @HLoop

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  NoLines
          jnz  @VLoop
  @TheEnd:
          pop  EBX
          pop  ESI
          pop  EDI
  end;
end;


procedure TAbstractSuperDIB.QuickFill(aColor: TColor);
var
  NumOfColors: DWord;
  Area: Pointer;
begin
  Area := FData;
  aColor := TColor(ColorToPixel32(AColor));
  NumOfColors := Width * Height;
  asm
    push    EDI
    mov     eax, aColor
    mov     edi, Area
    mov     ecx, NumOfColors
    cld
    rep     StoSD
    pop     EDI
  end;
  Changed;
end;

procedure TAbstractSuperDIB.QuickFillRect(aColor: TColor; aLeft, aTop,
  aWidth, aHeight: Integer);
var
  NoLines, NoPixels, DestModulo: DWord;
  Data: Pointer;
begin
  if aWidth < 1 then exit;
  if aHeight < 1 then exit;
  if aLeft + aWidth < 0 then exit;
  if aTop + aHeight < 0 then exit;
  if aLeft >= Width then exit;
  if aTop >= Height then exit;

  if aLeft < 0 then 
  begin
    aWidth := aWidth - abs(aLeft);
    aLeft := 0;
  end;

  if aTop < 0 then 
  begin
    aHeight := aHeight - abs(aTop);
    aTop := 0;
  end;

  if aLeft + aWidth > Width then aWidth := Width - aLeft;
  if aTop + aHeight > Height then aHeight := Height - aTop;

  NoPixels := aWidth;
  NoLines := aHeight;
  aColor := ColorToRGB(aColor);

  Data := Pointer(Integer(FData) + (((Height - 1) - aTop) * Width * 4) + (aLeft * 4));
  DestModulo := (NoPixels * 4) + (Width * 4);

  asm
          push EDI
          push ESI

          mov  EDI, Data
          mov  EDX, NoLines
          mov  EAX, aColor
          bswap EAX
          SHR  EAX, 8
  @VLoop:
          mov  ECX, NoPixels
  rep     STOSD

          sub  EDI, DestModulo
          dec  EDX
          jnz  @VLoop
  @TheEnd:
          pop  ESI
          pop  EDI
  end;
end;

procedure TAbstractSuperDIB.ReSize(aWidth, aHeight: Word);
var
  FullSize: Boolean;
begin
  if (aWidth = Width) and (aHeight = Height) then exit;
  FullSize :=
    (ClipRect.Left = 0) and (ClipRect.Top = 0) and
    (ClipRect.Right = Width - 1) and (ClipRect.Bottom = Height - 1);

  FreeTheData;
  if aWidth < 1 then aWidth := 1;
  if aHeight < 1 then aHeight := 1;
  FWidth := aWidth;
  FHeight := aHeight;
  CreateTheData;
  //  QuickFill(clBlack);
  if FullSize then
    FClipRect := Rect(0, 0, Width - 1, Height - 1)
  else
    ClipRect := ClipRect;
end;

{$DEFINE SMOOTHROTOZOOM}
{$IFNDEF SMOOTHROTOZOOM}
procedure TAbstractSuperDIB.RotoZoom(D: TAbstractSuperDIB);
var
  Source, Dest: PChar;
  NextPixelXInc, NextPixelYInc: Integer;
  NextLineXInc, NextLineYInc: Integer;
  NextLineXPos, NextLineYPos: Integer;
  Xpos, YPos: Integer;
  SLineSize: Integer;
  NegHalfSWidth, HalfSWidth, NegHalfSHeight, HalfSHeight: Integer;
  DestWidth, DestHeight: Integer;
  ScaleX, ScaleY: Extended;
  DestTransCol: DWORD;
begin
  if Masked then
    DestTransCol := DWORD(cNullPixel32)
  else
    DestTransCol := DWORD(FTransparentColor);

  Source := FData;
  Dest := D.FData;
  SLineSize := Width * 4;

  NegHalfSWidth := -(Width div 2);
  NegHalfSHeight := -(Height div 2);
  HalfSWidth := Width div 2;
  HalfSHeight := Height div 2;
  if Width mod 2 = 0 then
    Dec(NegHalfSWidth);
  if Height mod 2 = 0 then
    Dec(NegHalfSHeight);


  DestWidth := D.Width;
  DestHeight := D.Height;

  ScaleX := FScaleX / 100;
  ScaleY := FScaleY / 100;

  if (Width * ScaleX = 0) or (Height * ScaleY = 0) then
    Exit;

  NextPixelXInc := Round(((CosTable1(Angle)) * Width) / (Width * ScaleX));
  NextPixelYInc := Round(((SinTable1(Angle)) * Height) / (Height * ScaleY));

  NextLineXInc := Round(((CosTable2(Angle)) * Width) / (Width * ScaleX));
  NextLineYInc := Round(((SinTable2(Angle)) * Height) / (Height * ScaleY));

  NextLineXPos := ((-NextPixelXInc) * (DestWidth div 2)) - (NextLineXInc * (DestHeight div 2));
  NextLineYPos := ((-NextPixelYInc) * (DestWidth div 2)) - (NextLineYInc * (DestHeight div 2));

  Source := Source + (HalfSHeight * SLineSize) + (HalfSWidth * 4);

  asm
          push EDI
          push ESI
          push EBX

          mov  EDI, Dest
          mov  ESI, Source

          mov  ECX, DestHeight// for VLoop := 0 to D.Height -1 do begin
  @VLoop:
          mov  EAX, NextLineXPos
          mov  EBX, NextLineYPos
          mov  XPos, EAX      // XPos := NextLineXPos
          mov  YPos, EBX      // YPos := NextLineYPos

          push ECX
          mov  ECX, DestWidth //for HLoop:=0 to D.Width -1 do begin

  @HLoop:
          //Calculate offset using int(YPos)
          Mov  EAX, YPos
          test EAX, EAX
          jns  @ActualYGTZero

  @ActualYGTZero:
          sar  EAX, $10       // ActualY := YPos div 256;

          cmp  EAX, HalfSHeight
          Jge  @SkipPixel     // If ActualY > (S.Height div 2) then skip

          mov  EBX, NegHalfSHeight
          cmp  EAX, EBX
          jle  @SkipPixel     // If ActualY < -(S.Height div 2) then skip

          mov  EBX, SLineSize
          imul EBX
          mov  EDX, EAX       // Offset := (ActualY * SLineSize)

          //Calculate offset using ActualX
          mov  EAX, XPos
          test EAX, EAX
          jns  @ActualXGTZero

  @ActualXGTZero:
          sar  EAX, $10       // ActualX := XPos div 256;

          cmp  EAX, HalfSWidth
          Jge  @SkipPixel     //if ActualX > (S.Width div 2) then skip

          mov  EBX, NegHalfSWidth
          cmp  EAX, EBX
          Jle  @SkipPixel

          lea  EAX, [EAX*4+EDX]  //EAX := EAX * 4; 4 bytes per pixel

          mov  EAX, [ESI +EAX]
          mov  [EDI], EAX

          jmp  @NextPixel

  @SkipPixel:
          mov  EAX, DestTransCol
          mov  [EDI], EAX

  @NextPixel:
          lea  EDI, [EDI+4]
          mov  EAX, NextPixelXInc
          mov  EBX, NextPixelYInc
          add  XPos, EAX      //XPos := XPos + NextPixelXInc;
          add  YPos, EBX      //Ypos := YPos + NextPixelYInc;
          dec  ECX
          jnz  @HLoop         //end; //for HLoop

  @NextLine:
          pop  ECX
          mov  EAX, NextLineXInc
          mov  EBX, NextLineYInc
          add  NextLineXPos, EAX         //I := NextLineXPos + NextLineXInc;
          add  NextLineYPos, EBX         //J := NextLineYPos + NextLineYInc;

          dec  ECX
          jnz  @Vloop         //end; //for VLoop

  @TheEnd:
          pop  EBX
          pop  ESI
          pop  EDI
  end;
  D.Changed;
end;
{$ENDIF}



{$IFDEF SMOOTHROTOZOOM}
//quality vs. performance version of rotozoom by Klaus Göttling (20070318)
procedure TAbstractSuperDIB.RotoZoom(D: TAbstractSuperDIB);
type
  PixelPointer = record
    Red   : Byte;
    Green : Byte;
    Blue  : Byte;
    Alpha : Byte;
  end;
  PPixelPointer = ^PixelPointer;
var
    DestWidth, DestHeight  : Integer;
    swidth, sheight        : single;
    ScaleX, ScaleY         : Extended;
    cosTheta, sinTheta     : Single;
    Theta, cx, cy          : Single;
    sfrom_y, sfrom_x       : Single;
    ifrom_y, ifrom_x       : Integer;
    to_y, to_x, ix, iy     : Integer;
    weight_x, weight_y     : array[0..1] of Single;   //weight the subpixels
    weight                 : Single;
    total_red, total_green : Single; //pixel values to draw
    total_blue, total_alpha: Single;
    adx, ady               : single;
    pd, ps                 : PPixelPointer; //scanlines

begin
  ScaleX := FScaleX / 100;
  ScaleY := FScaleY / 100;
  DestWidth := D.Width;
  DestHeight := D.Height;
  swidth := width * ScaleX;
  sheight := height * ScaleY;
  if ((swidth <= 0) or (sheight <= 0) or (destwidth <= 0) or (destheight <= 0)) then
    Exit;

  Theta:=-(Angle)*Pi/180;
  sinTheta:=Sin(Theta);
  cosTheta:=Cos(Theta);

  //Center of rotation
  cx := (swidth / 2);
  cy := (sheight / 2);
  //correct aspect
  adx := (1 - swidth / destwidth) * (destwidth / 2);
  ady := (1 - sheight / destheight) * (destheight / 2);

  // Perform the rotation (walk destination and get source-pixels with subpixel-resolution)
  for to_y := 0 to destHeight-1 do begin
    pd := d.scanline[to_y];
    for to_x := 0 to destWidth-1 do begin
     // Find the location (from_x, from_y) that
     // rotates to position (to_x, to_y).
      sfrom_x := (cx + (to_x - adx - cx) * cosTheta - (to_y - ady - cy) * sinTheta) / ScaleX;
      ifrom_x := Trunc(sfrom_x);
      sfrom_y := (cy + (to_x - adx - cx) * sinTheta + (to_y - ady - cy) * cosTheta) / ScaleY;
      ifrom_y := Trunc(sfrom_y);
      if ((ifrom_x > 0) and (ifrom_y > 0) and (ifrom_y < Height-1) AND (ifrom_x < Width-1)) then begin  //checkbounds
        // Calculate the weights.
        weight_x[1] := sfrom_x - ifrom_x;
        weight_x[0] := 1 - weight_x[1];
        weight_y[1] := sfrom_y - ifrom_y;
        weight_y[0] := 1 - weight_y[1];
        // Average the color components of the surrounding pixels.
        total_red   := 0.0;
        total_green := 0.0;
        total_blue  := 0.0;
        total_alpha := 0.0;
       for iy := 0 to 1 do begin
         ps := scanline[ifrom_y + iy];
         inc(ps, ifrom_x);
         for ix := 0 to 1 do begin
            weight := weight_x[ix] * weight_y[iy];
            //sum and weight the source-pixel values //readpixel := GetPixel(ifrom_x + ix, ifrom_y + iy);
            total_red   := total_red   + ps^.Red  * weight;
            total_green := total_green + ps^.Green * weight;
            total_blue  := total_blue  + ps^.Blue  * weight;
            total_alpha  := total_alpha  + ps^.Alpha  * weight;
            inc(ps);  //next pixel
            end;  //ix
         end;  //iy
        //Set the pixel  //D.SetPixel(to_x, to_y, newpixel);
        pd^.Red := Round(total_red);
        pd^.Green := Round(total_green);
        pd^.Blue := Round(total_blue);
        pd^.Alpha := Round(total_alpha);
       end; //check bounds
      inc(pd); //next pixel
    end;   //to_x
  end;    //to_y
  D.Changed;
end;
{$ENDIF}


procedure TAbstractSuperDIB.SaveDataToStream(S: TStream);
var
  MS: TMemoryStream;
begin
  MS := TMemoryStream.Create;
  try
    with MS do
    begin
      Write(FWidth, SizeOf(FWidth));
      Write(FHeight, SizeOf(FHeight));
      Write(FData^, Width * Height * 4);
      Seek(0, soFromBeginning);
      Compress(Self, MS, S);
    end;
  finally
    MS.Free;
  end;
end;

procedure TAbstractSuperDIB.SetAngle(const Value: Extended);
begin
  if SafeAngle(Value) = FAngle then exit;
  FAngle := SafeAngle(Value);
  Changed;
end;

procedure TAbstractSuperDIB.SetAutoSize(const Value: Boolean);
begin
  if Value = FAutosize then exit;
  FAutoSize := Value;
  Changed;
end;

procedure TAbstractSuperDIB.SetHeight(const aValue: Word);
begin
  Resize(Width, aValue);
end;

procedure TAbstractSuperDIB.SetMasked(const Value: Boolean);
begin
  if Value = FMasked then exit;
  FMasked := Value;
  if FMasked then
    FTransparent := False;
  Changed;
end;

procedure TAbstractSuperDIB.SetMaskedValues(const Opacity: Byte);
var
  PixelCount: Cardinal;
  Data: PByteArray;
begin
  PixelCount := FWidth * FHeight;
  Data := PByteArray(FData);
  asm
          push EDI

          mov  EDI, Data
          mov  al,  Opacity
          mov  ECX, PixelCount
    @Loop:
          mov  [EDI+3], al
          lea  EDI, [EDI+4]
          dec  ECX
          jnz  @Loop

          pop  EDI
  end;
  Changed;
end;

procedure TAbstractSuperDIB.SetOpacity(const Value: Byte);
begin
  if Value = FOpacity then exit;
  FOpacity := Value;
  Changed;
end;

procedure TAbstractSuperDIB.SetScale(const Value: Extended);
begin
  if (Value = ScaleX) and (Value = ScaleY) then exit;
  FScaleX := Value;
  FScaleY := Value;
  Changed;
end;

procedure TAbstractSuperDIB.SetScaleX(const Value: Extended);
begin
  if Value = ScaleX then exit;
  FScaleX := Value;
  Changed;
end;

procedure TAbstractSuperDIB.SetScaleY(const Value: Extended);
begin
  if Value = ScaleY then exit;
  FScaleY := Value;
  Changed;
end;


procedure TAbstractSuperDIB.SetTransparent(const Value: Boolean);
begin
  if Value = FTransparent then exit;
  FTransparent := Value;
  if Transparent then
    FMasked := False;
  Changed;
end;

procedure TAbstractSuperDIB.SetTransparentColor(Value: TColor);
begin
  if Value = Pixel32ToColor(FTransparentColor) then exit;
  FTransparentColor := ColorToPixel32(Value);
  Changed;
end;

procedure TAbstractSuperDIB.SetTransparentMode(const Value: TTransparentMode);
begin
  if Value = TransparentMode then exit;
  FTransparentMode := Value;
  Changed;
end;

procedure TAbstractSuperDIB.SetWidth(const aValue: Word);
begin
  ReSize(aValue, Height);
end;

procedure TAbstractSuperDIB.SolidBlit(SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord; NoPixels, NoLines: Integer);
begin
  asm
          push EDI
          push ESI

          mov  ESI, SourceData
          mov  EDI, DestData

          mov  EDX, NoLines
  @VLoop:
          mov  ECX, NoPixels
  rep     MOVSD

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  EDX
          jnz  @VLoop
  @TheEnd:
          pop  ESI
          pop  EDI
  end;
end;

procedure TAbstractSuperDIB.SolidBlitO(SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord; NoPixels, NoLines: Integer);
var
  Opacity: Byte;
begin
  Opacity := FOpacity;
  asm
          push EDI
          push ESI
          push EBX

          mov  bh,  Opacity
          mov  bl,  Opacity

          mov  ESI, SourceData
          mov  EDI, DestData

          not  bh
          xor  EDX, EDX
  @VLoop:
          mov  ECX, NoPixels

  @HLoop:
          //Green
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB

          //Blue
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB

          //Red
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB
          mov  AL, [ESI]
          Inc  ESI
          cmp  [EDI], AL
          ja   @DontCopyMask
          mov  [EDI], AL
  @DontCopyMask:
          Inc  EDI

          dec  ECX
          jnz  @HLoop

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  NoLines
          jnz  @VLoop
  @TheEnd:
          pop  EBX
          pop  ESI
          pop  EDI
  end;
end;

procedure TAbstractSuperDIB.TransparentBlit(SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord; NoPixels, NoLines: Integer);
var
  TransColor: TPixel32;
begin
  TransColor := FTransparentColor;
  //  if TransparentMode = tmFixed then
  //     TransColor := FTransparentColor
  //  else
  //    TransColor := TColor(FData^);
  asm
          push EDI
          push ESI
          push EBX

          mov  ESI, SourceData
          mov  EDI, DestData

          mov  EDX, TransColor
          and  EDX, $00ffffff
  @VLoop:
          mov  ECX, NoPixels
  @HLoop:
          Mov  EAX, [ESI]
          and  EAX, $00ffffff
          cmp  EAX, EDX
          je   @SkipPixel
          mov  [EDI], EAX
  @SkipPixel:
          lea  ESI, [ESI+4]
          lea  EDI, [EDI+4]
          dec  ECX
          jnz  @HLoop

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  NoLines
          jnz  @VLoop
  @TheEnd:
          pop  EBX
          pop  ESI
          pop  EDI
  end;
end;

procedure TAbstractSuperDIB.TransparentBlitO(SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord; NoPixels, NoLines: Integer);
var
  TransColor: TPixel32;
  Opacity: Byte;
begin
  Opacity := FOpacity;
  TransColor := FTransparentColor;
  //  if TransparentMode = tmFixed then
  //     TransColor := FTransparentColor
  //  else
  //    TransColor := TColor(FData^);

  asm
          push EDI
          push ESI
          push EBX

          mov  EDX, TransColor
          and  EDX, $00ffffff
          mov  TransColor, EDX

          mov  bh,  Opacity
          mov  bl,  Opacity

          mov  ESI, SourceData
          mov  EDI, DestData

          xor  EDX, EDX

          not  bh
  @VLoop:
          mov  ECX, NoPixels
  @HLoop:
          mov  EAX, [ESI]
          and  EAX, $00ffffff
          cmp  EAX, TransColor
          je   @SkipPixel


          //Green
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          Mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB

          //Blue
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB

          //Red
          xor  Ah,Ah
          LodSB
          Mul  Bl
          Mov  DX, AX
          Xor  AX, AX
          Mov  Al, [EDI]
          mul  Bh
          add  Ax, Dx
          lea  EAX, [EAX+255]
          mov  Al, Ah
          StoSB
          mov  AL, [ESI]
          Inc  ESI
          mov  [EDI], AL
          Inc  EDI

          Jmp  @NextPixel

  @SkipPixel:
          //Next pixel
          lea  ESI, [ESI+4]
          lea  EDI, [EDI+4]
  @NextPixel:
          dec  ECX
          jnz  @HLoop

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  NoLines
          jnz  @VLoop
  @TheEnd:
          pop  EBX
          pop  ESI
          pop  EDI
  end;
end;


procedure TAbstractSuperDIB.PointDataAt(aSource: TAbstractSuperDIB);
begin
  FreeTheData;
  FOwnedData := False;
  aSource.AssignHeaderTo(Self);
  FData := aSource.FData;
end;

function TAbstractSuperDIB.Valid: Boolean;
begin
  Result := (FData <> nil) or not FOwnedData;
end;

destructor TAbstractSuperDIB.Destroy;
begin
  FreeTheData;
  inherited;
end;

procedure TAbstractSuperDIB.BlitMaskOnly(SourceData, DestData: Pointer;
  SourceModulo, DestModulo: DWord; NoPixels, NoLines: Integer);
begin
  asm
          push EDI
          push ESI

          mov  ESI, SourceData
          mov  EDI, DestData
          lea  ESI, [ESI+3]
          lea  EDI, [EDI+3]

          mov  EDX, NoLines
  @VLoop:
          mov  ECX, NoPixels
  @HLoop:
          mov  al, [ESI]
          lea  ESI, [ESI+4]
          mov  [EDI], al
          lea  EDI, [EDI+4]
          dec  ECX
          jnz  @HLoop

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  EDX
          jnz  @VLoop
  @TheEnd:
          pop  ESI
          pop  EDI
  end;
end;

procedure TAbstractSuperDIB.CreateTheData;
begin
  if FOwnedData then CreateData;
  FClipRect := Rect(0, 0, Width - 1, Height - 1);
end;

procedure TAbstractSuperDIB.FreeTheData;
begin
  if FOwnedData and (FData <> nil) then FreeData;
end;

procedure TAbstractSuperDIB.ResetHeader;
begin
  FAngle := 0;
  FMasked := False;
  FOpacity := 255;
  FScaleX := 100;
  FScaleY := 100;
  FTransparent := False;
end;

procedure TAbstractSuperDIB.SetClipRect(const aRect: TRect);
var
  Temp: Integer;
begin
  FClipRect := aRect;
  with FClipRect do 
  begin
    if Left > Right then 
    begin
      Temp := Left;
      Left := Right;
      Right := Temp;
    end;

    if Top > Bottom then 
    begin
      Temp := Top;
      Top := Bottom;
      Bottom := Temp;
    end;

    if Right >= Width then Right := Width - 1;
    if Left < 0 then Left := 0;
    if Bottom >= Height then Bottom := Height - 1;
    if Top < 0 then Top := 0;
  end;
end;

procedure TAbstractSuperDIB.StretchCopyPicture(Source: TAbstractSuperDIB);
var
  SWidth, SHeight, DWidth, DHeight: DWord;
  XInt, YInt: DWord;
  XFactor, YFactor: Word;
  SCurrentLine, DCurrentLine: Pointer;
  SLineSize, DLineSize: DWord;
begin
  SWidth := Source.Width;
  SHeight := Source.Height;
  DWidth := Width;
  DHeight := Height;

  XInt := (SWidth shl 16) div (DWidth shl 16);
  XFactor := (SWidth shl 16) div DWidth;
  YInt := (SHeight shl 16) div (DHeight shl 16);
  YFactor := (SHeight shl 16) div DHeight;


  SCurrentLine := Source.FData;
  DCurrentLine := FData;

  SLineSize := Source.Width * 4;
  DLineSize := Width * 4;
  XInt := XInt * 4;
  YInt := YInt * SLineSize;

  asm
        push ESI
        push EDI
        push EBX

        //Current X and Y factor in EDX
        mov  DX, YFactor
        BSWAP EDX
        mov  DX, XFactor

        //X and Y factor in EBX
        mov  BX, 65535
        BSWAP EBX

        //For Y := 0 to dst.height -1
        mov  ECX, DHeight

  @VLoop:

        //CurrentFactX := 65535;
        mov  BX, 65535
        //SData := SCurrentLine;
        mov  ESI, SCurrentLine
        //DData := DCurrentLine;
        mov  EDI, DCurrentLine

        //For X:=0 to Dst.Width-1
        push ECX
        mov  ECX, DWidth
  @HLoop:
        //DWord(DData^) := DWord(SData^);
        mov  EAX, [ESI]
        mov  [EDI], EAX

        //SData := Pointer(Cardinal(SData) + XInt);
        add  ESI, XInt
        //DData := Pointer(Cardinal(DData) + 4);
        lea  EDI, [EDI+4]

        //Check the XFactor
        sub  BX, DX
        jae  @NoWrapX
        lea  ESI, [ESI+4]
  @NoWrapX:
        dec  ECX
        jnz  @HLoop

        //Switch to Factors for Y loop
        BSWAP EBX
        BSWAP EDX

        //SCurrentLine := Pointer(Cardinal(SCurrentLine) + YInt);
        mov  EAX, YInt
        add  SCurrentLine, EAX
        //DCurrentLine := Pointer(Cardinal(DCurrentLine) + DLineSize);
        mov  EAX, DLineSize
        add  DCurrentLine, EAX

        //Check the Y Factor
        sub  BX, DX
        jae  @NoWrapY
        mov  EAX, SLineSize
        add  SCurrentLine, EAX
  @NoWrapY:
        //Switch back to Factors for X loop
        BSWAP EBX
        BSWAP EDX

        pop  ECX
        dec  ECX
        jnz  @VLoop

  @TheEnd:
        pop  EBX
        pop  EDI
        pop  ESI
  end;
  Changed;
end;

procedure TAbstractSuperDIB.Render8Bit(DestDC: HDC; X, Y, aWidth,
  aHeight: Integer; XSrc, YSrc: Word; ROP: Cardinal; Palette: TDIBPalette);
var
  SourceModulo, DestModulo: Integer;
  BitInfo: PBitmapInfo;
  DestData, SourceData: Pointer;
  FirstLine, LineSize: Integer;
  Table: Pointer;
  //For temp DIB
  Data: Pointer;
  DC: HDC;
  OldBitmap, Bitmap: HBitmap;
begin
  if Palette.UseTable = False then
    raise EDIBError.Create('Render8Bit can only be used with a palette containing a lookup table');
  if GetDeviceCaps(DestDC, BITSPixel) <> 8 then
    raise EDIBError.Create('Render8Bit can only be used to blit to an 8 bit DC');


  if XSrc >= Width then exit;
  if YSrc >= Height then exit;

  if X < 0 then 
  begin
    aWidth := Width - Abs(X);
    X := 0;
  end;
  if Y < 0 then 
  begin
    aHeight := Height - Abs(Y);
    Y := 0;
  end;
  if aWidth < 1 then exit;
  if aHeight < 1 then exit;

  if XSrc + aWidth > Width then aWidth := Width - (aWidth - XSrc);
  if YSrc + aHeight > Height then aHeight := Height - (aHeight - YSrc);

  //Make the 8 bit DIB
  DC := CreateCompatibleDC(DestDC);
  GetMem(BitInfo, SizeOf(TBitmapInfo) + 1024);
  with BitInfo.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    biPlanes := 1;
    biBitCount := 8;
    biCompression := BI_RGB;
    biWidth := aWidth;
    biHeight := aHeight;
    biSizeImage := 0;
    biXPelsPerMeter := 0;
    biYPelsPerMeter := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;
  GetPaletteEntries(Palette.Palette, 0, 235, BitInfo.bmiColors[0]);
  SetLastError(0);
  Bitmap := CreateDIBSection(DC, BitInfo^, DIB_PAL_COLORS, Data, 0, 0);
  if Bitmap = 0 then
    raise Exception.Create('Windows error (' + IntToStr(GetLastError) + ') ' + LastError);
  GDIFlush;
  OldBitmap := SelectObject(DC, Bitmap);

  //We now should have the bits in DATA
  LineSize := aWidth;
  if LineSize mod 4 > 0 then
    LineSize := LineSize + (4 - (LineSize mod 4));  //Increase to DWord

  DestModulo := aWidth + LineSize;
  SourceModulo := (aWidth * 4) + (Width * 4);

  FirstLine := (Height - 1) - YSrc;
  SourceData := Pointer(Integer(FData) + (FirstLine * Width * 4) + (XSrc * 4));
  DestData := Pointer(Integer(Data) + (LineSize * (aHeight - 1)));
  Table := @Palette.ColorTable[0];

  asm
      push ESI
      push EDI
      push EBX

      mov  EBX, Table
      mov  ESI, SourceData
      mov  EDI, DestData

      mov  ECX, aHeight
  @YLoop:
      push ECX
      mov  ECX, aWidth
  @XLoop:
      xor  EAX, EAX
      LodSB
      shr  EAX, 2
//      shl  eax, 12
      mov  EDX, EAX

      xor  EAX, EAX
      LodSB //Green
      shr  EAX, 2
      shl  EAX, 6
      add  EDX, EAX

      xor  EAX, EAX
      LodSB //Blue
      shr  EAX, 2
      shl  EAX, 12
      Add  EDX, EAX

      LodSB  //Ignore the mask

      //Get the index number
      mov  al, [EBX+EDX]

      StoSB //Put the result into the 8bit bitmap

      dec  ECX
      Jnz  @XLoop

      Sub  ESI, SourceModulo
      Sub  EDI, DestModulo

      pop  ECX
      dec  ECX
      jnz  @YLoop

  @TheEnd:
      pop  EBX
      pop  EDI
      pop  ESI
  end;

  SetDIBitsToDevice(DestDC, X, Y, aWidth, aHeight, 0, 0, 0, aHeight,
    Data, BitInfo^, DIB_RGB_COLORS);
  //  bitblt(destdc,x,y,awidth,aheight,dc,0,0,rop);
  SelectObject(DC, OldBitmap);
  DeleteObject(Bitmap);
  DeleteDC(DC);
  FreeMem(BitInfo);
end;

//MakeRGN and MakeRGNFromColor are almost identical.  A bug in one will most
//likely mean that there is a bug in the other.
function TAbstractSuperDIB.MakeRGN(const AMasklevel: Byte): HRGN;
var
  DataHandle: HGlobal;
  RGNData: PRGNData;
  CurrentRect: PRect;
  CurrentMask: PByte;
  X: Integer;
  Y: Integer;
  FirstPixelPos: Integer;
  RectStarted: Boolean;
  RectCount: Integer;

  procedure CombineRGNToResult;
  var
    TempRGN: HRGN;
  begin
    TempRGN := ExtCreateRegion(nil, SizeOf(TRgnDataHeader) +
      (RGNData.rdh.nCount * SizeOf(TRect)), RGNData^);
    Assert(TempRGN <> 0);
    if Result <> 0 then
    begin
      CombineRgn(Result, Result, TempRGN, RGN_OR);
      DeleteObject(TempRGN);
    end 
    else
      Result := TempRGN;
    RGNData.rdh.nCount := 0;
    CurrentRect := @RGNData^.Buffer[0];
  end;

  procedure AddRectangle;
  begin
    SetRect(CurrentRect^, FirstPixelPos, Y, X, Y + 1);
    CurrentRect := Pointer(Integer(CurrentRect) + SizeOf(TRect));
    Inc(RGNData.rdh.nCount);
    if RGNData.rdh.nCount = cRectAllocs then
      CombineRGNToResult;
  end;
begin
  Result := 0;

  DataHandle := GlobalAlloc(GMEM_MOVEABLE, SizeOf(TRgnDataHeader) +
    (SizeOf(TRect) * cRectAllocs));
  RGNData := GlobalLock(DataHandle);
  RGNData.rdh.dwSize := SizeOf(TRgnDataHeader);
  RGNData.rdh.iType := RDH_RECTANGLES;
  SetRect(RGNData.rdh.rcBound, 0, 0, Width, Height);
  RGNData.rdh.nCount := 0;
  RGNData.rdh.nRgnSize := 0;

  CurrentRect := @RGNData^.Buffer[0];
  for Y := 0 to Height - 1 do
  begin
    CurrentMask := PByte(Integer(ScanLine[Y]) + 3);
    FirstPixelPos := 0;
    RectStarted := (CurrentMask^ > AMaskLevel);
    for X := 0 to Width - 1 do
    begin
      if RectStarted then
      begin
        //We are making a rectangle, check if it has ended by passing over into
        //a lower mask level
        if (CurrentMask^ <= AMaskLevel) then
        begin
          RectStarted := False;
          AddRectangle;
        end;
      end
      else
      begin
        //We have been passing over transparent pixels, check if we have now
        //passed over a non-transparent pixel and, if so, start a rectangle
        if (CurrentMask^ > AMaskLevel) then
        begin
          RectStarted := True;
          FirstPixelPos := X;
        end;
      end;
      //
      CurrentMask := Pointer(Integer(CurrentMask) + 4);
    end;
    //We have passed all the way to the bottom, if we were over a non-transparent
    //pixel then we need to add a rectangle
    if RectStarted then
    begin
      X := Width;
      AddRectangle;
    end;
  end;

  if RGNData.rdh.nCount < cRectAllocs then
  begin
    RectCount := RGNData.rdh.nCount;
    GlobalUnlock(DataHandle);
    DataHandle := GlobalReAlloc(DataHandle, SizeOf(TRgnDataHeader) +
      (RectCount * SizeOf(TRect)), GMEM_MOVEABLE);
    RGNData := GlobalLock(DataHandle);
    Assert(RGNData <> nil);
  end;


  if RGNData.rdh.nCount > 0 then
    CombineRGNToResult;
  GlobalUnlock(DataHandle);
  GlobalFree(DataHandle);
end;

//MakeRGN and MakeRGNFromColor are almost identical.  A bug in one will most
//likely mean that there is a bug in the other.
function TAbstractSuperDIB.MakeRGNFromColor(ATransparentColor: TColor): HRGN;
var
  DataHandle: HGlobal;
  RGNData: PRGNData;
  CurrentRect: PRect;
  CurrentPixel: PDWORD;
  X: Integer;
  Y: Integer;
  FirstPixelPos: Integer;
  RectStarted: Boolean;
  RectCount: Integer;
  TransCol: TPixel32;

  procedure CombineRGNToResult;
  var
    TempRGN: HRGN;
  begin
    TempRGN := ExtCreateRegion(nil, SizeOf(TRgnDataHeader) +
      (RGNData.rdh.nCount * SizeOf(TRect)), RGNData^);
    Assert(TempRGN <> 0);
    if Result <> 0 then
    begin
      CombineRgn(Result, Result, TempRGN, RGN_OR);
      DeleteObject(TempRGN);
    end 
    else
      Result := TempRGN;
    RGNData.rdh.nCount := 0;
    CurrentRect := @RGNData^.Buffer[0];
  end;

  procedure AddRectangle;
  begin
    SetRect(CurrentRect^, FirstPixelPos, Y, X, Y + 1);
    CurrentRect := Pointer(Integer(CurrentRect) + SizeOf(TRect));
    Inc(RGNData.rdh.nCount);
    if RGNData.rdh.nCount = cRectAllocs then
      CombineRGNToResult;
  end;
  
begin
  Result := 0;
  TransCol := ColorToPixel32(ATransparentColor);

  DataHandle := GlobalAlloc(GMEM_MOVEABLE, SizeOf(TRgnDataHeader) +
    (SizeOf(TRect) * cRectAllocs));
  RGNData := GlobalLock(DataHandle);
  RGNData.rdh.dwSize := SizeOf(TRgnDataHeader);
  RGNData.rdh.iType := RDH_RECTANGLES;
  SetRect(RGNData.rdh.rcBound, 0, 0, Width, Height);
  RGNData.rdh.nCount := 0;
  RGNData.rdh.nRgnSize := 0;

  CurrentRect := @RGNData^.Buffer[0];
  for Y := 0 to Height - 1 do
  begin
    CurrentPixel := ScanLine[Y];
    FirstPixelPos := 0;
    RectStarted := (CurrentPixel^ and $00FFFFFF) <> DWORD(TransCol);
    for X := 0 to Width - 1 do
    begin
      if RectStarted then
      begin
        //We are making a rectangle, check if it has ended by passing over into
        //a transparent pixel
        if (CurrentPixel^ and $00FFFFFF) = DWORD(TransCol) then
        begin
          RectStarted := False;
          AddRectangle;
        end;
      end 
      else
      begin
        //We have been passing over transparent pixels, check if we have now
        //passed over a non-transparent pixel and, if so, start a rectangle
        if (CurrentPixel^ and $00FFFFFF) <> DWORD(TransCol) then
        begin
          RectStarted := True;
          FirstPixelPos := X;
        end;
      end;
      //
      CurrentPixel := Pointer(Integer(CurrentPixel) + 4);
    end;
    //We have passed all the way to the bottom, if we were over a non-transparent
    //pixel then we need to add a rectangle
    if RectStarted then
    begin
      X := Width;
      AddRectangle;
    end;
  end;

  if RGNData.rdh.nCount < cRectAllocs then
  begin
    RectCount := RGNData.rdh.nCount;
    GlobalUnlock(DataHandle);
    DataHandle := GlobalReAlloc(DataHandle, SizeOf(TRgnDataHeader) +
      (RectCount * SizeOf(TRect)), GMEM_MOVEABLE);
    RGNData := GlobalLock(DataHandle);
    Assert(RGNData <> nil);
  end;


  if RGNData.rdh.nCount > 0 then
    CombineRGNToResult;
  GlobalUnlock(DataHandle);
  GlobalFree(DataHandle);
end;


function TAbstractSuperDIB.GetScanline(Row: Integer): Pointer;
begin
  Row := (Height - 1) - Row;
  Result := Pointer(Integer(FData) + (Row * (Width * 4)));
end;

function TAbstractSuperDIB.GetPixel(X, Y: Integer): TPixel32;
var
  P: Pointer;
begin
  P := ScanLine[Y];
  Inc(Integer(P), X * 4);
  DWord(Result) := DWORD(P^);
end;

procedure TAbstractSuperDIB.SetPixel(X, Y: Integer; Value: TPixel32);
var
  P: Pointer;
begin
  P := ScanLine[Y];
  Inc(Integer(P), X * 4);
  DWord(P^) := DWord(Value);
  Changed;
end;

procedure TAbstractSuperDIB.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TAbstractSuperDIB.EndUpdate;
begin
  if FUpdateCount = 0 then
    raise EDIBError.Create('EndUpdate without BeginUpdate');
  Dec(FUpdateCount);
  if FUpdateCount = 0 then Changed;
end;

procedure TAbstractSuperDIB.LoadPicture(const Filename: string);
var
  Format: TAbstractDIBFormat;
begin
  if not FileExists(Filename) then
    raise EDIBError.Create('File does not exist.');

  Format := cDIBFormat.FindDIBImporter(Filename);
  if not Assigned(Format) then
    ImportPicture(Filename)
  else
  begin
    Format.LoadFromFile(Filename, Self);
    Changed;
  end;
end;

procedure TAbstractSuperDIB.SavePicture(const Filename: string);
var
  Format: TAbstractDIBFormat;
begin
  Format := cDIBFormat.FindDIBExporter(Filename);
  if not Assigned(Format) then
    raise EDIBError.Create('Not a supported picture format.');
  Format.SaveToFile(Filename, Self);
end;

procedure TAbstractSuperDIB.LoadPictureFromStream(FileExt: string;
  Stream: TStream);
var
  Format: TAbstractDIBFormat;
begin
  if Pos('.', FileExt) = 0 then FileExt := '.' + FileExt;
  Format := cDIBFormat.FindDIBImporter(FileExt);
  if not Assigned(Format) then
    raise EDIBError.Create('Not a supported picture format.');
  Format.LoadFromStream(FileExt, Stream, Self);
  Changed;
end;

procedure TAbstractSuperDIB.SavePictureToStream(FileExt: string;
  Stream: TStream);
var
  Format: TAbstractDIBFormat;
begin
  if Pos('.', FileExt) = 0 then FileExt := '.' + FileExt;
  Format := cDIBFormat.FindDIBExporter(FileExt);
  if not Assigned(Format) then
    raise EDIBError.Create('Not a supported picture format.');
  Format.SaveToStream(FileExt, Stream, Self);
end;

procedure TAbstractSuperDIB.DrawTiled(DestRect: TRect;
  Dest: TAbstractSuperDIB);
var
  XPos, YPos: Integer;
begin
  YPos := DestRect.Top;
  while YPos < DestRect.Bottom do
  begin
    XPos := DestRect.Left;
    while XPos < DestRect.Right do
    begin
      Draw(XPos, YPos, Width, Height, Dest, 0, 0);
      Inc(XPos, Width);
    end;
    Inc(YPos, Height);
  end;
end;

procedure TAbstractSuperDIB.ExportMask(AFilename: string);
var
  Pic: TPicture;
  WinDIB: TWinDIB;
  R: TRect;
begin
  R := Rect(0, 0, Self.Width, Self.Height);
  WinDIB := TWinDIB.Create(R.Right, R.Bottom);
  Pic := TPicture.Create;
  try
    WinDIB.SetClipRect(R);
    Self.DrawMaskAsGrayScale(0, 0, R.Right, R.Bottom, WinDIB, 0, 0);
    Pic.Bitmap.Width := R.Right;
    Pic.Bitmap.Height := R.Bottom;
    Pic.Bitmap.Canvas.CopyRect(R, WinDIB.Canvas, R);
    Pic.SaveToFile(AFilename);
  finally
    Pic.Free;
    WinDIB.Free;
  end;
end;

procedure TAbstractSuperDIB.ExportPicture(AFilename: string);
var
  Pic: TPicture;
  WinDIB: TWinDIB;
  R: TRect;
begin
  R := Rect(0, 0, Self.Width, Self.Height);
  WinDIB := TWinDIB.Create(R.Right, R.Bottom);
  Pic := TPicture.Create;
  try
    WinDIB.SetClipRect(R);
    Self.Draw(0, 0, R.Right, R.Bottom, WinDIB, 0, 0);
    Pic.Bitmap.Width := R.Right;
    Pic.Bitmap.Height := R.Bottom;
    Pic.Bitmap.Canvas.CopyRect(R, WinDIB.Canvas, R);
    Pic.SaveToFile(AFilename);
  finally
    Pic.Free;
    WinDIB.Free;
  end;
end;

procedure TAbstractSuperDIB.DrawGlyph(DestX, DestY, GlyphIndex, NumGlyphs: Integer;
  Dest: TAbstractSuperDIB);
var
  Temp: TMemoryDIB;
  GlyphWidth: Integer;
begin
  GlyphWidth := Width div NumGlyphs;
  Temp := TMemoryDIB.Create(GlyphWidth, Height);
  try
    DrawAll(0, 0, GlyphWidth, Height, Temp, GlyphIndex * GlyphWidth, 0);
    AssignHeaderTo(Temp);
    Temp.Draw(DestX, DestY, GlyphWidth, Height, Dest, 0, 0);
  finally
    Temp.Free;
  end;
end;

procedure TAbstractSuperDIB.DrawGlyphTween(DestX, DestY,
  NumGlyphs: Integer; Dest: TAbstractSuperDIB; Min, Max,
  Position: Integer; LoopFrames: Boolean);
var
  Temp: TMemoryDIB;
  Temp2: TMemoryDIB;
  GlyphWidth: Integer;
  GlyphPercent: Extended;
  FirstGlyphIndex: Integer;
  SecondGlyphIndex: Integer;
  Opacity1, Opacity2: Byte;
  Range: Integer;
begin
  Range := Max - Min;
  Position := Position - Min;
  GlyphPercent := (Position / Range * NumGlyphs);
  FirstGlyphIndex := Ceil(GlyphPercent);
  SecondGlyphIndex := Floor(GlyphPercent);
  GlyphPercent := GlyphPercent - Trunc(GlyphPercent);
  Opacity1 := Round(GlyphPercent * 255);
  Opacity2 := 255 - Opacity1;
  if FirstGlyphIndex >= NumGlyphs then
    if LoopFrames then FirstGlyphIndex := 0 else FirstGlyphIndex := NumGlyphs - 1;
  if FirstGlyphIndex < 0 then
    if LoopFrames then FirstGlyphIndex := NumGlyphs - 1 else FirstGlyphIndex := 0;
  if SecondGlyphIndex >= NumGlyphs then
    if LoopFrames then SecondGlyphIndex := 0 else SecondGlyphIndex := NumGlyphs - 1;
  if SecondGlyphIndex < 0 then
    if LoopFrames then SecondGlyphIndex := NumGlyphs - 1 else SecondGlyphIndex := 0;

  GlyphWidth := Width div NumGlyphs;
  Temp := TMemoryDIB.Create(GlyphWidth, Height);
  Temp2 := TMemoryDIB.Create(GlyphWidth, Height);
  try
    //Draw first index with 255 opacity
    DrawAll(0, 0, GlyphWidth, Height, Temp, FirstGlyphIndex * GlyphWidth, 0);
    AssignHeaderTo(Temp);
    Temp.Opacity := 255;

    //Draw second index onto main working DIB
    DrawAll(0, 0, GlyphWidth, Height, Temp2, SecondGlyphIndex * GlyphWidth, 0);
    Temp2.Angle := 0;
    Temp2.Scale := 100;
    Temp2.Opacity := Opacity2;
    Temp2.Draw(0, 0, GlyphWidth, Height, Temp, 0, 0);
    AssignHeaderTo(Temp2);

    //Finally, draw Temp to the destination
    Temp.Opacity := Opacity;
    Temp.Draw(DestX, DestY, GlyphWidth, Temp.Height, Dest, 0, 0);
  finally
    Temp.Free;
    Temp2.Free;
  end;
end;

procedure TAbstractSuperDIB.BlitMaskAsGrayScale(SourceData,
  DestData: Pointer; SourceModulo, DestModulo: DWord; NoPixels,
  NoLines: Integer);
begin
  asm
          push EDI
          push ESI

          mov  ESI, SourceData
          mov  EDI, DestData
          lea  ESI, [ESI+3]
          lea  EDI, [EDI+3]

          mov  EDX, NoLines
  @VLoop:
          mov  ECX, NoPixels
  @HLoop:
          mov  al, [ESI]
          lea  ESI, [ESI+4]
          mov  [EDI], al
          mov  [EDI+1], al
          mov  [EDI+2], al
          mov  [EDI+3], al
          lea  EDI, [EDI+4]
          dec  ECX
          jnz  @HLoop

          sub  ESI, SourceModulo
          sub  EDI, DestModulo
          dec  EDX
          jnz  @VLoop
  @TheEnd:
          pop  ESI
          pop  EDI
  end;
end;

procedure TAbstractSuperDIB.DrawMaskAsGrayScale(DestX, DestY, DestWidth,
  DestHeight: Integer; Dest: TAbstractSuperDIB; SrcX, SrcY: Word);
var
  OrigBlitter: TBlitterProc;
begin
  OrigBlitter := FBlitter;
  try
    FBlitter := BlitMaskAsGrayScale;
    Draw(DestX, DestY, DestWidth, DestHeight, Dest, SrcX, SrcY);
  finally
    FBlitter := OrigBlitter;
  end;
end;

procedure TAbstractSuperDIB.ImportMask(Source: Pointer; Width,
  Height: Integer);
var
  DestData: Pointer;
  PixelCount: Integer;
begin
  DestData := FData;
  PixelCount := Width * Height;
  asm
        push EDI
        push ESI

        mov  ESI, Source
        mov  EDI, DestData
        mov  ECX, PixelCount

  @Loop:
        Mov  al, [ESI]
        mov  [EDI+3], al
        lea  ESI, [ESI+1]
        lea  EDI, [EDI+4]
        dec  ECX
        jnz  @Loop

        pop  ESI
        pop  EDI
  end;
end;

procedure TAbstractSuperDIB.ExportMask(Destination: Pointer);
var
  SourceData: Pointer;
  PixelCount: Integer;
begin
  SourceData := FData;
  PixelCount := Width * Height;
  asm
        push EDI
        push ESI

        mov  ESI, SourceData
        mov  EDI, Destination
        mov  ECX, PixelCount

  @Loop:
        Mov  al, [ESI+3]
        mov  [EDI], al
        lea  ESI, [ESI+4]
        lea  EDI, [EDI+1]
        dec  ECX
        jnz  @Loop

        pop  ESI
        pop  EDI
  end;
end;

{ TCustomWinDIB }

constructor TCustomWinDIB.Create;
begin
  inherited;
  FCanvas := TCanvas.Create;
  FCanvas.OnChange := DoCanvasChanged;
end;

procedure TCustomWinDIB.CreateData;
var
  TempDC: HDC;
  BitInfo: TBitmapInfo;
begin
  TempDC := GetDC(0);
  FDC := CreateCompatibleDC(TempDC);
  with BitInfo.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    biPlanes := 1;
    biBitCount := 32;
    biCompression := BI_RGB;
    biWidth := Width;
    biHeight := Height;
    biSizeImage := 0;
    biXPelsPerMeter := 0;
    biYPelsPerMeter := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;
  SetLastError(0);
  FBitmap := CreateDIBSection(FDC, BitInfo, DIB_RGB_COLORS, FData, 0, 0);
  if FBitmap = 0 then
    raise Exception.Create('Windows error (' + IntToStr(GetLastError) + ') ' + LastError);
  GDIFlush;

  //SysRPL
  //DeleteObject(SelectObject(FDC,FBitmap));
  FOldBitmap := SelectObject(FDC, FBitmap);
  ReleaseDC(0, TempDC);
  FCanvas.Handle := FDC;
end;

destructor TCustomWinDIB.Destroy;
begin
  FCanvas.Free;
  FCanvas := nil;
  inherited;
end;

procedure TCustomWinDIB.DoCanvasChanged(Sender: TObject);
begin
  Changed;
end;

procedure TCustomWinDIB.FreeData;
begin
  GDIFlush;
  SelectObject(FDC, FOldBitmap);
  DeleteObject(FBitmap);
  DeleteDC(FDC);
  //SysRPL
  FData := nil;
end;


{ TCustomMemoryDIB }

procedure TCustomMemoryDIB.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TCustomMemoryDIB then
    with TCustomMemoryDIB(Dest) do
    begin
      FImageFilename := Self.ImageFilename;
      FMaskFilename := Self.MaskFilename;
    end;
end;

constructor TCustomMemoryDIB.Create;
begin
  inherited;
  FImageFilename := '';
  FMaskFilename := '';
  FSaveImageData := True;
end;

procedure TCustomMemoryDIB.CreateData;
begin
  Getmem(FData, Width * Height * 4);
end;

procedure TCustomMemoryDIB.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('ImageFilename', ReadImageFilename,
    WriteImageFilename, (FImageFilename <> ''));
  Filer.DefineProperty('MaskFilename', ReadMaskFilename,
    WriteMaskFilename, (FMaskFilename <> ''));
end;

procedure TCustomMemoryDIB.FreeData;
begin
  Freemem(FData);
end;

procedure TCustomMemoryDIB.ImportMask(AFilename: string);
begin
  inherited;
  FMaskFilename := AFilename;
end;

procedure TCustomMemoryDIB.ImportPicture(AFilename: string);
begin
  inherited;
  FImageFilename := AFilename;
end;

procedure TCustomMemoryDIB.LoadDataFromStream(S: TStream);
begin
  if S.Size > 0 then
    inherited;
end;

procedure TCustomMemoryDIB.ReadImageFilename(Reader: TReader);
begin
  FImageFilename := Reader.ReadString;
end;

procedure TCustomMemoryDIB.ReadMaskFilename(Reader: TReader);
begin
  FMaskFilename := Reader.ReadString;
end;

procedure TCustomMemoryDIB.SaveDataToStream(S: TStream);
begin
  if SaveImageData then
    inherited;
end;

procedure TCustomMemoryDIB.WriteImageFilename(Writer: TWriter);
begin
  Writer.WriteString(FImageFilename);
end;

procedure TCustomMemoryDIB.WriteMaskFilename(Writer: TWriter);
begin
  Writer.WriteString(FMaskFilename);
end;



{==================INITIALIZATION====================}
var
  X: Integer;
  Angle: Extended;


initialization
  for X := 0 to (360 * CSinCosTablePrecision) - 1 do
  begin
    Angle := X * pi / ((360 * CSinCosTablePrecision) / 2);
    GSinTable1[X] := Ceil(Sin(Angle) * 65536);
    GCosTable1[X] := Ceil(Cos(Angle) * 65536);
    GSinTable2[X] := Ceil(Sin(Angle + (pi / 2)) * 65536);
    GCosTable2[X] := Ceil(Cos(Angle + (pi / 2)) * 65536);
  end;
end.
