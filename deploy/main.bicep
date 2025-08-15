targetScope = 'subscription'

param deploymentLocation string

param secondaryDeploymentLocation string

param deploymentEnvironment string

param resourceGroupName string

param serviceBusNamespaceName string

param apiManagementName string

param storageAccountName string

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

module serviceBusNamespace './modules/servicebus.bicep' = {
  name: serviceBusNamespaceName
  scope: az.resourceGroup(resourceGroupName)
  params: {
    deploymentLocation: deploymentLocation
    secondaryDeploymentLocation: secondaryDeploymentLocation
    deploymentEnvironment: 'dev'
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module apim 'br/public:avm/res/api-management/service:0.6.0' = {
  name: 'apim'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    name: apiManagementName
    publisherEmail: 'some.jo@mail.com'
    publisherName: 'some.jo'
    location: deploymentLocation
    sku: 'Developer'
    managedIdentities: {
      systemAssigned: true
    }
  }
  dependsOn: [
    resourceGroup
  ]
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.9.0' = {
  name: 'storageAccount'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    tags: tags
    name: storageAccountName
    kind: 'BlobStorage'
    allowBlobPublicAccess: true
    location: deploymentLocation
    skuName: 'Standard_LRS'
    blobServices: {
      containers: [
        {
          name: 'landing'
        }
      ]
      deleteRetentionPolicyEnabled: false
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
  dependsOn: [
    resourceGroup
  ]
}
