param location string
param logAnalyticsWorkspaceResourceId string
param automationAccountName string
param runbookNames array
param pwsh7RunbookNames array
param azAccountsUri string
param azAccountsVersion string
param azAlertsUri string
param azAlertsVersion string
param newAutomationAccount bool

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = if (newAutomationAccount) {
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

resource aa 'Microsoft.Automation/automationAccounts@2021-06-22' existing = {
  name: (newAutomationAccount) ? automationAccount.name : automationAccountName
}

resource runbookDeployment 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = [for (runbook, i) in runbookNames: {
  name: runbook.name
  parent: aa
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

resource pwsh7runbookDeployment 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = [for (runbook, i) in pwsh7RunbookNames: {
  name: runbook.name
  parent: aa
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
  scope: aa
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

resource azAccountsModule 'Microsoft.Automation/automationAccounts/modules@2022-08-08' = {
  name: 'Az.Accounts'
  location: location
  parent: aa
  properties: {
    contentLink: {
      uri: azAccountsUri
      version: azAccountsVersion
    }
  }
}

resource azAlertsModule 'Microsoft.Automation/automationAccounts/modules@2022-08-08' = {
  name: 'Az.AlertsManagement'
  dependsOn:[
    azAccountsModule
  ]
  location: location
  parent: aa
  properties: {
    contentLink: {
      uri: azAlertsUri
      version: azAlertsVersion
    }
  }
}

output aaIdentityId string = newAutomationAccount ? automationAccount.identity.principalId : aa.identity.principalId
output aaLocation string = automationAccount.location
