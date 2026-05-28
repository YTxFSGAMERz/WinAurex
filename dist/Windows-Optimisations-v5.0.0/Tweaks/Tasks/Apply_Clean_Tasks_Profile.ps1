# Windows Configuration & Optimization Framework
# Apply Clean Tasks Profile (Tweaks/Tasks/Apply_Clean_Tasks_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY CLEAN TASKS PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile disables background telemetry scheduled tasks."
Write-Host "It prevents Microsoft's Customer Experience Improvement Program"
Write-Host "and compatibility appraisers from consuming CPU in the background."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Tasks" -Action "Aborted Clean Tasks Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Tasks" -Action "Starting Master Clean Tasks Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/1] Disabling Telemetry Scheduled Tasks..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Telemetry_Tasks.ps1")

Write-FrameworkLog -ModuleName "Tasks" -Action "Completed Master Clean Tasks Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Clean Tasks Profile deployment complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
