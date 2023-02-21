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
