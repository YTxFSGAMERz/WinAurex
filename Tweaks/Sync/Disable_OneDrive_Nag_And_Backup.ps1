[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable OneDrive Nag & Windows Backup Prompts (Tweaks/Sync/Disable_OneDrive_Nag_And_Backup.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   DISABLING ONEDRIVE BACKUP NAGS & AUTOSTART    " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Kill active OneDrive nag processes and toasts
Write-Host " [*] Terminating running OneDrive notification processes..." -ForegroundColor Yellow
Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "OneDriveSetup" -Force -ErrorAction SilentlyContinue

# 2. Block Known Folder Move (KFM) "Turn On Windows Backup" Nag Prompts via Policy
Write-Host " [*] Applying OneDrive KFMBlockOptIn policy (blocks 'Turn on Windows Backup' dialog)..." -ForegroundColor Yellow
$odPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
if (-not (Test-Path $odPolicy)) { New-Item -Path $odPolicy -Force | Out-Null }

Set-ItemProperty -Path $odPolicy -Name "KFMBlockOptIn" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $odPolicy -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $odPolicy -Name "PreventNetworkTrafficPreUserSignIn" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# 3. Disable Consumer Windows Backup Cloud Nags
$cloudPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $cloudPolicy)) { New-Item -Path $cloudPolicy -Force | Out-Null }
Set-ItemProperty -Path $cloudPolicy -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# 4. Remove automatic startup entry
Write-Host " [*] Removing OneDrive startup autorun..." -ForegroundColor Yellow
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (Test-Path $runKey) {
    Remove-ItemProperty -Path $runKey -Name "OneDrive" -ErrorAction SilentlyContinue
}

# 5. Disable scheduled tasks for OneDrive standalone update
$odTasks = @(
    "\OneDrive Standalone Update Task*",
    "\Microsoft\OneDrive\*"
)
foreach ($pattern in $odTasks) {
    Get-ScheduledTask -TaskName $pattern -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "`n[SUCCESS] OneDrive 'Turn On Windows Backup' nags and automatic startup disabled." -ForegroundColor Green
Write-Host "Existing personal files remain safe and intact on your disk." -ForegroundColor Cyan
