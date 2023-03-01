@description('Specifies the location for resources.')
param location string = resourceGroup().location

@description('Workload name')
param workloadName string

var tags = {
  owner: 'OPS'
}

resource hub_policy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: 'afwp-${workloadName}-hub'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Premium'
    }
    intrusionDetection: {
      mode: 'Alert'
    }
    threatIntelMode: 'Alert'
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

