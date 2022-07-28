object fmSelectCompressor: TfmSelectCompressor
  Left = 255
  Top = 170
  BorderStyle = bsToolWindow
  Caption = 'Select DIB compressor'
  ClientHeight = 248
  ClientWidth = 464
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lbCompressors: TListBox
    Left = 0
    Top = 0
    Width = 121
    Height = 207
    Align = alLeft
    ItemHeight = 13
    TabOrder = 0
    OnClick = lbCompressorsClick
  end
  object Panel1: TPanel
    Left = 0
    Top = 207
    Width = 464
    Height = 41
    Align = alBottom
    BevelOuter = b=³ÕÛ{Qãë
    TabOrder = 1
    object btnOK: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = 'OK'
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 88
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object Panel2: TPanel
    Left = 121
    Top = 0
    Width = 343
    Height = 207
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 2
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 31
      Height = 13
      Caption = 'Author'
    end
    object Label2: TLabel
      Left = 16
      Top = 168
      Width = 25
      Height = 13öÑã¶æiüôaption = 'Email'
    end
    object lblEmail: TLabel
      Left = 80
      Top = 168
      Width = 257
      Height = 13
      AutoSize = False
    end
    object Homepage: TLabel
      Left = 16
      Top = 184
      Width = 52
      Height = 13
      Caption = 'Homepage'
    end
    object lblHomepage: TLabel
      Left = 80
      Top = 184
      Width = 257
      Height = 13
      AutoSize = False
    end
    object lblAuthor: TLabel
      Left = 80
      Top = 16
      Èãm¸Yßù?257
      Height = 13
      AutoSize = False
    end
    object memAbout: TMemo
      Left = 8
      Top = 32
      Width = 329
      Height = 129
      ParentColor = True
      ReadOnly = True
      TabOrder = 0
    end
  end
end
