# Windows Configuration & Optimization Framework
# Disable Windows Settings Sync (Tweaks/Sync/Disable_Windows_Settings_Sync.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Sync" -Action "Initiating Windows Settings Sync Disablement"

$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\SettingSync"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }

# 1. Disable Settings Sync (2 = Disabled completely)
$NameSync = "DisableSettingSync"
$CurrentSync = (Get-ItemProperty -Path $RegistryPath -Name $NameSync -ErrorAction SilentlyContinue).$NameSync
if ($null -eq $CurrentSync) { $CurrentSync = "Not_Set" }

Set-ItemProperty -Path $RegistryPath -Name $NameSync -Value 2 -Type DWord -Force
Write-FrameworkLog -ModuleName "Sync" -Action "Disabled Settings Sync" -OldValue $CurrentSync -NewValue "2"

# 2. Disable User Override
$NameOverride = "DisableSettingSyncUserOverride"
$CurrentOverride = (Get-ItemProperty -Path $RegistryPath -Name $NameOverride -ErrorAction SilentlyContinue).$NameOverride
if ($null -eq $CurrentOverride) { $CurrentOverride = "Not_Set" }

Set-ItemProperty -Path $RegistryPath -Name $NameOverride -Value 1 -Type DWord -Force
Write-FrameworkLog -ModuleName "Sync" -Action "Disabled Settings Sync User Override" -OldValue $CurrentOverride -NewValue "1"

Write-Host "`n[SUCCESS] Windows Settings Sync has been disabled." -ForegroundColor Green
Write-Host "Your passwords, themes, and preferences will remain strictly local." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
