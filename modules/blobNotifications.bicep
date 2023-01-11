param actionGroupName string
param emailContact string
param location string
param tags object
param storageAccount string
param storageAccountId string

var logAlerts = [
  {
    name: 'New blob uploaded to container on ${storageAccount}'
    description: 'New Blob Uploaded to AVD container on ${storageAccount}. Please close this alert to act as approval in workflow.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    muteActionsDuration: 'P1D'
    criteria: {
      allOf: [
        {
          query: 'StorageBlobLogs | where OperationName == "PutBlob" and StatusText == "Success"'
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
]

resource actionGroup 'Microsoft.Insights/actionGroups@2019-06-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: 'EmailAlerts'
    enabled: true
    emailReceivers: [
      {
        name: emailContact
        emailAddress: emailContact
        useCommonAlertSchema: true
      }
    ]
  }
}

resource scheduledQueryRules 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = [for i in range(0, length(logAlerts)): {
  name: logAlerts[i].name
  location: location
  tags: tags
  properties: {
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
    }
    criteria: logAlerts[i].criteria
    displayName: logAlerts[i].name
    description: logAlerts[i].description
    autoMitigate: false
    enabled: true
    evaluationFrequency: logAlerts[i].evaluationFrequency
    scopes: [
      storageAccountId
    ]
    targetResourceTypes:[
      'Microsoft.Storage/storageAccounts'
    ]
    severity: logAlerts[i].severity
    windowSize: logAlerts[i].windowSize
  }
}]
