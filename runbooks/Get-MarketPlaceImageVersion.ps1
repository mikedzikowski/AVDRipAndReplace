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

$Versions = (Get-AzVMImage -Location $hostpoolVm.Location -PublisherName $hostpoolVm.StorageProfile.ImageReference.Publisher -Offer $hostpoolVm.StorageProfile.ImageReference.Offer -Sku $hostpoolVm.StorageProfile.ImageReference.Sku).Version

$VersionDates = @()
foreach($Version in $Versions)
{
    $VersionDates += $Version.Split('.')[-1]
}

$LatestVersionDate = $VersionDates | Sort-Object -Descending | Select-Object -First 1

[string]$LatestVersion = $Versions -like "*$LatestVersionDate"

if ($LatestVersion.Split('.')[-1] -gt $hostpoolVm.StorageProfile.ImageReference.ExactVersion.Split('.')[-1])
{
    $newImageFound = $true
}
else
{
    $newImageFound = $false
}

$objOut = [PSCustomObject]@{
    NewImageFound = $newImageFound
    ImageVersion = $LatestVersion
}

Write-Output ( $objOut | ConvertTo-Json)