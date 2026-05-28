[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Hibernation (Tweaks/Power/Disable_Hibernation.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Power" -Action "Initiating Hibernation Disablement"

# 1. Disable Hibernation via powercfg
powercfg.exe /h off
$Success = ($LASTEXITCODE -eq 0)

if ($Success) {
    Write-FrameworkLog -ModuleName "Power" -Action "Disabled Windows Hibernation" -OldValue "Enabled" -NewValue "Disabled"
    Write-Host "`n[SUCCESS] Hibernation disabled. The hiberfil.sys file has been removed, freeing up SSD space." -ForegroundColor Green
} else {
    Write-FrameworkLog -ModuleName "Power" -Action "Failed to Disable Windows Hibernation" -Level ERROR
    Write-Host "`n[ERROR] Failed to disable hibernation. Ensure you have administrator rights." -ForegroundColor Red
}



$null = Read-Host "Press Enter to exit..."
