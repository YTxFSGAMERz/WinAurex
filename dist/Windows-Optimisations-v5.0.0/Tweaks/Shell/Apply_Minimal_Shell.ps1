# Windows Configuration & Optimization Framework
# Apply Minimal Shell Orchestrator (Tweaks/Shell/Apply_Minimal_Shell.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY MINIMAL SHELL PRESET" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will disable Copilot, Widgets, Start Menu Recommendations, and Notification Spam."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Shell" -Action "Aborted Minimal Shell Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Shell" -Action "Starting Master Minimal Shell Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/4] Disabling Copilot Taskbar Integration..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Copilot_Taskbar.ps1")

Write-Host "`n[2/4] Disabling Windows Widgets..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Windows_Widgets.ps1")

Write-Host "`n[3/4] Removing Recommended Section from Start Menu..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Remove_Recommended_Section.ps1")

Write-Host "`n[4/4] Disabling Notification Spam..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Notification_Spam.ps1")

Write-FrameworkLog -ModuleName "Shell" -Action "Completed Master Minimal Shell Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Minimal Shell deployment complete!" -ForegroundColor Green
Write-Host "Restarting Windows Explorer to apply all visual changes immediately..." -ForegroundColor Yellow
Stop-Process -Name "explorer" -Force

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
