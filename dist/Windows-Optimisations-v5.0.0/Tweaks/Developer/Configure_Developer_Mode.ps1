# Windows Configuration & Optimization Framework
# Configure Developer Mode (Tweaks/Developer/Configure_Developer_Mode.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore"

Write-Host "================================================="
Write-Host "   CONFIGURE WINDOWS DEVELOPER MODE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Developer Mode enables side-loading apps, relaxes"
Write-Host "execution policies for local scripts, and exposes"
Write-Host "advanced file explorer tools."
Write-Host "Press 'Y' to enable Developer Mode or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Developer" -Action "Aborted Developer Mode config"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Developer" -Action "Backing up Developer Mode registry keys"
$RegPath1 = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "DevMode_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y | Out-Null

Write-Host "`nEnabling Developer Mode..." -ForegroundColor Yellow
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

Set-ItemProperty -Path $RegPath -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $RegPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

Write-FrameworkLog -ModuleName "Developer" -Action "Enabled Developer Mode"

Write-Host "`n[SUCCESS] Windows Developer Mode has been enabled." -ForegroundColor Green
Start-Sleep -Seconds 2
