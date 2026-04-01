<#
.SYNOPSIS
    Post-deployment configuration for AVD session hosts on Azure Local.

.DESCRIPTION
    Verifies session host registration, assigns users to the app group,
    and optionally enables AVD Insights (Azure Monitor integration).

.PARAMETER ResourceGroupName
    Resource group containing the AVD resources.

.PARAMETER HostPoolName
    Name of the AVD host pool.

.PARAMETER AppGroupName
    Name of the AVD application group. Defaults to 'ag-mms-demo'.

.PARAMETER UserPrincipalName
    UPN of the test user to assign to the app group (optional).

.PARAMETER EnableInsights
    If specified, configures AVD Insights diagnostics settings.

.PARAMETER LogAnalyticsWorkspaceId
    Log Analytics workspace resource ID (required when EnableInsights is set).

.EXAMPLE
    .\03-configure-session-hosts.ps1 `
        -ResourceGroupName "rg-avd-azurelocal-demo" `
        -HostPoolName "hp-mms-demo" `
        -UserPrincipalName "demo.user@contoso.com" `
        -EnableInsights
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory)]
    [string] $HostPoolName,

    [string] $AppGroupName = 'ag-mms-demo',

    [string] $UserPrincipalName,

    [switch] $EnableInsights,

    [string] $LogAnalyticsWorkspaceId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helpers
function Write-Step    { param ([string] $M) Write-Host "`n==> $M" -ForegroundColor Cyan }
function Write-Success { param ([string] $M) Write-Host "    [OK] $M"   -ForegroundColor Green }
function Write-Warn    { param ([string] $M) Write-Host "    [WARN] $M" -ForegroundColor Yellow }
#endregion

#region Check session host health
Write-Step "Checking session host status in host pool: $HostPoolName"

$sessionHosts = Get-AzWvdSessionHost `
    -ResourceGroupName $ResourceGroupName `
    -HostPoolName      $HostPoolName

if (-not $sessionHosts) {
    Write-Warn "No session hosts found. Deployment may still be in progress."
} else {
    foreach ($host in $sessionHosts) {
        $name   = $host.Name.Split('/')[1]
        $status = $host.Status
        $color  = if ($status -eq 'Available') { 'Green' } else { 'Yellow' }
        Write-Host "    $name  →  $status" -ForegroundColor $color
    }
    $unavailable = $sessionHosts | Where-Object { $_.Status -ne 'Available' }
    if ($unavailable) {
        Write-Warn "$($unavailable.Count) session host(s) are not Available yet."
    } else {
        Write-Success "All session hosts are Available"
    }
}
#endregion

#region Assign user to app group
if ($UserPrincipalName) {
    Write-Step "Assigning '$UserPrincipalName' to app group '$AppGroupName'"

    $user = Get-AzADUser -UserPrincipalName $UserPrincipalName -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Warn "User '$UserPrincipalName' not found in Entra ID. Skipping assignment."
    } else {
        $appGroupResourceId = (Get-AzWvdApplicationGroup `
            -ResourceGroupName $ResourceGroupName `
            -Name              $AppGroupName).Id

        $existingAssignment = Get-AzRoleAssignment `
            -ObjectId           $user.Id `
            -RoleDefinitionName 'Desktop Virtualization User' `
            -Scope              $appGroupResourceId `
            -ErrorAction        SilentlyContinue

        if ($existingAssignment) {
            Write-Success "User already has Desktop Virtualization User on $AppGroupName"
        } else {
            New-AzRoleAssignment `
                -ObjectId           $user.Id `
                -RoleDefinitionName 'Desktop Virtualization User' `
                -Scope              $appGroupResourceId | Out-Null
            Write-Success "Role assignment created for $UserPrincipalName"
        }
    }
}
#endregion

#region Enable AVD Insights
if ($EnableInsights) {
    Write-Step "Configuring AVD Insights diagnostics"

    if (-not $LogAnalyticsWorkspaceId) {
        # Try to find a Log Analytics workspace in the resource group
        $law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($law) {
            $LogAnalyticsWorkspaceId = $law.ResourceId
            Write-Success "Found Log Analytics workspace: $($law.Name)"
        } else {
            Write-Warn "No Log Analytics workspace found and -LogAnalyticsWorkspaceId not provided. Skipping Insights config."
            $EnableInsights = $false
        }
    }

    if ($EnableInsights -and $LogAnalyticsWorkspaceId) {
        $hostPoolResourceId = (Get-AzWvdHostPool `
            -ResourceGroupName $ResourceGroupName `
            -Name              $HostPoolName).Id

        $diagnosticSettings = @{
            ResourceId            = $hostPoolResourceId
            WorkspaceId           = $LogAnalyticsWorkspaceId
            Name                  = 'avd-insights-diag'
            Category              = @('Checkpoint', 'Error', 'Management', 'Connection', 'HostRegistration', 'AgentHealthStatus')
        }

        Set-AzDiagnosticSetting @diagnosticSettings | Out-Null
        Write-Success "Diagnostic settings configured on host pool $HostPoolName"
    }
}
#endregion

#region Summary
Write-Step "Session host configuration complete"
Write-Host @"

  Resource Group : $ResourceGroupName
  Host Pool      : $HostPoolName
  App Group      : $AppGroupName

Next step: Run .\04-validate-deployment.ps1
"@
#endregion
