param DomainName string
param HostPoolName string
param HostPoolResourceGroupName string
param KeyVaultName string
param KeyVaultResourceGroupName string
param KeyVaultSubscriptionId string
param Location string
param NamingStandard string
param ScriptContainerUri string
param SessionHostCount int
param SessionHostIndex int
param Timestamp string
param VmName string


var ManagedIdentityName = 'uami-${NamingStandard}-drainmode'
var RoleAssignmentName = guid(resourceGroup().id, ManagedIdentityName)


resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: ManagedIdentityName
  location: Location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(userAssignedIdentity.id, '2018-11-30').principalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: KeyVaultName
  scope: resourceGroup(KeyVaultSubscriptionId, KeyVaultResourceGroupName)
}

module deploymentScript 'deploymentScript.bicep' = {
  name: 'DeploymentScript_DrainMode_${Timestamp}'
  params : {
    Arguments: ' -DomainName ${DomainName} -HostPool ${HostPoolName} -ResourceGroup ${HostPoolResourceGroupName} -SessionHostCount ${SessionHostCount} -SessionHostIndex ${SessionHostIndex} -VmName ${VmName}'
    Location: Location
    Name: 'ds-${NamingStandard}-drainMode'
    ScriptContainerSasToken: keyVault.getSecret('SasToken')
    ScriptContainerUri: ScriptContainerUri
    ScriptName: 'Set-DrainMode.ps1'
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.id
  }
  dependsOn: [
    roleAssignment
  ]
}
