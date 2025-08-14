param apiManagementName string

param storageAccountName string

var apiName = 'blob-api'

var putOperation = 'put'

var containerName = 'landing'

var formattedServicePolicyValue = format(loadTextContent('policies/servicePolicy.xml'), storageAccount.properties.primaryEndpoints.blob, containerName)

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apiManagementName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageAccountName
}

resource api 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: apiName
  parent: apim
  properties: {
    displayName: 'Blob Storage API'
    subscriptionRequired: true
    path: 'blob-api'

    protocols: [
      'https'
    ]
    isCurrent: true
    description: 'Azure Blob Storage API'
    serviceUrl: '${storageAccount.properties.primaryEndpoints.blob}${containerName}/'
    subscriptionKeyParameterNames: {
      header: 'Subscription-Key-Header-Name'
      query: 'subscription-key-query-param-name'
    }
  }
}

resource operation 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: api
  name: putOperation

  properties: {
    templateParameters: [
      {
        name: 'blobName'
        type: 'string'
     }
    ]
    displayName: '/put/{blobName}'
    description: 'Put the Blob to an Azure Storage Account and Container.'
    method: 'PUT'
    urlTemplate: '/put/{blobName}'
 }
}

resource servicePolicy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  parent: api
  name: 'policy'
  properties: {
    value: formattedServicePolicyValue
    format: 'rawxml'
  }
}

resource operationPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-08-01' = {
  parent: operation
  name: 'policy'
  properties: {
    value: loadTextContent('policies/apiPolicy.xml')
    format: 'rawxml'
  }
}

