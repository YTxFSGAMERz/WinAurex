# Windows Configuration & Optimization Framework
# Apply Privacy Clipboard Profile (Tweaks/Clipboard/Apply_Privacy_Clipboard_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY PRIVACY CLIPBOARD PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile strictly locks down your clipboard for privacy and security."
Write-Host "It disables clipboard history (to prevent password snooping in RAM)"
Write-Host "and completely blocks clipboard syncing to the Microsoft Cloud."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Clipboard" -Action "Aborted Privacy Clipboard Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Clipboard" -Action "Starting Master Privacy Clipboard Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/2] Disabling Local Clipboard History..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Clipboard_History.ps1")

Write-Host "`n[2/2] Disabling Cloud Clipboard Syncing..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Disable_Clipboard_Cloud_Sync.ps1")

Write-FrameworkLog -ModuleName "Clipboard" -Action "Completed Master Privacy Clipboard Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Privacy Clipboard Profile deployment complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
