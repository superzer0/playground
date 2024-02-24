targetScope = 'resourceGroup'
metadata name = 'Networking AZ104'

@description('Azure Region')
param parLocation string

@description('Naming suffix. Includes env, location code and module name')
param parNameSuffix string

@description('Tags')
param parTags object

var nsgRulesDefault = [ {
    name: 'AllowAllHttp'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'Internet'
      destinationPortRange: '80'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowSsh'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'Internet'
      destinationPortRange: '22'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  } ]

resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-web-${parNameSuffix}'
  location: parLocation
  properties: {
    securityRules: concat(
      nsgRulesDefault, []
    )
  }
}

resource nsgBackend 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-backend-${parNameSuffix}'
  location: parLocation
  properties: {
    securityRules: concat(
      nsgRulesDefault, []
    )
  }
}

resource nsgDB 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-db-${parNameSuffix}'
  location: parLocation
  properties: {
    securityRules: concat(
      nsgRulesDefault, [
        // {
        //   name: 'BlockFromVnet'
        //   properties: {
        //     protocol: 'Tcp'
        //     sourcePortRange: '*'
        //     sourceAddressPrefix: 'VirtualNetwork'
        //     destinationPortRange: '*'
        //     destinationAddressPrefix: 'VirtualNetwork'
        //     access: 'Deny'
        //     priority: 200
        //     direction: 'Inbound'
        //   }
        // }
        // {
        //   name: 'AllowFromBackend'
        //   properties: {
        //     protocol: 'Tcp'
        //     sourcePortRange: '*'
        //     sourceAddressPrefix: cidrSubnet(vNetAddressPrefix, 24, 1)
        //     destinationPortRange: '*'
        //     destinationAddressPrefix: 'VirtualNetwork'
        //     access: 'Deny'
        //     priority: 150
        //     direction: 'Inbound'
        //   }
        // }
      ]
    )
  }
}

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
          networkSecurityGroup: {
            id: nsgWeb.id
          }
        }
      }
      {
        name: 'backend'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 1)
          networkSecurityGroup: {
            id: nsgBackend.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'db'
        properties: {
          addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 2)
          networkSecurityGroup: {
            id: nsgDB.id
          }
        }
      }
    ]
  }
  tags: parTags
}

// resource rtWebViaBackend 'Microsoft.Network/routeTables@2023-09-01' = {
//   name: 'rt-web-via-backend'
//   tags: parTags
//   location: parLocation
//   properties: {
//     routes: [
//       {
//         name: 'fwd-via-backend'
//         properties: {
//           addressPrefix: cidrSubnet(vNetAddressPrefix, 24, 2)
//           nextHopType: 'VirtualAppliance'
//           nextHopIpAddress: cidrHost(cidrSubnet(vNetAddressPrefix, 24, 1), 3)
//         }
//       }
//     ]
//   }
// }

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
          idleTimeoutInMinutes: 4
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
    inboundNatRules: [
      {
        name: 'direct-ssh-web'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', varLbName, varLbFrontendName)
          }
          frontendPort: 2001
          backendPort: 22
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: true
          backendAddressPool: {
            id: resourceId('Microsoft.Network/networkInterfaces/ipConfigurations', 'nic-vm-web-netsandbox-${parNameSuffix}', 'ipconfig1')
          }
        }
      }
      {
        name: 'direct-ssh-backend'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', varLbName, varLbFrontendName)
          }
          frontendPort: 2002
          backendPort: 22
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: true
          backendAddressPool: {
            id: resourceId('Microsoft.Network/networkInterfaces/ipConfigurations', 'nic-vm-backend-netsandbox-${parNameSuffix}', 'ipconfig1')
          }
        }
      }
      {
        name: 'direct-ssh-db'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', varLbName, varLbFrontendName)
          }
          frontendPort: 2003
          backendPort: 22
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: true
          backendAddressPool: {
            id: resourceId('Microsoft.Network/networkInterfaces/ipConfigurations', 'nic-vm-db-netsandbox-${parNameSuffix}', 'ipconfig1')
          }
        }
      }
    ]
    outboundRules: [
      {
        name: 'standard-outbound'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', varLbName, varWebBackendPool)
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', varLbName, varLbFrontendName)
            }
          ]
          protocol: 'All'
          enableTcpReset: true
          idleTimeoutInMinutes: 4
          allocatedOutboundPorts: 32 // only for testing
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
