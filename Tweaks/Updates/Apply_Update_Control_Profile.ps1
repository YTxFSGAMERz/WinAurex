[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Apply Update Control Profile (Tweaks/Updates/Apply_Update_Control_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY UPDATE CONTROL PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile restores control over Windows Updates."
Write-Host "It blocks Windows from automatically overwriting your hardware drivers"
Write-Host "and disables P2P Delivery Optimization to save network bandwidth."
Write-Host "Press 'Y' to continue or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Updates" -Action "Aborted Update Control Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Updates" -Action "Starting Master Update Control Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/2] Disabling Automatic Driver Updates..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Automatic_Driver_Updates.ps1") -Force:$Force

Write-Host "`n[2/2] Disabling Delivery Optimization (P2P)..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Delivery_Optimization.ps1") -Force:$Force

Write-FrameworkLog -ModuleName "Updates" -Action "Completed Master Update Control Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Update Control Profile deployment complete!" -ForegroundColor Green
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

