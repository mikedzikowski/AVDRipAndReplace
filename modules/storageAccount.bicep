param storageAccountName string
param containerName string

resource sa 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${sa.name}/default/${containerName}'
}

output storageAccountName string = sa.name
output storageAccountId string = sa.id
