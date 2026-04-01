<#
.SYNOPSIS
    Deploys the Azure Virtual Desktop infrastructure on Azure Local using Bicep templates.

.DESCRIPTION
    Creates the AVD resource group (if needed), then runs a Bicep deployment that
    provisions the host pool, app group, workspace, and Arc VM session hosts.

.PARAMETER SubscriptionId
    Azure subscription ID.

.PARAMETER ResourceGroupName
    Target resource group for AVD resources.

.PARAMETER Location
    Azure region for the AVD control-plane resources (e.g. eastus).

.PARAMETER ParameterFile
    Path to the .bicepparam file with deployment parameters.
    Defaults to .\bicep\parameters\demo.bicepparam.

.PARAMETER WhatIf
    If specified, runs az deployment group what-if only without deploying.

.EXAMPLE
    .\02-deploy-avd-infrastructure.ps1 `
        -SubscriptionId "00000000-0000-0000-0000-000000000000" `
        -ResourceGroupName "rg-avd-azurelocal-demo" `
        -Location "eastus"
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string] $SubscriptionId,

    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory)]
    [string] $Location,

    [string] $ParameterFile = '.\bicep\parameters\demo.bicepparam',

    [switch] $WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helpers
function Write-Step  { param ([string] $M) Write-Host "`n==> $M" -ForegroundColor Cyan }
function Write-Success { param ([string] $M) Write-Host "    [OK] $M" -ForegroundColor Green }
#endregion

$templateFile   = Join-Path $PSScriptRoot '..\bicep\main.bicep'
$parameterFile  = $ParameterFile
$deploymentName = "avd-demo-$(Get-Date -Format 'yyyyMMddHHmmss')"

#region Validate file paths
Write-Step "Validating file paths"
if (-not (Test-Path $templateFile)) {
    throw "Bicep template not found at: $templateFile"
}
if (-not (Test-Path $parameterFile)) {
    throw "Parameter file not found at: $parameterFile"
}
Write-Success "Template  : $templateFile"
Write-Success "Parameters: $parameterFile"
#endregion

#region Azure login
Write-Step "Setting Azure CLI subscription context"
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) { throw "Failed to set subscription. Run 'az login' first." }
Write-Success "Subscription set to $SubscriptionId"
#endregion

#region Create resource group
Write-Step "Ensuring resource group '$ResourceGroupName' exists in '$Location'"
az group create --name $ResourceGroupName --location $Location --output none
if ($LASTEXITCODE -ne 0) { throw "Failed to create/verify resource group." }
Write-Success "Resource group ready"
#endregion

#region What-If
Write-Step "Running deployment what-if preview"
az deployment group what-if `
    --resource-group $ResourceGroupName `
    --template-file  $templateFile `
    --parameters     $parameterFile `
    --name           $deploymentName

if ($WhatIf) {
    Write-Host "`nWhat-If mode: no changes deployed." -ForegroundColor Yellow
    exit 0
}
#endregion

#region Confirm and deploy
if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Deploy AVD infrastructure")) {
    $confirmation = Read-Host "`nDeploy changes above? [y/N]"
    if ($confirmation -notin @('y', 'Y', 'yes', 'Yes')) {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }

    Write-Step "Deploying Bicep stack (name: $deploymentName)"
    az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file  $templateFile `
        --parameters     $parameterFile `
        --name           $deploymentName `
        --output         table

    if ($LASTEXITCODE -ne 0) { throw "Deployment failed. Review error output above." }
    Write-Success "Deployment '$deploymentName' completed successfully"
}
#endregion

#region Output
Write-Step "Deployment complete"
Write-Host @"

  Resource Group : $ResourceGroupName
  Deployment     : $deploymentName

Next step: Run .\03-configure-session-hosts.ps1
"@
#endregion
