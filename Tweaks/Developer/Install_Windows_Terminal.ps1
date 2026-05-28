[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Install Windows Terminal (Tweaks/Developer/Install_Windows_Terminal.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   INSTALL WINDOWS TERMINAL" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Windows Terminal is the modern, hardware-accelerated"
Write-Host "command-line experience for Windows with tabs and profiles."
Write-Host "Press 'Y' to install or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Developer" -Action "Aborted Windows Terminal Install"
    Write-Host "`nAborted by user."
    Exit
}

if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "`n[ERROR] WinGet is not installed or not in PATH." -ForegroundColor Red
    Exit
}

Write-FrameworkLog -ModuleName "Developer" -Action "Installing Windows Terminal via WinGet"
Write-Host "`nInstalling Microsoft.WindowsTerminal..." -ForegroundColor Yellow

Start-Process -FilePath "winget" -ArgumentList "install", "--id", "Microsoft.WindowsTerminal", "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements" -Wait -NoNewWindow

Write-FrameworkLog -ModuleName "Developer" -Action "Completed Windows Terminal Install"
Write-Host "`n[SUCCESS] Windows Terminal has been installed." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."

