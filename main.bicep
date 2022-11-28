targetScope = 'subscription'

@description('The UPN of the privileged account to domain join the AVD session hosts to your domain. This should be an account the resides within the domain you are joining.')
param DomainJoinUserPrincipalName string

@secure()
@description('The password of the privileged account to domain join the AVD session hosts to your domain')
param DomainJoinPassword string

@description('The Local Administrator Username for the Session Hosts')
param VmUsername string

@secure()
@description('Local administrator password for the AVD session hosts')
param VmPassword string

@secure()
@description('SAS Token for storage account')
param SasToken string

@description('The location for the resources deployed in this solution.')
param location string = deployment().location

@description('The Template Spec version ID that will be used to by the rip and replace AVD solution.')
param templateSpecId string = ''

@description('Set the following values if there are exisiting resource groups, automation accounts, or storage account that should be targeted. If values are not set a default naming convention will be used by resources created.')
param exisitingAutomationAccount string = ''
param existingAutomationAccountRg string = ''
param existingLogicAppRg string = ''
param exisitingStorageAccount string = ''
param existingStorageAccountRg string = ''

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

// Get BlobUpdate Logic App Parameters
param container string

@description('The name of the key vault where secrets will be stored and consumed by runbooks. If deploying a new key vault, this value must be globally unique.')
param keyVaultName string

// Variables
var cloud = environment().name
var tenantId = tenant().tenantId
var subscriptionId = subscription().subscriptionId
var workflows_GetImageVersion_name = 'la-${hostPoolName}-avd-imageVersion'
var workflows_GetBlobUpdate_name = 'la-${hostPoolName}-avd-blobUpdate'
var recurrenceType = 'Recurrence'
var waitForRunBook = true
var officeConnectionName = 'office365'
var automationAccountConnectionName = 'azureautomation'
var blobConnectionName = 'azureblob'
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
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-RunBookSchedule.ps1'
  }
  {
    name: 'Get-MarketPlaceImageVersion'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-MarketPlaceImageVersion.ps1'
  }
  {
    name: 'Get-SessionHostVirtualMachine'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Get-SessionHostVirtualMachine.ps1'
  }
  {
    name: 'New-AutomationSchedule'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/New-AutomationSchedule.ps1'
  }
]

var runbooksPwsh7 = [
  {
    name: 'Start-AzureVirtualDesktopRipAndReplace'
    uri: 'https://raw.githubusercontent.com/mikedzikowski/logicapps/main/runbooks/Start-AzureVirtualDesktopRipAndReplace.ps1'
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

var automationAccountRgVar = ((!empty(existingAutomationAccountRg )) ? [
  existingAutomationAccountRg
]: [
  'rg-${NamingStandard}-aa'
])

var logicAppRgVar = ((!empty(existingLogicAppRg)) ? [
  existingLogicAppRg
]: [
  'rg-${NamingStandard}-la'
])

var storageAccountRgVar = ((!empty(existingStorageAccountRg)) ? [
  existingStorageAccountRg
]: [
  'rg-${NamingStandard}-stg'
])

var automationAccountNameVar = ((!empty(exisitingAutomationAccount)) ? [
  exisitingAutomationAccount
]: [
  replace('aa-${NamingStandard}', 'aa', uniqueString(NamingStandard))
])

var rg = (array(concat(automationAccountRgVar,logicAppRgVar,storageAccountRgVar)))
var rgVals = (array(concat(automationAccountRgVar,logicAppRgVar,storageAccountRgVar)))
var ResourceGroups = union(rg, rgVals)
var automationAccountNameValue = first(automationAccountNameVar)

// Resource Groups needed for the solution
resource resourceGroups 'Microsoft.Resources/resourceGroups@2020-10-01' = [for i in range(0, length((ResourceGroups))): {
  name: ResourceGroups[i]
  location: location
}]

module storageAccount 'modules/storageAccount.bicep' = {
  name: 'sa-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[2])
  params: {
    storageAccountName: exisitingStorageAccount
    containerName: container
  }
  dependsOn: [
    resourceGroups
  ]
}

module automationAccount 'modules/automationAccount.bicep' = {
  name: 'aa-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[0])
  params: {
    automationAccountName: automationAccountNameValue
    location: location
    runbookNames: runbooks
    pwsh7RunbookNames: runbooksPwsh7
  }
  dependsOn: [
    resourceGroups
  ]
}

module automationAccountConnection 'modules/automationAccountConnection.bicep' = {
  name: 'automationAccountConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[1])
  params: {
    location: location
    connection_azureautomation_name: automationAccountConnectionName
    subscriptionId: subscriptionId
    displayName: automationAccountConnectionName
  }
  dependsOn: [
    automationAccount
    resourceGroups
  ]
}

module blobConnection 'modules/blobConnection.bicep' = {
  name: 'blobConnection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[1])
  params: {
    location: location
    storageName: storageAccount.outputs.storageAccountName
    name: blobConnectionName
    saResourceGroup: rg[2]
    subscriptionId: subscriptionId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
  ]
}

module o365Connection 'modules/officeConnection.bicep' = {
  name: 'o365Connection-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[1])
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
  scope: resourceGroup(subscriptionId, rg[0])
  params: {
    principalId: getImageVersionlogicApp.outputs.imagePrincipalId
    roleId: roleId
    scope: 'resourceGroup().id'
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
  ]
}

module rbacBlobPermissionConnector 'modules/rbacPermissions.bicep' = {
  name: 'rbac-blobConnector-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[0])
  params: {
    principalId: getBlobUpdateLogicApp.outputs.blobPrincipalId
    roleId: roleId
  }
  dependsOn: [
    automationAccount
    automationAccountConnection
    blobConnection
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
  scope: resourceGroup(subscriptionId, rg[1])
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
    automationAccountResourceGroup: rg[0]
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
    getRunbookScheduleRunbookName: runbookScheduleRunbookName
    getRunbookGetSessionHostVm: runbookGetSessionHostVm
    getGetMarketPlaceImageVersion: runbookMarketPlaceImageVersion
    waitForRunBook: waitForRunBook
    hostPoolName: hostPoolName
    identityType: identityType
  }
  dependsOn: [
    blobConnection
    o365Connection
    keyVault
  ]
}

module getBlobUpdateLogicApp 'modules/logicAppGetBlobUpdate.bicep' = {
  name: 'getBlobUpdateLogicApp-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[1])
  params: {
    location: location
    workflows_GetBlobUpdate_name: workflows_GetBlobUpdate_name
    automationAccountConnectionName: automationAccountConnectionName
    automationAccountName: automationAccountNameValue
    automationAccountResourceGroup: rg[0]
    blobConnectionName: blobConnectionName
    identityType: identityType
    state: state
    schema: schema
    contentVersion: contentVersion
    connectionType: connectionType
    triggerFrequency: triggerFrequency
    triggerInterval: triggerInterval
    storageAccountName: storageAccount.outputs.storageAccountName
    container: container
    hostPoolName: hostPoolName
    checkBothCreatedAndModifiedDateTime: checkBothCreatedAndModifiedDateTime
    maxFileCount: maxFileCount
    subscriptionId: subscriptionId
    runbookGetRunBookSchedule: runbookScheduleRunbookName
    runbookGetSessionHostVirtualMachine: runbookGetSessionHostVm
    runbookNewHostPoolRipAndReplace: runbookNewHostPoolRipAndReplace
  }
  dependsOn: [
    blobConnection
  ]
}

module keyVault 'modules/keyVault.bicep' = {
  name: 'kv-deployment-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, rg[1])
  params:{
    SasToken: SasToken
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    VmUsername: VmUsername
    VmPassword: VmPassword
    location: location
    keyvaultName: keyVaultName
    aaIdentityId: automationAccount.outputs.aaIdentityId
  }
  dependsOn: [
    resourceGroups
  ]
}

output automationAccountName string = automationAccountNameValue
output storageAccountName string = storageAccount.outputs.storageAccountName
output ResourceGroups array = array(concat(automationAccountRgVar,logicAppRgVar,storageAccountRgVar))
output keyVaultName string = keyVault.outputs.keyVaultName
