[CmdletBinding()]
param (
    [parameter(mandatory = $false)]$VmName,
	[parameter(mandatory = $false)]$ResourceGroupName,
    [parameter(mandatory = $true)]$Environment,
    [parameter(mandatory = $false)]$ImageSource,
    [parameter(mandatory = $false)]$aibID
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

if($ImageSource -eq "marketplace")
{
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
}
else
{
    $id = "/subscriptions/f4972a61-1083-4904-a4e2-a790107320bf/resourceGroups/rg-aib-d-va/providers/Microsoft.Compute/galleries/cg_aib_d_va_t/images/Win10-21h2-o365/versions/0.25339.55539"
    $computeGallery= $id.Split("/")[8]
    $version = $id.Split("/")[12]
    $imageDef = $id.Split("/")[10]
    $aibRg = $id.Split("/")[4]

    $imageVersionPublishDate = (Get-AzGalleryImageVersion -ResourceGroupName $aibRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef)

    foreach($date in $imageVersionPublishDate.PublishingProfile.PublishedDate)
    {
        if ($date -lt (Get-date).addHours(-24))
        {
            $newImageFound = $false
            Write-Host "false"
        }
        else
        {
            $aibImageFound = $true
            Write-Host "true"
            $LatestVersion = ((Get-AzGalleryImageVersion -ResourceGroupName $aibRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef) | Where-Object {$_.PublishingProfile.PublishedDate -eq $date}).name
        }
    }
}
if($aibImageFound)
{
    $newImageFound = $true
}

$objOut = [PSCustomObject]@{
    NewImageFound = $newImageFound
    ImageVersion = $LatestVersion
}

Write-Output ( $objOut | ConvertTo-Json)
