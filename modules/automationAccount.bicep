param location string
param automationAccountName string
param runbookNames array

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  //name: uniqueString(automationAccountName, resourceGroup().id)
  name: automationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {}
    }
  }
}

resource runbookDeployment 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = [for (runbook, i) in runbookNames: {
  name: runbook.name
  parent: automationAccount
  location: location
  properties: {
    runbookType: 'PowerShell'
    logProgress: true
    logVerbose: true
    publishContentLink: {
      uri: runbook.uri
      version: '1.0.0.0'
    }
  }
}]

output aaIdentityId string = automationAccount.identity.principalId
output aaLocation string = automationAccount.location
