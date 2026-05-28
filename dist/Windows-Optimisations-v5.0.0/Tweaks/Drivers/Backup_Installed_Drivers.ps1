# Windows Configuration & Optimization Framework
# Backup Installed Drivers (Tweaks/Drivers/Backup_Installed_Drivers.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$BackupRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore\Drivers"

Write-Host "================================================="
Write-Host "   DRIVER BACKUP UTILITY (DISM)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will export all third-party drivers currently installed"
Write-Host "on your system to a safe backup directory. This is critical"
Write-Host "before doing major optimizations or GPU driver cleanups (DDU)."
Write-Host "Press 'Y' to begin the backup or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Drivers" -Action "Aborted Driver Backup"
    Write-Host "`nAborted by user."
    Exit
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ExportDir = Join-Path -Path $BackupRoot -ChildPath "Backup_$Timestamp"

if (-not (Test-Path $ExportDir)) {
    New-Item -Path $ExportDir -ItemType Directory -Force | Out-Null
}

Write-FrameworkLog -ModuleName "Drivers" -Action "Started third-party driver export"

Write-Host "`nExporting drivers. This may take a few minutes..." -ForegroundColor Yellow
dism.exe /online /export-driver /destination:"$ExportDir" | Out-Null

Write-FrameworkLog -ModuleName "Drivers" -Action "Completed third-party driver export to $ExportDir"

Write-Host "`n================================================="
Write-Host "[SUCCESS] Drivers have been exported safely." -ForegroundColor Green
Write-Host "Backup Location: $ExportDir"
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
