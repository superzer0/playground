@description('Azure Region')
param parLocation string

@description('Naming suffix. Includes env, location code and module name')
param parNameSuffix string

@description('Tags')
param parTags object

var varPublicSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDq0/qSuGXiep5Q/GPnc1kx8lCmqh3lU9TSYKxcXBEt+m0bSzVb4KF/BSI/xvkYuZX19ALvVXnLpWm2RvFJZ/Z8L0q+8Uo0GRy9Dzed+te69oGOVgfJO7C78t5dbsBDrptycanuHqFg2G6JZTF1tLXq6j5arMIiUHahXk7fZSFSqm53L32/aCqRP3UslShjJJ5hdp8tk06Ua4EHQbWGwstVJRfKx+ro1OcrZeNGlcvaE3ytMG5VkoJeRcjcEfQ0P7/z1qLT1sKwzBCY13GFRbgXnECgN+RZ0fYEzSE9oqPbEKQCtkgJq+43mzDEDGr9YnhICKhb7p94Vrki3QDSr1QO+8LFllEP2P18waFPqUhEynmnKq0Wvq5akKRaBASwsFnTsEHXTf5U3CrV0f2s9/eyVJ0qoVNBrmhyGA7/r5HlILd8Siqh1XGjWTvrAUmgbN5WhpUk5ntIV7cMnvIpAtUVi/tlmLALVJyICr6GX9vYcTnJ3lkbeIAFAnfJd5B2Ktk= generated-by-azure'
var varVnetName = 'vnet-${parNameSuffix}'
var varSubnetsPrefix = 'zone'
var vmsToCreate = [ '00', '01' ]

module modVMs 'vm.bicep' = [for vmIdentifier in vmsToCreate: {
  name: 'modVm-${vmIdentifier}-${parNameSuffix}'
  params: {
    adminPublicKey: varPublicSshKey
    parLocation: parLocation
    parNameSuffix: parNameSuffix
    parTags: parTags
    parVnetName: varVnetName
    parSubnetName: '${varSubnetsPrefix}${vmIdentifier}'
    parVmIdentifier: vmIdentifier
  }
}]
