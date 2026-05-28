[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Apply Privacy Sync Profile (Tweaks/Sync/Apply_Privacy_Sync_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY PRIVACY SYNC PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile disables background telemetry and data syncing."
Write-Host "It disables Timeline Activity History tracking and blocks Windows"
Write-Host "from syncing your passwords, themes, and settings to the cloud."
Write-Host "Press 'Y' to continue or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Sync" -Action "Aborted Privacy Sync Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Sync" -Action "Starting Master Privacy Sync Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/2] Disabling Activity History and Timeline tracking..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Activity_History.ps1") -Force:$Force

Write-Host "`n[2/2] Disabling Windows Settings Cloud Syncing..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Windows_Settings_Sync.ps1") -Force:$Force

Write-FrameworkLog -ModuleName "Sync" -Action "Completed Master Privacy Sync Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Privacy Sync Profile deployment complete!" -ForegroundColor Green
if (-not $Force) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

