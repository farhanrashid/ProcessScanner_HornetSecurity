object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Task Manager'
  ClientHeight = 695
  ClientWidth = 962
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlSettings: TPanel
    Left = 0
    Top = 0
    Width = 962
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 733
    object cbSystemProcess: TCheckBox
      Left = 10
      Top = 10
      Width = 129
      Height = 17
      Caption = 'System Processes'
      TabOrder = 0
    end
    object cbProcessOtherUsers: TCheckBox
      Left = 180
      Top = 10
      Width = 185
      Height = 17
      Caption = 'Process from other users'
      TabOrder = 1
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 41
    Width = 344
    Height = 535
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 448
    object Label1: TLabel
      Left = 1
      Top = 1
      Width = 342
      Height = 15
      Align = alTop
      Caption = 'Processes'
      ExplicitWidth = 51
    end
    object tvProcesses: TTreeView
      Left = 1
      Top = 16
      Width = 342
      Height = 518
      Align = alClient
      Indent = 19
      TabOrder = 0
      ExplicitWidth = 446
    end
  end
  object pnlDetails: TPanel
    Left = 0
    Top = 576
    Width = 962
    Height = 119
    Align = alBottom
    TabOrder = 2
    ExplicitWidth = 733
    object lblDetails: TLabel
      Left = 1
      Top = 1
      Width = 960
      Height = 15
      Align = alTop
      Caption = 'Process Details'
      ExplicitWidth = 78
    end
    object lvDetails: TListView
      Left = 1
      Top = 16
      Width = 960
      Height = 102
      Align = alClient
      Columns = <>
      TabOrder = 0
      ExplicitWidth = 731
    end
  end
  object pnlLog: TPanel
    Left = 344
    Top = 41
    Width = 618
    Height = 535
    Align = alRight
    TabOrder = 3
    object lblLog: TLabel
      Left = 1
      Top = 1
      Width = 616
      Height = 15
      Align = alTop
      Caption = 'Log'
      ExplicitWidth = 20
    end
    object memoLog: TMemo
      Left = 1
      Top = 16
      Width = 616
      Height = 518
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
      ExplicitLeft = 5
      ExplicitTop = 12
      ExplicitWidth = 283
    end
  end
end
