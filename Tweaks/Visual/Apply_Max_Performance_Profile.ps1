# Windows Configuration & Optimization Framework
# Apply Max Performance Profile (Tweaks/Visual/Apply_Max_Performance_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY MAX PERFORMANCE VISUAL PROFILE" -ForegroundColor Red
Write-Host "================================================="
Write-Host "This profile strips Windows visuals to the bare minimum to maximize performance."
Write-Host "It disables transparency, animations, and menu delays."
Write-Host "(Font Smoothing is intentionally kept enabled so text remains readable)."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Visual" -Action "Aborted Max Performance Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Visual" -Action "Starting Master Max Performance Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/3] Disabling UI Transparency Effects..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Transparency.ps1")

Write-Host "`n[2/3] Reducing Menu Show Delay for snappier navigation..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Reduce_Menu_Show_Delay.ps1")

Write-Host "`n[3/3] Disabling Unnecessary Taskbar and Window Animations..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Unnecessary_Animations.ps1")

Write-FrameworkLog -ModuleName "Visual" -Action "Completed Master Max Performance Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Max Performance Visual Profile deployment complete!" -ForegroundColor Green
Write-Host "Restarting Windows Explorer to apply all visual changes immediately..." -ForegroundColor Yellow
Stop-Process -Name "explorer" -Force

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
