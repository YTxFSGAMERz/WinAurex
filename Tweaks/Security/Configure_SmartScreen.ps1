# Windows Configuration & Optimization Framework
# Configure SmartScreen (Tweaks/Security/Configure_SmartScreen.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore"

Write-Host "================================================="
Write-Host "   CONFIGURE DEFENDER SMARTSCREEN" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "SmartScreen protects against malicious apps and sites,"
Write-Host "but can flag unsigned independent developer tools."
Write-Host "1. Enable SmartScreen (Recommended for Security)"
Write-Host "2. Disable SmartScreen (For Developers/Power Users)"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-FrameworkLog -ModuleName "Security" -Action "Aborted SmartScreen config"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Security" -Action "Backing up SmartScreen registry keys"
$RegPath1 = "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"
$RegPath2 = "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "SmartScreen_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y | Out-Null
& reg export $RegPath2 $BackupFile /y | Out-Null

$SysKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
$AppKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost"

if (-not (Test-Path $SysKey)) { New-Item -Path $SysKey -Force | Out-Null }
if (-not (Test-Path $AppKey)) { New-Item -Path $AppKey -Force | Out-Null }

if ($Choice -eq '1') {
    Write-Host "`nEnabling SmartScreen..." -ForegroundColor Yellow
    Set-ItemProperty -Path $SysKey -Name "EnableSmartScreen" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $AppKey -Name "EnableWebContentEvaluation" -Value 1 -Type DWord -Force
    Write-FrameworkLog -ModuleName "Security" -Action "Enabled SmartScreen"
    Write-Host "[SUCCESS] SmartScreen is ENABLED." -ForegroundColor Green
} else {
    Write-Host "`nDisabling SmartScreen..." -ForegroundColor Yellow
    Set-ItemProperty -Path $SysKey -Name "EnableSmartScreen" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $AppKey -Name "EnableWebContentEvaluation" -Value 0 -Type DWord -Force
    Write-FrameworkLog -ModuleName "Security" -Action "Disabled SmartScreen" -Level WARNING
    Write-Host "[SUCCESS] SmartScreen is DISABLED." -ForegroundColor Red
}



$null = Read-Host "Press Enter to exit..."
