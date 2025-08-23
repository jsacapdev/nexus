$subscriptionId = "0fbe9ddf-04bf-4b96-bdc6-032844dfaa9c"      
$domain = "nexus.net"                                       
$apimServiceName = "apim-nexus-westeu-dev-02"               
$apimDomainNameLabel = $apimServiceName                     
$apimAdminEmail = "me.dat@nexus.net"                       

$gatewayHostname = "api.$domain"                         
$portalHostname = "portal.$domain"                      
$managementHostname = "management.$domain"               

$baseCertPath = "..\nexus\scripts\certs\"            
$trustedRootCertCerPath = "${baseCertPath}Nexus-Test-Root-CA.cer"   
$gatewayCertPfxPath = "${baseCertPath}api.nexus.net.pfx"            
$portalCertPfxPath = "${baseCertPath}portal.nexus.net.pfx"       
$managementCertPfxPath = "${baseCertPath}management.nexus.net.pfx"  

$resGroupName = "rg-nexus-westeu-dev-02"         
$location = "West Europe"        
$apimOrganization = "Nexus"       
$appgwName = "agw-nexus-westeu-dev-02"

$appGatewayInternalIP = "10.0.0.100"

$appGatewayExternalIP = Get-AzPublicIpAddress `
  -ResourceGroupName $resGroupName `
  -Name "pip-agw-nexus-westeu-dev-02"

# Get the VNet first
$vnet = Get-AzVirtualNetwork -Name "vnet-nexus-westeu-dev-02" -ResourceGroupName $resGroupName

# Then get the subnet from that VNet
$appGatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name "snet-appg-nexus-westeu-dev-02" -VirtualNetwork $vnet

$gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP01" -Subnet $appGatewaySubnet

$fp01 = New-AzApplicationGatewayFrontendPort -Name "port01"  -Port 443

$fipconfig01 = New-AzApplicationGatewayFrontendIPConfig -Name "gateway-public-ip" -PublicIPAddress $appGatewayExternalIP

$fipconfig02 = New-AzApplicationGatewayFrontendIPConfig -Name "gateway-private-ip" -PrivateIPAddress $appGatewayInternalIP -Subnet $vnet.Subnets[0]

$pwd = ConvertTo-SecureString -String "" -AsPlainText -Force

$certGateway = New-AzApplicationGatewaySslCertificate -Name "gatewaycert" -CertificateFile $gatewayCertPfxPath -Password $pwd

$certPortal = New-AzApplicationGatewaySslCertificate -Name "portalcert" -CertificateFile $portalCertPfxPath -Password $pwd

$certManagement = New-AzApplicationGatewaySslCertificate -Name "managementcert" -CertificateFile $managementCertPfxPath -Password $pwd

# Public/external listeners
$gatewayListener = New-AzApplicationGatewayHttpListener -Name "gatewaylistener" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certGateway -HostName $gatewayHostname -RequireServerNameIndication true

$portalListener = New-AzApplicationGatewayHttpListener -Name "portallistener" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certPortal -HostName $portalHostname -RequireServerNameIndication true

$managementListener = New-AzApplicationGatewayHttpListener -Name "managementlistener" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certManagement -HostName $managementHostname -RequireServerNameIndication true

# Private/internal listeners
$gatewayListenerPrivate = New-AzApplicationGatewayHttpListener -Name "gatewaylistener-private" -Protocol "Https" -FrontendIPConfiguration $fipconfig02 -FrontendPort $fp01 -SslCertificate $certGateway -HostName $gatewayHostname -RequireServerNameIndication true

$portalListenerPrivate = New-AzApplicationGatewayHttpListener -Name "portallistener-private" -Protocol "Https" -FrontendIPConfiguration $fipconfig02 -FrontendPort $fp01 -SslCertificate $certPortal -HostName $portalHostname -RequireServerNameIndication true

$managementListenerPrivate = New-AzApplicationGatewayHttpListener -Name "managementlistener-private" -Protocol "Https" -FrontendIPConfiguration $fipconfig02 -FrontendPort $fp01 -SslCertificate $certManagement -HostName $managementHostname -RequireServerNameIndication true

$apimGatewayProbe = New-AzApplicationGatewayProbeConfig -Name "apimgatewayprobe" -Protocol "Https" -HostName $gatewayHostname -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8

$apimPortalProbe = New-AzApplicationGatewayProbeConfig -Name "apimportalprobe" -Protocol "Https" -HostName $portalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8

$apimManagementProbe = New-AzApplicationGatewayProbeConfig -Name "apimmanagementprobe" -Protocol "Https" -HostName $managementHostname -Path "/ServiceStatus" -Interval 60 -Timeout 300 -UnhealthyThreshold 8

$trustedRootCert = New-AzApplicationGatewayTrustedRootCertificate -Name "allowlistcert1" -CertificateFile $trustedRootCertCerPath

$apimPoolGatewaySetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolGatewaySetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimGatewayProbe -TrustedRootCertificate $trustedRootCert -PickHostNameFromBackendAddress -RequestTimeout 180

$apimPoolPortalSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolPortalSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimPortalProbe -TrustedRootCertificate $trustedRootCert -PickHostNameFromBackendAddress -RequestTimeout 180

$apimPoolManagementSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolManagementSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimManagementProbe -TrustedRootCertificate $trustedRootCert -PickHostNameFromBackendAddress -RequestTimeout 180

$apimGatewayBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "gatewaybackend" -BackendFqdns $gatewayHostname

$apimPortalBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "portalbackend" -BackendFqdns $portalHostname

$apimManagementBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "managementbackend" -BackendFqdns $managementHostname

# Public/external gateway rules
$gatewayRule = New-AzApplicationGatewayRequestRoutingRule -Name "gatewayrule" -RuleType Basic -HttpListener $gatewayListener -BackendAddressPool $apimGatewayBackendPool -BackendHttpSettings $apimPoolGatewaySetting -Priority 10

$portalRule = New-AzApplicationGatewayRequestRoutingRule -Name "portalrule" -RuleType Basic -HttpListener $portalListener -BackendAddressPool $apimPortalBackendPool -BackendHttpSettings $apimPoolPortalSetting -Priority 20

$managementRule = New-AzApplicationGatewayRequestRoutingRule -Name "managementrule" -RuleType Basic -HttpListener $managementListener -BackendAddressPool $apimManagementBackendPool -BackendHttpSettings $apimPoolManagementSetting -Priority 30

# Private/internal gateway rules
$gatewayRulePrivate = New-AzApplicationGatewayRequestRoutingRule -Name "gatewayrule-private" -RuleType Basic -HttpListener $gatewayListenerPrivate -BackendAddressPool $apimGatewayBackendPool -BackendHttpSettings $apimPoolGatewaySetting -Priority 11

$portalRulePrivate = New-AzApplicationGatewayRequestRoutingRule -Name "portalrule-private" -RuleType Basic -HttpListener $portalListenerPrivate -BackendAddressPool $apimPortalBackendPool -BackendHttpSettings $apimPoolPortalSetting -Priority 21

$managementRulePrivate = New-AzApplicationGatewayRequestRoutingRule -Name "managementrule-private" -RuleType Basic -HttpListener $managementListenerPrivate -BackendAddressPool $apimManagementBackendPool -BackendHttpSettings $apimPoolManagementSetting -Priority 31

$sku = New-AzApplicationGatewaySku -Name "WAF_v2" -Tier "WAF_v2" -Capacity 1

$config = New-AzApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Detection"

$policy = New-AzApplicationGatewaySslPolicy -PolicyType Predefined -PolicyName AppGwSslPolicy20220101

$appgw = New-AzApplicationGateway -Name $appgwName -ResourceGroupName $resGroupName -Location $location -Sku $sku -SslPolicy $policy -SslCertificates $certGateway, $certPortal, $certManagement -TrustedRootCertificate $trustedRootCert -BackendAddressPools $apimGatewayBackendPool, $apimPortalBackendPool, $apimManagementBackendPool -BackendHttpSettingsCollection $apimPoolGatewaySetting, $apimPoolPortalSetting, $apimPoolManagementSetting -GatewayIpConfigurations $gipconfig -FrontendIpConfigurations $fipconfig01, $fipconfig02 -FrontendPorts $fp01 -HttpListeners $gatewayListener, $portalListener, $managementListener, $gatewayListenerPrivate, $portalListenerPrivate, $managementListenerPrivate -RequestRoutingRules $gatewayRule, $portalRule, $managementRule, $gatewayRulePrivate, $portalRulePrivate, $managementRulePrivate -Probes $apimGatewayProbe, $apimPortalProbe, $apimManagementProbe -WebApplicationFirewallConfig $config

Write-Host "Complete"