# Windows Configuration & Optimization Framework
# System File Checker & DISM Repair (Tools/Repair/Run_SFC_And_DISM.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   SYSTEM FILE & IMAGE REPAIR" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This script runs DISM (Deployment Image Servicing and Management)"
Write-Host "and SFC (System File Checker) to detect and repair corrupted"
Write-Host "core Windows files."
Write-Host "Note: This process may take 10-30 minutes."
Write-Host "Press 'Y' to begin or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Repair" -Action "Aborted SFC/DISM Repair"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Repair" -Action "Started SFC/DISM Repair process"

Write-Host "`n[1/3] Running DISM CheckHealth (Fast scan)..." -ForegroundColor Yellow
dism.exe /Online /Cleanup-image /CheckHealth

Write-Host "`n[2/3] Running DISM RestoreHealth (Downloading replacements if needed)..." -ForegroundColor Yellow
dism.exe /Online /Cleanup-image /RestoreHealth

Write-Host "`n[3/3] Running System File Checker (SFC)..." -ForegroundColor Yellow
sfc.exe /scannow

Write-FrameworkLog -ModuleName "Repair" -Action "Completed SFC/DISM Repair process"

Write-Host "`n================================================="
Write-Host "[SUCCESS] Repair operations have finished." -ForegroundColor Green
Write-Host "Please review the output above for any unresolved corruptions."
Write-Host "A SYSTEM REBOOT is highly recommended if errors were fixed."
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
