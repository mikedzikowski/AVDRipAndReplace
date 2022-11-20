param connection_azureautomation_name string
param subscriptionId string
param location string
param displayName string

resource connection_azureautomation_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connection_azureautomation_name
  location: location
  kind: 'V1'
  properties: {
    displayName: displayName
    parameterValueType: 'Alternative'
    customParameterValues: {}
    api: {
      id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/azureautomation'
    }
    testLinks: []
  }
}

