[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable USB Selective Suspend (Tweaks/Power/Disable_USB_Selective_Suspend.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Power" -Action "Initiating USB Selective Suspend Disablement"

# GUIDs for USB settings
# Subgroup: 2a737441-1930-4402-8d77-b2bea1222653 (USB Settings)
# Setting: 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 (USB selective suspend setting)

powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea1222653 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea1222653 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /S SCHEME_CURRENT

Write-FrameworkLog -ModuleName "Power" -Action "Disabled USB Selective Suspend" -OldValue "Unknown" -NewValue "0"

Write-Host "`n[SUCCESS] USB Selective Suspend disabled." -ForegroundColor Green
Write-Host "Your USB peripherals will no longer sleep, fixing disconnects and lowering input latency." -ForegroundColor Yellow



$null = Read-Host "Press Enter to exit..."
