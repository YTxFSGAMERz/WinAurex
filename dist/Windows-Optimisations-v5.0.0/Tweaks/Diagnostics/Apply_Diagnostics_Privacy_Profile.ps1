# Windows Configuration & Optimization Framework
# Apply Diagnostics Privacy Profile (Tweaks/Diagnostics/Apply_Diagnostics_Privacy_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY DIAGNOSTICS PRIVACY PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile disables OS-level telemetry and tracking."
Write-Host "It blocks Windows from sending diagnostic data to Microsoft"
Write-Host "and disables personalized ads/tips based on your usage."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Diagnostics" -Action "Aborted Diagnostics Privacy Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Diagnostics" -Action "Starting Master Diagnostics Privacy Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/2] Disabling Diagnostic Data Collection (Telemetry)..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Diagnostic_Data.ps1")

Write-Host "`n[2/2] Disabling Tailored Experiences (Ads/Tips)..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Tailored_Experiences.ps1")

Write-FrameworkLog -ModuleName "Diagnostics" -Action "Completed Master Diagnostics Privacy Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Diagnostics Privacy Profile deployment complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
