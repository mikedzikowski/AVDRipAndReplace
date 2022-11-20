param CustomRdpProperty string
param Description string
param FriendlyName string
param HostPoolName string
param HostPoolType string
param LoadBalancerType string
param Location string
param MaxSessionLimit int
param PreferredAppGroupType string
param StartVmOnConnect bool
param Tags object
param Timestamp string = utcNow('u')
param ValidationEnvironment bool
param VmTemplate string


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2022-04-01-preview' = {
  name: HostPoolName
  location: Location
  tags: Tags
  properties: {
    customRdpProperty: CustomRdpProperty
    description: Description
    friendlyName: FriendlyName
    hostPoolType: HostPoolType
    loadBalancerType: LoadBalancerType
    maxSessionLimit: MaxSessionLimit
    personalDesktopAssignmentType: null
    preferredAppGroupType: PreferredAppGroupType
    registrationInfo: {
      expirationTime: dateTimeAdd(Timestamp, 'PT2H')
      registrationTokenOperation: 'Update'
    }
    startVMOnConnect: StartVmOnConnect
    validationEnvironment: ValidationEnvironment
    vmTemplate: VmTemplate
  }
}
