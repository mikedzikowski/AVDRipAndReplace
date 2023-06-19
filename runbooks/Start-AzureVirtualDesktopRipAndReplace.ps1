[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [string]$HostPoolName,

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
    [string]$ScheduleName,

    [Parameter(mandatory = $true)]
    [string]$ImageSource,

    [parameter(mandatory = $false)]
    [string]$aibSubscription
)

$ErrorActionPreference = 'Stop'

try
{
    $AzureContext = (Connect-AzAccount -Identity -Environment $Environment).context
}
catch
{
    Write-Output "There is no system-assigned user identity. Aborting.";
    exit
}

try
{
    # Get the host pool's info
    $HostPool = Get-AzResource -ResourceType 'Microsoft.DesktopVirtualization/hostpools' | Where-Object {$_.Name -eq $HostPoolName}
    $HostPoolResourceGroup = $HostPool.ResourceGroupName
    $HostPoolTags = $HostPool.Tags
    $TimeStamp = (Get-Date -Format 'yyyyMMddhhmmss')

    # Get all session hosts
    $SessionHosts = Get-AzWvdSessionHost `
        -ResourceGroupName $HostPoolResourceGroup `
        -HostPoolName $HostPoolName

    $SessionHostsCount = $SessionHosts.count

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

    if($ImageSource -eq "gallery")
    {
        $hostpoolVm = Get-AzVM -ResourceGroupName $SessionHostsResourceGroup -Name $VmName
        
        # Set context to aib subscription
        Set-AzContext -SubscriptionId $aibSubscription

        $imageId = $hostpoolVm.StorageProfile.ImageReference.Id
        $id = $imageId
        $computeGallery= $id.Split("/")[8]
        $imageDef = $id.Split("/")[10]
        $galleryRg = $id.Split("/")[4]
        $ImageId = (Get-AzGalleryImageVersion -ResourceGroupName $galleryRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef).id[-1]
    }

    # Get details for deployment params
    if($ImageSource -eq "marketplace")
    {
        $Params = @{
            ImageVersion = 'latest'
            SessionHostCount = $SessionHostsCount
            Timestamp = $TimeStamp
            ImageSource = 'marketplace'
        }
    }
    else {
        $hostpoolVm = Get-AzVM -ResourceGroupName $SessionHostsResourceGroup -Name $VmName
        
        # Set context to aib subscription
        Set-AzContext -SubscriptionId $aibSubscription
        
        $Params = @{
            ImageId = ((Get-AzGalleryImageVersion -ResourceGroupName $galleryRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef)).id[-1]
            SessionHostCount = $SessionHostsCount
            Timestamp = $TimeStamp
        }
    }

    # Set context to management subscription 
    Set-AzContext -SubscriptionId $SubscriptionId

    # Scaling Plans
    $sp = Get-AzWvdScalingPlan -HostPoolName $HostPoolName -ResourceGroupName $HostPoolResourceGroup
    $hpreference = @()
    if($sp)
    {
        $scalingParams = @{
        FriendlyName = $sp.FriendlyName
        HostPoolType = $sp.HostPoolType
        Schedule = $sp.Schedule
        TimeZone = $sp.TimeZone
        ResourceGroupName = $sp.id.Split('/')[4]
        Name = $sp.Name
        Location = $sp.Location
        }
        foreach($hpr in $sp.HostPoolReference)
        {
            if($hpr.HostPoolArmPath.Contains($HostPoolName)) {
                $disabledSp =@(
                    @{'hostPoolArmPath' =  $hpr.HostPoolArmPath;
                    'scalingPlanEnabled' = $false;
                }
                )
                $hpreference += $disabledSp
            }
            else {
                $enabledSp= @(
                    @{'hostPoolArmPath' =  $hpr.HostPoolArmPath;
                    'scalingPlanEnabled' = $true;
                }
                )
                $hpreference += $enabledSp
            }
        }
    }

    # Disable Scaling Plan on Hostpool
    if($sp)
    {
        Update-AzWvdScalingPlan `
        -ResourceGroupName $scalingParams.ResourceGroupName `
        -Name $scalingParams.Name `
        -HostPoolReference @(
        $hpreference
        )
    }

    # Set parameters for re-enabling scaling plan
    $hpreference = $null
    foreach($hpr in $sp.HostPoolReference)
    {
        if($sp.HostPoolReference) {
            $enabledSp= @(
                @{'hostPoolArmPath' =  $hpr.HostPoolArmPath;
                'scalingPlanEnabled' = $true;
            }
            )
            $hpreference += $enabledSp
        }
    }

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
    $SessionHosts | ForEach-Object -parallel {
        $SessionHostsName = $_.Id.Split('/')[-1]
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
        # Remove OS Diks | Running an extra check incase OSDisk was deleted with VM
        if($osDiskName)
        {
            $diskCheck = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $osDiskName -ErrorAction SilentlyContinue
            if($diskCheck)
            {
                Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $osDiskName | Remove-AzDisk -Force -Verbose
            }
        }
        # Remove Network Interfaces | Running an extra check incase NIC was deleted with VM
        if($vmNics)
        {
            $nicCheck = Get-AzNetworkInterface -Name $vmNics.name -ResourceGroupName $vmNics.ResourceGroupName -ErrorAction SilentlyContinue
            if($nicCheck)
            {
                foreach($vmNic in $vmNics)
                {
                    Get-AzNetworkInterface -Name $vmNic.name -ResourceGroupName $vmNic.ResourceGroupName | Remove-AzNetworkInterface  -Force -Verbose
                }
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

    # Add scaling plan back to hostpool
    if($sp)
    {
       Update-AzWvdScalingPlan `
       -ResourceGroupName $scalingParams.ResourceGroupName `
       -Name $scalingParams.Name `
       -HostPoolReference @(
        $hpreference
        )
    }
    # Replacing Tags
    if($HostPoolTags)
    {
        Update-AzTag -ResourceId $SessionHostsResourceGroupId -Tag $HostPoolTags -Operation Replace
    }
    # Removing Azutomation Schedule
    Remove-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $ScheduleName -ResourceGroupName $AutomationAccountResourceGroupName -Force
    Write-Output "$HostPoolName | $HostPoolResourceGroup | AVD Rip & Replace succeeded."
}
catch
{
    Write-Output "$HostPoolName | $HostPoolResourceGroup | AVD Rip & Replace failed. Exception: $_"
    throw
}