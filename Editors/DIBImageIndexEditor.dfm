object fmImageIndexEditor: TfmImageIndexEditor
  Left = 171
  Top = 121
  Width = 544
  Height = 375
  Caption = 'Select an image'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlControl: TPanel
    Left = 0
    Top = 300
    Width = 536
    Height = 41
    Align = alBottom
    TabOrder = 0
    object btnOk: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = '&OK'
      TabOrder = 0
      OnClick = btnOkClick
    end
    object btnCancel: TButton
      Left = 88
      Top = 8
      Width = 75
      Height = 25
      Caption = '&Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object lbNames: TListBox
    Left = 0
    Top = 0
    Width = 153
    Height = 300
    Align = alLeft
    ItemHeight = 13
    TabOrder = 1
    OnClick = lbNamesClick
  end
  object dicRender: TDIBImageContainer
    Left = 153
    Top = 0
    Width = 383
    Height = 300
    IndexImage.DIBIndex = 0
    TileMethod = tmTile
    Align = alClient
    BorderDrawPosition = bdOverControls
    TabOrder = 2
    UseDockManager = True
    object diRender: TDIBImage
      Left = 1
      Top = 1
      Width = 381
      Height = 305
      Accelerator = #0
      AutoSize = True
      Center = False
      Children = <>
      DIBFeatures = <>
      IndexMain.DIBIndex = -1
      Opacity = 255
      Scale = 100.000000000000000000
      Stretch = False
      DIBTabOrder = -1
    end
  end
end
