targetScope = 'subscription'


@allowed([
  'AvailabilitySet'
  'AvailabilityZones'
  'None'
])
param Availability string = 'None'
param AvailabilitySetNamePrefix string = ''
param AvailabilityZones array = []
param DiskNamePrefix string = ''
param DiskSku string = 'Premium_LRS'
param DomainName string = ''
@allowed([
  'ActiveDirectory' // Active Directory Domain Services or Azure Active Directory Domain Services
  'None' // Azure AD Join
  'NoneWithIntune' // Azure AD Join with Intune enrollment
])
param DomainServices string = 'ActiveDirectory'
param HostPoolCustomRdpProperty string = ''
param HostPoolDescription string = ''
param HostPoolFriendlyName string = ''
param HostPoolLoadBalancerType string = ''
param HostPoolLocation string = deployment().location
param HostPoolMaxSessionLimit int = 1
param HostPoolName string = ''
param HostPoolPreferredAppGroupType string = ''
param HostPoolResourceGroupName string = ''
param HostPoolStartVmOnConnect bool = false
param HostPoolTags object = {}
param HostPoolType string = ''
param HostPoolValidationEnvironment bool = false
param HostPoolVmTemplate string = ''
param ImageOffer string = ''
param ImagePublisher string = ''
param ImageSku string = ''
param ImageVersion string = 'latest'
param KeyVaultResourceId string = ''
param NetworkInterfaceNamePrefix string = ''
param SessionHostCount int = 1
param SessionHostIndex int = 0
param SessionHostOuPath string = ''
param SubnetResourceId string = ''
param Timestamp string = utcNow('yyyyMMddhhmmss')
param TrustedLaunch bool = false
param VirtualMachineLocation string = deployment().location
param VirtualMachineNamePrefix string = ''
param VirtualMachineResourceGroupName string = ''
param VirtualMachineSize string = ''
param VirtualMachineTags object = {}
param ImageId string = ''


/*  BEGIN BATCHING VARIABLES */
// The following variables are used to determine the batches to deploy any number of AVD session hosts.
var MaxResourcesPerTemplateDeployment = 133 // This is the max number of session hosts that can be deployed from the sessionHosts.bicep file in each batch / for loop. Math: (800 - <Number of Static Resources>) / <Number of Looped Resources> 
var DivisionValue = SessionHostCount / MaxResourcesPerTemplateDeployment // This determines if any full batches are required.
var DivisionRemainderValue = SessionHostCount % MaxResourcesPerTemplateDeployment // This determines if any partial batches are required.
var SessionHostBatchCount = DivisionRemainderValue > 0 ? DivisionValue + 1 : DivisionValue // This determines the total number of batches needed, whether full and / or partial.
/*  END BATCHING VARIABLES */

/*  BEGIN AVAILABILITY SET COUNT */
// The following variables are used to determine the number of availability sets.
var MaxAvSetCount = 200 // This is the max number of session hosts that can be deployed in an availability set.
var DivisionAvSetValue = SessionHostCount / MaxAvSetCount // This determines if any full availability sets are required.
var DivisionAvSetRemainderValue = SessionHostCount % MaxAvSetCount // This determines if any partial availability sets are required.
var AvailabilitySetCount = DivisionAvSetRemainderValue > 0 ? DivisionAvSetValue + 1 : DivisionAvSetValue // This determines the total number of availability sets needed, whether full and / or partial.
/*  END AVAILABILITY SET COUNT */


var KeyVaultName = split(KeyVaultResourceId, '/')[8]
var KeyVaultResourceGroupName = split(KeyVaultResourceId, '/')[4]
var KeyVaultSubscriptionId = split(KeyVaultResourceId, '/')[2]


module hostPool 'modules/hostPool.bicep' = {
  name: 'HostPool_UpdateRegistrationToken_${Timestamp}'
  scope: resourceGroup(HostPoolResourceGroupName)
  params: {
    CustomRdpProperty: HostPoolCustomRdpProperty
    Description: HostPoolDescription
    FriendlyName: HostPoolFriendlyName
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    LoadBalancerType: HostPoolLoadBalancerType
    Location: HostPoolLocation
    MaxSessionLimit: HostPoolMaxSessionLimit
    PreferredAppGroupType: HostPoolPreferredAppGroupType
    StartVmOnConnect: HostPoolStartVmOnConnect
    Tags: HostPoolTags
    ValidationEnvironment: HostPoolValidationEnvironment
    VmTemplate: HostPoolVmTemplate
  }
}

@batchSize(1)
module sessionHosts 'modules/sessionHosts.bicep' = [for i in range(1, SessionHostBatchCount): {
  name: 'SessionHosts_${i}_${Timestamp}'
  scope: resourceGroup(VirtualMachineResourceGroupName)
  params: {
    Availability: Availability
    AvailabilitySetNamePrefix: AvailabilitySetNamePrefix
    AvailabilitySetCount: AvailabilitySetCount
    AvailabilityZones: AvailabilityZones
    DiskNamePrefix: DiskNamePrefix
    DiskSku: DiskSku
    DomainName: DomainName
    DomainServices: DomainServices
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: HostPoolResourceGroupName
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersion: ImageVersion
    KeyVaultName: KeyVaultName
    KeyVaultResourceGroupName: KeyVaultResourceGroupName
    KeyVaultSubscriptionId: KeyVaultSubscriptionId
    Location: VirtualMachineLocation
    NetworkInterfaceNamePrefix: NetworkInterfaceNamePrefix
    SessionHostOuPath: SessionHostOuPath
    SessionHostCount: i == SessionHostBatchCount && DivisionRemainderValue > 0 ? DivisionRemainderValue : MaxResourcesPerTemplateDeployment
    SessionHostIndex: i == 1 ? SessionHostIndex : ((i - 1) * MaxResourcesPerTemplateDeployment) + SessionHostIndex
    SubnetResourceId: SubnetResourceId
    Timestamp: Timestamp
    TrustedLaunch: TrustedLaunch
    VirtualMachineNamePrefix: VirtualMachineNamePrefix
    VirtualMachineSize: VirtualMachineSize
    VirtualMachineTags: VirtualMachineTags
    ImageId : ImageId
  }
  dependsOn: [
    hostPool
  ]
}]
