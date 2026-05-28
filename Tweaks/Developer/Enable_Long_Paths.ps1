[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Enable Long Paths (Tweaks/Developer/Enable_Long_Paths.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore"

Write-Host "================================================="
Write-Host "   ENABLE WIN32 LONG PATHS" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will remove the 260-character path limit in Windows."
Write-Host "This is highly recommended for developers using Git, Node.js,"
Write-Host "and deeply nested folder structures."
Write-Host "Press 'Y' to enable or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Developer" -Action "Aborted Long Paths config"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Developer" -Action "Backing up LongPaths registry key"
$RegPath = "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "LongPaths_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath $BackupFile /y | Out-Null

Write-Host "`nEnabling Win32 Long Paths..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -Type DWord -Force

Write-FrameworkLog -ModuleName "Developer" -Action "Enabled Win32 Long Paths"

Write-Host "`n[SUCCESS] Long Paths have been enabled. A restart may be required for some apps." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."

