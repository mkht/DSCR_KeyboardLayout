#
# モジュール 'DSCR_KeyboardLayout' のモジュール マニフェスト
#
# 生成者: mkht
#
# 生成日: 2016/10/30
#

@{

# このマニフェストに関連付けられているスクリプト モジュール ファイルまたはバイナリ モジュール ファイル。
RootModule = 'DSCR_KeyboardLayout.psm1'

# このモジュールのバージョン番号です。
ModuleVersion = '1.1.0'

# このモジュールを一意に識別するために使用される ID
GUID = '0e3d225d-563a-4499-af75-4e1eacdce887'

# このモジュールの作成者
Author = 'mkht'

# このモジュールの会社またはベンダー
CompanyName = ''

# このモジュールの著作権情報
Copyright = '(c) 2017 mkht. All rights reserved.'

# このモジュールの機能の説明
Description = 'Add / Remove / Get Keyboard layout.`n This module support Windows 7 computer only.'

# このモジュールに必要な Windows PowerShell エンジンの最小バージョン
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# RootModule/ModuleToProcess に指定されているモジュールの入れ子になったモジュールとしてインポートするモジュール
# NestedModules = @()

# このモジュールからエクスポートする関数です。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートする関数がない場合は、エントリを削除しないで空の配列を使用してください。
FunctionsToExport = @(
    'Get-KeyboardLayout',
    'Set-KeyboardLayout',
    'Get-DefaultKeyboardLayout'
)

# このモジュールからエクスポートするコマンドレットです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするコマンドレットがない場合は、エントリを削除しないで空の配列を使用してください。
CmdletsToExport = @()

# このモジュールからエクスポートする変数
VariablesToExport = @()

# このモジュールからエクスポートするエイリアスです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするエイリアスがない場合は、エントリを削除しないで空の配列を使用してください。
AliasesToExport = @()

# このモジュールからエクスポートする DSC リソース
# DscResourcesToExport = @()

# このモジュールからエクスポートされたコマンドの既定のプレフィックス。既定のプレフィックスをオーバーライドする場合は、Import-Module -Prefix を使用します。
# DefaultCommandPrefix = ''

}

