object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Task Manager'
  ClientHeight = 695
  ClientWidth = 1284
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object SplitterLog: TSplitter
    Left = 381
    Top = 41
    Height = 549
    Align = alRight
    ExplicitLeft = 312
    ExplicitTop = 208
    ExplicitHeight = 100
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
      Left = 560
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Stop all scan'
      TabOrder = 4
      OnClick = btnStopAllClick
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 41
    Width = 381
    Height = 549
    Align = alClient
    TabOrder = 1
    object lvlProcesses: TLabel
      Left = 1
      Top = 1
      Width = 379
      Height = 15
      Align = alTop
      Caption = 'Processes'
      ExplicitWidth = 51
    end
    object tvProcesses: TTreeView
      Left = 1
      Top = 16
      Width = 379
      Height = 532
      Align = alClient
      Indent = 19
      TabOrder = 0
      OnChange = tvProcessesChange
      OnCustomDrawItem = tvProcessesCustomDrawItem
    end
  end
  object pnlDetails: TPanel
    Left = 0
    Top = 590
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
      ExplicitWidth = 78
    end
    object lvDetails: TListView
      Left = 1
      Top = 16
      Width = 1282
      Height = 88
      Align = alClient
      Columns = <
        item
          Caption = 'Property'
          Width = 100
        end
        item
          Caption = 'Value'
          Width = 800
        end>
      Items.ItemData = {
        059D0000000300000000000000FFFFFFFFFFFFFFFF01000000FFFFFFFF000000
        0009460069006C0065002000500061007400680000F81E2C2400000000FFFFFF
        FFFFFFFFFF01000000FFFFFFFF000000000A500072006F006300650073007300
        20004900440000C81C2C2400000000FFFFFFFFFFFFFFFF01000000FFFFFFFF00
        0000000A530065007300730069006F006E002000490044000090232C24FFFFFF
        FFFFFF}
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object pnlLog: TPanel
    Left = 384
    Top = 41
    Width = 900
    Height = 549
    Align = alRight
    TabOrder = 3
    object lblLog: TLabel
      Left = 1
      Top = 1
      Width = 898
      Height = 15
      Align = alTop
      Caption = 'Log'
      ExplicitWidth = 20
    end
    object memoLog: TMemo
      Left = 1
      Top = 16
      Width = 898
      Height = 532
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
