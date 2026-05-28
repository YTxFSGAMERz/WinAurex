# Windows Configuration & Optimization Framework
# Apply Debloat Profile (Tweaks/Apps/Apply_Debloat_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY WINDOWS DEBLOAT PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile removes sponsored bloatware (TikTok, Candy Crush)"
Write-Host "and unnecessary default Microsoft apps (3D Viewer, Feedback Hub)."
Write-Host "This cleans up the Start Menu and reclaims disk space."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Apps" -Action "Aborted Debloat Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Apps" -Action "Starting Master Debloat Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/2] Removing Sponsored Bloatware..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Remove_Sponsored_Apps.ps1")

Write-Host "`n[2/2] Removing Unnecessary Microsoft Apps..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Remove_Unnecessary_MS_Apps.ps1")

Write-FrameworkLog -ModuleName "Apps" -Action "Completed Master Debloat Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Debloat Profile deployment complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
