[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Lock Screen Camera (Tweaks/Camera/Disable_LockScreen_Camera.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Camera" -Action "Initiating Lock Screen Camera Disablement"

$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }
$Name = "NoLockScreenCamera"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (1 = Disabled, 0 = Enabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 1 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Camera" -Action "Disabled Lock Screen Camera" -OldValue $CurrentValue -NewValue "1"

Write-Host "`n[SUCCESS] The camera can no longer be activated from the Windows Lock Screen." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
