object Form2: TForm2
  Left = 513
  Top = 272
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 92
  ClientWidth = 358
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object sPanel1: TsPanel
    Left = 0
    Top = 0
    Width = 358
    Height = 57
    Align = alTop
    Caption = '00:00:00'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = 'Tahoma'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    SkinData.SkinSection = 'PANEL'
  end
  object sBitBtn1: TsBitBtn
    Left = 142
    Top = 64
    Width = 75
    Height = 25
    TabOrder = 1
    OnClick = sBitBtn1Click
    Kind = bkOK
    SkinData.SkinSection = 'BUTTON'
  end
  object tmr1: TTimer
    Enabled = False
    OnTimer = tmr1Timer
    Left = 32
    Top = 16
  end
end
