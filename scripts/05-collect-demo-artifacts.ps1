<#
.SYNOPSIS
    Collects demo artifacts and screenshots by querying Azure resources.

.DESCRIPTION
    Gathers deployment outputs, session host status, and resource details
    into a local artifacts folder for pre-demo validation and fallback use.

.PARAMETER ResourceGroupName
    Resource group containing AVD demo resources.

.PARAMETER OutputPath
    Local folder to save collected artifacts. Defaults to .\artifacts.

.EXAMPLE
    .\05-collect-demo-artifacts.ps1 -ResourceGroupName "rg-avd-azurelocal-demo"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    [string] $OutputPath = '.\artifacts'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step  { param ([string] $M) Write-Host "`n==> $M" -ForegroundColor Cyan }
function Write-Success { param ([string] $M) Write-Host "    [OK] $M" -ForegroundColor Green }

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Step "Collecting host pool information"
$hostPools = az desktopvirtualization hostpool list `
    --resource-group $ResourceGroupName `
    --output json | ConvertFrom-Json

foreach ($hp in $hostPools) {
    $hpName = $hp.name
    Write-Success "Host pool: $hpName"

    # Session hosts
    Write-Step "Collecting session hosts for $hpName"
    $sessionHosts = az desktopvirtualization hostpool show `
        --name $hpName `
        --resource-group $ResourceGroupName `
        --output json | ConvertFrom-Json

    $sessionHosts | ConvertTo-Json -Depth 10 |
        Set-Content -Path (Join-Path $OutputPath "$hpName-hostpool.json")
}

Write-Step "Collecting resource group resources"
az resource list --resource-group $ResourceGroupName --output json |
    ConvertFrom-Json | ConvertTo-Json -Depth 5 |
    Set-Content -Path (Join-Path $OutputPath "resource-list.json")

Write-Step "Collecting Arc VM status"
$arcVMs = az connectedmachine list --resource-group $ResourceGroupName --output json 2>$null
if ($arcVMs) {
    $arcVMs | Set-Content -Path (Join-Path $OutputPath "arc-vms.json")
    Write-Success "Arc VMs collected"
} else {
    Write-Host "    No Arc VMs found in resource group" -ForegroundColor Yellow
}

Write-Step "Artifacts collected to: $OutputPath"
Get-ChildItem -Path $OutputPath | Format-Table Name, Length, LastWriteTime
