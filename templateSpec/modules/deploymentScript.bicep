param Arguments string
param Location string
param Name string
param ScriptContainerUri string
@secure()
param ScriptContainerSasToken string
param ScriptName string
param Timestamp string
param UserAssignedIdentityResourceId string


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: Name
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {}
    }
  }
  location: Location
  kind: 'AzurePowerShell'
  tags: {}
  properties: {
    azPowerShellVersion: '5.4'
    cleanupPreference: 'OnSuccess'
    primaryScriptUri: '${ScriptContainerUri}${ScriptName}${ScriptContainerSasToken}'
    arguments: Arguments
    forceUpdateTag: Timestamp
    retentionInterval: 'P1D'
    timeout: 'PT30M'
  }
}
