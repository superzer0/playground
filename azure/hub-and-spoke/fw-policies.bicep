@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Workload name')
param workloadName string

var tags = {
  owner: 'OPS'
}

resource hub_policy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: 'afwp-${workloadName}-hub-standard'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Standard'
    }
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource vpnCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-07-01' = {
  parent: hub_policy
  name: 'VPN'
  properties: {
    priority: 500
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'VPN-Traffic'
        priority: 501
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'Allow-P2S-VPN-Client'
            ruleType: 'NetworkRule'
            description: 'Allow VPN traffic'
            ipProtocols: [
              'Any'
            ]
            destinationAddresses: [
              '10.224.0.0/12'
            ]
            destinationPorts: [
              '*'
            ]
            sourceAddresses: [
              '172.16.201.0/24'
            ]
          }
          {
            name: 'Allow-P2S-VPN-Subnet'
            ruleType: 'NetworkRule'
            description: 'Allow VPN traffic subnet'
            ipProtocols: [
              'Any'
            ]
            destinationAddresses: [
              '10.224.0.0/12'
            ]
            destinationPorts: [
              '*'
            ]
            sourceAddresses: [
              '10.224.128.0/24'
            ]
          }
        ]
      }
    ]
  }
}

resource appGatewayCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-07-01' = {
  parent: hub_policy
  name: 'app-gateway'
  dependsOn:[
    vpnCollectionGroup
  ]
  properties: {
    priority: 500
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'app-gateway-global'
        priority: 501
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-app-gateway-traffic'
            ruleType: 'NetworkRule'
            description: 'Allow traffic originating at application gateway'
            ipProtocols: [
              'Any'
            ]
            destinationAddresses: [
              '10.224.0.0/12'
            ]
            destinationPorts: [
              '*'
            ]
            sourceAddresses: [
              '10.224.112.0/24'
            ]
          }
        ]
      }
    ]
  }
}
