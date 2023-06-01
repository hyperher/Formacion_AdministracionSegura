#set static IP address 
$ipaddress = “192.168.1.238” 
$ipprefix = “24” 
$ipgw = “192.168.1.244” 
$ipdns = “127.0.0.1” 
$ipif = (Get-NetAdapter).ifIndex 
New-NetIPAddress -IPAddress $ipaddress -PrefixLength $ipprefix -InterfaceIndex $ipif -DefaultGateway $ipgw

#rename the computer 
$newname = “DcPing” 
Rename-Computer -NewName $newname –force


Install-windowsfeature -name "Ad-domain-services" -includeallsubfeature -includemanagementtools

Install-windowsfeature -name "dns" -includeallsubfeature -includemanagementtools

Install-ADDSForest -DomainName "dominio.local" -DomainNetBiosName "domain" -InstallDns:$true 