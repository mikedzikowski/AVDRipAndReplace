[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [string]$HostPoolName,

    [Parameter(Mandatory)]
    [string]$KeyVault,

    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$TemplateSpecId,

    [Parameter(Mandatory)]
    [string]$TenantId,

    [Parameter(mandatory = $true)]
    [string]$AutomationAccountName,

    [Parameter(mandatory = $true)]
    [string]$AutomationAccountResourceGroupName,

    [Parameter(mandatory = $true)]
    [string]$ScheduleName
)

$ErrorActionPreference = 'Stop'

Disable-AzContextAutosave `
    –Scope Process

Connect-AzAccount `
    -Environment $Environment `
    -Identity `
    -Subscription $SubscriptionId `
    -Tenant $TenantId

# Get the host pool's info
$HostPool = Get-AzResource -ResourceType 'Microsoft.DesktopVirtualization/hostpools' | Where-Object {$_.Name -eq $HostPoolName}
$HostPoolResourceGroup = $HostPool.ResourceGroupName
$HostPoolInfo = Get-AzWvdHostPool -ResourceGroupName $HostPoolResourceGroup -Name $HostPoolName
$AppGroupResourceId = $HostPoolInfo.ApplicationGroupReference[-1]
$SecurityPrincipalIds = @(Get-AzRoleAssignment -Scope $AppGroupResourceId -RoleDefinitionName 'Desktop Virtualization User').ObjectId
$HostPoolTags = $HostPool.Tags
$Configuration = $HostPoolTags.AvdConfiguration | ConvertFrom-Json
$SoftwareSettings = $HostPoolTags.AvdSoftware | ConvertFrom-Json
$TimeStamp = (Get-Date -Format 'yyyyMMddhhmmss')

# Get all session hosts
$SessionHosts = Get-AzWvdSessionHost `
    -ResourceGroupName $HostPoolResourceGroup `
    -HostPoolName $HostPoolName

$SessionHostsCount = $SessionHosts.count

# Get Virtal Network and Subnet
$sessionHostName = $SessionHosts[0].Name.split('/')[-1]
$vmName = $sessionHostName.split('.')[0]
$vM = Get-AzVm -Name $vmName
$nic = $vM.NetworkProfile.NetworkInterfaces
$networkInterface = ($nic.id -split '/')[-1]
$nicDetails = Get-AzNetworkInterface -Name $networkInterface

# Need to add keyvault to build and setting secrets to build
$SasToken = (Get-AzKeyVaultSecret -VaultName $KeyVault -Name "SasToken").SecretValue
$DomainJoinUser= (Get-AzKeyVaultSecret -VaultName $KeyVault -Name "DomainJoinUserPrincipalName" -AsPlainText)
$DomainJoinPassword =  (Get-AzKeyVaultSecret -VaultName $KeyVault -Name "DomainJoinPassword").SecretValue
$vmUser =  (Get-AzKeyVaultSecret -VaultName $KeyVault -Name "VmUsername" -AsPlainText)
$vmPassword =  (Get-AzKeyVaultSecret -VaultName $KeyVault -Name "VmPassword").SecretValue

# Get details for deployment params
$Params = @{
    AddOrReplaceSessionHosts = $true
    DeployAip = $SoftwareSettings.DeployAip
    DeployAppMaskingRules = $SoftwareSettings.DeployAppMaskingRules
    DeployProjectVisio = $SoftwareSettings.DeployProjectVisio
    DisaStigCompliance = $SoftwareSettings.DisaStigCompliance
    DiskSku = $Configuration.DiskSku
    DomainName = $Configuration.DomainName
    DomainServices = $Configuration.DomainServices
    Environment = $HostPoolName.Split('-')[4]
    HostPoolType = $HostPoolInfo.HostPoolType.ToString() + ' ' + $HostPoolInfo.LoadBalancerType.ToString()
    ImageOffer = $Configuration.Image.Split(':')[1]
    ImagePublisher = $Configuration.Image.Split(':')[0]
    ImageSku = $Configuration.Image.Split(':')[2]
    ImageVersion = 'latest'
    LogAnalyticsWorkspaceId = $HostPoolTags.AvdMonitoring
    MissionOwnerShortName = $HostPoolName.Split('-')[2]
    RecoveryServices = $Configuration.RecoveryServices
    ScreenCaptureProtection = $SoftwareSettings.ScreenCaptureProtection
    ScriptContainerUri = $HostPoolTags.AvdContainer
    SecurityPrincipalIds = @($SecurityPrincipalIds)
    SessionHostOuPath = $HostPoolTags.AvdOuPath
    StampIndex = $HostPoolName.Split('-')[5].ToInt32($null)
    TenantShortName = $HostPoolName.Split('-')[1]
    VmSize = $Configuration.VmSize
    SessionHostCount = $SessionHostsCount
    VirtualNetwork = ($nicdetails.IpConfigurations.subnet.Id -split '/')[-3]
    VirtualNetworkResourceGroup = ($nicdetails.IpConfigurations.subnet.Id -split '/')[-7]
    Subnet = ($nicdetails.IpConfigurations.subnet.Id -split '/')[-1]
    Timestamp = $TimeStamp
    ValidationEnvironment = $true
    ScriptContainerSasToken = $SasToken
    DomainJoinPassword = $DomainJoinPassword
    DomainJoinUserPrincipalName = $DomainJoinUser
    VmPassword = $vmPassword
    VmUserName =  $vmUser
}

# Put all session hosts in drain mode
foreach($SessionHost in $SessionHosts)
{
    Update-AzWvdSessionHost `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -Name $SessionHost.Id.Split('/')[-1] `
        -AllowNewSession:$false `
        | Out-Null
        $SessionHostsName = $SessionHost.Id.Split('/')[-1]
		$vmName = $SessionHostsName.Split('.')[0]
		$SessionHostsResourceGroup = (Get-azVm -name $vmName).ResourceGroupName
		$SessionHostsResourceGroupId = (Get-AzResourceGroup -name $SessionHostsResourceGroup).ResourceId
}

# Get all active sessions
$Sessions = Get-AzWvdUserSession `
    -ResourceGroupName $HostPoolResourceGroup `
    -HostPoolName $HostPoolName

# Send a message to any user with an active session
$Time = (Get-Date).ToUniversalTime().AddMinutes(15)
foreach($Session in $Sessions)
{
    $SessionHost = $Session.Id.split('/')[-3]
    $UserSessionId = $Session.Id.split('/')[-1]

    Write-Verbose "Sending maintenance message to user id: $($UserSessionId)"
    Send-AzWvdUserSessionMessage  `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -SessionHostName $SessionHost `
        -UserSessionId $UserSessionId `
        -MessageBody "Maintenance will begin in 15 minutes: $Time UTC. Please save your work and sign out. If you do not sign out within 15 minutes, your session will be terminated and you may lose your work." `
        -MessageTitle 'Upcoming Maintenance'
}

# Wait 15 minutes for all users to sign out
Start-Sleep -Seconds 900

# Force logout any leftover sessions
foreach($Session in $Sessions)
{
    $SessionHost = $Session.Id.split('/')[-3]
    $UserSessionId = $Session.Id.split('/')[-1]

    Remove-AzWvdUserSession  `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -SessionHostName $SessionHost `
        -Id $UserSessionId
    Write-Verbose "Logging out user id: $($UserSessionId)"
}

# Remove the session hosts from the Host Pool
foreach($SessionHost in $SessionHosts)
{
    Remove-AzWvdSessionHost `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName `
        -Name $SessionHost.Id.Split('/')[-1] `
        | Out-Null
    Write-Verbose "Removing session host $($SessionHost) from the pool $($HostPoolName)"
}

# Programmatically clean up resources in session host resource group
$asList = @()
foreach ($SessionHost in $SessionHosts)
{
    $SessionHostsName = $SessionHost.Id.Split('/')[-1]
    $vmName = $SessionHostsName.Split('.')[0]
    $virtualMachine = (Get-AzVM | Where-Object {$_.Name -eq $vmName})
    $networkInterfaces = $virtualMachine.NetworkProfile
    $vmNics = foreach($nic in $networkInterfaces.NetworkInterfaces.id) {(Get-AzResource -ResourceId $nic | Get-AzNetworkInterface)}
    $publicIps = foreach($nic in $vmNics) {(Get-AzPublicIpAddress | Where-Object {$_.id -eq $nic.ipconfigurations.publicIpAddress.id})}
    $resourceGroupName = $virtualMachine.ResourceGroupName
    $storageProfile = $virtualMachine.StorageProfile
    $dataDiskName = $storageProfile.DataDisks.Name
    $osDiskName = $storageProfile.OsDisk.Name
    if($virtualMachine.AvailabilitySetReference)
    {
        $availabilitySet = Get-AzAvailabilitySet -Name $virtualMachine.AvailabilitySetReference.Id.Split('/')[-1]
        $asList += $availabilitySet.Name
    }

    # Remove Data Disk from VM
    if($dataDiskName)
    {
        foreach($diskName in $dataDiskName)
        {
            Get-AzVM -Name $vmName -ResourceGroupName $resourceGroupName | Remove-AzVMDataDisk -DataDiskNames $diskName | Update-AzVM -Verbose
            Remove-AzDisk -DiskName $diskName -ResourceGroupName $resourceGroupName -Force -Verbose
        }
    }
    # Remove Virutal Machine
    if($virtualMachine)
    {
        Remove-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Force -WarningAction SilentlyContinue -Verbose
    }
    # Remove OS Diks
    if ($osDiskName)
    {
        Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $osDiskName| Remove-AzDisk -Force -Verbose
    }
    # Remove Network Interfaces
    if($vmNics)
    {
        foreach($vmNic in $vmNics)
        {
            Get-AzNetworkInterface -Name $vmNic.name -ResourceGroupName $vmNic.ResourceGroupName | Remove-AzNetworkInterface  -Force -Verbose
        }
    }
    # Remove Public Ip Addresses
    if($publicIps)
    {
        foreach($publicIp in $publicIps)
        {
            Remove-AzPublicIpAddress -Name $publicIp.Name -ResourceGroupName $publicIp.ResourceGroupName -Force -Verbose
        }
    }
}

# Remove Availability Sets
$availabilitySetsToRemove = $asList | Select-Object -Unique
foreach($availabilitySet in $availabilitySetsToRemove)
{
    $as = Get-AzAvailabilitySet -Name $availabilitySet
    Remove-AzAvailabilitySet -Name $availabilitySet -ResourceGroupName $as.ResourceGroupName -Force
}

Write-Verbose "Deploying new session hosts to the pool $($HostPoolName)"
# Deploy new session hosts to the host pool
New-AzSubscriptionDeployment `
    -Location $HostPool.Location `
    -Name $(Get-Date -F 'yyyyMMddHHmmss') `
    -TemplateSpecId $TemplateSpecId `
    @params

# Replacing Tags
Update-AzTag -ResourceId $SessionHostsResourceGroupId -Tag $HostPoolTags -Operation Replace

# Removing Azutomation Schedule
Remove-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ResourceGroupName $AutomationAccountResourceGroupName -Force