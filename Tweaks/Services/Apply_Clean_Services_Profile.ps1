[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Apply Clean Services Profile (Tweaks/Services/Apply_Clean_Services_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY CLEAN SERVICES PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile disables background telemetry services like DiagTrack."
Write-Host "It frees up background RAM and stops Windows from transmitting"
Write-Host "diagnostic/usage data to Microsoft servers."
Write-Host "Press 'Y' to continue or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Services" -Action "Aborted Clean Services Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Services" -Action "Starting Master Clean Services Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/1] Disabling Telemetry Background Services..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Telemetry_Services.ps1") -Force:$Force

Write-FrameworkLog -ModuleName "Services" -Action "Completed Master Clean Services Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Clean Services Profile deployment complete!" -ForegroundColor Green
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

