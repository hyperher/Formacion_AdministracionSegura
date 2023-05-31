$results = @()
$users = get-aduser -filter * -Properties lastlogondate,AccountExpirationDate -ErrorAction SilentlyContinue 
foreach ($usr in $users) {
    $user = $usr.SamAccountName

    $lastLogon = $usr.lastlogondate
    if ($lastLogon -eq $null) {
        $lastLogon = "User never logged on"
    } else {
        $lastLogon = $lastLogon.Day.ToString() + "/" + $lastLogon.Month.ToString() + "/" + $lastLogon.Year.ToString()
    }
        
    $expiration = $usr.AccountExpirationDate
    if ($expiration -eq $null) {
        $expiration = "User does not expire"
    } else {
        $expiration = $expiration.Day.ToString() + "/" + $expiration.Month.ToString() + "/" + $expiration.Year.ToString()
    }

    $result = New-Object PSCustomObject
    $result | Add-Member NoteProperty -Name UserName -Value $user
    $result | Add-Member NoteProperty -Name LastLogonDate -Value $lastLogon
    $result | Add-Member NoteProperty -Name ExpirationDate -Value $expiration

    $results += $result
}

$results | Export-Csv C:\temp\userList.txt -NoTypeInformation -Delimiter "`t"