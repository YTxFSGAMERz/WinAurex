# Windows Configuration & Optimization Framework
# Memory Integrity Manager (Tweaks/Security/Memory_Integrity_Manager.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore"

Write-Host "================================================="
Write-Host "   MEMORY INTEGRITY (HVCI) MANAGER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Memory Integrity uses hardware virtualization to prevent"
Write-Host "malicious code from injecting into the kernel."
Write-Host ""
Write-Host "[Trade-off] High Security vs. Slight Gaming/VM Overhead"
Write-Host "================================================="
Write-Host "1. Enable Memory Integrity (High Security)"
Write-Host "2. Disable Memory Integrity (Max Performance/Legacy Drivers)"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-FrameworkLog -ModuleName "Security" -Action "Aborted HVCI config"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Security" -Action "Backing up HVCI registry keys"
$RegPath1 = "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "HVCI_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y | Out-Null

$KeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
if (-not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force | Out-Null }

if ($Choice -eq '1') {
    Write-Host "`nEnabling Memory Integrity..." -ForegroundColor Yellow
    Set-ItemProperty -Path $KeyPath -Name "Enabled" -Value 1 -Type DWord -Force
    Write-FrameworkLog -ModuleName "Security" -Action "Enabled HVCI"
    Write-Host "[SUCCESS] Memory Integrity is ENABLED." -ForegroundColor Green
} else {
    Write-Host "`nDisabling Memory Integrity..." -ForegroundColor Yellow
    Set-ItemProperty -Path $KeyPath -Name "Enabled" -Value 0 -Type DWord -Force
    Write-FrameworkLog -ModuleName "Security" -Action "Disabled HVCI" -Level WARNING
    Write-Host "[SUCCESS] Memory Integrity is DISABLED." -ForegroundColor Red
}

Write-Host "A SYSTEM REBOOT is required for HVCI changes to take effect." -ForegroundColor Yellow
Start-Sleep -Seconds 3
