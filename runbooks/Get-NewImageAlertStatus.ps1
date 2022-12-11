
[CmdletBinding()]
param (
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

try
{
    # Loop until the alert is closed
    while ((Get-AzAlert | Where-Object {$_.Name -like "New Image Found for AVD Environment"}).State -eq "Open") {
        Write-Output "Alert New Image Found for AVD Environment:" ((Get-AzAlert | Where-Object {$_.Name -like "New Image Found for AVD Environment"})).State
        Start-Sleep -Seconds 1
    }
}
catch
{
    Write-Output "Alert: New Image Found for AVD Environment not triggered or found $_"
    throw
}