object fmAnimEditor: TfmAnimEditor
  Left = 503
  Top = 445
  Width = 544
  Height = 396
  Caption = 'Animation manager'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = mnMain
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object dicRender: TDIBImageContainer
    Left = 153
    Top = 0
    Width = 383
    Height = 248
    IndexImage.DIBIndex = 0
    TileMethod = tmTile
    Align = alClient
    BorderDrawPosition = bdOverControls
    TabOrder = 0
    UseDockManager = True
    object diRender: TDIBImage
      Left = 1
      Top = -7
      Width = 381
      Height = 332
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
  object pnlControl: TDIBImageContainer
    Left = 0
    Top = 248
    Width = 536
    Height = 94
    IndexImage.DIBIndex = 0
    TileMethod = tmTile
    Align = alBottom
    BorderDrawPosition = bdOverControls
    TabOrder = 1
    UseDockManager = True
    object dflOpacity: TDIBFadeLabel
      Left = 160
      Top = 13
      Width = 36
      Height = 13
      AutoSize = True
      Caption = 'Opacity'
      Children = <>
      ColorHighlighted = clWhite
      DIBFeatures = <>
      FrameCount = 10
      FrameDelay = 50
      Layout = tlTop
      Opacity = 255
      ShowAccelChar = True
      Scale = 100.000000000000000000
      DIBTabOrder = -1
      Transparent = True
      WordWrap = False
    end
    object dflScale: TDIBFadeLabel
      Left = 160
      Top = 37
      Width = 27
      Height = 13
      AutoSize = True
      Caption = 'Scale'
      Children = <>
      ColorHighlighted = clWhite
      DIBFeatures = <>
      FrameCount = 10
      FrameDelay = 50
      Layout = tlTop
      Opacity = 255
      ShowAccelChar = True
      Scale = 100.000000000000000000
      DIBTabOrder = -1
      Transparent = True
      WordWrap = False
    end
    object dflAngle: TDIBFadeLabel
      Left = 160
      Top = 61
      Width = 27
      Height = 13
      AutoSize = True
      Caption = 'Angle'
      Children = <>
      ColorHighlighted = clWhite
      DIBFeatures = <>
      FrameCount = 10
      FrameDelay = 50
      Layout = tlTop
      Opacity = 255
      ShowAccelChar = True
      Scale = 100.000000000000000000
      DIBTabOrder = -1
      Transparent = True
      WordWrap = False
    end
    object DIBFadeLabel1: TDIBFadeLabel
      Left = 8
      Top = 8
      Width = 63
      Height = 13
      AutoSize = True
      Caption = 'DIBImageList'
      Children = <>
      ColorHighlighted = clWhite
      DIBFeatures = <>
      FrameCount = 30
      FrameDelay = 50
      Layout = tlTop
      Opacity = 255
      ShowAccelChar = True
      Scale = 100.000000000000000000
      DIBTabOrder = -1
      Transparent = True
      WordWrap = False
    end
    object btnOK: TButton
      Left = 8
      Top = 57
      Width = 75
      Height = 25
      Caption = '&OK'
      ModalResult = 1
      TabOrder = 0
    end
    object edOpacity: TEdit
      Left = 208
      Top = 8
      Width = 49
      Height = 21
      TabOrder = 1
      Text = '255'
      OnChange = edOpacityChange
    end
    object edScale: TEdit
      Left = 208
      Top = 32
      Width = 49
      Height = 21
      TabOrder = 2
      Text = '100'
      OnChange = edScaleChange
    end
    object edAngle: TEdit
      Left = 208
      Top = 56
      Width = 49
      Height = 21
      TabOrder = 3
      Text = '0'
      OnChange = edAngleChange
    end
    object cbImageList: TComboBox
      Left = 8
      Top = 24
      Width = 137
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 4
      OnChange = cbImageListChange
    end
    object udOpacity: TUpDown
      Left = 257
      Top = 8
      Width = 16
      Height = 21
      Associate = edOpacity
      Max = 255
      Position = 255
      TabOrder = 5
    end
    object udScale: TUpDown
      Left = 257
      Top = 32
      Width = 16
      Height = 21
      Associate = edScale
      Min = 1
      Position = 100
      TabOrder = 6
    end
    object udAngle: TUpDown
      Left = 257
      Top = 56
      Width = 16
      Height = 21
      Associate = edAngle
      Max = 359
      TabOrder = 7
    end
  end
  object pnlProperties: TPanel
    Left = 0
    Top = 0
    Width = 153
    Height = 248
    Align = alLeft
    TabOrder = 2
    object tvAnimations: TTreeView
      Left = 1
      Top = 1
      Width = 151
      Height = 246
      Align = alClient
      DragMode = dmAutomatic
      Indent = 19
      ReadOnly = True
      TabOrder = 0
      OnChange = tvAnimationsChange
      OnDblClick = tvAnimationsDblClick
      OnDragDrop = tvAnimationsDragDrop
      OnDragOver = tvAnimationsDragOver
      OnKeyDown = tvAnimationsKeyDown
      OnMouseDown = tvAnimationsMouseDown
    end
  end
  object mnMain: TMainMenu
    Left = 224
    Top = 72
    object Item1: TMenuItem
      Caption = 'Item'
      OnClick = Item1Click
      object Animation1: TMenuItem
        Caption = 'Animation'
        object miNewAnimation: TMenuItem
          Caption = 'New'
          OnClick = miNewAnimationClick
        end
        object miRenameAnimation: TMenuItem
          Caption = 'Rename'
          ShortCut = 113
          OnClick = miRenameAnimationClick
        end
      end
      object Frame1: TMenuItem
        Caption = 'Frame'
        object miNewFrame: TMenuItem
          Caption = 'New'
          OnClick = miNewFrameClick
        end
        object miEditFrame: TMenuItem
          Caption = 'Edit'
          OnClick = miEditFrameClick
        end
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object miDelete: TMenuItem
        Caption = '&Delete'
        OnClick = miDeleteClick
      end
    end
  end
  object dibPalette: TDIBPalette
    UseTable = False
    Left = 265
    Top = 72
    DIBPaletteColors = {
      FFFFFF00FEFEFE00FDFDFD00FCFCFC00FBFBFB00FAFAFA00F9F9F900F8F8F800
      F7F7F700F6F6F600F5F5F500F4F4F400F3F3F300F2F2F200F1F1F100F0F0F000
      EFEFEF00EEEEEE00EDEDED00ECECEC00EBEBEB00EAEAEA00E9E9E900E8E8E800
      E7E7E700E6E6E600E5E5E500E4E4E400E3E3E300E2E2E200E1E1E100E0E0E000
      DFDFDF00DEDEDE00DDDDDD00DCDCDC00DBDBDB00DADADA00D9D9D900D8D8D800
      D7D7D700D6D6D600D5D5D500D4D4D400D3D3D300D2D2D200D1D1D100D0D0D000
      CFCFCF00CECECE00CDCDCD00CCCCCC00CBCBCB00CACACA00C9C9C900C8C8C800
      C7C7C700C6C6C600C5C5C500C4C4C400C3C3C300C2C2C200C1C1C100C0C0C000
      BFBFBF00BEBEBE00BDBDBD00BCBCBC00BBBBBB00BABABA00B9B9B900B8B8B800
      B7B7B700B6B6B600B5B5B500B4B4B400B3B3B300B2B2B200B1B1B100B0B0B000
      AFAFAF00AEAEAE00ADADAD00ACACAC00ABABAB00AAAAAA00A9A9A900A8A8A800
      A7A7A700A6A6A600A5A5A500A4A4A400A3A3A300A2A2A200A1A1A100A0A0A000
      9F9F9F009E9E9E009D9D9D009C9C9C009B9B9B009A9A9A009999990098989800
      9797970096969600959595009494940093939300929292009191910090909000
      8F8F8F008E8E8E008D8D8D008C8C8C008B8B8B008A8A8A008989890088888800
      8787870086868600858585008484840083838300828282008181810080808000
      7F7F7F007E7E7E007D7D7D007C7C7C007B7B7B007A7A7A007979790078787800
      7777770076767600757575007474740073737300727272007171710070707000
      6F6F6F006E6E6E006D6D6D006C6C6C006B6B6B006A6A6A006969690068686800
      6767670066666600656565006464640063636300626262006161610060606000
      5F5F5F005E5E5E005D5D5D005C5C5C005B5B5B005A5A5A005959590058585800
      5757570056565600555555005454540053535300525252005151510050505000
      4F4F4F004E4E4E004D4D4D004C4C4C004B4B4B004A4A4A004949490048484800
      4747470046464600454545004444440043434300424242004141410040404000
      3F3F3F003E3E3E003D3D3D003C3C3C003B3B3B003A3A3A003939390038383800
      3737370036363600353535003434340033333300323232003131310030303000
      2F2F2F002E2E2E002D2D2D002C2C2C002B2B2B002A2A2A002929290028282800
      2727270026262600252525002424240023232300222222002121210020202000
      1F1F1F001E1E1E001D1D1D001C1C1C001B1B1B001A1A1A001919190018181800
      171717001616160015151500}
  end
  object pmAnimPop: TPopupMenu
    Left = 225
    Top = 104
    object miAnimNewFrame: TMenuItem
      Caption = 'New Frame'
      OnClick = miNewFrameClick
    end
    object miAnimDeleteAnim: TMenuItem
      Caption = 'Delete Anim'
      ShortCut = 46
      OnClick = miDeleteClick
    end
    object miAnimRename: TMenuItem
      Caption = 'Rename Anim'
      ShortCut = 113
      OnClick = miRenameAnimationClick
    end
  end
  object pmFramePop: TPopupMenu
    Left = 265
    Top = 104
    object ChoseImage1: TMenuItem
      Caption = 'Chose Image'
      OnClick = miEditFrameClick
    end
    object DeleteFrame1: TMenuItem
      Caption = 'Delete Frame'
      ShortCut = 46
      OnClick = miDeleteClick
    end
  end
  object pmBackPop: TPopupMenu
    Left = 185
    Top = 104
    object miBackNewAnim: TMenuItem
      Caption = 'New Anim'
      OnClick = miNewAnimationClick
    end
  end
end
