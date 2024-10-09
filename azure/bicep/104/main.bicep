targetScope = 'subscription'
metadata name = 'Practice AZ104'

@description('Azure Region')
param parLocation string

@description('Location code - region')
param parLocationCode string

@description('Location code - region')
param parEnvironment string

var varModuleName = 'netsandbox'
var varSuffix = '${varModuleName}-${parEnvironment}-${parLocationCode}'
var tags = {
  environment: parEnvironment
  moduleName: varModuleName
}

var varResourceGroupName = 'rg-${varSuffix}'
resource resResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  location: parLocation
  name: 'rg-${varSuffix}'
  tags: tags
}

module modNetworking 'networking.bicep' = {
  name: 'modNetworking-${varSuffix}'
  scope: resourceGroup(varResourceGroupName)
  dependsOn: [
    resResourceGroup
  ]
  params: {
    parLocation: parLocation
    parNameSuffix: varSuffix
    parTags: tags
  }
}

module modCompute 'compute.bicep' = {
  name: 'modCompute-${varSuffix}'
  scope: resourceGroup(varResourceGroupName)
  dependsOn: [
    modNetworking
  ]
  params: {
    parLocation: parLocation
    parNameSuffix: varSuffix
    parTags: tags
  }
}
