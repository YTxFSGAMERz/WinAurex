# Windows Configuration & Optimization Framework
# Apply Laptop Battery Profile (Tweaks/Power/Apply_Laptop_Battery_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY LAPTOP BATTERY PROFILE" -ForegroundColor Green
Write-Host "================================================="
Write-Host "This profile configures your system to preserve battery life and thermals."
Write-Host "It enables hibernation, sets the Balanced power plan, and allows"
Write-Host "USB devices to sleep when not in use."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Power" -Action "Aborted Laptop Battery Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Power" -Action "Starting Master Laptop Battery Orchestrator" -Level WARNING

Write-Host "`n[1/3] Enabling Hibernation (for deep sleep)..." -ForegroundColor Cyan
powercfg.exe /h on
Write-FrameworkLog -ModuleName "Power" -Action "Enabled Windows Hibernation" -OldValue "Disabled" -NewValue "Enabled"

Write-Host "`n[2/3] Setting Balanced Power Plan..." -ForegroundColor Cyan
# 381b4222-f694-41d0-9685-ff5bb260df2e is the standard GUID for Balanced
powercfg /setactive 381b4222-f694-41d0-9685-ff5bb260df2e
Write-FrameworkLog -ModuleName "Power" -Action "Enabled Balanced Power Plan" -OldValue "Unknown" -NewValue "381b4222-f694-41d0-9685-ff5bb260df2e"

Write-Host "`n[3/3] Enabling USB Selective Suspend (battery saving)..." -ForegroundColor Cyan
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea1222653 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea1222653 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg /S SCHEME_CURRENT
Write-FrameworkLog -ModuleName "Power" -Action "Enabled USB Selective Suspend" -OldValue "Unknown" -NewValue "1"

Write-FrameworkLog -ModuleName "Power" -Action "Completed Master Laptop Battery Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Laptop Battery Profile deployment complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
