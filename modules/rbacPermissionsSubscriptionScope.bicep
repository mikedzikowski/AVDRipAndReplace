targetScope = 'subscription'

param canDelegate bool = false
param description string = 'Contributor RBAC permission'
param principalId string
param scope string

resource rbac 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(scope, principalId, 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  properties: {
    canDelegate: canDelegate
    description: description
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
    principalType: 'ServicePrincipal'
  }
}

output rbac string = rbac.properties.roleDefinitionId
