# These variables must be changed.
# $subscriptionId = "aaaa0a0a-bb1b-cc2c-dd3d-eeeeee4e4e4e"      # GUID of your Azure subscription
$domain = "nexus.net"                                       # The custom domain for your certificate
$apimServiceName = "apim-nexus-westeu-dev-02"                             # API Management service instance name, must be globally unique    
$apimDomainNameLabel = $apimServiceName                       # Domain name label for API Management's public IP address, must be globally unique
$apimAdminEmail = "me.dat@nexus.net"                         # Administrator's email address - use your email address

$gatewayHostname = "api.$domain"                              # API gateway host
$portalHostname = "portal.$domain"                            # API developer portal host
$managementHostname = "management.$domain"                    # API management endpoint host

$baseCertPath = "..\nexus\scripts\certs\"                           # The base path where all certificates are stored
$trustedRootCertCerPath = "${baseCertPath}Nexus-Test-Root-CA.cer"    # Full path to contoso.net trusted root .cer file
$gatewayCertPfxPath = "${baseCertPath}api.nexus.net.pfx"            # Full path to api.contoso.net .pfx file
$portalCertPfxPath = "${baseCertPath}portal.nexus.net.pfx"              # Full path to portal.contoso.net .pfx file
$managementCertPfxPath = "${baseCertPath}management.nexus.net.pfx"      # Full path to management.contoso.net .pfx file

$gatewayCertPfxPassword = ""            # Password for api.contoso.net pfx certificate
$portalCertPfxPassword = ""             # Password for portal.contoso.net pfx certificate
$managementCertPfxPassword = ""         # Password for management.contoso.net pfx certificate

# These variables may be changed.
$resGroupName = "rg-nexus-westeu-dev-02"                                 # Resource group name that will hold all assets
$location = "West Europe"                                         # Azure region that will hold all assets
$apimOrganization = "Nexus"                                 # Organization name    
# $appgwName = "agw-contoso"                                    # The name of the Application Gateway

New-AzResourceGroup -Name $resGroupName -Location $location -Force

# public ip for application gateway
$appGatewayExternalIP = New-AzPublicIpAddress `
-ResourceGroupName $resGroupName `
-name "pip-agw-nexus-westeu-dev-02" `
-location $location `
-AllocationMethod Static `
-Sku Standard -Force

$appGatewayInternalIP = "10.0.0.100"

[String[]]$appGwNsgDestIPs = $appGatewayInternalIP, $appGatewayExternalIP.IpAddress

# various nsg rules for the application gateway subnet
$appGwRule1 = New-AzNetworkSecurityRuleConfig -Name appgw-in -Description "AppGw inbound" -Access Allow -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix GatewayManager -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 65200-65535

$appGwRule2 = New-AzNetworkSecurityRuleConfig -Name appgw-in-internet -Description "AppGw inbound Internet" -Access Allow -Protocol "TCP" -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix $appGwNsgDestIPs -DestinationPortRange 443

# the nsg for application gateway using the rules just created
$appGwNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resGroupName -Location $location -Name "nsg-agw-nexus-westeu-dev-02" -SecurityRules $appGwRule1, $appGwRule2 -Force

# various nsg rules for the api management subnet
$apimRule1 = New-AzNetworkSecurityRuleConfig -Name APIM-Management -Description "APIM inbound" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix ApiManagement -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 3443

$apimRule2 = New-AzNetworkSecurityRuleConfig -Name AllowAppGatewayToAPIM -Description "Allows inbound App Gateway traffic to APIM" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix "10.0.0.0/24" -SourcePortRange * -DestinationAddressPrefix "10.0.1.0/24" -DestinationPortRange 443

$apimRule3 = New-AzNetworkSecurityRuleConfig -Name AllowAzureLoadBalancer -Description "Allows inbound Azure Infrastructure Load Balancer traffic to APIM" -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 -SourceAddressPrefix AzureLoadBalancer -SourcePortRange * -DestinationAddressPrefix "10.0.1.0/24" -DestinationPortRange 6390

$apimRule4 = New-AzNetworkSecurityRuleConfig -Name AllowKeyVault -Description "Allows outbound traffic to Azure Key Vault" -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix "10.0.1.0/24" -SourcePortRange * -DestinationAddressPrefix AzureKeyVault -DestinationPortRange 443

# the nsg for the api management using the rules just created
$apimNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resGroupName -Location $location -Name "nsg-apim-nexus-westeu-dev-02" -SecurityRules $apimRule1, $apimRule2, $apimRule3, $apimRule4 -Force

# the app gateway subnet
$appGatewaySubnet = New-AzVirtualNetworkSubnetConfig -Name "snet-appg-nexus-westeu-dev-02" -NetworkSecurityGroup $appGwNsg -AddressPrefix "10.0.0.0/24"

# the apim subnet
$apimSubnet = New-AzVirtualNetworkSubnetConfig -Name "snet-apim-nexus-westeu-dev-02" -NetworkSecurityGroup $apimNsg -AddressPrefix "10.0.1.0/24"

# the apim subnet
$vmSubnet = New-AzVirtualNetworkSubnetConfig -Name "snet-vm-nexus-westeu-dev-03" -AddressPrefix "10.0.2.0/24"

# the vnet with the app gateway and apim subnets
$vnet = New-AzVirtualNetwork -Name "vnet-nexus-westeu-dev-02" -ResourceGroupName $resGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $appGatewaySubnet,$apimSubnet,$vmSubnet -Force

$appGatewaySubnetData = $vnet.Subnets[0]
$apimSubnetData = $vnet.Subnets[1]

# a public ip for apim?!!! i thought apim was not publicly available...
$apimPublicIpAddressId = New-AzPublicIpAddress -ResourceGroupName $resGroupName -name "pip-apim-nexus-westeu-dev-02" -location $location -AllocationMethod Static -Sku Standard -Force -DomainNameLabel $apimDomainNameLabel

# an apim vnet object? eh? whats that when its at home...
$apimVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $apimSubnetData.Id

# create apim!!!
# $apimService = New-AzApiManagement -ResourceGroupName $resGroupName -Location $location -Name $apimServiceName -Organization $apimOrganization -AdminEmail $apimAdminEmail -VirtualNetwork $apimVirtualNetwork -VpnType "Internal" -Sku "Developer" -PublicIpAddressId $apimPublicIpAddressId.Id

$apimService = Get-AzApiManagement -ResourceGroupName $resGroupName -Name $apimServiceName

$certGatewayPwd = ConvertTo-SecureString -String $gatewayCertPfxPassword -AsPlainText -Force
$certPortalPwd = ConvertTo-SecureString -String $portalCertPfxPassword -AsPlainText -Force
$certManagementPwd = ConvertTo-SecureString -String $managementCertPfxPassword -AsPlainText -Force

$gatewayHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $gatewayHostname -HostnameType Proxy -PfxPath $gatewayCertPfxPath -PfxPassword $certGatewayPwd

$portalHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $portalHostname -HostnameType DeveloperPortal -PfxPath $portalCertPfxPath -PfxPassword $certPortalPwd

$managementHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $managementHostname -HostnameType Management -PfxPath $managementCertPfxPath -PfxPassword $certManagementPwd

$apimService.ProxyCustomHostnameConfiguration = $gatewayHostnameConfig
$apimService.PortalCustomHostnameConfiguration = $portalHostnameConfig
$apimService.ManagementCustomHostnameConfiguration = $managementHostnameConfig

Set-AzApiManagement -InputObject $apimService

Write-Host "Complete"
