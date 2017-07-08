$modulePath = (get-item (Split-Path -parent $MyInvocation.MyCommand.Path)).Parent.FullName
# check os version
$private:Ver = ([System.Environment]::OSVersion).Version
switch (('{0}.{1}' -f $Ver.Major, $Ver.Minor)) {
    '6.1' { $OS = '7' }    #Win7
    '10.0' { $OS = '10'}  #Win10
}

$private:lang = Join-Path $modulePath ('lang_w{0}.json' -f $OS)
$private:kbl = Join-Path $modulePath ('kbl_w{0}.json' -f $OS)
if(Test-Path $lang){
    $LanguageList = gc $lang | ConvertFrom-Json -ea SilentlyContinue
}
if(Test-Path $kbl){
    $KeyboardList = gc $kbl | ConvertFrom-Json -ea SilentlyContinue
}

function Convert-KblNameToId
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='Name')]
        [Alias('Tag')]
        [string]$LanguageTag,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='Name')]
        [Alias('Name')]
        [string]$KeyboardLayoutName
    )

    Process{
        $private:langId = $LanguageList.where({$_.tag -eq $LanguageTag}).Id
        $private:kblId = $KeyboardList.where({$_.name -eq $KeyboardLayoutName}).Id
        if($langId -and $kblId){ ("{0}:{1}" -f $langId, $kblId) }
    }
}

function Convert-LangIdToTag
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Alias('Id')]
        [string]$LanguageId
    )

    Process{
        @($LanguageList.where({$_.id -eq $LanguageId}).tag)[0]
    }
}

function Convert-KblIdToName
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [Alias('Id')]
        [string]$KeyboardLayoutId
    )

    Process{
        @($KeyboardList.where({$_.name -eq $KeyboardLayoutId}).id)[0]
    }
}

function New-GsXml
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-f]{4}:[0-9a-f\-\{\}]{8,}$')]
        [string]$KeyboardLayoutId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('add','remove')]
        [string]$Action = 'add',

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$Default = $false,

        [switch]$CopySettingsToDefaultUserAcct,
        [switch]$CopySettingsToSystemAcct
    )

    Begin{
        $local:ConstantData = @{
        GsBaseXml = @'
        <gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
            <gs:UserList>
                <gs:User UserID="Current" CopySettingsToDefaultUserAcct="{0}" CopySettingsToSystemAcct="{1}"/>
            </gs:UserList>
            <gs:InputPreferences>
                {2}
            </gs:InputPreferences>
        </gs:GlobalizationServices>
'@
        GsKbXmlRaw = '<gs:InputLanguageID Action="{0}" ID="{1}" Default="{2}"/>'
    }

        $KblRaws = [string[]]@()
    }

    Process{
        $KblRaws += ($ConstantData.GsKbXmlRaw -f $Action, $KeyboardLayoutId, $Default.ToString().ToLower())
    }

    End{
        [Xml]($ConstantData.GsBaseXml -f $CopySettingsToDefaultUserAcct.ToString().ToLower(), $CopySettingsToSystemAcct.ToString().ToLower(), [string]$KblRaws)
    }
}

<#
.Synopsis
   Add or Remove keyboard layout
.DESCRIPTION
   Add or Remove keyboard layout to current user & computer.
   This cmdlet support Windows 7 & 10 system only.
.PARAMETER KeyboardLayoutId
   Specify keyboard layout ID (KLID)
   KLID is special formatted string like "0409:00000409" (Lang tag:Layout id)
   If you don't know desired KLID, you can refer to JSON files in this module's root directory or Use Get-KeyboardLayout cmdlet (or Google it).
.PARAMETER LanguageTag
   If you don't wont see unsuitable KLID, Use LanguageTag and KeyboardLayoutName arguments.
   You can use friendly name to specify keyboard layout instead of KLID.
   Specify LanguageTag for IETF Language Tag like "en-US" or "fr-FR"
.PARAMETER KeyboardLayoutName
   Specify name of keyboard layout.
   The list of all available layout names are written in JSON file that saved in this module's root directory
   e.g.) "United States-International" , "Chinese (Traditional) - US Keyboard"
.PARAMETER Action
   You can choose "add" or "remove".
   default: 'add'
.PARAMETER Default
   If this param set to $true, keyboard layout will configure to default keyboard of current user.
   default: False
.PARAMETER CopySettingsToDefaultUserAcct
   Copy settings to default user account profile.
   This parameter only works on Windows 7 systems.
   default: False
.PARAMETER CopySettingsToSystemAcct
   Copy settings to system account profile.
   This parameter only works on Windows 7 systems.
   default: False
.PARAMETER ClearExist
   Clear existence keyboard layouts.
   This parameter only works on Windows 10 systems.
   default: False
.EXAMPLE
   Add "US - US Keyboard" using KLID
   Set-KeyboardLayout -KeyboardLayoutId "0409:00000409"
.EXAMPLE
   Add "Chinese (Taiwan) - Chinese Simplified QuanPin" using friendly name
   Set-KeyboardLayout -LanguageTag 'zh-TW' -KeyboardLayoutName "Chinese Simplified QuanPin"
#>
function Set-KeyboardLayout
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='ID')]
        [ValidatePattern('^[0-9a-f]{4}:[0-9a-f\-\{\}]{8,}$')]
        [Alias('Id')]
        [string]$KeyboardLayoutId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='Name')]
        [ValidateScript({$LanguageList.tag -eq $_})]
        [Alias('Tag')]
        [Alias('Language')]
        [string]$LanguageTag,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='Name')]
        [ValidateScript({$KeyboardList.name -eq $_})]
        [Alias('Name')]
        [string]$KeyboardLayoutName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('add','remove')]
        [string]$Action = 'add',

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$Default = $false,

        [switch]$CopySettingsToDefaultUserAcct, # Win7 only
        [switch]$CopySettingsToSystemAcct, # Win7 only
        [switch]$ClearExist # Win10 only
    )

    Begin{
        $KblRaws = @()
    }

    Process{
        if($PSCmdlet.ParameterSetName -eq 'ID'){
            $LanguageTag = Convert-LangIdToTag $KeyboardLayoutId.Substring(0, 4)
            $KeyboardLayoutName = Convert-KblIdToName $KeyboardLayoutId.Substring(5)
        }

        if($LanguageTag -and $KeyboardLayoutName){
            $kblRaws += [PSCustomObject]@{
                LanguageTag = $LanguageTag
                KeyboardLayoutName = $KeyboardLayoutName
                Action = $Action
                Default = $Default
            }
            Write-Verbose ('Adding Keyboard (Lang:"{0}" / Layout:"{1}")' -f $LanguageTag,$KeyboardLayoutName)
        }
        elseif ($KeyboardLayoutId) {
            $kblRaws += [PSCustomObject]@{
                KeyboardLayoutId = $KeyboardLayoutId
                Action = $Action
                Default = $Default
            }
            Write-Verbose ('Adding Keyboard (Id:"{0}")' -f $KeyboardLayoutId)
        }
    }

    End {
        switch ($OS) {
            '7' {
                $kblRaws | Set-KeyboardLayout-Win7 -CopySettingsToDefaultUserAcct:$CopySettingsToDefaultUserAcct -CopySettingsToSystemAcct:$CopySettingsToSystemAcct
             }
            '10' {
                $KblRaws | Set-KeyboardLayout-Win10 -ClearExist:$ClearExist
            }
            Default {
                Write-Error ('Non supported Operating System')
                $KblRaws | Set-KeyboardLayout-Win10 -ClearExist:$ClearExist
            }
        }
    }
}

function Set-KeyboardLayout-Win7
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='ID')]
        [ValidatePattern('^[0-9a-f]{4}:[0-9a-f\-\{\}]{8,}$')]
        [Alias('Id')]
        [string]$KeyboardLayoutId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='Name')]
        [ValidateScript({$LanguageList.tag -eq $_})]
        [Alias('Tag')]
        [Alias('Language')]
        [string]$LanguageTag,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName='Name')]
        [ValidateScript({$KeyboardList.name -eq $_})]
        [Alias('Name')]
        [string]$KeyboardLayoutName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('add','remove')]
        [string]$Action = 'add',

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$Default = $false,

        [switch]$CopySettingsToDefaultUserAcct,
        [switch]$CopySettingsToSystemAcct
    )

    Begin{
        $KblRaws = @()
    }

    Process{
        if($PSCmdlet.ParameterSetName -eq 'Name'){
            $KeyboardLayoutId = Convert-KblNameToId -LanguageTag $LanguageTag -KeyboardLayoutName $KeyboardLayoutName
        }

        if($KeyboardLayoutId){
            $kblRaws += [pscustomobject]@{
                KeyboardLayoutId = $KeyboardLayoutId
                Action = $Action
                Default = $Default
            }
        }
    }

    End{
        try{
            if($kblRaws.count -le 0){
                Write-Error 'Set keyboard layout failed. invalid arguments'
            }
            $GsXml = [string]($kblRaws | New-GsXml -CopySettingsToDefaultUserAcct:$CopySettingsToDefaultUserAcct -CopySettingsToSystemAcct:$CopySettingsToSystemAcct -ErrorAction Stop).OuterXml
            $tmpFile = New-Item (Join-Path $env:TEMP ('{0}\gstmp.xml' -f [guid]::NewGuid())) -ItemType File -Force -ErrorAction Stop
            $GsXml | Out-File -FilePath $tmpFile -Encoding utf8 -Force
            if(Test-Path $tmpFile){
                $StartTime = [datetime]::Now
                $Process = Start-Command -FilePath 'control.exe' -ArgumentList ('intl.cpl,, /f:"{0}"' -f $tmpFile) -Timeout (300 * 1000)
                $error = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-International/Operational'; StartTime=$StartTime} -MaxEvents 5 -Verbose:$false -ErrorAction SilentlyContinue | where {$_.Level -ne 4} | select -First 1
                ($kblRaws | where {$_.Action -eq 'add'}).KeyboardLayoutId | Set-KeyboardLayoutRegistry
                if($error){
                    Write-Error $error.Message
                }
                else{
                    Write-Verbose 'Set keyboard layout completed successfully'
                }
            }
            else{
                Write-Error 'Set keyboard layout failed. xml not found'
            }
        }
        catch [Exception]{
            Write-Error $_.Exception.Message
        }
        finally{
            if($tmpFile -and (Test-Path $tmpFile.Directory)){
                Remove-Item $tmpFile.Directory -Recurse -Force -ErrorAction Continue
            }
        }
    }
}

function Set-KeyboardLayout-Win10 {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ID')]
        [ValidatePattern('^[0-9a-f]{4}:[0-9a-f\-\{\}]{8,}$')]
        [Alias('Id')]
        [string]$KeyboardLayoutId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Alias('Tag')]
        [Alias('Language')]
        [string]$LanguageTag,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Name')]
        [Alias('Name')]
        [string]$KeyboardLayoutName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('add', 'remove')]
        [string]$Action = 'add',

        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$Default = $false,

        [switch]$ClearExist
    )

    Begin {
        if ($ClearExist) {
            $KblList = New-Object -TypeName 'System.Collections.Generic.List`1[[Microsoft.InternationalSettings.Commands.WinUserLanguage]]'
        }
        else {
            $KblList = Get-WinUserLanguageList
        }
        $DefaultKbl = ''
    }

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            $KeyboardLayoutId = Convert-KblNameToId -LanguageTag $LanguageTag -KeyboardLayoutName $KeyboardLayoutName
        }

        if (-not $LanguageTag) {
            $LanguageTag = Convert-LangIdToTag $KeyboardLayoutId.Substring(0, 4)
        }

        if ($private:LangObj = $KblList.Find( {$args.LanguageTag -eq $LanguageTag})) {
            #既に言語は存在するのでキーボードレイアウトだけを追加or削除する
            switch ($Action) {
                'add' {
                    if ($LangObj.InputMethodTips.FindIndex( {$args -eq $KeyboardLayoutId}) -lt 0) {
                        Write-Verbose ('Installing keyboard layout ({0})' -f $KeyboardLayoutId)
                        $LangObj.InputMethodTips.Add($KeyboardLayoutId)
                    }
                    else{
                        Write-Verbose 'The keyboard layout is already exist.'
                    }
                }
                'remove' {
                    $index = $LangObj.InputMethodTips.FindIndex( {$args -eq $KeyboardLayoutId})
                    if ($index -ge 0) {
                        $LangObj.InputMethodTips.RemoveAt($index)
                    }
                    if ($LangObj.InputMethodTips.Count -eq 0) {
                        #レイアウトを消した結果その言語にレイアウトが一つもなくなった場合、言語自体も消す
                        $index = $KblList.FindIndex( {$args.LanguageTag -eq $LanguageTag})
                        $KblList.RemoveAt($index)
                    }
                }
            }
        }
        else {
            #言語+キーボードレイアウトを追加する(削除は何もする必要なし)
            switch ($Action) {
                'add' {
                    $private:Lang = New-WinUserLanguageList $LanguageTag -ea SilentlyContinue
                    if ((-not $Lang) -or (-not $Lang.EnglishName)) {
                        Write-Error ('"{0}" is not valid LanguageTag' -f $LanguageTag)
                    }
                    else {
                        if ($Lang[0].InputMethodTips.FindIndex( {$args -eq $KeyboardLayoutId}) -lt 0) {
                            Write-Verbose ('Installing keyboard layout ({0})' -f $KeyboardLayoutId)
                            $Lang[0].InputMethodTips.Clear()
                            $Lang[0].InputMethodTips.Add($KeyboardLayoutId)
                        }
                        $KblList.Add($Lang[0])
                    }
                }
                'remove' {
                    # nothing to do
                    Write-Verbose 'The keyboard layout is already removed. Nothing need to do.'
                }
            }
        }

        if ($Default -and ($Action) -eq 'add') {
            $DefaultKbl = $KeyboardLayoutId
        }
    }

    End {
        Set-WinUserLanguageList $KblList -Force
        Write-Verbose ('Keyboard layouts installed successfully')
        if ($DefaultKbl) {
            Write-Verbose ('Set default keyboard layout ({0})' -f $DefaultKbl)
            Set-WinDefaultInputMethodOverride $DefaultKbl
        }
    }
}

<#
.Synopsis
   Get installed keyboard layout
.DESCRIPTION
   Get installed keyboard layout id (KLID)
.PARAMETER Target
   You can select 'CurrentUser' or 'System'
   default: 'CurrentUser'
#>
function Get-KeyboardLayout
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    Param(
        [ValidateSet('CurrentUser','System')]
        [string]$Target = 'CurrentUser'
    )

    $RegKeyLanguage = 'HKCU:\Software\Microsoft\CTF\SortOrder\Language'
    $RegKeyLayout = 'HKCU:\Software\Microsoft\CTF\SortOrder\AssemblyItem'
    $RegKeyIdMap = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts'
    $MysteriousGUID = '{34745C63-B2F0-4784-8B67-5E12C8701A31}'

    if($Target -eq 'CurrentUser'){
        if(-not (Test-Path $RegKeyLanguage)){
            Write-Error 'Registry key not found.'
            return
        }

        $KeyIdMap = @{}
        Get-ChildItem $RegKeyIdMap | Get-ItemProperty | where {$_.'Layout Id'} | % {$KeyIdMap.Add($_.'Layout Id', $_.PsChildName)}

        $RegLangs = Get-Item $RegKeyLanguage
        $InstalledLangsId = $RegLangs.GetValueNames() | sort | foreach {$RegLangs.GetValue($_)}

        $InstalledLayoutId = New-Object 'System.Collections.Generic.List[string]'
        foreach($lang in $InstalledLangsId){
            $private:RegKeyTmp1 = (Join-Path $RegKeyLayout ("0x$lang\$MysteriousGUID"))
            if(Test-Path $RegKeyTmp1){
                $private:counter = 0
                while($true){
                    $private:RegKeyTmp2 = Join-Path $RegKeyTmp1 $counter.ToString("00000000")
                    if(Test-Path $RegKeyTmp2){
                        $private:tmp = (get-item $RegKeyTmp2).GetValue('KeyboardLayout')
                        if($tmp){
                            $private:keyId = $tmp.ToString('X').PadLeft(8, '0').Substring(0,4)
                            # $private:langId = $tmp.ToString('X').PadLeft(8, '0').Substring(4,4)
                            if($keyId -and ($keyId.StartsWith('F'))){
                                $KeyId = ("0{0}" -f $KeyId.Substring(1))
                                $layoutId = $KeyIdMap.$Keyid
                            }
                            else{
                                $layoutId = $keyId.PadLeft(8, '0')
                            }
                            $InstalledLayoutId.Add(('{0}:{1}' -f $lang.Substring(4,4), $layoutId).ToUpper())
                        }
                        elseif($tmp -eq 0){
                            $private:CLSID = (get-item $RegKeyTmp2).GetValue('CLSID')
                            $private:Profile = (get-item $RegKeyTmp2).GetValue('Profile')
                            $InstalledLayoutId.Add(('{0}:{1}{2}' -f $lang.Substring(4,4), $CLSID, $Profile).ToUpper())
                        }
                    }
                    else{
                        break
                    }
                    $counter++
                }
            }
        }
    }
    elseif($Target -eq 'System'){
        $InstalledLayoutId = New-Object 'System.Collections.Generic.List[string]'
        (DISM.exe /Online /Get-Intl /English) | Select-String -SimpleMatch 'Active keyboard(s)' |
            ForEach-Object {
                if($_ -match ':\s*(.*)'){$Matches[1]}
            } | ForEach-Object {
                ($_ -split ',')
            } | ForEach-Object {
                $InstalledLayoutId.Add($_.Trim())
            }
    }

    if(-not $InstalledLayoutId){
        # Write-Error 'Cannot get keyboard layout'
    }
    else{
        $InstalledLayoutId.ToArray()
    }
}

function Get-DefaultKeyboardLayout
{
    [CmdletBinding()]
    Param()

    $private:RegPreload = 'HKCU:\Keyboard Layout\Preload'
    $private:RegSubstitutes = 'HKCU:\Keyboard Layout\Substitutes'
    $private:RegAssemblies = 'HKCU:\Software\Microsoft\CTF\Assemblies'
    $private:MysteriousGUID = '{34745C63-B2F0-4784-8B67-5E12C8701A31}'
    $private:ZeroGUID = '{00000000-0000-0000-0000-000000000000}'

    if(-not ($PreloadId = (Get-ItemProperty $RegPreload).1)){   # $PreloadId = d0010411
        Write-Error "Coudn't get default keyboardLayout"
        return
    }

    # langId equals last 4 chars of Preload value
    $langId = $PreloadId.PadLeft(8, '0').Substring(4,4)   # $langId = 0411

    if($layoutId = (Get-ItemProperty $RegSubstitutes).$PreloadId){  # $layoutId = 0002041e
        # if preload id include in the list of substitutes key, data of substitutes is layoutId
    }
    else{
        $tmpKey = Join-Path $RegAssemblies ("0x{0}\{1}" -f $langId.PadLeft(8, '0'), $MysteriousGUID) # 'HKCU:\Software\Microsoft\CTF\Assemblies\0x00000411\{34745C63-B2F0-4784-8B67-5E12C8701A31}'
        if(-not (Test-Path $tmpKey)){
            Write-Error "Coudn't get default keyboardLayout"
            return
        }
        $defaultGuid = (get-item $tmpKey).GetValue('Default')   # GUID
        $profileGuid = (get-item $tmpKey).GetValue('Profile')   # GUID
        $layoutId = (get-item $tmpKey).GetValue('KeyboardLayout')   # hex 0x04110411
        if($ZeroGuid -eq $defaultGuid){
            # if default = allzero guid => first 4 chars of keyboardLayout value = layoutId
            $layoutId = $layoutId.ToString('X').PadLeft(8, '0').Substring(0,4).PadLeft(8, '0')  # 00000411
        }
        else{
            # layout id = combined default guid & profile guid
            $layoutId = ('{0}{1}' -f $defaultGuid, $profileGuid)    # {4518B9B5-7112-4855-B64F-2EC0DD2831E6}{54EDCC94-1524-4bb1-9FB7-7BABE4F4CA64}
        }
    }
    return ("{0}:{1}" -f $langId,$layoutId)
}

# function Sort-KeyboardLayout {
#     [CmdletBinding()]
#     Param(
#         [Parameter(Mandatory)]
#         [string[]]$KeyboardLayoutIds,

#         [switch]$Force
#     )

#     Begin
#     {
#         $KblCurrent = Get-KeyboardLayout
#         $KblToAdd = @()
#         $kblToRemove = @()
#     }

# }

function Set-KeyboardLayoutRegistry {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidatePattern('^[0-9a-f]{4}:[0-9a-f\-\{\}]{8,}$')]
        [string[]]$KeyboardLayoutIds
    )

    Begin
    {
        # Constant parameters
        $RegKeyAssembly = 'HKCU:\Software\Microsoft\CTF\SortOrder\AssemblyItem'
        $RegKeyLanguage = 'HKCU:\Software\Microsoft\CTF\SortOrder\Language'
        $RegKeyIdMap = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts'
        $MysteriousGUID = '{34745C63-B2F0-4784-8B67-5E12C8701A31}'
        $AllZeroGUID = '{00000000-0000-0000-0000-000000000000}'

        # Registry key initialize (if not yet)
        ($RegKeyAssembly, $RegKeyLanguage) | foreach {
            if(-not (Test-Path $_)){
                New-Item $_ -Force
            }
        }
    }

    Process
    {
        foreach($KeyboardLayoutId in $KeyboardLayoutIds){
            # Split KeyboardLayoutId to LanguageID and LayoutID  e.g) 0411:00000409
            $LangId = $KeyboardLayoutId.Substring(0,4)  # First 4 chars is LanguageID (0411)
            $LayoutId = $KeyboardLayoutId.Substring(5)  # After ':' is LayoutID (00000409)

            # Parse IDs to registry values
            $RegValue_Language = $LangId.PadLeft(8, '0') # Registry value under Language (00000411)
            $RegKey_AssemblyItem = ('0x{0}' -f $RegValue_Language) # Registry key name under AssemblyItem (0x00000411)
            if($LayoutId -match "(\{[0-9a-f\-]{36}\})(\{[0-9a-f\-]{36}\})"){    # PatternA: LayoutID is combined GUIDs style
                $RegValue_CLSID = $Matches[1]   # CLSID is first guid
                $RegValue_KeyboardLayout = 0    # keyboardLayout is 0
                $RegValue_Profile = $Matches[2] # Profile is second guid
            }
            else{   # PatternB: LayoutID is number style
                if($SpecialId = [string](Get-ItemProperty (Join-Path $RegKeyIdMap $LayoutId)).'Layout Id'){
                    $SpecialId = 'F' + $SpecialId.Substring(1)
                    $RegValue_KeyboardLayout = [Convert]::ToInt32(('0x{0}{1}' -f $SpecialId, $LangId), 16)
                }
                else{
                    $RegValue_KeyboardLayout = [Convert]::ToInt32(('0x{0}{1}' -f $LayoutId.Substring(4), $LangId), 16)  # Combine (last 4 digits of LayoutID) and (LangugaeID) then Convert to Int. (0x04090411 => 67699729)
                }
                $RegValue_CLSID = $AllZeroGUID
                $RegValue_Profile = $AllZeroGUID
            }

            # STEP1: Set LanguageID to registry under 'HKCU:\Software\Microsoft\CTF\SortOrder\Language'
                # Check registry value already exists or not
                $LastIndex = 0
                for ($Index = 0; $Index -lt 64; $Index++) { #Max 64 (Prevent Infinite Loop)
                    $LastIndex = $Index
                    $strIndex = ([string]$Index).PadLeft(8, '0')
                    $tmpItem = Get-ItemProperty -Path $RegKeyLanguage
                    if($tmpItem.$strIndex){
                        if($tmpItem.$strIndex -eq $RegValue_Language){
                            $LastIndex = -1 # Reg value is exist
                            break
                        }
                    }
                    else{
                        break
                    }
                }

                # Set registry values
                if($LastIndex -eq -1){
                    Write-Verbose ('Language ID is already exist')
                }
                else{
                    $strIndex = ([string]$LastIndex).PadLeft(8, '0')
                    Write-Verbose ('Setting LanguageID registry in "{0}"' -f $RegKeyLanguage)
                    New-ItemProperty -Path $RegKeyLanguage -Name $strIndex -Value $RegValue_Language -PropertyType 'String' | Out-Null
                }


            # STEP2: Set LayoutID to registry under 'HKCU:\Software\Microsoft\CTF\SortOrder\Language'
                # Check registry set already exist
                $LastIndex = 0
                for ($Index = 0; $Index -lt 64; $Index++) { #Max 64 (Prevent Infinite Loop)
                    $LastIndex = $Index
                    $strIndex = ([string]$Index).PadLeft(8, '0')
                    $tmpPath = ($RegKeyAssembly, $RegKey_AssemblyItem, $MysteriousGUID, $strIndex) -join '\'
                    if(Test-Path $tmpPath){
                        $tmpItem = Get-ItemProperty -Path $tmpPath
                        if($tmpItem.'CLSID' -ne $RegValue_CLSID){
                            Continue
                        }
                        if($tmpItem.'KeyboardLayout' -ne $RegValue_KeyboardLayout){
                            Continue
                        }
                        if($tmpItem.'Profile' -ne $RegValue_Profile){
                            Continue
                        }
                        $LastIndex = -1 # Reg set is exist
                        break
                    }
                    else{
                        break
                    }
                }

                # Set registry key and values
                if($LastIndex -eq -1){
                    Write-Verbose ('LayoutID is already exist')
                }
                else{
                    $strIndex = ([string]$LastIndex).PadLeft(8, '0')
                    $tmpPath = ($RegKeyAssembly, $RegKey_AssemblyItem, $MysteriousGUID, $strIndex) -join '\'
                    if(-not (Test-Path $tmpPath)){
                        Write-Verbose ('Setting LayoutID registry in "{0}"' -f $tmpPath)
                        New-Item $tmpPath -Force | Out-Null
                        New-ItemProperty -Path $tmpPath -Name 'CLSID' -Value $RegValue_CLSID -PropertyType 'String' | Out-Null
                        New-ItemProperty -Path $tmpPath -Name 'KeyboardLayout' -Value $RegValue_KeyboardLayout -PropertyType 'DWord' | Out-Null
                        New-ItemProperty -Path $tmpPath -Name 'Profile' -Value $RegValue_Profile -PropertyType 'String' | Out-Null
                    }
                }
        }

        # End
        Write-Verbose ('Operation completed successfully')
    }
}

function Start-Command {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FilePath,
        [Parameter(Mandatory=$false, Position=1)]
        [string[]]$ArgumentList,
        [int]$Timeout = [int]::MaxValue
    )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $FilePath
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.Arguments = [string]$ArgumentList
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    $Process.Start() | Out-Null
    if(!$Process.WaitForExit($Timeout)){
        $Process.Kill()
        Write-Error ('Process timeout. Terminated. (Timeout:{0}s, Process:{1})' -f ($Timeout * 0.001), $FilePath)
    }
    $Process
}