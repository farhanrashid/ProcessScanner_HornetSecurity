object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Process Scanner'
  ClientHeight = 729
  ClientWidth = 1284
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object SplitterLog: TSplitter
    Left = 381
    Top = 41
    Height = 583
    Align = alRight
  end
  object pnlSettings: TPanel
    Left = 0
    Top = 0
    Width = 1284
    Height = 41
    Align = alTop
    TabOrder = 0
    object cbSystemProcess: TCheckBox
      Left = 130
      Top = 10
      Width = 129
      Height = 17
      Caption = 'System processes'
      Checked = True
      Enabled = False
      State = cbChecked
      TabOrder = 0
    end
    object cbProcessOtherUsers: TCheckBox
      Left = 280
      Top = 10
      Width = 185
      Height = 17
      Caption = 'Process from other users'
      Checked = True
      Enabled = False
      State = cbChecked
      TabOrder = 1
    end
    object btnRefresh: TButton
      Left = 4
      Top = 6
      Width = 100
      Height = 25
      Caption = 'Refresh Now'
      TabOrder = 2
      OnClick = btnRefreshClick
    end
    object btnRescan: TButton
      Left = 471
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Rescan files'
      TabOrder = 3
      OnClick = btnRescanClick
    end
    object btnStopAll: TButton
      Left = 552
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Stop all scan'
      TabOrder = 4
      OnClick = btnStopAllClick
    end
    object btnClearLog: TButton
      Left = 633
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Clear Log'
      TabOrder = 5
      OnClick = btnClearLogClick
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 41
    Width = 381
    Height = 583
    Align = alClient
    TabOrder = 1
    object lvlProcesses: TLabel
      Left = 1
      Top = 1
      Width = 379
      Height = 15
      Align = alTop
      Caption = 'Processes'
    end
    object tvProcesses: TTreeView
      Left = 1
      Top = 16
      Width = 379
      Height = 566
      Align = alClient
      Indent = 19
      TabOrder = 0
      OnChange = tvProcessesChange
      OnCustomDrawItem = tvProcessesCustomDrawItem
    end
  end
  object pnlDetails: TPanel
    Left = 0
    Top = 624
    Width = 1284
    Height = 105
    Align = alBottom
    TabOrder = 2
    object lblDetails: TLabel
      Left = 1
      Top = 1
      Width = 1282
      Height = 15
      Align = alTop
      Caption = 'Process Details'
    end
    object vleDeltails: TValueListEditor
      Left = 1
      Top = 16
      Width = 1282
      Height = 88
      Align = alClient
      TabOrder = 0
      TitleCaptions.Strings = (
        'Property'
        'Value')
      ColWidths = (
        150
        1126)
    end
  end
  object pnlLog: TPanel
    Left = 384
    Top = 41
    Width = 900
    Height = 583
    Align = alRight
    TabOrder = 3
    object lblLog: TLabel
      Left = 1
      Top = 1
      Width = 898
      Height = 15
      Align = alTop
      Caption = 'Log'
    end
    object memoLog: TMemo
      Left = 1
      Top = 16
      Width = 898
      Height = 566
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object CountdownTimer: TTimer
    OnTimer = CountdownTimerTimer
    Left = 328
    Top = 64
  end
end
