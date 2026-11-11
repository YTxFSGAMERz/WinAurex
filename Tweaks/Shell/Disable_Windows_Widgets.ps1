[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$RestartExplorer
)

# Windows Configuration & Optimization Framework
# Disable Windows Widgets (Tweaks/Shell/Disable_Windows_Widgets.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

# 1. System-Wide Group Policy Disablement (Universal Windows 11 22H2 / 23H2 / 24H2 / 25H2)
$DshPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $DshPolicy)) { New-Item -Path $DshPolicy -Force | Out-Null }
Set-ItemProperty -Path $DshPolicy -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$FeedsPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
if (-not (Test-Path $FeedsPolicy)) { New-Item -Path $FeedsPolicy -Force | Out-Null }
Set-ItemProperty -Path $FeedsPolicy -Name "EnableFeeds" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 2. User Explorer Preferences (TaskbarDa = 0 hides the widget taskbar weather/news entry)
$UserAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
try {
    if (-not (Test-Path $UserAdvanced)) { New-Item -Path $UserAdvanced -Force | Out-Null }
    Set-ItemProperty -Path $UserAdvanced -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
} catch {}

# 3. Force-terminate active Widgets.exe process to instantly drop open widget boards
Write-Host " [*] Terminating active Widgets background processes..." -ForegroundColor Yellow
Stop-Process -Name "Widgets" -Force -ErrorAction SilentlyContinue
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "*widget*" } | Stop-Process -Force -ErrorAction SilentlyContinue

# 4. Optional Explorer restart to refresh taskbar immediately
if ($RestartExplorer) {
    Write-Host " [*] Refreshing Windows Explorer shell..." -ForegroundColor Yellow
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
        Start-Process "explorer.exe"
    }
}

Write-Host "`n[SUCCESS] Windows Widgets and News Feed completely disabled." -ForegroundColor Green
