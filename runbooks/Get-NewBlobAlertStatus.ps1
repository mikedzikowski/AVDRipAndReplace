[CmdletBinding()]
param (
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

# Sleeping to ensure data is ingested into workspace
while ($null -eq (($alert = Get-AzAlert | Where-Object {$_.Name -like "New blob uploaded to container*" -and $_.State -eq "New"} | Sort-Object -Property StartDateTime | Select-Object -Last 1 ))) {
Start-Sleep -Seconds 30
}

try
{
    # Loop until the alert is closed
    while ((($alert = Get-AzAlert | Where-Object {$_.Name -like "New blob uploaded to container*"} `
    | Sort-Object -Property StartDateTime | Select-Object -Last 1).State -eq "New") -and `
    ($null -eq ($comments = (Get-AzAlertObjectHistory -ResourceId $alert.id.split('/')[-1])[0] | Where-Object {$_.Comments -eq $null}))) {
        Start-Sleep -Seconds 5
    }
    Start-Sleep -Seconds 120
    $alert = (Get-AzAlert | Where-Object {($_.Name -like "New blob uploaded to container*") -and ($_.State -eq "Closed")} `
    | Sort-Object -Property StartDateTime | Select-Object -Last 1)
    $comments = (Get-AzAlertObjectHistory -ResourceId $alert.id.split('/')[-1]).Comments
    if($comments[0].contains("Approved")){
        $Approval = $true
    }
    else{
        $Approval = $false
    }
}
catch
{
    $Approval = $false
    throw
}

$objOut = [PSCustomObject]@{
    Approval = $Approval
}

Write-Output ( $objOut | ConvertTo-Json)