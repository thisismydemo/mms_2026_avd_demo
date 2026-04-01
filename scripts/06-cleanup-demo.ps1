<#
.SYNOPSIS
    Cleans up demo resources after the session.

.DESCRIPTION
    Removes the AVD demo resource group and all resources within it.
    Does NOT remove the Azure Local cluster resource group.

.PARAMETER ResourceGroupName
    Resource group to delete. Defaults to rg-avd-azurelocal-demo.

.PARAMETER Force
    Skip confirmation prompt.

.EXAMPLE
    .\06-cleanup-demo.ps1 -ResourceGroupName "rg-avd-azurelocal-demo"
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step  { param ([string] $M) Write-Host "`n==> $M" -ForegroundColor Cyan }

Write-Step "Preparing to delete resource group: $ResourceGroupName"

# Safety check — refuse to delete common infrastructure resource groups
$protectedPatterns = @('*hci*', '*cluster*', '*infrastructure*', '*network*')
foreach ($pattern in $protectedPatterns) {
    if ($ResourceGroupName -like $pattern) {
        Write-Error "Resource group '$ResourceGroupName' matches protected pattern '$pattern'. Refusing to delete."
        return
    }
}

# List resources that will be deleted
Write-Step "Resources in '$ResourceGroupName' that will be deleted:"
az resource list --resource-group $ResourceGroupName --output table

if (-not $Force) {
    $confirmation = Read-Host "`nType the resource group name to confirm deletion"
    if ($confirmation -ne $ResourceGroupName) {
        Write-Host "Confirmation did not match. Cleanup cancelled." -ForegroundColor Yellow
        return
    }
}

if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Delete resource group")) {
    Write-Step "Deleting resource group '$ResourceGroupName'..."
    az group delete --name $ResourceGroupName --yes --no-wait
    Write-Host "`nDeletion initiated (running in background). Verify in the Azure portal." -ForegroundColor Green
    Write-Host "Note: Do NOT delete the Azure Local cluster resource group — it is shared infrastructure." -ForegroundColor Yellow
}
