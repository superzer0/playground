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
        name: 'web'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 0)
        }
      }
      {
        name: 'backend'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 1)
        }
      }
      {
        name: 'db'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 2)
        }
      }
    ]
  }
  tags: parTags
}

var varPipLbName = 'pip-lb-${parNameSuffix}'
resource lbPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-lb-${parNameSuffix}'
  location: parLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  tags: parTags
  properties: {
    dnsSettings: {
      domainNameLabel: varPipLbName
    }
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

var varLbName = 'lb-${parNameSuffix}'
var varLbFrontendName = 'lb-frontend'
var varWebBackendPool = 'common-pool'
var varWebBackendPoolProbe = 'common-pool-probe'
resource publicLb 'Microsoft.Network/loadBalancers@2023-09-01' = {
  name: varLbName
  location: parLocation
  tags: parTags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: varLbFrontendName
        properties: {
          publicIPAddress: {
            id: lbPip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: varWebBackendPool
      }
    ]
    loadBalancingRules: [
      {
        name: 'web-balancing-rule'
        properties: {
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 15
          protocol: 'Tcp'
          enableTcpReset: true
          loadDistribution: 'Default'
          disableOutboundSnat: true
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', varLbName, varLbFrontendName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', varLbName, varWebBackendPool)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', varLbName, varWebBackendPoolProbe)
          }
        }
      }
    ]
    probes: [
      {
        name: varWebBackendPoolProbe
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}
