$domain =  "domain.local"
# Set $baseOU to a DN if you want to limit the scope. Leave it as "" to use the whole domain
$baseOU = ""
$daysInactive = 90
$daysToDelete = 30
$logFilename = "C:\scripts\log\comps_to_delete.csv"
$deletedFilename = "C:\scripts\log\comps_deleted.csv"

$domainDN = (Get-ADDomain $domain).distinguishedname
$now = Get-Date 
$cutoffDate = $now.Adddays(-($daysInactive)).ToFileTime()
$deleteDate = "{0:yyyy-MM-dd}" -f ($now.Adddays($daysToDelete))
$allOUs = @()
$ResultsList = @()
$DeletedList = @()
$computers = @()

"Domain: $domain"

# Recreate the list of computers in case there have been changes in the exclusions

if ($baseOU -ne "") {
    $computers += get-adcomputer -server $domain -SearchBase $baseOU -Properties Description,pwdLastSet,lastlogondate -Filter * |  Where-Object {($_.Description -like "`* To delete*")}
    "Initial OU: " + $baseOU
} else {
    $computers += get-adcomputer -server $domain -Properties Description,pwdLastSet,lastlogondate -Filter * |  Where-Object {($_.Description -like "`* To delete*")}
    "Scanning full domain: " + $domain
}

    ""
    "-------------------"
    ""

foreach ($comp in $computers) {
    
    $deleteDate = -join $comp.Description[12..21]
  
        $Results = New-Object PSCustomObject
        $Results | Add-Member NoteProperty -Name ComputerName -Value ($comp.Name)
        $Results | Add-Member NoteProperty -Name SamAccountName -Value ($comp.SamAccountName)
        $Results | Add-Member NoteProperty -Name Location -Value (($comp.distinguishedname).Split(",",2)[1])
        $Results | Add-Member NoteProperty -Name LastLogon -Value ($comp.LastLogonDate)
        $Results | Add-Member NoteProperty -Name PasswordLastSet -Value ([datetime]::fromFileTime($comp.pwdLastSet))
        $Results | Add-Member NoteProperty -Name DeleteDate -Value $deleteDate
        $Results | Add-Member NoteProperty -Name Description -Value $comp.Description

    $ResultsList += $Results

}

$ResultsList | export-csv $logFilename -NoTypeInformation -Delimiter "`t"

# Scan for stale computers

$ResultsList = @()

if ($baseOU -ne "") {
    $computers += get-adcomputer -server $domain -SearchBase $baseOU -Properties Description,pwdLastSet,lastlogondate,lastLogonTimestamp -Filter * |  Where-Object {($_.Description -notlike "EXC DEL*") -and (($_.pwdLastSet -lt $cutoffDate) -and ($_.pwdLastSet -notlike "")) -and (($_.lastLogonTimestamp -lt $cutoffDate)-and ($_.lastlogontimestamp -notlike ""))}
} else {
    $computers += get-adcomputer -server $domain -Properties Description,pwdLastSet,lastlogondate,lastLogonTimestamp -Filter * |  Where-Object {($_.Description -notlike "EXC DEL*") -and (($_.pwdLastSet -lt $cutoffDate) -and ($_.pwdLastSet -notlike "")) -and (($_.lastLogonTimestamp -lt $cutoffDate)-and ($_.lastlogontimestamp -notlike ""))}
}

foreach ($comp in $computers) {

    $currentDesc = $comp.Description

    # Determine the action to execute based on the current description
    if (($currentDesc -like "") -or ((-join $currentDesc[0..10]) -ne "* To delete")) {

        $newDesc = "* To delete $deleteDate * " + $currentDesc
        Set-ADComputer $comp.SamAccountName -Description $newDesc

        $Results = New-Object PSCustomObject
        $Results | Add-Member NoteProperty -Name ComputerName -Value ($comp.Name)
        $Results | Add-Member NoteProperty -Name SamAccountName -Value ($comp.SamAccountName)
        $Results | Add-Member NoteProperty -Name Location -Value (($comp.distinguishedname).Split(",",2)[1])
        $Results | Add-Member NoteProperty -Name LastLogon -Value ($comp.LastLogonDate)
        $Results | Add-Member NoteProperty -Name PasswordLastSet -Value ([datetime]::fromFileTime($comp.pwdLastSet))
        $Results | Add-Member NoteProperty -Name DeleteDate -Value $deleteDate
        $Results | Add-Member NoteProperty -Name Description -Value $newDesc

        $ResultsList += $Results

    }

}

if (test-path $logFilename) {
    
    $logComputers = import-csv $logFilename -Delimiter "`t"

    foreach ($comp in $logComputers) {

        $description = $comp.Description
        $computersNames = $computers | Select-Object -ExpandProperty Name

        # Determine the action to execute based on whether it is now active and then if it is time to be deleted

        if ($computersNames -notcontains $comp.ComputerName) {

                # The computer is now active and must be removed from the log

                $newDesc = -join $description[25..$description.Length]
                Set-ADComputer $comp.SamAccountName -Description $newDesc

            } else {

                # The computer is not active and the deletion date is checked

                $checkDate = [datetime]$comp.DeleteDate

                if ($checkDate -gt $now) {

                    #The computer must not be deleted yet

                    $Results = New-Object PSCustomObject
                    $Results | Add-Member NoteProperty -Name ComputerName -Value ($comp.ComputerName)
                    $Results | Add-Member NoteProperty -Name SamAccountName -Value ($comp.SamAccountName)
                    $Results | Add-Member NoteProperty -Name Location -Value ($comp.Location)
                    $Results | Add-Member NoteProperty -Name LastLogon -Value ($comp.LastLogon)
                    $Results | Add-Member NoteProperty -Name PasswordLastSet -Value ($comp.PasswordLastSet)
                    $Results | Add-Member NoteProperty -Name DeleteDate -Value $comp.DeleteDate
                    $Results | Add-Member NoteProperty -Name Description -Value ($comp.Description)

                    $ResultsList += $Results

                } else {

                    # The computer must be deleted

                    Remove-ADObject $comp.SamAccountName
                    $deleteExecutedDate = "{0:yyyy-MM-dd}" -f ($now)

                    $Results = New-Object PSCustomObject
                    $Results | Add-Member NoteProperty -Name ComputerName -Value ($comp.ComputerName)
                    $Results | Add-Member NoteProperty -Name SamAccountName -Value ($comp.SamAccountName)
                    $Results | Add-Member NoteProperty -Name Location -Value ($comp.Location)
                    $Results | Add-Member NoteProperty -Name LastLogon -Value ($comp.LastLogon)
                    $Results | Add-Member NoteProperty -Name PasswordLastSet -Value ($comp.PasswordLastSet)
                    $Results | Add-Member NoteProperty -Name DeletedDate -Value $deleteExecutedDate
                    $Results | Add-Member NoteProperty -Name Description -Value ($comp.Description)

                    $DeletedList += $Results

                }
            }

    }

}

$ResultsList | export-csv $logFilename -NoTypeInformation -Delimiter "`t"
$DeletedList | export-csv $deletedFilename -NoTypeInformation -Delimiter "`t" -Append