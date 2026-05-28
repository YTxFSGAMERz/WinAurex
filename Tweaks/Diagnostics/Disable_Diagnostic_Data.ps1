# Windows Configuration & Optimization Framework
# Disable Diagnostic Data (Tweaks/Diagnostics/Disable_Diagnostic_Data.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Diagnostics" -Action "Initiating Diagnostic Data Disablement"

$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }
$Name = "AllowTelemetry"

# 1. Snapshot current state
$CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentValue) { $CurrentValue = "Not_Set" }

# 2. Apply Configuration (0 = Disabled, 1 = Basic, 3 = Full)
Set-ItemProperty -Path $RegistryPath -Name $Name -Value 0 -Type DWord -Force

# 3. Log Outcome
Write-FrameworkLog -ModuleName "Diagnostics" -Action "Disabled Windows Telemetry (AllowTelemetry)" -OldValue $CurrentValue -NewValue "0"

Write-Host "`n[SUCCESS] Windows Diagnostic Data collection (Telemetry) has been set to 0 (Disabled)." -ForegroundColor Green
Write-Host "This blocks the OS from sending usage metrics and system state data to Microsoft." -ForegroundColor Yellow
Start-Sleep -Seconds 1
