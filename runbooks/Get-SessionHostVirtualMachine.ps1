[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$HostpoolName,
    [parameter(mandatory = $true)]$Environment,
    [parameter(mandatory = $true)]$subscriptionId
)

# Connect using a Managed Service Identity
try
{
    $AzureContext = (Connect-AzAccount -Identity -Environment $Environment -SubscriptionId $subscriptionId).context
}
catch
{
    Write-Output "There is no system-assigned user identity. Aborting.";
    exit
}


$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

# Getting the hostpool first
$hostpool = Get-AzWvdHostPool | Where-Object { $_.Name -eq $hostpoolname }

if ($null -eq $hostpool)
{
    "Hostpool $hostpoolname not found"
    exit;
}

$hostpoolRg = ($hostpool).id.split("/")[4]

# Select a VM in hostpool
$sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $hostpoolRg -HostPoolName $hostpoolName
$existingSessionHost = ($sessionHosts[0].Name.Split("/")[-1]).Split(".")[0]
$productionVirtualMachine = Get-AzVM -Name $existingSessionHost

$objOut = [PSCustomObject]@{
    productionVm = $productionVirtualMachine.Name
	productionVmRg = $productionVirtualMachine.ResourceGroupName
    hostPool = $hostPoolName
}
Write-Output ( $objOut | ConvertTo-Json)
