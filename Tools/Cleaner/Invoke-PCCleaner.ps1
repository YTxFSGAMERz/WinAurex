<#
.SYNOPSIS
    Invoke-PCCleaner.ps1 - WinAurex Intelligent PC Storage Cleaner (Interactive CLI)
.DESCRIPTION
    Analyzes, categorizes, and forcefully cleans useless system junk, stale AI caches,
    crash dumps, updater leftovers, and obsolete app versions after user consent.
#>

[CmdletBinding()]
param(
    [switch]$ScanOnly,
    [switch]$ForceAll,
    [switch]$NoPause
)

# Auto-Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Administrator privileges required. Elevating..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ModulePath = Join-Path $PSScriptRoot "WinAurex-Cleaner.psm1"
if (-not (Test-Path $ModulePath)) {
    Write-Host "[ERROR] WinAurex-Cleaner.psm1 not found at $ModulePath" -ForegroundColor Red
    Pause
    exit 1
}

Import-Module $ModulePath -Force

function Show-CyberHeader {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor DarkCyan
    Write-Host "                WINAUREX - INTELLIGENT PC STORAGE CLEANER                " -ForegroundColor Cyan
    Write-Host "             Deep Junk Analysis & Forceful Multi-Tier Cleanup            " -ForegroundColor Gray
    Write-Host "==========================================================================" -ForegroundColor DarkCyan
    Write-Host ""
}

Show-CyberHeader

# Display Drive C: Status
$drive = Get-PSDrive C -ErrorAction SilentlyContinue
$totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
$usedGB  = [math]::Round($drive.Used / 1GB, 2)
$freeGB  = [math]::Round($drive.Free / 1GB, 2)
$freePct = [math]::Round(($drive.Free / ($drive.Used + $drive.Free)) * 100, 1)

Write-Host " [+] SYSTEM DRIVE C: STATUS:" -ForegroundColor Green
Write-Host "     Total Capacity : $totalGB GB" -ForegroundColor White
Write-Host "     Used Space     : $usedGB GB" -ForegroundColor Gray
Write-Host "     Free Space     : $freeGB GB ($freePct% free)" -ForegroundColor Cyan
Write-Host ""
Write-Host " [*] Scanning storage tiers (Temp, CrashDumps, AI Indexes, Squirrel, Caches)..." -ForegroundColor Yellow

$analysis = Get-WinAurexJunkAnalysis

Write-Host ""
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ("{0,-3} {1,-42} {2,12}  {3,-12}" -f "#", "CATEGORY", "RECLAIMABLE", "RISK LEVEL") -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

$idx = 1
$totalReclaimableBytes = 0L

foreach ($item in $analysis) {
    $color = if ($item.Safety -eq "Zero Risk") { "Green" } elseif ($item.Safety -eq "Low Risk") { "Yellow" } else { "Magenta" }
    Write-Host ("[{0}] {1,-42} {2,12}  " -f $idx, $item.Category, $item.SizeText) -NoNewline
    Write-Host ("{0,-12}" -f $item.Safety) -ForegroundColor $color
    if ($item.Id -ne "ComponentStore") {
        $totalReclaimableBytes += $item.SizeBytes
    }
    $idx++
}

Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " [!] TOTAL RECLAIMABLE SPACE (Safe Tiers): $(Format-Bytes $totalReclaimableBytes)" -ForegroundColor Green
Write-Host " [i] PROTECTED: Downloads, Photos/Pictures, Virtual Machines, Git Repos" -ForegroundColor Gray
Write-Host ""

if ($ScanOnly) {
    Write-Host "Scan-only mode completed." -ForegroundColor Cyan
    if (-not $NoPause) { Read-Host "Press Enter to exit..." }
    exit 0
}

# Interactive Consent Menu
Write-Host "SELECT CLEANING ACTION:" -ForegroundColor White
Write-Host " [1] Clean All Recommended (Safe Tiers: Temp, Dumps, AI, Squirrel, Dev, Browser)" -ForegroundColor Green
Write-Host " [2] Maximum Deep Clean (Recommended + DISM Windows Component Store)" -ForegroundColor Yellow
Write-Host " [3] Select Specific Categories Manually" -ForegroundColor Cyan
Write-Host " [Q] Cancel & Exit" -ForegroundColor Red
Write-Host ""

if ($ForceAll) {
    $choice = "1"
} else {
    $choice = Read-Host "Enter your choice [1/2/3/Q]"
}

$selectedCategories = @()

switch ($choice.Trim().ToUpper()) {
    "1" {
        $selectedCategories = @("SystemTemp", "CrashDumps", "AIIndexCaches", "AppUpdaters", "SquirrelVersions", "LooseInstallers", "BrowserCaches", "DevCaches")
    }
    "2" {
        $selectedCategories = @("SystemTemp", "CrashDumps", "AIIndexCaches", "AppUpdaters", "SquirrelVersions", "LooseInstallers", "BrowserCaches", "DevCaches", "ComponentStore")
    }
    "3" {
        Write-Host ""
        Write-Host "Enter category numbers separated by commas (e.g. 1,2,3,5): " -ForegroundColor Yellow
        $numInput = Read-Host
        $nums = $numInput -split "," | ForEach-Object { [int]$_.Trim() }
        foreach ($n in $nums) {
            if ($n -ge 1 -and $n -le $analysis.Count) {
                $selectedCategories += $analysis[$n - 1].Id
            }
        }
    }
    Default {
        Write-Host "[*] Cleanup canceled by user." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        exit 0
    }
}

if ($selectedCategories.Count -eq 0) {
    Write-Host "[!] No valid categories selected. Aborting." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit 0
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Red
Write-Host "                      EXPLICIT USER CONSENT CONFIRMATION                  " -ForegroundColor Yellow
Write-Host "==========================================================================" -ForegroundColor Red
Write-Host "You are about to forcefully purge $($selectedCategories.Count) selected categories." -ForegroundColor White
Write-Host "Selected: $($selectedCategories -join ', ')" -ForegroundColor Cyan
Write-Host "Protected personal folders (Downloads, Photos) will NOT be touched." -ForegroundColor Green
Write-Host ""
$confirm = Read-Host "Are you absolutely sure you want to proceed? (Type 'Y' to confirm)"
if ($confirm.Trim().ToUpper() -ne "Y") {
    Write-Host "[*] Operation aborted by user." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit 0
}

Write-Host ""
Write-Host "[*] Initiating WinAurex Forceful Cleanup..." -ForegroundColor Cyan
Write-Host ""

$result = Invoke-WinAurexCleanup -Categories $selectedCategories -OnProgress {
    param($msg)
    Write-Host $msg -ForegroundColor Cyan
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "                         CLEANUP COMPLETED!                               " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host " Total Storage Freed : $($result.FreedText)" -ForegroundColor White
Write-Host " Current Free Space  : $($result.EndFreeText)" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit..."
