@minLength(3)
@maxLength(11)
param storagePrefix string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageSKU string = 'Standard_LRS'
param location string = resourceGroup().location

var uniqueStorageName = '${storagePrefix}${uniqueString(resourceGroup().id)}'

resource stg 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: uniqueStorageName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
  resource blob 'blobServices@2022-05-01' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        enabled: false
      }
      automaticSnapshotPolicyEnabled: false
      isVersioningEnabled: false
    }
  }
}

resource storageAccounts 'Microsoft.Storage/storageAccounts@2022-05-01' = [for i in range(0, 3): {
  name: '${i}storage${uniqueString(resourceGroup().id)}'
  location: location
  sku:{
    name: 'Standard_LRS'

  }
  kind: 'BlobStorage'
  properties: {
    accessTier: 'Cool'
  }
}]

output storageEndpoint object = stg.properties.primaryEndpoints
