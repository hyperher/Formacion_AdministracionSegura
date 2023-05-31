$Location = "DC=Domain,DC=net"
$outfile = "c:\temp\testfile.txt"

$Results = "Name;Operating System;Description"
$Results | Out-File -FilePath $outfile -Force

$computers=get-adcomputer -Filter * -SearchBase $Location -Properties Description,OperatingSystem

foreach ($computer in $computers){
    $BitLockerObjects = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $computer.DistinguishedName -Properties 'msFVE-RecoveryPassword' 
    if ($BitLockerObjects -ne $null) {
        $Results = $computer.name + ";" + $computer.description + ";" + $computer.operatingsystem
        $Results | Out-File -FilePath $outfile -Append
    }
}