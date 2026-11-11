[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$RestartExplorer
)

# Windows Configuration & Optimization Framework
# Enable Desktop Spotlight (Tweaks/Shell/Enable_Desktop_Spotlight.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

$guid = "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}"
$paths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Remove-ItemProperty -Path $p -Name $guid -ErrorAction SilentlyContinue
    }
}

Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSpotlightCollectionOnDesktop" -ErrorAction SilentlyContinue

if ($RestartExplorer) {
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
        Start-Process "explorer.exe"
    }
}

Write-Host "`n[SUCCESS] Desktop Spotlight settings restored." -ForegroundColor Green
