targetScope = 'subscription'

@description('The location for the resources deployed in this solution.')
param location string = deployment().location

param deployWithO365Connector bool = false

@description('The resource ID to an existing log analytics workspace. Ideally, utilizing the same workspace used for AVD Insights.')
param logAnalyticsWorkspaceResourceId string

@description('The Template Spec version ID that will be used to by the rip and replace AVD solution.')
param templateSpecId string

@description('Set the following values if there are exisiting resource groups, automation accounts, or storage account that should be targeted. If values are not set a default naming convention will be used by resources created.')
param exisitingAutomationAccount string
param existingAutomationAccountRg string

// Start Blob Check Params
@description('To be used with AVD solutions that deploy post configuration software. Set the following values if there is a storage account that should be targeted. If values are not set a default naming convention will be used by resources created.')
param deployBlobUpdateLogicApp bool = false
param newStorageAccount bool = false
param exisitingStorageAccount string = 'none'
param existingStorageAccountRg string = 'none'
param container string = 'none'
@allowed([
  'Month'
  'Week'
  'Day'
  'Hour'
  'Minute'
  'Second'
])
@description('Frequency of logic app trigger for Blob Check Logic App.')
param triggerFrequency string = 'Minute'

@description('Interval of logic app trigger for Blob Check Logic App.')
param triggerInterval int = 1
// End Blob Check Params

@description('Host pool name to target.')
param hostPoolName string

@description('Host pool resource group name to target.')
param hostPoolResourceGroupName string

@description('Session host resource group name to target.')
param sessionHostResourceGroupName string

@description('deployment name suffix.')
param deploymentNameSuffix string = utcNow()

@allowed([
  'Month'
  'Week'
  'Day'
  'Hour'
  'Minute'
  'Second'
])
@description('Frequency of logic app trigger for Image Check Logic App.')
param recurrenceFrequency string = 'Day'

@description('Interval of logic app trigger for Image Check Logic App.')
param recurrenceInterval int = 1

@description('E-mail contact or group used by logic app approval workflow.')
param emailContact string

// Maintence Window
@allowed([
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
  'Saturday'
  'Sunday'
])
@description('The target maintenance window day for AVD')
param dayOfWeek string = 'Saturday'

@allowed([
  'First'
  'Second'
  'Third'
  'Fourth'
  'LastDay'
])
@description('The target maintenance window week occurrence for AVD')
param dayOfWeekOccurrence string = 'First'

@description('The target maintenance window start time for AVD')
param startTime string = '23:00'

param newAutomationAccount bool

param storageAccountSubscriptionId string = subscription().subscriptionId
param automationAccountSubscriptionId string = subscription().subscriptionId
param lawAccountSubscriptionId string = subscription().subscriptionId
param lawResourceGroup string
@allowed([
  'marketplace'
  'aib'
])
param imageSource string

// Variables
var cloud = environment().name
var tenantId = tenant().tenantId
var subscriptionId = subscription().subscriptionId
var actionGroupName = 'ag-${NamingStandard}-avd-rar'
var workflows_GetImageVersion_name = 'la-${hostPoolName}-avd-imageVersion'
var workflows_GetBlobUpdate_name = 'la-${hostPoolName}-avd-blobUpdate'
var recurrenceType = 'Recurrence'
var waitForRunBook = true
var officeConnectionName = 'office365'
var automationAccountConnectionName = 'azureautomation'
var blobConnectionName = 'sa-azureblob'
var identityType = 'SystemAssigned'
var state = 'Enabled'
var schema = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
var contentVersion = '1.0.0.0'
var connectionType = 'Object'
var checkBothCreatedAndModifiedDateTime = false
var maxFileCount = 10
var roleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var runbookNewHostPoolRipAndReplace = 'Start-AzureVirtualDesktopRipAndReplace'
var runbookScheduleRunbookName = 'Get-RunBookSchedule'
var runbookGetSessionHostVm = 'Get-SessionHostVirtualMachine'
var runbookMarketPlaceImageVersion = 'Get-MarketPlaceImageVersion'
var azAccountsUri = 'https://www.powershellgallery.com/api/v2/package/Az.Accounts/2.10.4'
var azAccountsVersion  = '2.10.4'
var azAlertsUri = 'https://www.powershellgallery.com/api/v2/package/Az.AlertsManagement/0.5.0'
var azAlertsVersion = '0.5.0'
var runbooks = [
  {
    name: 'Get-RunBookSchedule'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/runbooks/Get-RunBookSchedule.ps1'
  }
  {
    name: 'Get-MarketPlaceImageVersion'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/runbooks/Get-MarketPlaceImageVersion.ps1'
  }
  {
    name: 'Get-SessionHostVirtualMachine'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/runbooks/Get-SessionHostVirtualMachine.ps1'
  }
  {
    name: 'New-AutomationSchedule'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/runbooks/New-AutomationSchedule.ps1'
  }
  {
    name: 'Get-NewImageAlertStatus'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/runbooks/Get-NewImageAlertStatus.ps1'
  }
  {
    name: 'Get-NewBlobAlertStatus'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/runbooks/Get-NewImageAlertStatus.ps1'
  }
]

var runbooksPwsh7 = [
  {
    name: 'Start-AzureVirtualDesktopRipAndReplace'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/runbooks/Start-AzureVirtualDesktopRipAndReplace.ps1'
  }
]

var LocationShortNames = {
  australiacentral: 'ac'
  australiacentral2: 'ac2'
  australiaeast: 'ae'
  australiasoutheast: 'as'
  brazilsouth: 'bs2'
  brazilsoutheast: 'bs'
  canadacentral: 'cc'
  canadaeast: 'ce'
  centralindia: 'ci'
  centralus: 'cu'
  eastasia: 'ea'
  eastus: 'eu'
  eastus2: 'eu2'
  francecentral: 'fc'
  francesouth: 'fs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  japaneast: 'je'
  japanwest: 'jw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'kc'
  koreasouth: 'ks'
  northcentralus: 'ncu'
  northeurope: 'ne'
  norwayeast: 'ne2'
  norwaywest: 'nw'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scu'
  southeastasia: 'sa'
  southindia: 'si'
  swedencentral: 'sc'
  switzerlandnorth: 'sn'
  switzerlandwest: 'sw'
  uaecentral: 'uc'
  uaenorth: 'un'
  uksouth: 'us'
  ukwest: 'uw'
  usdodcentral: 'uc'
  usdodeast: 'ue'
  usgovarizona: 'az'
  usgoviowa: 'ia'
  usgovtexas: 'tx'
  usgovvirginia: 'va'
  westcentralus: 'wcu'
  westeurope: 'we'
  westindia: 'wi'
  westus: 'wu'
  westus2: 'wu2'
  westus3: 'wu3'
}
var LocationShortName = LocationShortNames[location]
var NamingStandard = '${LocationShortName}'

var automationAccountNameVar = ((!empty(exisitingAutomationAccount)) ? [
  exisitingAutomationAccount
]: [
  replace('aa-${NamingStandard}', 'aa', uniqueString(NamingStandard))
])

var automationAccountNameValue = first(automationAccountNameVar)
var blobWithConnector  = deployBlobUpdateLogicApp && deployWithO365Connector
var blobWithOutConnector = deployBlobUpdateLogicApp && !deployWithO365Connector
var imageWithConnector = deployWithO365Connector
var imageWithOutConnector = !deployWithO365Connector

module automationAccount 'modules/automationAccount.bicep' = {
  name: 'aa-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(automationAccountSubscriptionId, existingAutomationAccountRg)
  params: {
    automationAccountName: automationAccountNameValue
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    runbookNames: runbooks
    pwsh7RunbookNames: runbooksPwsh7
    azAccountsUri:azAccountsUri
    azAccountsVersion:azAccountsVersion
    azAlertsUri:azAlertsUri
    azAlertsVersion:azAlertsVersion
    newAutomationAccount: newAutomationAccount
  }
}

module automationAccountConnection 'modules/automationAccountConnection.bicep' = {
  name: 'automationAccountConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    location: location
    connection_azureautomation_name: automationAccountConnectionName
    subscriptionId: subscriptionId
    displayName: automationAccountConnectionName
  }
  dependsOn: [
    automationAccount
  ]
}

module o365Connection 'modules/officeConnection.bicep' = if(deployWithO365Connector) {
  name: 'o365Connection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    displayName: deployWithO365Connector ? officeConnectionName : 'None'
    location: deployWithO365Connector ? location : 'None'
    subscriptionId: deployWithO365Connector ? subscriptionId : 'None'
    connection_azureautomation_name: deployWithO365Connector ? officeConnectionName : 'None'
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}

module rbacHostPoolPermissionAzureAutomationAccount 'modules/rbacPermissions.bicep' = {
  name: 'rbacHost-automationAccount-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, hostPoolResourceGroupName)
  params: {
    principalId: automationAccount.outputs.aaIdentityId
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}

module rbacSessionHostPermissionAzureAutomationAccount 'modules/rbacPermissions.bicep' = {
  name: 'rbacSession-automationAccount-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, sessionHostResourceGroupName)
  params: {
    principalId: automationAccount.outputs.aaIdentityId
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}

module rbacPermissionAzureAutomationAccountRg 'modules/rbacPermissionsSubscriptionScope.bicep' = {
  name: 'rbac-automationAccountOwner-deployment-${deploymentNameSuffix}'
  params: {
    principalId: automationAccount.outputs.aaIdentityId
    scope: subscription().id
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}

module getImageVersionlogicAppUsingAzureMonitorAlerts 'modules/logicappGetImageVersionUsingAzureMonitorAlerts.bicep'  = if(imageWithOutConnector) {
  name: 'getImageVersionlogicAppWOConnectpr-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    dayOfWeek: dayOfWeek
    startTime: startTime
    dayOfWeekOccurrence: dayOfWeekOccurrence
    cloud: cloud
    subscriptionId: subscriptionId
    tenantId: tenantId
    templateSpecId: templateSpecId
    workflows_GetImageVersion_name: workflows_GetImageVersion_name
    automationAccountConnectionName: automationAccountConnectionName
    location: location
    state: state
    recurrenceFrequency: recurrenceFrequency
    recurrenceType: recurrenceType
    recurrenceInterval: recurrenceInterval
    automationAccountName: automationAccountNameValue
    automationAccountLocation: automationAccount.outputs.aaLocation
    automationAccountResourceGroup: existingAutomationAccountRg
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
    getRunbookScheduleRunbookName: runbookScheduleRunbookName
    getRunbookGetSessionHostVm: runbookGetSessionHostVm
    getGetMarketPlaceImageVersion: runbookMarketPlaceImageVersion
    waitForRunBook: waitForRunBook
    hostPoolName: hostPoolName
    identityType: identityType
    automationAccountConnectId: automationAccountConnection.outputs.automationConnectId
    imageSource: imageSource
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
  ]
}

module getImageVersionlogicApp 'modules/logicappGetImageVersion.bicep' = if(imageWithConnector) {
  name: 'getImageVersionlogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    dayOfWeek: dayOfWeek
    startTime: startTime
    dayOfWeekOccurrence: dayOfWeekOccurrence
    cloud: cloud
    officeConnectionName: officeConnectionName
    subscriptionId: subscriptionId
    tenantId: tenantId
    templateSpecId: templateSpecId
    emailContact: emailContact
    workflows_GetImageVersion_name: workflows_GetImageVersion_name
    automationAccountConnectionName: automationAccountConnectionName
    location: location
    state: state
    recurrenceFrequency: recurrenceFrequency
    recurrenceType: recurrenceType
    recurrenceInterval: recurrenceInterval
    automationAccountName: automationAccountNameValue
    automationAccountLocation: automationAccount.outputs.aaLocation
    automationAccountResourceGroup: existingAutomationAccountRg
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
    getRunbookScheduleRunbookName: runbookScheduleRunbookName
    getRunbookGetSessionHostVm: runbookGetSessionHostVm
    getGetMarketPlaceImageVersion: runbookMarketPlaceImageVersion
    waitForRunBook: waitForRunBook
    hostPoolName: hostPoolName
    identityType: identityType
    automationAccountConnectId: automationAccountConnection.outputs.automationConnectId
    office365ConnectionId: imageWithConnector ? o365Connection.outputs.office365ConnectionId : 'None'
    imageSource: imageSource
  }
}

module storageAccount 'modules/storageAccount.bicep' = if(deployBlobUpdateLogicApp) {
  name: 'sa-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(storageAccountSubscriptionId, existingStorageAccountRg)
  params: {
    storageAccountName: deployBlobUpdateLogicApp ? exisitingStorageAccount : 'None'
    containerName: deployBlobUpdateLogicApp ? container  : 'None'
    location: deployBlobUpdateLogicApp ? location  : 'None'
    new: deployBlobUpdateLogicApp ? newStorageAccount  : false
    logAnalyticsWorkspaceId: deployBlobUpdateLogicApp ? logAnalyticsWorkspaceResourceId  : 'None'
  }
}

module rbacPermissionAzureAutomationWconnector 'modules/rbacPermissions.bicep' = if(deployWithO365Connector) {
  name: 'rbac-aaConnectorWConn-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    principalId: deployWithO365Connector ? getImageVersionlogicApp.outputs.imagePrincipalId : 'None'
    roleId: roleId
    scope: 'resourceGroup().id'
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}

module rbacPermissionAzureAutomationConnector 'modules/rbacPermissions.bicep' = if(imageWithOutConnector) {
  name: 'rbac-aaConnectorWoConn-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    principalId:  imageWithOutConnector ? getImageVersionlogicAppUsingAzureMonitorAlerts.outputs.imagePrincipalId : 'None'
    roleId: roleId
    scope: 'resourceGroup().id'
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}


module blobConnection 'modules/blobConnection.bicep' = if (deployBlobUpdateLogicApp) {
  name: 'blobConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    location: deployBlobUpdateLogicApp ? location : 'None'
    storageName: deployBlobUpdateLogicApp ? storageAccount.outputs.storageAccountName : 'None'
    name: deployBlobUpdateLogicApp ? blobConnectionName : 'None'
    saResourceGroup: deployBlobUpdateLogicApp ? storageAccount.outputs.storageAccountRg : 'None'
    storageSubscriptionId: deployBlobUpdateLogicApp ? storageAccount.outputs.storageAccountSubscriptionId : 'None'
  }
}

module rbacBlobPermissionConnector 'modules/rbacPermissions.bicep' = if(blobWithConnector) {
  name: 'rbac-blobConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    principalId: blobWithConnector ? getBlobUpdateLogicApps.outputs.blobPrincipalId  : 'None'
    roleId: blobWithConnector ? roleId : 'None'
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
  ]
}

module rbacBlobPermissionConnectorAlert 'modules/rbacPermissions.bicep' = if(blobWithOutConnector) {
  name: 'rbac-blobConnector-alert-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    principalId: blobWithOutConnector ? getBlobUpdateLogicAppUsingAzureMonitorAlerts.outputs.blobPrincipalId  : 'None'
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
  ]
}

module getBlobUpdateLogicApps 'modules/logicAppGetBlobUpdate.bicep' = if (blobWithConnector) {
  name: 'getBlobUpdateLogicApps-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    location: location
    cloud: cloud
    dayOfWeek:dayOfWeek
    dayOfWeekOccurrence: dayOfWeekOccurrence
    emailContact:emailContact
    officeConnectionName: officeConnectionName
    startTime: startTime
    templateSpecId: templateSpecId
    tenantId: tenantId
    waitForRunBook: waitForRunBook
    workflows_GetBlobUpdate_name: workflows_GetBlobUpdate_name
    automationAccountConnectionName: automationAccountConnectionName
    automationAccountName: automationAccountNameValue
    automationAccountResourceGroup: existingAutomationAccountRg
    automationAccountLocation: automationAccount.outputs.aaLocation
    blobConnectionName: blobConnectionName
    identityType: identityType
    state: state
    schema: schema
    contentVersion: contentVersion
    connectionType: connectionType
    triggerFrequency: triggerFrequency
    triggerInterval: triggerInterval
    storageAccountName: blobWithConnector ? exisitingStorageAccount: 'None'
    container: blobWithConnector ? container : 'None'
    hostPoolName: hostPoolName
    checkBothCreatedAndModifiedDateTime: checkBothCreatedAndModifiedDateTime
    maxFileCount: maxFileCount
    subscriptionId: subscriptionId
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
    office365ConnectionId: blobWithConnector ? o365Connection.outputs.office365ConnectionId : 'None'
    automationAccountConnectId: automationAccountConnection.outputs.automationConnectId
    blobConnectId: blobWithConnector ? blobConnection.outputs.blobConnectionId : 'None'
  }
  dependsOn: [
    blobConnection
  ]
}

module getBlobUpdateLogicAppUsingAzureMonitorAlerts 'modules/logicAppGetBlobUpdateUsingAzureMonitorAlerts.bicep' = if(blobWithOutConnector) {
  name: 'getBlobUpdateLogicAppWAlerts-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    location: location
    cloud: cloud
    dayOfWeek: dayOfWeek
    dayOfWeekOccurrence: dayOfWeekOccurrence
    startTime: startTime
    templateSpecId: templateSpecId
    tenantId: tenantId
    waitForRunBook: waitForRunBook
    workflows_GetBlobUpdate_name: workflows_GetBlobUpdate_name
    automationAccountConnectionName: automationAccountConnectionName
    automationAccountName: automationAccountNameValue
    automationAccountResourceGroup: existingAutomationAccountRg
    blobConnectionName: blobConnectionName
    identityType: identityType
    state: state
    schema: schema
    contentVersion: contentVersion
    connectionType: connectionType
    triggerFrequency: triggerFrequency
    triggerInterval: triggerInterval
    storageAccountName: blobWithOutConnector ? exisitingStorageAccount: 'None'
    container: blobWithOutConnector ? container : 'None'
    hostPoolName: hostPoolName
    checkBothCreatedAndModifiedDateTime: checkBothCreatedAndModifiedDateTime
    maxFileCount: maxFileCount
    subscriptionId: subscriptionId
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
    automationAccountConnectId: automationAccountConnection.outputs.automationConnectId
    blobConnectId: blobWithOutConnector ? blobConnection.outputs.blobConnectionId : 'None'
  }
  dependsOn: [
    blobConnection
    automationAccount
  ]
}

module notifications 'modules/notifications.bicep' = {
  scope: resourceGroup(lawAccountSubscriptionId, lawResourceGroup)
  name: 'notifications-deployment-${deploymentNameSuffix}'
  params: {
    actionGroupName: actionGroupName
    emailContact: emailContact
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    tags: {
    }
  }
}

module blobNotifications 'modules/blobNotifications.bicep' = if(deployBlobUpdateLogicApp) {
  scope: resourceGroup(storageAccountSubscriptionId, existingStorageAccountRg)
  name: 'blobNotifications-deployment-${deploymentNameSuffix}'
  params: {
    actionGroupName: actionGroupName
    emailContact: emailContact
    location: location
    storageAccount: deployBlobUpdateLogicApp ? storageAccount.outputs.storageAccountName : 'None'
    storageAccountId: deployBlobUpdateLogicApp ? storageAccount.outputs.storageAccountId : 'None'
    tags: {
    }
  }
}
