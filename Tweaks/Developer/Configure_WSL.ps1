# Windows Configuration & Optimization Framework
# Configure WSL (Tweaks/Developer/Configure_WSL.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   ENABLE WINDOWS SUBSYSTEM FOR LINUX (WSL)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This script will enable the Virtual Machine Platform"
Write-Host "and WSL optional features natively. It will NOT"
Write-Host "install a specific Linux distro."
Write-Host "Press 'Y' to enable WSL or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Developer" -Action "Aborted WSL config"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Developer" -Action "Enabling WSL Optional Features"

Write-Host "`n[1/2] Enabling Windows Subsystem for Linux..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart

Write-Host "[2/2] Enabling Virtual Machine Platform..." -ForegroundColor Yellow
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

Write-FrameworkLog -ModuleName "Developer" -Action "Completed WSL Feature Enablement"

Write-Host "`n[SUCCESS] WSL and Virtual Machine Platform are enabled." -ForegroundColor Green
Write-Host "A SYSTEM RESTART IS REQUIRED for the changes to take effect." -ForegroundColor Red
Write-Host "After rebooting, you can install a distro via 'wsl --install -d Ubuntu'."


$null = Read-Host "Press Enter to exit..."
