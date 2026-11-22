<#
.SYNOPSIS
    Creates the 6 test users for the IAM lab series in Microsoft Entra ID.
.NOTES
    Auth: delegated (sign in as a lab admin). Scope: User.ReadWrite.All only.
    The temp password is typed at runtime and never stored in this file.
#>

Connect-MgGraph -Scopes "User.ReadWrite.All"

$domain = "jjiamlaboutlook.onmicrosoft.com"
$tempPw = Read-Host "Enter a temporary password for the test users"

$users = @(
    @{F="Ava";  L="Lee";  D="IT";      T="Helpdesk Technician"}
    @{F="Ben";  L="Cruz"; D="Finance"; T="Accountant"}
    @{F="Cara"; L="Diaz"; D="Finance"; T="Finance Manager"}
    @{F="Dan";  L="Moss"; D="HR";      T="HR Specialist"}
    @{F="Eve";  L="Park"; D="IT";      T="Cloud Engineer"}
    @{F="Finn"; L="Ray";  D="Sales";   T="Contractor"}
)

foreach ($u in $users) {
    $nick = "$($u.F).$($u.L)".ToLower()
    New-MgUser -DisplayName "$($u.F) $($u.L)" -GivenName $u.F -Surname $u.L `
        -UserPrincipalName "$nick@$domain" -MailNickname $nick `
        -Department $u.D -JobTitle $u.T -CompanyName "JJ IAM Lab" -UsageLocation "US" -AccountEnabled `
        -PasswordProfile @{ Password = $tempPw; ForceChangePasswordNextSignIn = $true } | Out-Null
    Write-Host "Created $nick@$domain"
}

Disconnect-MgGraph