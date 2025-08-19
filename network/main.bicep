targetScope = 'subscription'

param deploymentLocation string

param deploymentEnvironment string

param resourceGroupName string

param virtualNetworkName string

param internalApimSubnetName string

var tags = union(loadJsonContent('./tags.json'), {
  Environment: deploymentEnvironment
})

module resourceGroup 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: '${uniqueString(deployment().name, deploymentLocation)}-resourceGroup'
  params: {
    name: resourceGroupName
    location: deploymentLocation
    tags: tags
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'vnet'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    addressPrefixes: [
      '10.0.0.0/16' 
    ]
    name: virtualNetworkName
    subnets: [
      {
        addressPrefix: '10.0.1.0/24' 
        name: internalApimSubnetName
      }
    ]
    tags: tags
  }
  dependsOn: [
    resourceGroup
  ]
}
