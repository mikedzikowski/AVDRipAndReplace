param storageAccountName string
param containerName string
param new bool
param location string
param logAnalyticsWorkspaceId string

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = if (new) {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storage
  name: 'default'
  properties: {}
}

resource diagnosticsBlob 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: blobService
  name: 'diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'StorageWrite'
        enabled: true
      }
    ]
  }
}

resource sa 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: new ? storage.name : storageAccountName
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = if (new ) {
  name: '${sa.name}/default/${containerName}'
}

resource existingContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' existing = {
  name: '${sa.name}/default/${containerName}'
}

output storageAccountName string = sa.name
output storageAccountId string = sa.id
output container string = new ? container.name : existingContainer.name
