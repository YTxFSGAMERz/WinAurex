[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Install Essential Apps via WinGet (Tools/Apps/Install_Essential_Apps_WinGet.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   ESSENTIAL APPS INSTALLER (WINGET)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This script will use Microsoft's native package manager (WinGet)"
Write-Host "to silently install essential utilities for a fresh Windows setup."
Write-Host "Apps to install: 7-Zip, VLC, Notepad++, Brave Browser, Discord."
Write-Host "Press 'Y' to continue or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-Host "`nAborted by user."
    Exit
}

# Verify WinGet is installed
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "`n[ERROR] WinGet is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Ensure you have the 'App Installer' package from the Microsoft Store."
    Start-Sleep -Seconds 3
    Exit
}

$Apps = @{
    "7zip.7zip" = "7-Zip"
    "VideoLAN.VLC" = "VLC Media Player"
    "Notepad++.Notepad++" = "Notepad++"
    "Brave.Brave" = "Brave Browser"
    "Discord.Discord" = "Discord"
}

Write-Host "`nStarting installation process..." -ForegroundColor Cyan

foreach ($Id in $Apps.Keys) {
    Write-Host "Installing $($Apps[$Id])..." -ForegroundColor Yellow
    
    # Run winget silently, accepting source agreements
    $InstallArgs = @("install", "--id", $Id, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements")
    Start-Process -FilePath "winget" -ArgumentList $InstallArgs -Wait -NoNewWindow
    
    Write-Host "$($Apps[$Id]) installation command completed.`n" -ForegroundColor Green
}

Write-Host "================================================="
Write-Host "[SUCCESS] All essential applications have been processed!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

