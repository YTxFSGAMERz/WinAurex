# Windows Configuration & Optimization Framework
# Apply Gaming GPU Profile (Tweaks/GPU/Apply_Gaming_GPU_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY GAMING GPU PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile configures Windows to prioritize game performance."
Write-Host "It enables Hardware Accelerated GPU Scheduling (HAGS) for higher FPS"
Write-Host "and enables Windows Game Mode to suppress background activity."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "GPU" -Action "Aborted Gaming GPU Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "GPU" -Action "Starting Master Gaming GPU Orchestrator" -Level WARNING

$ScriptDir = $PSScriptRoot

Write-Host "`n[1/2] Enabling Hardware Accelerated GPU Scheduling..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Enable_Hardware_Accelerated_GPU_Scheduling.ps1")

Write-Host "`n[2/2] Enabling Windows Game Mode..." -ForegroundColor Cyan
& (Join-Path -Path $ScriptDir -ChildPath "Enable_Game_Mode.ps1")

Write-FrameworkLog -ModuleName "GPU" -Action "Completed Master Gaming GPU Orchestrator" -Level WARNING

Write-Host "`n[SUCCESS] Gaming GPU Profile deployment complete!" -ForegroundColor Green
Write-Host "A system reboot is highly recommended to apply GPU scheduling changes." -ForegroundColor Red
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
