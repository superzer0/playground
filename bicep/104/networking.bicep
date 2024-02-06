targetScope = 'resourceGroup'
metadata name = 'Networking AZ104'

@description('Azure Region')
param parLocation string

@description('Naming suffix. Includes env, location code and module name')
param parNameSuffix string

@description('Tags')
param parTags object

var vNetAddressPrefix = '10.0.0.0/18' // 10.0.0.0 - 10.0.63.254
resource vNet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: 'vnet-${parNameSuffix}'
  location: parLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/18' // 10.0.0.0 - 10.0.63.254
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: 'zone00'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 0)
        }
      }
      {
        name: 'zone01'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 1)
        }
      }
      {
        name: 'zone02'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 2)
        }
      }
      {
        name: 'zone03'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 3)
        }
      }
    ]
  }
  tags: parTags
}
