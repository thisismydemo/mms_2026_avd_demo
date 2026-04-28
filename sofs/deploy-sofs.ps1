<#
.SYNOPSIS
    Deploy the MMS MOA 2026 SOFS supporting infrastructure cluster.

.DESCRIPTION
    Orchestrates deployment of the Scale-Out File Server (SOFS) cluster that
    provides FSLogix profile storage for the AVD Anywhere demo.

    This script:
      1. Validates prerequisites (Az PowerShell, git, variables.yml populated)
      2. Clones or updates AzureLocal/azurelocal-sofs-fslogix
      3. Copies sofs/variables.yml into the repo's config location
      4. Invokes the SOFS deployment (Deploy-SOFS-Azure.ps1 + Configure-SOFS-Cluster.ps1)

    SUPPORTING INFRASTRUCTURE — run this BEFORE the demo session, not during it.

.PARAMETER SofsRepoPath
    Path to clone/use the azurelocal-sofs-fslogix repo.
    Defaults to a 'sofs-deploy' folder in the system temp directory.

.PARAMETER SkipClone
    If the repo already exists at SofsRepoPath, skip git clone/pull.

.EXAMPLE
    .\sofs\deploy-sofs.ps1

.EXAMPLE
    .\sofs\deploy-sofs.ps1 -SofsRepoPath "C:\repos\azurelocal-sofs-fslogix"
#>
[CmdletBinding()]
param(
    [string] $SofsRepoPath = (Join-Path $env:TEMP "sofs-deploy\azurelocal-sofs-fslogix"),
    [switch] $SkipClone
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot    = Split-Path $PSScriptRoot -Parent
$VariablesYml = Join-Path $RepoRoot "sofs\variables.yml"
$SofsRepoUrl  = "https://github.com/AzureLocal/azurelocal-sofs-fslogix.git"

# ── Banner ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  MMS MOA 2026 — SOFS Supporting Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "  Demo: AVD Anywhere" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Validate variables.yml has no PLACEHOLDERs ───────────────────
Write-Host "[1/5] Validating sofs/variables.yml..." -ForegroundColor Yellow

if (-not (Test-Path $VariablesYml)) {
    Write-Error "sofs/variables.yml not found at: $VariablesYml"
    exit 1
}

$varContent = Get-Content $VariablesYml -Raw
$placeholders = [regex]::Matches($varContent, 'PLACEHOLDER[^\s"'']*')
if ($placeholders.Count -gt 0) {
    Write-Warning "variables.yml still contains $($placeholders.Count) PLACEHOLDER value(s):"
    $placeholders | Select-Object -ExpandProperty Value -Unique | ForEach-Object { Write-Warning "  - $_" }
    $continue = Read-Host "Continue anyway? (yes/no)"
    if ($continue -ne "yes") { exit 1 }
}
Write-Host "  OK — variables.yml loaded" -ForegroundColor Green

# ── Step 2: Validate Az PowerShell ──────────────────────────────────────────
Write-Host "[2/5] Checking Az PowerShell module..." -ForegroundColor Yellow
if (-not (Get-Module -Name Az.Accounts -ListAvailable)) {
    Write-Error "Az PowerShell module not found. Install with: Install-Module Az -Scope CurrentUser"
    exit 1
}
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Host "  No active Azure context — connecting..." -ForegroundColor Yellow
    Connect-AzAccount -Tenant "a9b67171-3fbb-45bf-8394-eb56d02a86e4"
}
Write-Host "  OK — Azure context: $($context.Account.Id)" -ForegroundColor Green

# ── Step 3: Clone or update the SOFS deployment repo ────────────────────────
Write-Host "[3/5] Preparing azurelocal-sofs-fslogix repo..." -ForegroundColor Yellow

if ($SkipClone -and (Test-Path $SofsRepoPath)) {
    Write-Host "  Skipping clone — using existing repo at: $SofsRepoPath" -ForegroundColor Yellow
} elseif (Test-Path $SofsRepoPath) {
    Write-Host "  Repo exists — pulling latest..." -ForegroundColor Yellow
    Push-Location $SofsRepoPath
    git pull --quiet
    Pop-Location
    Write-Host "  OK — repo updated" -ForegroundColor Green
} else {
    $parentDir = Split-Path $SofsRepoPath -Parent
    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir | Out-Null }
    Write-Host "  Cloning $SofsRepoUrl to $SofsRepoPath..." -ForegroundColor Yellow
    git clone $SofsRepoUrl $SofsRepoPath --quiet
    Write-Host "  OK — repo cloned" -ForegroundColor Green
}

# ── Step 4: Copy variables.yml to repo config location ──────────────────────
Write-Host "[4/5] Copying variables.yml to repo config..." -ForegroundColor Yellow

$destDir = Join-Path $SofsRepoPath "config\variables"
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }

$destYml = Join-Path $destDir "variables.yml"
Copy-Item -Path $VariablesYml -Destination $destYml -Force
Write-Host "  OK — copied to $destYml" -ForegroundColor Green

# ── Step 5: Invoke SOFS deployment ──────────────────────────────────────────
Write-Host "[5/5] Invoking SOFS deployment..." -ForegroundColor Yellow
Write-Host "  This will take approximately 45-60 minutes." -ForegroundColor Yellow
Write-Host ""

$invokeScript = Join-Path $SofsRepoPath "src\powershell\deploy\Invoke-SOFSDeployment.ps1"
if (-not (Test-Path $invokeScript)) {
    Write-Error "Invoke-SOFSDeployment.ps1 not found at: $invokeScript`nVerify the azurelocal-sofs-fslogix repo structure."
    exit 1
}

Push-Location $SofsRepoPath
try {
    & $invokeScript
} finally {
    Pop-Location
}

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  SOFS deployment complete" -ForegroundColor Green
Write-Host "  Cluster:     sofs-mms26-01" -ForegroundColor Green
Write-Host "  Share path:  \\sofsap-mms26-01\profiles" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run validation commands from sofs/README.md, then proceed" -ForegroundColor Cyan
Write-Host "      with AVD infrastructure deployment (scripts/02-deploy-avd-infrastructure.ps1)" -ForegroundColor Cyan
