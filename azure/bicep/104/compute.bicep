@description('Azure Region')
param parLocation string

@description('Naming suffix. Includes env, location code and module name')
param parNameSuffix string

@description('Tags')
param parTags object

var varPublicSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDq0/qSuGXiep5Q/GPnc1kx8lCmqh3lU9TSYKxcXBEt+m0bSzVb4KF/BSI/xvkYuZX19ALvVXnLpWm2RvFJZ/Z8L0q+8Uo0GRy9Dzed+te69oGOVgfJO7C78t5dbsBDrptycanuHqFg2G6JZTF1tLXq6j5arMIiUHahXk7fZSFSqm53L32/aCqRP3UslShjJJ5hdp8tk06Ua4EHQbWGwstVJRfKx+ro1OcrZeNGlcvaE3ytMG5VkoJeRcjcEfQ0P7/z1qLT1sKwzBCY13GFRbgXnECgN+RZ0fYEzSE9oqPbEKQCtkgJq+43mzDEDGr9YnhICKhb7p94Vrki3QDSr1QO+8LFllEP2P18waFPqUhEynmnKq0Wvq5akKRaBASwsFnTsEHXTf5U3CrV0f2s9/eyVJ0qoVNBrmhyGA7/r5HlILd8Siqh1XGjWTvrAUmgbN5WhpUk5ntIV7cMnvIpAtUVi/tlmLALVJyICr6GX9vYcTnJ3lkbeIAFAnfJd5B2Ktk= generated-by-azure'
var varVnetName = 'vnet-${parNameSuffix}'
var vmsToCreate = [
  {
    name: 'web'
    cloudInit: loadFileAsBase64('cloud-init/web.txt')
  }, {
    name: 'backend'
    cloudInit: loadFileAsBase64('cloud-init/backend.txt')
  }, {
    name: 'db'
    cloudInit: loadFileAsBase64('cloud-init/db.txt')
  } ]

var varLbName = 'lb-${parNameSuffix}'

module modVMs 'vm.bicep' = [for vmProperties in vmsToCreate: {
  name: 'modVm-${vmProperties.name}-${parNameSuffix}'
  params: {
    adminPublicKey: varPublicSshKey
    parLocation: parLocation
    parNameSuffix: parNameSuffix
    parTags: parTags
    parVnetName: varVnetName
    parSubnetName: vmProperties.name
    parVmIdentifier: vmProperties.name
    cloudInitContent: vmProperties.cloudInit
    parLbName: varLbName
    parLbPoolName: 'common-pool'
  }
}]

resource vnetRef 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: varVnetName
}

resource subnetBackendRef 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' existing = {
  name: 'backend'
  parent: vnetRef
}

var varSaBackendName = 'sanetsandbboxjkasdc'
resource saBackend 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: varSaBackendName
  location: parLocation
  tags: parTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    accessTier: 'Cool'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnetBackendRef.id
          action: 'Allow'
        }
      ]
    }
  }
}

// this needs to be linked to the subnet with az cli/powershell.
resource sepBackend 'Microsoft.Network/serviceEndpointPolicies@2023-09-01' = {
  name: 'sep-vnet-backend-${parNameSuffix}'
  location: parLocation
  properties: {
    serviceEndpointPolicyDefinitions: [
      {
        name: 'sep-def-${varSaBackendName}'
        properties: {
          service: 'Microsoft.Storage'
          serviceResources: [
            saBackend.id
          ]
          description: 'Storage service endpoint policy from "backend" subnet to ${varSaBackendName}'
        }
      }
    ]
  }
}
