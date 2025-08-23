$domain = "nexus.net"
$resGroupName = "rg-nexus-westeu-dev-02"  
$apimServiceName = "apim-nexus-westeu-dev-02" 

$vnet = Get-AzVirtualNetwork -Name "vnet-nexus-westeu-dev-02" -ResourceGroupName $resGroupName

$apimService = Get-AzApiManagement -ResourceGroupName $resGroupName -Name $apimServiceName

$myZone = New-AzPrivateDnsZone -Name $domain -ResourceGroupName $resGroupName

$link = New-AzPrivateDnsVirtualNetworkLink -ZoneName $domain -ResourceGroupName $resGroupName -Name "mylink" -VirtualNetworkId $vnet.id

$apimIP = $apimService.PrivateIPAddresses[0]

New-AzPrivateDnsRecordSet -Name api -RecordType A -ZoneName $domain -ResourceGroupName $resGroupName -Ttl 3600 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $apimIP)

New-AzPrivateDnsRecordSet -Name portal -RecordType A -ZoneName $domain -ResourceGroupName $resGroupName -Ttl 3600 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $apimIP)

New-AzPrivateDnsRecordSet -Name management -RecordType A -ZoneName $domain -ResourceGroupName $resGroupName -Ttl 3600 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $apimIP)