# check os version
$private:Ver = ([System.Environment]::OSVersion).Version
switch (('{0}.{1}' -f $Ver.Major, $Ver.Minor)) {
    '6.1' { $OS = '7' }    #Win7
    '10.0' { $OS = '10'}  #Win10
    Default { $OS = 'NotSupport'}
}

if($OS -ne '7'){
    Write-Error 'This sample only works on Windows 7'
    return
}

$output = 'C:\dsc'
Import-Module DSCR_KeyboardLayout -Force -ErrorAction Stop

$configuraionData = @{
    AllNodes =
    @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
        },
        @{
            NodeName = "localhost"
            Role = "test"
        }
    )
}

Configuration KeyboardLayout_Sample
{
    param (
        [PSCredential]$Credential = (Get-Credential)
    )
    Import-DscResource -ModuleName DSCR_KeyboardLayout
    Node localhost
    {
        cKeyboardLayout KeyboardLayout_Sample_Win7
        {
            Ensure = 'Present'
            KeyboardLayout = ('ja-JP:Japanese', 'en-US:United States-Dvorak') -join ','
            Default = 'ja-JP:Japanese'
            ClearExist = $true
            PsDscRunAsCredential = $Credential
        }
    }
}

KeyboardLayout_Sample -OutputPath $output -ConfigurationData $configuraionData -ErrorAction Stop
Start-DscConfiguration -Path $output -Verbose -wait -force
Remove-DscConfigurationDocument -Stage Current,Previous,Pending -Force
