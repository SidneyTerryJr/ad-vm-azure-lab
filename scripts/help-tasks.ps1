Reset a User Password
Set-ADAccountPassword -Identity "bob.patel" -Reset -NewPassword (ConvertTo-SecureString "NewPass@2026!" -AsPlainText -Force)
Set-ADUser -Identity "bob.patel" -ChangePasswordAtLogon $true

Unlock a User Account
Unlock-ADAccount -Identity "carol.jones"

Disable a User Account
Disable-ADAccount -Identity "david.smith"

Find Disabled Accounts
Search-ADAccount -AccountDisabled | Select-Object Name, SamAccountName

Find Accounts Inactive for 90 Days
$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter {LastLogonDate -lt $cutoff -and Enabled -eq $true} -Properties LastLogonDate | Select-Object Name, LastLogonDate
