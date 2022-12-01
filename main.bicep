targetScope = 'subscription'

@description('The location for the resources deployed in this solution.')
param location string = deployment().location

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
param exisitingStorageAccount string = ''
param existingStorageAccountRg string = ''
param container string = ''
@allowed([
  'Month'
  'Week'
  'Day'
  'Hour'
  'Minute'
  'Second'
])
@description('Frequency of logic app trigger for Blob Check Logic App.')
param triggerFrequency string = 'Day'

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

module automationAccount 'modules/automationAccount.bicep' = {
  name: 'aa-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    automationAccountName: automationAccountNameValue
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    runbookNames: runbooks
    pwsh7RunbookNames: runbooksPwsh7
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

module o365Connection 'modules/officeConnection.bicep' = {
  name: 'o365Connection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    displayName: officeConnectionName
    location: location
    subscriptionId: subscriptionId
    connection_azureautomation_name: officeConnectionName
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}

module rbacPermissionAzureAutomationConnector 'modules/rbacPermissions.bicep' = {
  name: 'rbac-aaConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    principalId: getImageVersionlogicApp.outputs.imagePrincipalId
    roleId: roleId
    scope: 'resourceGroup().id'
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

module getImageVersionlogicApp 'modules/logicappGetImageVersion.bicep' = {
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
  }
  dependsOn: [
    o365Connection
  ]
}
module storageAccount 'modules/storageAccount.bicep' = if (deployBlobUpdateLogicApp) {
  name: 'sa-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingStorageAccountRg)
  params: {
    storageAccountName: exisitingStorageAccount
    containerName: container
  }
}

module rbacBlobPermissionConnector 'modules/rbacPermissions.bicep' = if (deployBlobUpdateLogicApp) {
  name: 'rbac-blobConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    principalId: deployBlobUpdateLogicApp ? getBlobUpdateLogicApp.outputs.blobPrincipalId : 'None'
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
  ]
}

module blobConnection 'modules/blobConnection.bicep' = if (deployBlobUpdateLogicApp) {
  name: 'blobConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, existingAutomationAccountRg)
  params: {
    location: location
    storageName: deployBlobUpdateLogicApp ? exisitingStorageAccount : 'None'
    name: blobConnectionName
    saResourceGroup: existingStorageAccountRg
    subscriptionId: subscriptionId
  }
  dependsOn: [
    storageAccount
  ]
}

module getBlobUpdateLogicApp 'modules/logicAppGetBlobUpdate.bicep' = if (deployBlobUpdateLogicApp)  {
  name: 'getBlobUpdateLogicApp-deployment-${deploymentNameSuffix}'
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
    storageAccountName: deployBlobUpdateLogicApp ? exisitingStorageAccount: 'None'
    container: deployBlobUpdateLogicApp ? container : 'None'
    hostPoolName: hostPoolName
    checkBothCreatedAndModifiedDateTime: checkBothCreatedAndModifiedDateTime
    maxFileCount: maxFileCount
    subscriptionId: subscriptionId
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
  }
  dependsOn: [
    blobConnection
  ]
}

module notifications 'modules/notifications.bicep' = {
  scope: resourceGroup(subscriptionId, hostPoolResourceGroupName)
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

output automationAccountName string = automationAccountNameValue
