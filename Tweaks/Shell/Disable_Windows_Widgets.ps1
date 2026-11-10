[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Windows Widgets (Tweaks/Shell/Disable_Windows_Widgets.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

# 1. System-Wide Group Policy Disablement (Works universally on Windows 11 22H2 / 23H2 / 24H2 / 25H2)
$DshPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $DshPolicy)) { New-Item -Path $DshPolicy -Force | Out-Null }
Set-ItemProperty -Path $DshPolicy -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$FeedsPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
if (-not (Test-Path $FeedsPolicy)) { New-Item -Path $FeedsPolicy -Force | Out-Null }
Set-ItemProperty -Path $FeedsPolicy -Name "EnableFeeds" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 2. User Explorer Preferences (TaskbarDa - Graceful fallback)
$UserAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
try {
    if (Test-Path $UserAdvanced) {
        Set-ItemProperty -Path $UserAdvanced -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
} catch {}

Write-Host "`n[SUCCESS] Windows Widgets and News Feed Disabled." -ForegroundColor Green
Write-Host "A Windows Explorer restart may be required to see changes immediately." -ForegroundColor Yellow
