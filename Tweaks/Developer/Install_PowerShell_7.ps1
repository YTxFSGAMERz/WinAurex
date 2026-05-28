# Windows Configuration & Optimization Framework
# Install PowerShell 7 (Tweaks/Developer/Install_PowerShell_7.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   INSTALL POWERSHELL 7 (CORE)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "PowerShell 7 is the modern, open-source, cross-platform"
Write-Host "version of PowerShell that runs side-by-side with Windows PowerShell 5.1."
Write-Host "Press 'Y' to install or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Developer" -Action "Aborted PowerShell 7 Install"
    Write-Host "`nAborted by user."
    Exit
}

if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "`n[ERROR] WinGet is not installed or not in PATH." -ForegroundColor Red
    Exit
}

Write-FrameworkLog -ModuleName "Developer" -Action "Installing PowerShell 7 via WinGet"
Write-Host "`nInstalling Microsoft.PowerShell..." -ForegroundColor Yellow

Start-Process -FilePath "winget" -ArgumentList "install", "--id", "Microsoft.PowerShell", "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements" -Wait -NoNewWindow

Write-FrameworkLog -ModuleName "Developer" -Action "Completed PowerShell 7 Install"
Write-Host "`n[SUCCESS] PowerShell 7 has been installed." -ForegroundColor Green
Write-Host "It will appear in your Start Menu as 'PowerShell' (black icon)."


$null = Read-Host "Press Enter to exit..."
