# These variables must be changed.
# $subscriptionId = "aaaa0a0a-bb1b-cc2c-dd3d-eeeeee4e4e4e"      # GUID of your Azure subscription
# $domain = "contoso.net"                                       # The custom domain for your certificate
# $apimServiceName = "apim-contoso"                             # API Management service instance name, must be globally unique    
# $apimDomainNameLabel = $apimServiceName                       # Domain name label for API Management's public IP address, must be globally unique
# $apimAdminEmail = "admin@contoso.net"                         # Administrator's email address - use your email address

# $gatewayHostname = "api.$domain"                              # API gateway host
# $portalHostname = "portal.$domain"                            # API developer portal host
# $managementHostname = "management.$domain"                    # API management endpoint host

# $baseCertPath = "C:\Users\Contoso\"                           # The base path where all certificates are stored
# $trustedRootCertCerPath = "${baseCertPath}trustedroot.cer"    # Full path to contoso.net trusted root .cer file
# $gatewayCertPfxPath = "${baseCertPath}gateway.pfx"            # Full path to api.contoso.net .pfx file
# $portalCertPfxPath = "${baseCertPath}portal.pfx"              # Full path to portal.contoso.net .pfx file
# $managementCertPfxPath = "${baseCertPath}management.pfx"      # Full path to management.contoso.net .pfx file

# $gatewayCertPfxPassword = "certificatePassword123"            # Password for api.contoso.net pfx certificate
# $portalCertPfxPassword = "certificatePassword123"             # Password for portal.contoso.net pfx certificate
# $managementCertPfxPassword = "certificatePassword123"         # Password for management.contoso.net pfx certificate

# These variables may be changed.
$resGroupName = "rg-nexus-westeu-dev-02"                                 # Resource group name that will hold all assets
$location = "West Europe"                                         # Azure region that will hold all assets
# $apimOrganization = "Contoso"                                 # Organization name    
# $appgwName = "agw-contoso"                                    # The name of the Application Gateway

New-AzResourceGroup -Name $resGroupName -Location $location -Force

$appGatewayExternalIP = New-AzPublicIpAddress `
-ResourceGroupName $resGroupName `
-name "pip-ag-nexus-westeu-dev-02" `
-location $location `
-AllocationMethod Static `
-Sku Standard -Force

$appGatewayInternalIP = "10.0.0.100"

[String[]]$appGwNsgDestIPs = $appGatewayInternalIP, $appGatewayExternalIP.IpAddress

$appGwRule1 = New-AzNetworkSecurityRuleConfig -Name appgw-in -Description "AppGw inbound" -Access Allow -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix GatewayManager -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 65200-65535

$appGwRule2 = New-AzNetworkSecurityRuleConfig -Name appgw-in-internet -Description "AppGw inbound Internet" -Access Allow -Protocol "TCP" -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix $appGwNsgDestIPs -DestinationPortRange 443

$appGwNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resGroupName -Location $location -Name "nsg-agw" -SecurityRules $appGwRule1, $appGwRule2

Write-Host "Complete"
