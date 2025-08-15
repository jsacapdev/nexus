param deploymentLocation string

param secondaryDeploymentLocation string

param deploymentEnvironment string

param serviceBusNamespaceName string

var tags = union(loadJsonContent('../tags.json'), {
  Environment: deploymentEnvironment
})

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2025-05-01-preview' = {
  name: serviceBusNamespaceName
  tags: tags
  location: deploymentLocation
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 1
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    geoDataReplication: {
      maxReplicationLagDurationInSeconds: 300
      locations: [
        {
          locationName: deploymentLocation
          roleType: 'Primary'
        }
        {
          locationName: secondaryDeploymentLocation
          roleType: 'Secondary'
        }
      ]
    }
  }
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2025-05-01-preview' = {
  parent: serviceBusNamespace
  name: 'nexus001'
  properties: {
    defaultMessageTimeToLive: 'P14D' 
    enableBatchedOperations: true
    enablePartitioning: false
    
  }
}

resource serviceBusSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2025-05-01-preview' = {
  name: 'sub001'
  parent: serviceBusTopic
  properties: {
    maxDeliveryCount: 10    
    defaultMessageTimeToLive: 'P7D' // Messages live for 7 days in subscription
  }
}
