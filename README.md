DSCR_KeyboardLayout
====

PowerShell functions & DSC Resource to add / remove Keyboard Layout (Input Locales).

## System Requirements
This module only supported Windows 7 & Windows 10

## Install
You can install Resource through [PowerShell Gallery](https://www.powershellgallery.com/packages/DSCR_KeyboardLayout/).
```Powershell
Install-Module -Name DSCR_KeyboardLayout
```

## Resources
* **cKeyboardLayout**
PowerShell DSC Resource add / remove Keyboard Layouts.

## Properties
### cKeyboardLayout
+ [string] **Ensure** (Write):
    + Specify installation state of the keyboad layouts.
    + The default value is `Present`. (`Present` or  `Absent`)

+ [string] **KeyboardLayout** (Key):
    + The input profiles are made up of a "language identifier" and a "keyboard identifier".
    + For details and list of IDs, see [the documents of Microsoft](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-input-locales-for-windows-language-packs)
    + You can specify not only ID, but also firendly name of profile. For example, you can specify `"fr-FR:French"` instead of `"040c:0000040c"`.
    + If you want to specify multiple layouts, separate them with a comma.

+ [string] **Default** (Write):
    + Specify a keyboard layout that will set to user's default layout.

+ [boolean] **ClearExist** (Write):
    + If you specify this property to `$true`, all existing keyboard layout will be removed.
    + The default value is `$false`.

+ [boolean] **CopySettingsToSystemAcct** (Write):
    + Set up not only for users but also for system accounts.
    + **[IMPORTANT]** This property is only on Windows 7.

+ [boolean] **CopySettingsToDefaultUserAcct** (Write):
    + Set up not only for users but also for default user account.
    + **[IMPORTANT]** This property is only on Windows 7.

## Examples
+ **Example 1**: Install french keyboard layout
```Powershell
Configuration Example1
{
    Import-DscResource -ModuleName DSCR_KeyboardLayout
    cKeyboardLayout KeyboardLayout_Sample
    {
        KeyboardLayout = 'fr-FR:French'
        PsDscRunAsCredential = $UserCredential
    }
}
```

+ **Example 2**: Clear existing layout & Add multiple layouts
```Powershell
Configuration Example2
{
    Import-DscResource -ModuleName DSCR_KeyboardLayout
    cKeyboardLayout KeyboardLayout_Sample
    {
        KeyboardLayout = 'ja:Microsoft IME (Japanese),en-US:United States-Dvorak,zh-Hant-TW:Microsoft Changjie'
        Default = 'ja:Microsoft IME (Japanese)'
        ClearExist = $true
        PsDscRunAsCredential = $UserCredential
    }
}
```

## ChangeLog
### 2.1.2
+ Fix minor issue in module manifest

### 2.1.0
+ Windows 10 support
+ Bug fix