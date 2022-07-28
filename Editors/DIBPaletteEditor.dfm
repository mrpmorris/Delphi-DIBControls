object fmDIBPaletteEditor: TfmDIBPaletteEditor
  Left = 399
  Top = 233
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Palette Editor'
  ClientHeight = 184
  ClientWidth = 253
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlPalette: TPanel
    Left = 5
    Top = 5
    Width = 242
    Height = 102
    BevelOuter = bvLowered
    TabOrder = 0
    object pbPalette: TPaintBox
      Left = 1
      Top = 1
      Width = 240
      Height = 100
      Align = alClient
      OnPaint = pbPalettePaint
    end
  end
  object btnLoadFromBmp: TButton
    Left = 134
    Top = 112
    Width = 113
    Height = 25
    Caption = 'Load From Bitmap'
    TabOrder = 1
    OnClick = btnLoadFromBmpClick
  end
  object btnLoadFromRaw: TButton
    Left = 8
    Top = 112
    Width = 113
    Height = 25
    Caption = 'Load From Raw'
    TabOrder = 2
    OnClick = btnLoadFromRawClick
  end
  object BitBtn1: TBitBtn
    Left = 88
    Top = 152
    Width = 75
    Height = 25
    TabOrder = 3
    Kind = bkOK
  end
  object btnCancel: TBitBtn
    Left = 172
    Top = 152
    Width = 75
    Height = 25
    TabOrder = 4
    Kind = bkCancel
  end
  object odRaw: TOpenDialog
    Filter = 
      'Photoshop Palette (*.act)|*.act|Raw Palette (*.pal)|*.pal|All Fi' +
      'les (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Open raw palette'
    Left = 8
    Top = 144
  end
  object odBitmap: TOpenDialog
    Filter = 'Bitmap File (*.bmp)|*.bmp'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Open bitmap'
    Left = 40
    Top = 144
  end
end
