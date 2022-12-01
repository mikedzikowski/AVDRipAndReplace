param location string
param logAnalyticsWorkspaceResourceId string
param automationAccountName string
param runbookNames array
param pwsh7RunbookNames array

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

resource pwsh7runbookDeployment 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = [for (runbook, i) in pwsh7RunbookNames: {
  name: runbook.name
  parent: automationAccount
  location: location
  properties: {
    runbookType: 'PowerShell7'
    logProgress: true
    logVerbose: true
    publishContentLink: {
      uri: runbook.uri
      version: '1.0.0.0'
    }
  }
}]

// Enables the runbook logs in Log Analytics for alerts
resource diagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  scope: automationAccount
  name: 'diag-${automationAccount.name}'
  properties: {
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output aaIdentityId string = automationAccount.identity.principalId
output aaLocation string = automationAccount.location
