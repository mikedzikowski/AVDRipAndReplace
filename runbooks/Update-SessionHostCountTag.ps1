[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$HostpoolName,
    [parameter(mandatory = $true)]$Environment
)


# Connect using a Managed Service Identity
try
{
    $AzureContext = (Connect-AzAccount -Identity -Environment $Environment).context
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

$hostpoolId = (Get-AzResourceGroup -Name $hostpoolRg).ResourceId

$sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $hostpoolRg -HostPoolName $hostpoolName
$tags = (Get-AzResourceGroup -Name $hostpoolRg).Tags
$Tags.Remove('SessionHostCount')
$Tags +=@{SessionHostCount = $sessionHosts.count}

Update-AzTag -resourceId $hostpoolId -Tag $Tags -operation Replace


