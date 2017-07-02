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
        foreach($klid in $AryKeyLayout){
            if($InstalledLayout.KeyboardLayout -match $klid){
                Write-Verbose ("Current default keyboard layout is NOT your desired one. (desired: '{0}' / current: '{1}')" -f $Defaultlayout, $InstalledLayout.Default)
                return $false
            }
        }
        return $true
    }
    else{
        if($Default){
            $Defaultlayout = @(Parse-KeyLayout $Default)[0]
            if(-not $Defaultlayout){
                Write-Error 'Default param is not valid format.'
            }
            elseif(-not ($Defaultlayout -eq $InstalledLayout.Default)){
                Write-Verbose ("Current default keyboard layout is NOT your desired one. (desired: '{0}' / current: '{1}')" -f $Defaultlayout, $InstalledLayout.Default)
                return $false
            }
            else{
                Write-Verbose ("Current default keyboard layout is your desired one. (desired: '{0}' / current: '{1}')" -f $Defaultlayout, $InstalledLayout.Default)
            }
        }

        foreach($klid in $AryKeyLayout){
            if(-not ($InstalledLayout.KeyboardLayout -match $klid)){
                Write-Verbose ("Installed keyboard layouts are NOT matched your desired ones. (desired: '{0}' / current: '{1}')" -f ($AryKeyLayout -join ','), $InstalledLayout.KeyboardLayout)
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
        $SetParams += [pscustomobject]@{
            KeyboardLayoutId = $key
            Action = $Action
            Default = ($key -eq $DefaultKeyLayout)
        }
    }

    if($ClearExist){
        $CurrentKeyLayout = Get-KeyboardLayout
        foreach($key in $CurrentKeyLayout){
            if($SetParams.KeyboardLayoutId -notcontains $key){
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

    $private:AryKeyLayout = New-Object 'System.Collections.Generic.List[string]'
    foreach($key in ($KeyboardLayout -split ',')){
        $key = $key.Trim()
        if($key -match '^[0-9a-f]{4}:[0-9a-f\-\{\}]{8,}$'){
            $AryKeyLayout.Add($key)
        }
        elseif($key -match '^.+:.+'){
            $AryKeyLayout.Add($klid)
        }
    }
    $AryKeyLayout.ToArray()
}

Export-ModuleMember -Function *-TargetResource