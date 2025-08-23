
$resGroupName = "rg-nexus-westeu-dev-02"    

$appgwName = "agw-nexus-westeu-dev-02"

Get-AzApplicationGatewayBackendHealth -Name $appgwName -ResourceGroupName $resGroupName
