<#
.SYNOPSIS
    Validates the full AVD on Azure Local deployment.

.DESCRIPTION
    Checks each layer of the deployment: Azure Local VMs, AVD host pool,
    session host registration, app group, and workspace. Outputs a summary
    with pass/fail indicators.

.PARAMETER ResourceGroupName
    Resource group containing all AVD resources.

.PARAMETER HostPoolName
    Name of the AVD host pool. Defaults to 'hp-mms-demo'.

.PARAMETER AppGroupName
    Name of the AVD application group. Defaults to 'ag-mms-demo'.

.PARAMETER WorkspaceName
    Name of the AVD workspace. Defaults to 'ws-mms-demo'.

.EXAMPLE
    .\04-validate-deployment.ps1 -ResourceGroupName "rg-avd-azurelocal-demo"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string] $ResourceGroupName,

    [string] $HostPoolName  = 'hp-mms-demo',
    [string] $AppGroupName  = 'ag-mms-demo',
    [string] $WorkspaceName = 'ws-mms-demo'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Result {
    param ([string] $Check, [bool] $Passed, [string] $Detail = '')
    $results.Add([PSCustomObject]@{
        Check  = $Check
        Status = if ($Passed) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
}

function Test-Resource {
    param ([string] $Check, [scriptblock] $ScriptBlock)
    try {
        $result = & $ScriptBlock
        Add-Result -Check $Check -Passed ($null -ne $result) -Detail ($result | Out-String).Trim()
    } catch {
        Add-Result -Check $Check -Passed $false -Detail $_.Exception.Message
    }
}

Write-Host "`nValidating AVD on Azure Local deployment..." -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName`n"

#region AVD Control Plane
Test-Resource "Host Pool exists" {
    Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $HostPoolName
}

Test-Resource "Application Group exists" {
    Get-AzWvdApplicationGroup -ResourceGroupName $ResourceGroupName -Name $AppGroupName
}

Test-Resource "Workspace exists" {
    Get-AzWvdWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
}
#endregion

#region Session Hosts
try {
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName

    if ($sessionHosts.Count -eq 0) {
        Add-Result -Check "Session hosts registered" -Passed $false -Detail "No session hosts found in host pool"
    } else {
        $availableCount = ($sessionHosts | Where-Object { $_.Status -eq 'Available' }).Count
        $totalCount     = $sessionHosts.Count
        Add-Result -Check "Session hosts registered" -Passed $true -Detail "$totalCount host(s) found"
        Add-Result -Check "Session hosts available"  -Passed ($availableCount -eq $totalCount) `
            -Detail "$availableCount / $totalCount available"
    }
} catch {
    Add-Result -Check "Session hosts registered" -Passed $false -Detail $_.Exception.Message
}
#endregion

#region Arc VMs
try {
    $arcVms = Get-AzResource -ResourceGroupName $ResourceGroupName `
        -ResourceType 'Microsoft.HybridCompute/machines' -ErrorAction SilentlyContinue
    if ($arcVms) {
        Add-Result -Check "Arc VMs present" -Passed $true -Detail "$($arcVms.Count) Arc machine(s) found"
    } else {
        Add-Result -Check "Arc VMs present" -Passed $false -Detail "No Arc machines found in resource group"
    }
} catch {
    Add-Result -Check "Arc VMs present" -Passed $false -Detail $_.Exception.Message
}
#endregion

#region App Group Role Assignments
try {
    $appGroupId  = (Get-AzWvdApplicationGroup -ResourceGroupName $ResourceGroupName -Name $AppGroupName).Id
    $assignments = Get-AzRoleAssignment -Scope $appGroupId -RoleDefinitionName 'Desktop Virtualization User'
    $hasDvuRole  = $assignments.Count -gt 0
    Add-Result -Check "App group has user assignments" -Passed $hasDvuRole `
        -Detail "$($assignments.Count) Desktop Virtualization User assignment(s)"
} catch {
    Add-Result -Check "App group has user assignments" -Passed $false -Detail $_.Exception.Message
}
#endregion

#region Print Results
$passCount = ($results | Where-Object { $_.Status -eq 'PASS' }).Count
$failCount = ($results | Where-Object { $_.Status -eq 'FAIL' }).Count

Write-Host "`n===== Validation Results =====" -ForegroundColor White
foreach ($r in $results) {
    $color = if ($r.Status -eq 'PASS') { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $r.Status, $r.Check) -ForegroundColor $color
    if ($r.Detail) {
        Write-Host ("        {0}" -f $r.Detail) -ForegroundColor Gray
    }
}

Write-Host ("`n  Passed: $passCount  Failed: $failCount") -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Yellow' })

if ($failCount -gt 0) {
    Write-Host "`nSome checks failed. Review the output above and consult docs/04-demo-walkthrough.md for troubleshooting." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nAll checks passed. The deployment is ready for the demo!" -ForegroundColor Green
#endregion
