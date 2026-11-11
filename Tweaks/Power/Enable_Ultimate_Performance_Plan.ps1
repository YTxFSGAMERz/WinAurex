[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Enable Ultimate Performance Plan (Tweaks/Power/Enable_Ultimate_Performance_Plan.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

# 1. Check if Ultimate Performance is ALREADY the active scheme
$activeScheme = powercfg /getactivescheme
if ($activeScheme -match "Ultimate Performance") {
    Write-Host "`n[+] Ultimate Performance Plan is already active. No changes needed." -ForegroundColor Green
    Exit 0
}

# 2. Check if an Ultimate Performance scheme already exists on the system to avoid duplicate schemes
$schemes = powercfg /list
$existingGUID = $null
foreach ($line in ($schemes -split "`r?`n")) {
    if ($line -match "Power Scheme GUID:\s+([a-fA-F0-9\-]{36})\s+\(.*Ultimate Performance.*\)") {
        $existingGUID = $matches[1]
        break
    }
}

if ($existingGUID) {
    powercfg /setactive $existingGUID
    Write-Host "`n[SUCCESS] Activated existing Ultimate Performance Plan ($existingGUID)!" -ForegroundColor Green
    Write-Host "This ensures zero CPU throttling and maximum hardware responsiveness." -ForegroundColor Yellow
    Exit 0
}

# 3. Duplicate and activate scheme if not already present
$DuplicateOutput = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
$Success = ($LASTEXITCODE -eq 0)

if ($Success -and $DuplicateOutput -match "([a-fA-F0-9\-]{36})") {
    $PlanGUID = $matches[1]
    powercfg /setactive $PlanGUID
    Write-Host "`n[SUCCESS] Ultimate Performance Plan unlocked and set as active!" -ForegroundColor Green
    Write-Host "This ensures zero CPU throttling and maximum hardware responsiveness." -ForegroundColor Yellow
} else {
    Write-Host "`n[ERROR] Failed to duplicate the Ultimate Performance scheme." -ForegroundColor Red
}

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $null = [System.Console]::ReadLine()
}
