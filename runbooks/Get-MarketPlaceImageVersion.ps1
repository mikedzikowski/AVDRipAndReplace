[CmdletBinding()]
param (
    [parameter(mandatory = $false)]$VmName,
	[parameter(mandatory = $false)]$ResourceGroupName,
    [parameter(mandatory = $true)]$Environment,
    [parameter(mandatory = $false)]$ImageSource,
    [parameter(mandatory = $false)]$aibSubscription
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

    $versions = (Get-AzVMImage -Location $hostpoolVm.Location -PublisherName $hostpoolVm.StorageProfile.ImageReference.Publisher -Offer $hostpoolVm.StorageProfile.ImageReference.Offer -Sku $hostpoolVm.StorageProfile.ImageReference.Sku).Version

    $versionDates = @()
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
    $hostpoolVm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

    $AzureContext = Set-AzContext -SubscriptionId $aibSubscription

    $imageId = $hostpoolVm.StorageProfile.ImageReference.Id
    $id = $imageId
    $computeGallery= $id.Split("/")[8]
    $version = $id.Split("/")[12]
    $imageDef = $id.Split("/")[10]
    $galleryRg = $id.Split("/")[4]
    $vmImagePublishdate = (Get-AzGalleryImageVersion -ResourceGroupName $galleryRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef -name $version).PublishingProfile.PublishedDate

    $imageVersionPublishDate = (Get-AzGalleryImageVersion -ResourceGroupName $galleryRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef)

    foreach($date in $imageVersionPublishDate.PublishingProfile.PublishedDate)
    {
        if ($date -gt $vmImagePublishdate)
        {
            $galleryImageFound = $true
            Write-Host "true"
            $LatestVersion = ((Get-AzGalleryImageVersion -ResourceGroupName $galleryRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef) | Where-Object {$_.PublishingProfile.PublishedDate -eq $date}).name
        }
        else
        {
            $newImageFound = $false
            Write-Host "false"
            $LatestVersion = ((Get-AzGalleryImageVersion -ResourceGroupName $galleryRg -GalleryName $computeGallery -GalleryImageDefinitionName $imageDef) | Where-Object {$_.PublishingProfile.PublishedDate -eq $date}).name
        }
    }
}
if($galleryImageFound)
{
    $newImageFound = $true
}

$objOut = [PSCustomObject]@{
    NewImageFound = $newImageFound
    ImageVersion = $LatestVersion
}

Write-Output ( $objOut | ConvertTo-Json)
