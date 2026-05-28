# Windows Configuration & Optimization Framework
# Repair Windows Update (Tools/Repair/Repair_Windows_Update.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   WINDOWS UPDATE REPAIR TOOL" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will stop update services, clear the SoftwareDistribution"
Write-Host "cache, and restart the services to fix stuck or broken updates."
Write-Host "Press 'Y' to begin or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Repair" -Action "Aborted Windows Update Repair"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Repair" -Action "Started Windows Update Repair"

Write-Host "`n[1/3] Stopping Windows Update and BITS services..." -ForegroundColor Yellow
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "bits" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "cryptsvc" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "[2/3] Clearing SoftwareDistribution and catroot2 caches..." -ForegroundColor Yellow
$SDPath = "$env:SystemRoot\SoftwareDistribution"
$CRPath = "$env:SystemRoot\System32\catroot2"

if (Test-Path $SDPath) { Remove-Item -Path "$SDPath\*" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path $CRPath) { Remove-Item -Path "$CRPath\*" -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "[3/3] Restarting Update services..." -ForegroundColor Yellow
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
Start-Service -Name "bits" -ErrorAction SilentlyContinue
Start-Service -Name "cryptsvc" -ErrorAction SilentlyContinue

Write-FrameworkLog -ModuleName "Repair" -Action "Completed Windows Update Repair"

Write-Host "`n================================================="
Write-Host "[SUCCESS] Windows Update caches have been reset." -ForegroundColor Green
Write-Host "Try checking for updates again in Settings."
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
