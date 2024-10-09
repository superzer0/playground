targetScope = 'resourceGroup'
metadata name = 'VM AZ104'

@description('Azure Region')
param parLocation string

@description('Naming suffix. Includes env, location code and module name')
param parNameSuffix string

@description('Tags')
param parTags object

@description('SSH user name')
param parAdminUsername string = 'azureuser'

@description('Virtual Machine identifier')
param parVmIdentifier string

@description('vNet name')
param parVnetName string

@description('subnet name')
param parSubnetName string

@description('Load balancer name')
param parLbName string

@description('Load balancer pool name')
param parLbPoolName string

@secure()
param adminPublicKey string

@description('Custom data to initialize the VM with')
param cloudInitContent string = ''

resource resVnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: parVnetName
}

resource resSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' existing = {
  parent: resVnet
  name: parSubnetName
}

var varVmName = 'vm-${parVmIdentifier}-${parNameSuffix}'

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: 'nic-${varVmName}'
  location: parLocation
  tags: parTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', parLbName, parLbPoolName)
            }
          ]
        }
      }
    ]
  }
  dependsOn: []
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: varVmName
  location: parLocation
  tags: parTags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    userData: empty(cloudInitContent) ? null : cloudInitContent
    additionalCapabilities: {
      hibernationEnabled: false
    }
    osProfile: {
      computerName: varVmName
      adminUsername: parAdminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${parAdminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
