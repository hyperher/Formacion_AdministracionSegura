Install-windowsfeature -name "Ad-domain-services" -includeallsubeature -includemanagementtools

Install-windowsfeature -name "dns" -includeallsubeature -includemanagementtools

Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "dominio.local" `
-DomainNetbiosName "DOMINIO" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true