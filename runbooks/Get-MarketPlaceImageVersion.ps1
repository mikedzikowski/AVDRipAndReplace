
[CmdletBinding()]
param (
    [parameter(mandatory = $true)]$VmName,
	[parameter(mandatory = $true)]$ResourceGroupName,
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

$hostpoolVm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

$versions = (Get-AzVMImage -Location $hostpoolVm.Location -PublisherName $hostpoolVm.StorageProfile.ImageReference.Publisher -Offer $hostpoolVm.StorageProfile.ImageReference.Offer -Sku $hostpoolVm.StorageProfile.ImageReference.Sku | Select-Object -Last 1).version

foreach ($version in $versions) {

    if ($version -gt $hostpoolVm.StorageProfile.ImageReference.ExactVersion)
    {
        $newImageFound = $true
    }
    else
    {
        $newImageFound = $false
    }
}

$objOut = [PSCustomObject]@{
    NewImageFound = $newImageFound
    ImageVersion = $versions
}

Write-Output ( $objOut | ConvertTo-Json)