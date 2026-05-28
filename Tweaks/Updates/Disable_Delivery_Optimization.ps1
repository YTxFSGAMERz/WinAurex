# Windows Configuration & Optimization Framework
# Disable Delivery Optimization (Tweaks/Updates/Disable_Delivery_Optimization.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Updates" -Action "Initiating Delivery Optimization Disablement"

# 1. Policy Level
$RegistryPathPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
if (-not (Test-Path $RegistryPathPolicy)) { New-Item -Path $RegistryPathPolicy -Force | Out-Null }

$Name = "DODownloadMode"
$CurrentPolicy = (Get-ItemProperty -Path $RegistryPathPolicy -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentPolicy) { $CurrentPolicy = "Not_Set" }

Set-ItemProperty -Path $RegistryPathPolicy -Name $Name -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Updates" -Action "Disabled Delivery Optimization (Policy)" -OldValue $CurrentPolicy -NewValue "0"

# 2. Base Configuration Level
$RegistryPathBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
if (-not (Test-Path $RegistryPathBase)) { New-Item -Path $RegistryPathBase -Force | Out-Null }

$CurrentBase = (Get-ItemProperty -Path $RegistryPathBase -Name $Name -ErrorAction SilentlyContinue).$Name
if ($null -eq $CurrentBase) { $CurrentBase = "Not_Set" }

Set-ItemProperty -Path $RegistryPathBase -Name $Name -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Updates" -Action "Disabled Delivery Optimization (Config)" -OldValue $CurrentBase -NewValue "0"

Write-Host "`n[SUCCESS] Windows Update Delivery Optimization (P2P) has been disabled." -ForegroundColor Green
Write-Host "Your PC will no longer silently upload Windows updates to other computers on the internet." -ForegroundColor Yellow
Start-Sleep -Seconds 1
