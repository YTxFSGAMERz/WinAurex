[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$RestartExplorer
)

# Windows Configuration & Optimization Framework
# Enable Windows Widgets (Tweaks/Shell/Enable_Windows_Widgets.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

# 1. Reset Group Policy
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -ErrorAction SilentlyContinue

# 2. Reset TaskbarDa to 1
$UserAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (Test-Path $UserAdvanced) {
    Set-ItemProperty -Path $UserAdvanced -Name "TaskbarDa" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}

if ($RestartExplorer) {
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
        Start-Process "explorer.exe"
    }
}

Write-Host "`n[SUCCESS] Windows Widgets restored to defaults." -ForegroundColor Green
