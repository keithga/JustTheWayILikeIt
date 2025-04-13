<#
Create a local user, add to local administrative group, and bind the local user to a microsoft account.

Ideal for non-domain (workgroup) scenarios.

#>




#region Account Support Functions

#######################################

function Add-MicrosoftAccountToUser {
    [cmdletbinding()]
    param( $MicrosoftAccount, $User )

    if ( -not ( Test-Path $env:temp\PSExec.exe ) ) {
        Invoke-WebRequest -Uri 'http://live.sysinternals.com/psexec.exe' -OutFile $env:temp\PSExec.exe
    }

    [scriptBlock]$CommandRun = {

        [cmdletbinding()]
        param( $MicrosoftAccount, $User )

        Start-Transcript -Path "c:\windows\logs\MicrosoftAccount_$($User).log"
        Write-Host "Hello World: $MicrosoftAccount $User"

        $objUser = New-Object System.Security.Principal.NTAccount($User)
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        $c = New-Object 'byte[]' $strsid.BinaryLength
        $strSID.GEtBinaryForm($c,0)

        $FoundUser = $NULL
        foreach ($user in get-childitem "HKLM:\Sam\Sam\Domains\Account\Users") {
            if ( $User.GetValue("V").length -gt 0 ) {
                $v = $User.GetValue("V")
                foreach ( $i in ($v.length-$c.Length)..0)  {
                    if ((compare-object $c $v[$i..($i-1+$c.length)] -sync 0).length -eq 0) {
                        $FoundUSer = $User
                        break
                    }
                }
            }
        }

        if ($FoundUser -is [object]) {
            Write-Verbose "Found USer: $($FoundUSer.PSPAth) now write $MicrosoftAccount"

            if ( $FoundUSer.GetValue("InternetUserName") -isnot [byte[]] ) {
                Set-ItemProperty $FoundUser.PSPath "ForcePasswordReset"   ([byte[]](0,0,0,0))
                Set-ItemProperty $FoundUser.PSPath "InternetUserName"     ([System.Text.Encoding]::UniCode.GetBytes($MicrosoftAccount))
                Set-ItemProperty $FoundUser.PSPath "InternetProviderGUID" ([GUID]("d7f9888f-e3fc-49b0-9ea6-a85b5f392a4f")).TOByteArray()
            }
        }

        Stop-Transcript
    }

    $tempfile = [System.IO.Path]::GetTempFileName() + '.ps1'
    $Prefix + $CommandRun.ToString() | Out-File -Encoding ascii -FilePath $tempFile

    write-verbose " Call: $tempfile -verbose -MicrosoftAccount '$Microsoftaccount' -User '$User'"
    $local:ErrorActionPreference = 'continue'
    & $env:temp\PSExec.exe /AcceptEula -e -i -s Powershell.exe -noprofile -executionpolicy bypass -File $tempfile -verbose -MicrosoftAccount "$Microsoftaccount" -User "$User" 2> out-null

    remove-item $tempFile -force

}

#######################################

#endregion

#region Accounts

$AllUsers = @(

    [pscustomobject] @{ User = 'user1'; MicrosoftAccount = 'User.One@hotmail.com' }
    [pscustomobject] @{ User = 'User2'; MicrosoftAccount = 'USer.two@outlook.com' }

)

write-verbose "userAccounts"

if ( (gwmi Win32_ComputerSystem | ? PartOfDomain -ne 'True' ) -and ( gwmi win32_operatingsystem | Where-Object ProductType -eq 1 ) ) {

    write-host "Create UserAccounts for non-domain joined machines"

    foreach ( $NewAccount in $AllUsers ) {

        Write-Verbose "Create the account: $($NewAccount.User)"
        net.exe user /add $($NewAccount.User) /FullName:"$($NewAccount.User)" /Expires:Never P@ssw0rd
        get-wmiobject -Class Win32_UserAccount -Filter "name='$($NewAccount.User)'"  | swmi -Argument @{PasswordExpires = 0}
        write-host "net.exe localgroup administrators /add $($NewAccount.User)"
        net.exe localgroup administrators /add $($NewAccount.User)

        if ( $isServer -or [string]::IsNullOrEmpty($NewAccount.MicrosoftAccount) ) {
            Write-Host "Enter Password for account $($NewAccount.User) :"
            net.exe user $($NewAccount.User) *
        }
        else {
            Add-MicrosoftAccountToUser -MicrosoftAccount $NewAccount.MicrosoftAccount -User $NewAccount.User
        }
    }

    Write-Verbose "Remove the local Administrator account if on Workstation..."
    if ( ( get-localuser |? SID -notmatch '(500|501|503)$' |? Enabled -EQ $True ) -or $isDomainJoined ) {
        Write-Verbose "There is at least one active account. So..."
        net user administrator /active:no
    }

}

if (gwmi Win32_ComputerSystem | ? PartOfDomain -eq 'True' ) {

    write-verbose "disable Admin account!"
    get-localuser |? SID -match '(500)$' | %{ net user "$($_.Name)" /active:no }

}

#endregion

