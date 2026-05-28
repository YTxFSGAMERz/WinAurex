[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Apply Desktop Power Profile (Tweaks/Power/Apply_Desktop_Power_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY DESKTOP POWER PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile configures your system for maximum consistent performance."
Write-Host "It disables hibernation (freeing SSD space), sets Ultimate Performance,"
Write-Host "and prevents USB devices from sleeping."
Write-Host "WARNING: DO NOT use this on a laptop that runs on battery." -ForegroundColor Red
Write-Host "Press 'Y' to continue or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Power" -Action "Aborted Desktop Power Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Power" -Action "Starting Master Desktop Power Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/3] Disabling Hibernation..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Hibernation.ps1") -Force:$Force

Write-Host "`n[2/3] Enabling Ultimate Performance Plan..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Enable_Ultimate_Performance_Plan.ps1") -Force:$Force

Write-Host "`n[3/3] Disabling USB Selective Suspend..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_USB_Selective_Suspend.ps1") -Force:$Force

Write-FrameworkLog -ModuleName "Power" -Action "Completed Master Desktop Power Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Desktop Power Profile deployment complete!" -ForegroundColor Green
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

