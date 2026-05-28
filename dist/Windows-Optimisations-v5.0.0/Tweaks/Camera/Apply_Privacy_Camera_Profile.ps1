# Windows Configuration & Optimization Framework
# Apply Privacy Camera Profile (Tweaks/Camera/Apply_Privacy_Camera_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY PRIVACY CAMERA PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile strictly locks down your camera for privacy and security."
Write-Host "It disables lock screen camera access and completely blocks Windows"
Write-Host "Apps from using your webcam."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Camera" -Action "Aborted Privacy Camera Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Camera" -Action "Starting Master Privacy Camera Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/2] Disabling Lock Screen Camera Access..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_LockScreen_Camera.ps1")

Write-Host "`n[2/2] Blocking Global App Camera Access..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_App_Camera_Access.ps1")

Write-FrameworkLog -ModuleName "Camera" -Action "Completed Master Privacy Camera Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Privacy Camera Profile deployment complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
