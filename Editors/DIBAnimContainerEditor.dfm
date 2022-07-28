object fmSnapshotEditor: TfmSnapshotEditor
  Left = 318
  Top = 117
  Width = 413
  Height = 495
  BorderStyle = bsSizeToolWin
  Caption = 'Snapshot editor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lbSnapshots: TListBox
    Left = 0
    Top = 0
    Width = 405
    Height = 417
    Align = alTop
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 0
  end
  object btnRename: TButton
    Left = 8
    Top = 424
    Width = 75
    Height = 25
    Caption = 'Rename'
    TabOrder = 1
    OnClick = btnRenameClick
  end
  object btnDelete: TButton
    Left = 264
    Top = 424
    Width = 75
    Height = 25
    Caption = 'Delete'
    TabOrder = 3
    OnClick = btnDeleteClick
  end
  object btnGoTo: TButton
    Left = 88
    Top = 424
    Width = 75
    Height = 25
    Caption = 'Go to'
    TabOrder = 2
    OnClick = btnGoToClick
  end
  object btnUpdate: TButton
    Left = 168
    Top = 424
    Width = 75
    Height = 25
    Caption = 'Update'
    TabOrder = 4
    OnClick = btnUpdateClick
  end
end
