[Cmdletbinding()]
param(
    [parameter(Mandatory=$false)]
    [string]$AvailabilitySetNamePrefix,

    [parameter(Mandatory)]
    [string]$DiskNamePrefix,    

    [parameter(Mandatory)]
    [ValidateSet('AzureCloud','AzureUSGovernment', 'AzureChinaCloud', 'AzureGermanCloud')]
    [string]$Environment,

    [parameter(Mandatory)]
    [string]$HostPoolName,

    [parameter(Mandatory)]
    [string]$HostPoolResourceGroupName,

    [parameter(Mandatory)]
    [string]$KeyVaultResourceId,

    [parameter(Mandatory)]
    [string]$NetworkInterfaceNamePrefix,

    [parameter(Mandatory)]
    [string]$SubscriptionId,

    [parameter(Mandatory)]
    [string]$TemplateSpecName,

    [parameter(Mandatory)]
    [string]$TemplateSpecVersion,

    [parameter(Mandatory)]
    [string]$TenantId,

    [parameter(Mandatory)]
    [string]$VirtualMachineNamePrefix,

    [parameter(Mandatory)]
    [string]$ImageSource

)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

try
{
    # Set Context to Subscription for AVD deployment
    Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId -Tenant $TenantId
    Write-Host 'Connected to Azure.'

    # Get Host Pool Information
    $HostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $HostPoolResourceGroupName
    
    # Get Virtual Machine Information
    $VirtualMachineResourceId = (Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolResourceGroupName)[0].ResourceId
    $VirtualMachineResourceGroupName = $VirtualMachineResourceId.Split('/')[4]
    $VirtualMachineName = $VirtualMachineResourceId.Split('/')[8].Split('.')[0]
    $VirtualMachine = Get-AzVm -ResourceGroupName $VirtualMachineResourceGroupName -Name $VirtualMachineName

    # Get Domain Services Value
    if($VirtualMachine.Extensions.VirtualMachineExtensionType -contains 'JsonADDomainExtension')
    {
        $DomainServices = 'ActiveDirectory'
        $ADDomainExtension = ($VirtualMachine.Extensions | Where-Object {$_.VirtualMachineExtensionType -eq 'JsonADDomainExtension'}).Settings
        $ADDomainString = "{$ADDomainExtension}"
        $ADDomainJSON = $ADDomainString -replace '" "', '", "' 
        $ADDomainProperties = $ADDomainJSON | ConvertFrom-Json
    }
    elseif($VirtualMachine.Extensions.VirtualMachineExtensionType -contains 'AADLoginForWindows')
    {
        $AADJExtension = ($VirtualMachine.Extensions | Where-Object {$_.VirtualMachineExtensionType -eq 'AADLoginForWindows'}).Settings
        $AADJString = "{$AADJExtension}"
        $AADJJSON = $AADJString -replace '" "', '", "' 
        $AADJProperties = $AADJJSON | ConvertFrom-Json
        if($AADJProperties.mdmId)
        {
            $DomainServices = 'NoneWithIntune'
        }
        else 
        {
            $DomainServices = 'None'
        }
    }

    # Get Disk Information
    $DiskName = $VirtualMachine.StorageProfile.OsDisk.ManagedDisk.Id.Split('/')[8]
    $DiskResourceGroupName = $VirtualMachine.StorageProfile.OsDisk.ManagedDisk.Id.Split('/')[4]
    $Disk = Get-AzDisk -ResourceGroupName $DiskResourceGroupName -DiskName $DiskName

    # Get Availability Information
    if($VirtualMachine.Zones)
    {
        [array]$SessionHosts = (Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolResourceGroupName).ResourceId
        $Zones = @()
        foreach($SessionHost in $SessionHosts)
        {
            $ResourceGroupName = $SessionHost.Split('/')[4]
            $Name = $SessionHost.Split('/')[8].Split('.')[0]
            $Zones += (Get-AzVm -ResourceGroupName $ResourceGroupName -Name $Name).Zones
        }
        $AvailabilityZones = $Zones | Select-Object -Unique | Sort-Object
        $Availability = 'AvailabilityZones'
    }
    elseif ($VirtualMachine.AvailabilitySetReference)
    {
        $Availability = 'AvailabilitySet'
    }
    else 
    {
        $Availability = 'None'
    }

    # Get Network Interface Information
    $NetworkInterface = Get-AzNetworkInterface -ResourceId $VirtualMachine.NetworkProfile.NetworkInterfaces[0].Id
    $SubnetResourceId = $NetworkInterface.IpConfigurations[0].Subnet.Id

    # Update default values for params in JSON template
    $TemplateJson = Get-Content -Path .\solution.json
    $Template = $TemplateJson | ConvertFrom-Json
    $Template.parameters.Availability.defaultValue = $Availability
    if($VirtualMachine.Zones)
    {
        $Template.parameters.AvailabilityZones.defaultValue = $AvailabilityZones
    }
    $Template.parameters.DiskNamePrefix.defaultValue = $DiskNamePrefix
    $Template.parameters.DiskSku.defaultValue = $Disk.Sku.Name
    if($VirtualMachine.Extensions.VirtualMachineExtensionType -contains 'JsonADDomainExtension')
    {
        $Template.parameters.DomainName.defaultValue = $ADDomainProperties.Name
    }
    $Template.parameters.DomainServices.defaultValue = $DomainServices
    $Template.parameters.HostPoolCustomRdpProperty.defaultValue = $HostPool.CustomRdpProperty
    if($HostPool.Description)
    {
        $Template.parameters.HostPoolDescription.defaultValue = $HostPool.Description
    }
    if($HostPool.FriendlyName)
    {
        $Template.parameters.HostPoolFriendlyName.defaultValue = $HostPool.FriendlyName
    }
    $Template.parameters.HostPoolLoadBalancerType.defaultValue = $HostPool.LoadBalancerType.ToString()
    $Template.parameters.HostPoolLocation.defaultValue = $HostPool.Location
    $Template.parameters.HostPoolMaxSessionLimit.defaultValue = $HostPool.MaxSessionLimit
    $Template.parameters.HostPoolName.defaultValue = $HostPool.Name
    $Template.parameters.HostPoolPreferredAppGroupType.defaultValue = $HostPool.PreferredAppGroupType.ToString()
    $Template.parameters.HostPoolResourceGroupName.defaultValue = $HostPool.Id.Split('/')[4]
    $Template.parameters.HostPoolStartVmOnConnect.defaultValue = $HostPool.StartVMOnConnect
    $Template.parameters.HostPoolTags.defaultValue = (Get-AzResource -ResourceId $HostPool.Id).Tags
    $Template.parameters.HostPoolType.defaultValue = $HostPool.HostPoolType.ToString()
    $Template.parameters.HostPoolValidationEnvironment.defaultValue = $HostPool.ValidationEnvironment
    $Template.parameters.HostPoolVmTemplate.defaultValue = $HostPool.VMTemplate
    if($ImageSource -eq "marketplace")
    {
    $Template.parameters.ImageOffer.defaultValue = $VirtualMachine.StorageProfile.ImageReference.Offer
    $Template.parameters.ImagePublisher.defaultValue = $VirtualMachine.StorageProfile.ImageReference.Publisher
    $Template.parameters.ImageSku.defaultValue = $VirtualMachine.StorageProfile.ImageReference.SKU
    $Template.parameters.ImageVersion.defaultValue = 'latest'
    $Template.parameters.ImageId.defaultValue = ''
    }
    if($ImageSource -eq "aib")
    {
    $Template.parameters.ImageId.defaultValue = $VirtualMachine.StorageProfile.ImageReference.Id
    $Template.parameters.ImageOffer.defaultValue = ''
    $Template.parameters.ImagePublisher.defaultValue = ''
    $Template.parameters.ImageSku.defaultValue = ''
    $Template.parameters.ImageVersion.defaultValue = ''
    }
    $Template.parameters.KeyVaultResourceId.defaultValue = $KeyVaultResourceId
    $Template.parameters.NetworkInterfaceNamePrefix.defaultValue = $NetworkInterfaceNamePrefix
    $Template.parameters.SessionHostCount.defaultValue = 1
    $Template.parameters.SessionHostIndex.defaultValue = 0
    if($VirtualMachine.Extensions.VirtualMachineExtensionType -contains 'JsonADDomainExtension')
    {
        $Template.parameters.SessionHostOuPath.defaultValue = $ADDomainProperties.OuPath
    }
    $Template.parameters.SubnetResourceId.defaultValue = $SubnetResourceId
    if($VirtualMachine.SecurityProfile.SecurityType -eq 'TrustedLaunch')
    {
        $Template.parameters.TrustedLaunch.defaultValue = $true
    }
    $Template.parameters.VirtualMachineLocation.defaultValue = $VirtualMachine.Location
    $Template.parameters.VirtualMachineNamePrefix.defaultValue = $VirtualMachineNamePrefix
    $Template.parameters.VirtualMachineResourceGroupName.defaultValue = $VirtualMachine.ResourceGroupName
    $Template.parameters.VirtualMachineSize.defaultValue = $VirtualMachine.HardwareProfile.VmSize
    $Template.parameters.VirtualMachineTags.defaultValue = $VirtualMachine.Tags
    $Template | ConvertTo-Json -Depth 50 | Out-File -FilePath '.\solution.json' -Force
    Write-Host 'Updated the default values on the template file to support the Rip & Replace solution.'

    # Create template spec with a custom UI definition in the management resource group
    New-AzTemplateSpec `
        -Location $HostPool.Location `
        -ResourceGroupName $HostPoolResourceGroupName `
        -Name $TemplateSpecName `
        -Version $TemplateSpecVersion `
        -TemplateFile .\solution.json `
        -Force | Out-Null
    Write-Host "Created or updated the template spec in the following resource group: $HostPoolResourceGroupName."
}
catch
{
    $_ | Select-Object *
}