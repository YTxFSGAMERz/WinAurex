[CmdletBinding()]
param (
    [switch]$Force,
    [ValidateSet("1", "2", "3")][string]$Choice
)

# Windows Configuration & Optimization Framework
# Optimize Pagefile (Tweaks/Storage-Advanced/Optimize_Pagefile_Configuration.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
# Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore"

Write-Host "================================================="
Write-Host "   SMART PAGEFILE & VIRTUAL MEMORY MANAGER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "MYTH: 'Disabling the pagefile gives you more FPS.'"
Write-Host "FACT: Windows relies on the pagefile for memory commit."
Write-Host "Disabling it entirely can cause games to crash instantly"
Write-Host "when VRAM/RAM allocations spike, and it disables crash dumps."
Write-Host "================================================="
Write-Host "1. System Managed (Recommended/Safe Default)"
Write-Host "2. Fixed Size (16GB) (For Heavy Gaming/Simulators)"
Write-Host "3. Abort"
Write-Host "================================================="

if (-not $Choice) {
    if ($Force -or [Console]::IsInputRedirected) {
        $Choice = "1"
    } else {
        $Choice = Read-Host "Select an option [1-3]"
    }
}

if ($Choice -notmatch '^[1-2]$') {
#     Write-FrameworkLog -ModuleName "Storage" -Action "Aborted Pagefile config"
    Write-Host "`nAborted by user."
    if (-not $Force -and -not [Console]::IsInputRedirected) { Read-Host "Press Enter to exit..." }
    Exit
}

# Write-FrameworkLog -ModuleName "Storage" -Action "Backing up Pagefile registry settings"
$RegPath1 = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "Pagefile_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y 2>$null | Out-Null

$SysKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

if ($Choice -eq '1') {
    Write-Host "`nSetting Pagefile to System Managed..." -ForegroundColor Yellow
    Set-CimInstance -Query "Select * from Win32_ComputerSystem" -Property @{AutomaticManagedPagefile = $true} -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $SysKey -Name "PagingFiles" -ErrorAction SilentlyContinue
#     Write-FrameworkLog -ModuleName "Storage" -Action "Set Pagefile to System Managed"
    Write-Host "[SUCCESS] Pagefile is now System Managed." -ForegroundColor Green
} else {
    Write-Host "`nSetting Pagefile to Fixed 16GB..." -ForegroundColor Yellow
    Set-CimInstance -Query "Select * from Win32_ComputerSystem" -Property @{AutomaticManagedPagefile = $false} -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $SysKey -Name "PagingFiles" -Value "C:\pagefile.sys 16384 16384" -Type MultiString -Force
#     Write-FrameworkLog -ModuleName "Storage" -Action "Set Pagefile to Fixed 16GB"
    Write-Host "[SUCCESS] Pagefile is now fixed to 16GB." -ForegroundColor Green
}

Write-Host "A SYSTEM REBOOT is required for virtual memory changes to take effect." -ForegroundColor Yellow

if (-not $Force -and -not [Console]::IsInputRedirected) {
    Read-Host "Press Enter to exit..."
}
