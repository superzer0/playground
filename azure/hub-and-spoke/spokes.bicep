@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Workload name')
param workloadName string

@description('Firewall private IP')
param firewallPrivateIp string = '10.224.129.4'

@description('Virtual network hub name')
param vnetHubName string = 'vnet-${workloadName}-hub'

param tags object = {
  owner: 'OPS'
}

// Address space 10.224.0.0/12

resource vnetHub 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetHubName
  scope: resourceGroup()
}

resource forceFirewallRouteTable 'Microsoft.Network/routeTables@2022-07-01' = {
  name: 'rt-${workloadName}-force-hub'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'Force-Firewall-Route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
          hasBgpOverride: false
        }
      }
    ]
  }
  tags: tags
}

resource routeInternalTrafficViaFirewallRouteTable 'Microsoft.Network/routeTables@2022-07-01' = {
  name: 'rt-${workloadName}-route-hub'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'Internal-Firewall-Route'
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

resource vnetApp 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${workloadName}-app'
  location: location
  tags: tags
  properties: {
    dhcpOptions: {
      dnsServers: [
        firewallPrivateIp
      ]
    }
    addressSpace: {
      addressPrefixes: [ '10.224.32.0/20' ]
    }
    subnets: [
      {
        name: 'ApplicationSubnet'
        properties: {
          addressPrefix: '10.224.32.0/21'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: forceFirewallRouteTable.id
          }
        }
      }
    ]
  }
}

resource vnetTech 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${workloadName}-tech'
  location: location
  tags: tags
  properties: {
    dhcpOptions: {
      dnsServers: [
        firewallPrivateIp
      ]
    }
    addressSpace: {
      addressPrefixes: [ '10.224.16.0/20' ]
    }
    subnets: [
      {
        name: 'ApplicationSubnet'
        properties: {
          addressPrefix: '10.224.16.0/21'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: forceFirewallRouteTable.id
          }
        }
      }
    ]
  }
}

resource vnetAppGateway 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${workloadName}-appgateway'
  location: location
  tags: tags
  properties: {
    dhcpOptions: {
      dnsServers: [
        firewallPrivateIp
      ]
    }
    addressSpace: {
      addressPrefixes: [ '10.224.112.0/20' ]
    }
    subnets: [
      {
        name: 'AppGateway'
        properties: {
          addressPrefix: '10.224.112.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: routeInternalTrafficViaFirewallRouteTable.id
          }
        }
      }
    ]
  }
}

// ######### PEERINGS ########

resource vnetAppToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-${vnetApp.name}-${vnetHub.name}'
  parent: vnetApp
  properties: {
    allowVirtualNetworkAccess: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource vnetHubToApp 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-${vnetHub.name}-${vnetApp.name}'
  parent: vnetHub
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetApp.id
    }
  }
}

resource vnetTechToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-${vnetTech.name}-${vnetHub.name}'
  parent: vnetTech
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource vnetHubToTech 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-${vnetHub.name}-${vnetTech.name}'
  parent: vnetHub
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetTech.id
    }
  }
}

resource vnetAppGatewayToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-${vnetAppGateway.name}-${vnetHub.name}'
  parent: vnetAppGateway
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource vnetHubToAppGateway 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: 'peer-${vnetHub.name}-${vnetAppGateway.name}'
  parent: vnetHub
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetTech.id
    }
  }
}
