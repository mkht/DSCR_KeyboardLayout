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
        cKeyboardLayout KeyboardLayout_Sample
        {
            Ensure = 'Present'
            KeyboardLayout = 'ja-JP:Japanese,ja-JP:Microsoft Office IME 2010'
            Default = 'ja-JP:Microsoft Office IME 2010'
            PsDscRunAsCredential = $Credential
        }
    }
}

KeyboardLayout_Sample -OutputPath $output -ConfigurationData $configuraionData
Start-DscConfiguration -Path $output -Verbose -wait -force

