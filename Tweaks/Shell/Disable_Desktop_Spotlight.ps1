[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$RestartExplorer
)

# Windows Configuration & Optimization Framework
# Disable Desktop Spotlight & Remove "Learn about this picture" Icon (Tweaks/Shell/Disable_Desktop_Spotlight.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   DISABLING DESKTOP SPOTLIGHT & PROMOS          " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Hide "Learn about this picture" desktop icon
$guid = "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}"
$paths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
)

foreach ($p in $paths) {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name $guid -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}

# 2. Disable ContentDeliveryManager Desktop Spotlight rotation channels
$cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (Test-Path $cdm) {
    Set-ItemProperty -Path $cdm -Name "RotatingImageOverlayEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdm -Name "SubscribedContent-88000326Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

# 3. Disable Windows Spotlight Desktop via Policy
$cloudPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $cloudPolicy)) { New-Item -Path $cloudPolicy -Force | Out-Null }
Set-ItemProperty -Path $cloudPolicy -Name "DisableSpotlightCollectionOnDesktop" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

if ($RestartExplorer) {
    Write-Host " [*] Refreshing Windows Explorer shell..." -ForegroundColor Yellow
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
        Start-Process "explorer.exe"
    }
}

Write-Host "`n[SUCCESS] Windows Desktop Spotlight and 'Learn about this picture' icon disabled." -ForegroundColor Green
