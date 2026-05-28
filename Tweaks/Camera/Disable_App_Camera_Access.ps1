[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable App Camera Access (Tweaks/Camera/Disable_App_Camera_Access.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Camera" -Action "Initiating Global App Camera Access Disablement"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }
$Name = "Value"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (Deny = Disabled, Allow = Enabled)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value "Deny" -Type String -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Camera" -Action "Disabled Global App Camera Access" -OldValue $CurrentValue -NewValue "Deny"

Write-Host "`n[SUCCESS] Global App access to the Camera has been blocked (Deny)." -ForegroundColor Green
Write-Host "Note: Traditional desktop apps (like OBS) may still access it, but UWP/Store apps are blocked." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
