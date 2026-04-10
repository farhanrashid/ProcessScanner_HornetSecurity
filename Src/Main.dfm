object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Task Manager'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object pnlSettings: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    Caption = 'pnlSettings'
    TabOrder = 0
  end
  object pnlMain: TPanel
    Left = 0
    Top = 41
    Width = 439
    Height = 359
    Align = alClient
    Caption = 'pnlMain'
    TabOrder = 1
  end
  object pnlDetails: TPanel
    Left = 439
    Top = 41
    Width = 185
    Height = 359
    Align = alRight
    Caption = 'pnlDetails'
    TabOrder = 2
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 400
    Width = 624
    Height = 41
    Align = alBottom
    Caption = 'pnlStatus'
    TabOrder = 3
  end
end
