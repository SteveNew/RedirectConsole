object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 297
  ClientWidth = 476
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    476
    297)
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 137
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Embed CMD into panel'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 0
    Top = 39
    Width = 476
    Height = 258
    Align = alBottom
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
  object Button2: TButton
    Left = 151
    Top = 8
    Width = 129
    Height = 25
    Caption = 'Execute and redirect'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 286
    Top = 8
    Width = 131
    Height = 25
    Caption = 'Attach to process'
    TabOrder = 3
    OnClick = Button3Click
  end
end
