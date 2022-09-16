
param location string = resourceGroup().location

// no resource defined so we can quickly validate if the loop is producing what we expect
var exampleForDebugging = [for i in range(0, 3): {
  name: '${i}storage${uniqueString(resourceGroup().id)}'
  location: location
  sku:{
    name: 'Standard_LRS'

  }
  kind: 'BlobStorage'
  properties: {
    accessTier: 'Cool'
  }
}]

output myOutput array = exampleForDebugging
