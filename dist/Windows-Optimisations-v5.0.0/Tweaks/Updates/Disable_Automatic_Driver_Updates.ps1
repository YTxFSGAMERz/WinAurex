# Windows Configuration & Optimization Framework
# Disable Automatic Driver Updates (Tweaks/Updates/Disable_Automatic_Driver_Updates.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Updates" -Action "Initiating Automatic Driver Updates Disablement"

# 1. Policy: Exclude drivers from Windows Quality Updates
$RegistryPathPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (-not (Test-Path $RegistryPathPolicy)) { New-Item -Path $RegistryPathPolicy -Force | Out-Null }

$NamePolicy = "ExcludeWUDriversInQualityUpdate"
$CurrentPolicy = (Get-ItemProperty -Path $RegistryPathPolicy -Name $NamePolicy -ErrorAction SilentlyContinue).$NamePolicy
if ($null -eq $CurrentPolicy) { $CurrentPolicy = "Not_Set" }

Set-ItemProperty -Path $RegistryPathPolicy -Name $NamePolicy -Value 1 -Type DWord -Force
Write-FrameworkLog -ModuleName "Updates" -Action "Disabled WU Drivers in Quality Updates" -OldValue $CurrentPolicy -NewValue "1"

# 2. Base setting: Driver Searching
$RegistryPathBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
if (-not (Test-Path $RegistryPathBase)) { New-Item -Path $RegistryPathBase -Force | Out-Null }

$NameBase = "SearchOrderConfig"
$CurrentBase = (Get-ItemProperty -Path $RegistryPathBase -Name $NameBase -ErrorAction SilentlyContinue).$NameBase
if ($null -eq $CurrentBase) { $CurrentBase = "Not_Set" }

Set-ItemProperty -Path $RegistryPathBase -Name $NameBase -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Updates" -Action "Disabled Automatic Driver Searching" -OldValue $CurrentBase -NewValue "0"

Write-Host "`n[SUCCESS] Windows will no longer forcibly update your hardware drivers." -ForegroundColor Green
Write-Host "This prevents Windows Update from overwriting your custom GPU or Audio drivers." -ForegroundColor Yellow
Start-Sleep -Seconds 1
