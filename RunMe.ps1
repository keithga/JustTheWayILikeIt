<#
.SYNOPSIS
    Configure a new instance of Windows
.DESCRIPTION
    Configure Windows, Just the way I like it.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

[cmdletbinding()]
param(
    [string] $role
)

write-host "Begin installation of everything for this computer from remote location"

#region Application Installation

#region Chocolatey Apps

Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco.exe GoogleChrome -y --ignore-checksums

if ( $role -ne 'none') {
    choco.exe install 7zip adobereader  notepadplusplus speccy vlc sysinternals -y --ignore-checksums
    choco.exe install DotNet4.5 dotnet-6.0-desktopruntime vcredist140 vcredist2015 -y --ignore-checksums
}

if ( $role -eq 'dev' ) { 
    choco install microsoft-office-deployment --params="'/64bit /Product:O365ProPlusRetail'"

    choco.exe install  streamdeck 1password op yubico-authenticator yubikey-manager gimp -y powershell-core rufus signal zoom rsat --ignore-checksums
    choco.exe install  git github-desktop python ilspy wireshark vscode vscode-codespellchecker vscode-powershell windows-adk-deploy windows-adk-winpe MDT  -y --ignore-checksums
}

#endregion

#region Install other Applications

copy-item -Path "$PSScriptRoot\*" -Destination "c:\windows" -ErrorAction continue

#endregion

#endregion

#region Common Setup

#region Group Policy

if ( gwmi win32_computersystem | Where-Object PartOfDomain -eq $True ) {
    write-host "Update Group Policy [1/2] (may take several minutes)..."
    gpupdate /force | out-string | write-verbose
    write-host "Update Group Policy [2/2] (may take several minutes)..."
    gpupdate /force | out-string | write-verbose
}

#endregion

#region Windows Server Setup

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue

reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutdownReasonOn /t REG_DWORD /d 0x00000000 /f
reg.exe add "HKLM\SOFTWARE\Microsoft\ServerManager" /v DoNotPopWACConsoleAtSMLaunch /t REG_DWORD /d 0x00000001 /f
reg add "hklm\Software\Policies\Microsoft\Internet Explorer\Main" /v DisableFirstRunCustomize /t REG_DWORD /d 0x00000001 /f

# netsh.exe advfirewall firewall set rule name="File and Printer Sharing (SMB-In)" dir=in profile=any new enable=yes

#endregion

#region Photo Viewer

write-verbose "Enable PHoto Viewer"

@"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll]

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell]

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open]
"MuiVerb"="@photoviewer.dll,-3043"

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\command]
@=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
00,5c,00,53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,72,00,75,00,\
6e,00,64,00,6c,00,6c,00,33,00,32,00,2e,00,65,00,78,00,65,00,20,00,22,00,25,\
00,50,00,72,00,6f,00,67,00,72,00,61,00,6d,00,46,00,69,00,6c,00,65,00,73,00,\
25,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,20,00,50,00,68,00,6f,\
00,74,00,6f,00,20,00,56,00,69,00,65,00,77,00,65,00,72,00,5c,00,50,00,68,00,\
6f,00,74,00,6f,00,56,00,69,00,65,00,77,00,65,00,72,00,2e,00,64,00,6c,00,6c,\
00,22,00,2c,00,20,00,49,00,6d,00,61,00,67,00,65,00,56,00,69,00,65,00,77,00,\
5f,00,46,00,75,00,6c,00,6c,00,73,00,63,00,72,00,65,00,65,00,6e,00,20,00,25,\
00,31,00,00,00

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\DropTarget]
"Clsid"="{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}"

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\print]

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\print\command]
@=hex(2):25,00,53,00,79,00,73,00,74,00,65,00,6d,00,52,00,6f,00,6f,00,74,00,25,\
00,5c,00,53,00,79,00,73,00,74,00,65,00,6d,00,33,00,32,00,5c,00,72,00,75,00,\
6e,00,64,00,6c,00,6c,00,33,00,32,00,2e,00,65,00,78,00,65,00,20,00,22,00,25,\
00,50,00,72,00,6f,00,67,00,72,00,61,00,6d,00,46,00,69,00,6c,00,65,00,73,00,\
25,00,5c,00,57,00,69,00,6e,00,64,00,6f,00,77,00,73,00,20,00,50,00,68,00,6f,\
00,74,00,6f,00,20,00,56,00,69,00,65,00,77,00,65,00,72,00,5c,00,50,00,68,00,\
6f,00,74,00,6f,00,56,00,69,00,65,00,77,00,65,00,72,00,2e,00,64,00,6c,00,6c,\
00,22,00,2c,00,20,00,49,00,6d,00,61,00,67,00,65,00,56,00,69,00,65,00,77,00,\
5f,00,46,00,75,00,6c,00,6c,00,73,00,63,00,72,00,65,00,65,00,6e,00,20,00,25,\
00,31,00,00,00

[HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\print\DropTarget]
"Clsid"="{60fd46de-f830-4894-a628-6fa81bc0190d}"

"@ | out-file -FilePath $env:temp\PhotoViewer.reg -Encoding ascii
reg.exe import $env:temp\PhotoViewer.reg
remove-item $env:temp\PhotoViewer.reg


#endregion

#region Remote Desktop (Non Domain Joined)

if (gwmi Win32_ComputerSystem | ? PartOfDomain -ne'True') {

    set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
    set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fSingleSessionPerUser" -Value 1
    netsh.exe advfirewall firewall set rule group="remote desktop" new enable=Yes
    
    get-netconnectionprofile |
        Where-Object NetworkCategory -eq public |
        get-netadapter |
        Where-Object  NDisphysicalMedium -in 0,14 |
        Set-NetConnectionProfile -NetworkCategory Private
    
    Enable-PSRemoting -force
    Set-Item wsman:localhost\client\trustedhosts -Value * -force
    winrm  quickconfig -transport:HTTP -force

}

#endregion

#endregion

#region Common Cleanup

#region Clean Desktop

Get-ChildITem -path ([Environment]::getfolderpath("CommonDesktop")) -Filter "*.lnk" | %{ Remove-Item $_.FullName }
Get-ChildITem -path ([Environment]::getfolderpath("CommonDesktop")) -Filter "desktop.ini" | %{ Remove-Item $_.FullName }
Get-ChildITem -path ([Environment]::getfolderpath("Desktop")) -Filter "desktop.ini" | %{ Remove-Item $_.FullName }

attrib.exe +h c:\PerfLogs
attrib.exe +h c:\Intel

#endregion 

#endregion
