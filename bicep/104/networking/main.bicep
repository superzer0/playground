targetScope = 'subscription'
metadata name = 'Networking practice AZ104'

@description('Azure Region')
param parLocation string

@description('Location code - region')
param parLocationCode string

@description('Location code - region')
param parEnvironment string

var varModuleName = 'netsandbox'
var tags = {
  environment: parEnvironment
  moduleName: varModuleName
}

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  location: parLocation
  name: 'rg-${varModuleName}-${parLocationCode}-${parEnvironment}'
  tags: tags
}
