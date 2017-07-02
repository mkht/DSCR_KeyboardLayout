$modulePath = (get-item (Split-Path -parent $MyInvocation.MyCommand.Path)).Parent.Parent.FullName
$functionsPath = '\functions'
Get-ChildItem (Join-Path $modulePath $functionsPath) -Include "*.ps1" -Recurse |
    % { . $_.PsPath }


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [string]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [string]
        $KeyboardLayout,

        [string]$Default
    )

    $ErrorActionPreference = 'Stop'

    $AllKeyLayout = Get-KeyboardLayout
    if($AllKeyLayout){
        $Ensure = "Present"
    }
    else{
        $Ensure = 'Absent'
    }

    return @{
        Ensure = $Ensure
        KeyboardLayout = ($AllKeyLayout -join ',')
        Default = Get-DefaultKeyboardLayout
    }
} # end of Get-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [string]
        $KeyboardLayout,

        [string]
        $Default,

        [bool]
        $CopySettingsToSystemAcct = $false,

        [bool]
        $CopySettingsToDefaultUserAcct = $false,

        [bool]
        $ClearExist = $false
    )

    $ErrorActionPreference = 'Stop'

    $private:GetParam = @{
        Ensure = $Ensure
        KeyboardLayout = $KeyboardLayout
    }

    $InstalledLayout = Get-TargetResource @GetParam -ErrorAction Stop
    $AryKeyLayout = Parse-KeyLayout $KeyboardLayout
    if($AryKeyLayout.Count -eq 0){
        Write-Error 'KeyboardLayout param is not valid format.'
    }

    if($Ensure -eq 'Absent'){
        foreach($key in $AryKeyLayout){
            if($InstalledLayout.KeyboardLayout -match $key.KeyboardLayoutId){
                Write-Verbose ("Current keyboard layouts are NOT matched your desired ones. (desired: '{0}' / current: '{1}')" -f ($AryKeyLayout.KeyboardLayoutId -join ','), $InstalledLayout.KeyboardLayout)
                return $false
            }
        }
        return $true
    }
    else{
        if($Default){
            $Defaultlayout = @(Parse-KeyLayout $Default)[0]
            if(-not $Defaultlayout.KeyboardLayoutId){
                Write-Error 'Default param is not valid format.'
            }
            elseif(-not ($Defaultlayout.KeyboardLayoutId -eq $InstalledLayout.Default)){
                Write-Verbose ("Current default keyboard layout is NOT your desired one. (desired: '{0}' / current: '{1}')" -f $Defaultlayout.KeyboardLayoutId, $InstalledLayout.Default)
                return $false
            }
            else{
                Write-Verbose ("Current default keyboard layout is your desired one. (desired: '{0}' / current: '{1}')" -f $Defaultlayout.KeyboardLayoutId, $InstalledLayout.Default)
            }
        }

        foreach($key in $AryKeyLayout){
            if(-not ($InstalledLayout.KeyboardLayout -match $key.KeyboardLayoutId)){
                Write-Verbose ("Installed keyboard layouts are NOT matched your desired ones. (desired: '{0}' / current: '{1}')" -f ($AryKeyLayout.KeyboardLayoutId -join ','), $InstalledLayout.KeyboardLayout)
                return $false
            }
        }
        return $true
    }
} # end of Test-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter(Mandatory = $true)]
        [string]
        $KeyboardLayout,

        [string]
        $Default,

        [bool]
        $CopySettingsToSystemAcct = $false,

        [bool]
        $CopySettingsToDefaultUserAcct = $false,

        [bool]
        $ClearExist = $false
    )

    $ErrorActionPreference = 'Stop'

    $AryKeyLayout = Parse-KeyLayout $KeyboardLayout
    if($Default){$DefaultKeyLayout = @(Parse-KeyLayout $Default)[0]}

    switch ($Ensure){
        'Present' { $Action = 'add' }
        'Absent' { $Action = 'remove' }
    }

    $SetParams = @()
    foreach($key in $AryKeyLayout){
        if($key.LanguageTag -and $key.KeyboardLayoutName){
            $SetParams += [pscustomobject]@{
                KeyboardLayoutName = $key.KeyboardLayoutName
                LanguageTag = $key.LanguageTag
                Action = $Action
                Default = ($key.KeyboardLayoutId -eq $DefaultKeyLayout.KeyboardLayoutId)
            }
        }
        else{
            $SetParams += [pscustomobject]@{
                KeyboardLayoutId = $key.KeyboardLayoutId
                Action = $Action
                Default = ($key.KeyboardLayoutId -eq $DefaultKeyLayout.KeyboardLayoutId)
            }
        }
    }

    if($ClearExist){
        $CurrentKeyLayout = Get-KeyboardLayout
        foreach($key in $CurrentKeyLayout){
            if($AryKeyLayout.KeyboardLayoutId -notcontains $key){
                $SetParams += [pscustomobject]@{
                    KeyboardLayoutId = $key
                    Action = 'remove'
                    Default = $false
                }
            }
        }

        Remove-Item 'HKCU:\Software\Microsoft\CTF\SortOrder\AssemblyItem' -Force -ErrorAction SilentlyContinue
        Remove-Item 'HKCU:\Software\Microsoft\CTF\SortOrder\Language' -Force -ErrorAction SilentlyContinue
    }

    $SetParams | Set-KeyboardLayout -CopySettingsToDefaultUserAcct:$CopySettingsToDefaultUserAcct -CopySettingsToSystemAcct:$CopySettingsToSystemAcct

} # end of Set-TargetResource

function Parse-KeyLayout{
    Param(
        [Parameter(Position=0)]
        [string]$KeyboardLayout
    )

    $private:AryKeyLayout = New-Object 'System.Collections.Generic.List[Hashtable]'
    foreach ($key in ($KeyboardLayout -split ',')) {
        $key = $key.Trim()
        # IDの場合
        if ($key -match '^[0-9a-f]{4}:[0-9a-f\-\{\}]{8,}$') {
            $Hash = @{
                KeyboardLayoutId   = $key   #IDのみで返す
                KeyboardLayoutName = ''
                LanguageTag        = ''
            }
            $AryKeyLayout.Add($Hash)
        }
        # 名前の場合
        elseif ($key -match '^.+:.+') {
            $private:lang = ($key -split ':')[0]
            $private:kbl = ($key -split ':')[1]
            # 名前をIDに変換する
            $private:klid = (Convert-KblNameToId -Tag $lang -Name $kbl)

            if (-not $klid) {
                #IDに変換できなかった場合はListに追加せずスキップする
            }
            else{
                #名前とID両方を返す
                $Hash = @{
                    KeyboardLayoutId   = $klid
                    KeyboardLayoutName = $kbl
                    LanguageTag        = $lang
                }
                $AryKeyLayout.Add($Hash)
            }
        }
    }
    $AryKeyLayout.ToArray()
}

Export-ModuleMember -Function *-TargetResource