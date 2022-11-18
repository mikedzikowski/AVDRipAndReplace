param storageName string
param location string
param name string
param subscriptionId string
param saResourceGroup string

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageName
  scope: resourceGroup(subscriptionId, saResourceGroup)
}
resource blobStorageConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: name
  kind: 'V1'
  location: location
  properties: {
    displayName: '${storageName}-blobconnection'
    parameterValues: {
      accountName: storageName
      accessKey: listKeys(storage.id, storage.apiVersion).keys[0].value
    }
    api: {
      name: name
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azureblob'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

output blobConnectionId string = blobStorageConnection.id
