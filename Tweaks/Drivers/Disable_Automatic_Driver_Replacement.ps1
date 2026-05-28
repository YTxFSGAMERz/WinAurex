# Windows Configuration & Optimization Framework
# Disable Automatic Driver Replacement (Tweaks/Drivers/Disable_Automatic_Driver_Replacement.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore"

Write-Host "================================================="
Write-Host "   AUTOMATIC DRIVER REPLACEMENT MANAGER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Windows Update often silently downgrades or replaces"
Write-Host "perfectly functioning AMD/NVIDIA GPU or network drivers."
Write-Host "This script configures group policies to exclude drivers"
Write-Host "from standard Windows Updates."
Write-Host "================================================="
Write-Host "1. Disable Driver Updates via Windows Update (Recommended)"
Write-Host "2. Enable Driver Updates via Windows Update (Default)"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-FrameworkLog -ModuleName "Drivers" -Action "Aborted Driver Update config"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Drivers" -Action "Backing up Driver Update registry keys"
$RegPath1 = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "DriverUpdates_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y 2>$null | Out-Null

$KeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (-not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force | Out-Null }

if ($Choice -eq '1') {
    Write-Host "`nDisabling driver inclusion in Windows Update..." -ForegroundColor Yellow
    Set-ItemProperty -Path $KeyPath -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force
    Write-FrameworkLog -ModuleName "Drivers" -Action "Disabled Windows Update from installing drivers"
    Write-Host "[SUCCESS] Windows Update will no longer replace your drivers." -ForegroundColor Green
} else {
    Write-Host "`nEnabling driver inclusion in Windows Update..." -ForegroundColor Yellow
    Set-ItemProperty -Path $KeyPath -Name "ExcludeWUDriversInQualityUpdate" -Value 0 -Type DWord -Force
    Write-FrameworkLog -ModuleName "Drivers" -Action "Enabled Windows Update to install drivers"
    Write-Host "[SUCCESS] Windows Update will manage your drivers." -ForegroundColor Green
}



$null = Read-Host "Press Enter to exit..."
