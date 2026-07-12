[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Repair Audio (Tools/Repair/Repair_Audio.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   AUDIO STACK REPAIR TOOL" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will restart the core Windows Audio services"
Write-Host "to fix sudden 'No Audio', crackling, or desync issues"
Write-Host "without needing a full system reboot."
Write-Host "Press 'Y' to begin or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Repair" -Action "Aborted Audio Repair"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Repair" -Action "Started Audio Stack Repair"

Write-Host "`n[1/2] Stopping Audio Services..." -ForegroundColor Yellow
Stop-Service -Name "Audiosrv" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "AudioEndpointBuilder" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "[2/2] Starting Audio Services..." -ForegroundColor Yellow
Start-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue
Start-Service -Name "Audiosrv" -ErrorAction SilentlyContinue

Write-FrameworkLog -ModuleName "Repair" -Action "Completed Audio Stack Repair"

Write-Host "`n================================================="
Write-Host "[SUCCESS] Windows Audio stack has been restarted." -ForegroundColor Green
Write-Host "If your game/app still has no sound, you may need to restart the app."
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

