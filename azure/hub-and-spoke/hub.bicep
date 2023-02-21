@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Workload name')
param workloadName string

@description('Firewall policies id')
param fwPoliciesName string = 'afwp-${workloadName}-hub'

@description('Availability zones')
param zones array = [ '1' ]

@description('Azure Tenant Id')
param azureTenantId string 


param tags object = {
  owner: 'OPS'
}

var firewallPrivateIp = '10.224.129.4' // TODO GEt the DNS IP dynamically via bicep or az cli.

// ######### PRIVATE DNS ZONES ########

resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  tags: tags
  location: 'global'
}

resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  tags: tags
  location: 'global'
}

resource storagePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  tags: tags
  location: 'global'
}

resource aksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.westeurope.azmk8s.io'
  tags: tags
  location: 'global'
}

// ######## HUB ########
// Address space 10.224.0.0/12
resource forceFirewallRouteTableGateway 'Microsoft.Network/routeTables@2022-07-01' = {
  name: 'rt-${workloadName}-vpng-westeu'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'Force-Firewall-Route'
        properties: {
          addressPrefix: '10.224.0.0/12'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
          hasBgpOverride: false
        }
      }
    ]
  }
  tags: tags
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${workloadName}-hub'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.224.128.0/20' ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.224.128.0/24'
          routeTable: {
            id: forceFirewallRouteTableGateway.id
          }
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.224.129.0/24'
        }
      }
    ]
  }
}

// ######### FIREWALL ########
resource appClusterFirewallIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-${workloadName}-app'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: zones
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource techClusterFirewallIp 'Microsoft.Network/publicIpAddresses@2022-07-01' = {
  name: 'pip-${workloadName}-tech'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: zones
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource hub_policy 'Microsoft.Network/firewallPolicies@2022-07-01' existing = {
  name: fwPoliciesName
  scope: resourceGroup()
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: 'afw-${workloadName}-hub'
  location: location
  zones: zones
  properties: {
    ipConfigurations: [
      {
        name: appClusterFirewallIp.name
        properties: {
          subnet: {
            id: vnetHub.properties.subnets[1].id
          }
          publicIPAddress: {
            id: appClusterFirewallIp.id
          }
        }
      }
      {
        name: techClusterFirewallIp.name
        properties: {
          publicIPAddress: {
            id: techClusterFirewallIp.id
          }
        }
      }
    ]
    sku: {
      tier: 'Premium'
    }
    firewallPolicy: {
      id: hub_policy.id
    }
  }
  tags: tags
}

// ######### LINKS WITH DNS ###########

// virtual network links
resource sqlPrivateDnsSnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'sql-${uniqueString(resourceGroup().name, subscription().id)}'
  parent: sqlPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource storagePrivateDnsSnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'storage-${uniqueString(resourceGroup().name, subscription().id)}'
  parent: storagePrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource acrPrivateDnsSnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'acr-${uniqueString(resourceGroup().name, subscription().id)}'
  parent: acrPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource aksPrivateDnsSnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'aks-${uniqueString(resourceGroup().name, subscription().id)}'
  parent: aksPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetHub.id
    }
  }
  tags: tags
}

// ######## Point 2 Site Gateway
resource point2SiteGatewayHubIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-p2s-vpng-${workloadName}rope'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
}

// https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-peering-gateway-transit
resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2022-07-01' = {
  name: 'vpng-${workloadName}rope'
  location: location
  properties: {
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
    customRoutes: {
      addressPrefixes: [
        '10.224.32.0/20'
        '10.224.16.0/20'
      ]
    }
    vpnClientConfiguration: {

      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnClientAddressPool: {
        addressPrefixes: [
          '172.16.201.0/24'
        ]
      }
      vpnAuthenticationTypes: [
        'AAD'
      ]
      aadTenant: 'https://login.microsoftonline.com/${azureTenantId}/'
      aadAudience: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
      aadIssuer: 'https://sts.windows.net/${azureTenantId}/'
    }
    gatewayType: 'Vpn'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnetHub.properties.subnets[0].id
          }
          publicIPAddress: {
            id: point2SiteGatewayHubIp.id
          }
        }
      }
    ]

    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    enableBgp: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
  }
  tags: tags
}

