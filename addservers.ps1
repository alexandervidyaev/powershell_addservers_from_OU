param (
    $arg0, $arg1
)
$domain = "DC=test,DC=local"
$ConnectionBrokerHostname = "broker-01.test.local"
$text = "OU=" +$arg0 + ",$domain"
$Command = Get-ADComputer -SearchBase $text -Filter * -Properties * | Select DNSHostName
get-process ServerManager | stop-process –force
$file = get-item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml"
$xml = [xml] (get-content $file )
copy-item –path $file –destination $file-backup –force


foreach ($Name in $Command) {
    $newserver = @($xml.ServerList.ServerInfo)[0].clone()
    $newserver.name = $Name.DnsHostName
    $newserver.lastUpdateTime = “0001-01-01T00:00:00” 
    $newserver.status = “2”
    $xml.ServerList.AppendChild($newserver)
    #add server to RDS Deployment
    Add-RDServer -Server $newserver.name -Role "RDS-RD-SERVER" -ConnectionBroker $ConnectionBrokerHostname -ErrorAction SilentlyContinue
    }
$xml.Save($file.FullName)
#create session collection
New-RDSessionCollection -CollectionName $arg1 -SessionHost $Command.DnsHostName -CollectionDescription "Example" -ConnectionBroker $ConnectionBrokerHostname
#start-process –filepath $env:SystemRoot\System32\ServerManager.exe –WindowStyle Maximized
