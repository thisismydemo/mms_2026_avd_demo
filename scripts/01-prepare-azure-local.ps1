<#
.SYNOPSIS
    Prepares an Azure Local cluster for Azure Virtual Desktop session host deployment.

.DESCRIPTION
    This script verifies Azure Local cluster health, confirms the Arc Resource Bridge
    is running, and ensures the required Azure resource providers are registered.

.PARAMETER SubscriptionId
    Azure subscription ID.

.PARAMETER ResourceGroupName
    Resource group that contains (or will contain) the AVD resources.

.PARAMETER ClusterName
    Name of the Azure Local cluster.

.PARAMETER Location
    Azure region (e.g. eastus).

.EXAMPLE
    .\01-prepare-azure-local.ps1 `
        -SubscriptionId "00000000-0000-0000-0000-000000000000" `
        -ResourceGroupName "rg-avd-azurelocal-demo" `
        -ClusterName "my-hci-cluster" `
        -Location "eastus"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string] $SubscriptionId,

    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory)]
    [string] $ClusterName,

    [Parameter(Mandatory)]
    [string] $Location
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helpers
function Write-Step {
    param ([string] $Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param ([string] $Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param ([string] $Message)
    Write-Host "    [WARN] $Message" -ForegroundColor Yellow
}
#endregion

#region Prerequisites check
Write-Step "Checking Azure PowerShell modules"
$requiredModules = @('Az.Accounts', 'Az.Resources', 'Az.StackHCI', 'Az.DesktopVirtualization')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Write-Warning "$module is not installed. Installing..."
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
    Write-Success "$module is available"
}
#endregion

#region Azure login
Write-Step "Connecting to Azure subscription $SubscriptionId"
$context = Get-AzContext
if (-not $context -or $context.Subscription.Id -ne $SubscriptionId) {
    Connect-AzAccount -Subscription $SubscriptionId | Out-Null
} else {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
}
Write-Success "Connected to subscription $SubscriptionId"
#endregion

#region Register resource providers
Write-Step "Registering required Azure resource providers"
$providers = @(
    'Microsoft.DesktopVirtualization',
    'Microsoft.HybridCompute',
    'Microsoft.AzureStackHCI',
    'Microsoft.Compute',
    'Microsoft.Network',
    'Microsoft.Storage',
    'Microsoft.KeyVault',
    'Microsoft.Insights',
    'Microsoft.ExtendedLocation'
)

foreach ($provider in $providers) {
    $state = (Get-AzResourceProvider -ProviderNamespace $provider).RegistrationState | Select-Object -First 1
    if ($state -ne 'Registered') {
        Write-Warning "$provider is $state – registering..."
        Register-AzResourceProvider -ProviderNamespace $provider | Out-Null
    }
    Write-Success "$provider is registered"
}
#endregion

#region Check Azure Local cluster
Write-Step "Checking Azure Local cluster: $ClusterName"
try {
    $cluster = Get-AzStackHciCluster -ResourceGroupName $ResourceGroupName -Name $ClusterName -ErrorAction Stop
    $status = $cluster.Status
    Write-Host "    Cluster status: $status"
    if ($status -ne 'Succeeded') {
        Write-Warning "Cluster status is '$status'. Expected 'Succeeded'. Proceed with caution."
    } else {
        Write-Success "Cluster is healthy"
    }
} catch {
    Write-Warning "Could not retrieve cluster details: $_"
    Write-Warning "Ensure the cluster exists in resource group '$ResourceGroupName'."
}
#endregion

#region Check Arc Resource Bridge
Write-Step "Checking Arc Resource Bridge in resource group: $ResourceGroupName"
try {
    $arb = Get-AzResource -ResourceGroupName $ResourceGroupName `
        -ResourceType 'Microsoft.ResourceConnector/appliances' -ErrorAction SilentlyContinue
    if ($arb) {
        Write-Success "Arc Resource Bridge found: $($arb.Name) – Status: $($arb.Properties.status)"
    } else {
        Write-Warning "No Arc Resource Bridge found in '$ResourceGroupName'. Verify the cluster is fully deployed."
    }
} catch {
    Write-Warning "Unable to query Arc Resource Bridge: $_"
}
#endregion

#region Summary
Write-Step "Preparation complete"
Write-Host @"

  Subscription : $SubscriptionId
  Resource Group: $ResourceGroupName
  Cluster       : $ClusterName
  Location      : $Location

Next step: Run .\02-deploy-avd-infrastructure.ps1
"@
#endregion
