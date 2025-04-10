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

Start-Transcript -OutputDirectory $env:TEMP

write-host "Begin installation of everything for this computer from remote location"

Stop-Transcript


