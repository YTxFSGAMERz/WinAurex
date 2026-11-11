[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Enable OneDrive & Restore Defaults (Tweaks/Sync/Enable_OneDrive_Nag_And_Backup.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$odPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
if (Test-Path $odPolicy) {
    Remove-ItemProperty -Path $odPolicy -Name "KFMBlockOptIn" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $odPolicy -Name "DisableFileSyncNGSC" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $odPolicy -Name "PreventNetworkTrafficPreUserSignIn" -ErrorAction SilentlyContinue
}

Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -ErrorAction SilentlyContinue

Write-Host "`n[SUCCESS] OneDrive policies restored to defaults." -ForegroundColor Green
