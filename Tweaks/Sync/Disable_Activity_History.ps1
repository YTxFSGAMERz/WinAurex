[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Activity History (Tweaks/Sync/Disable_Activity_History.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Sync" -Action "Initiating Activity History Disablement"

$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force | Out-Null }

# 1. Disable Activity Feed (Timeline)
$NameFeed = "EnableActivityFeed"
$CurrentFeed = (Get-ItemProperty -Path $RegistryPath -Name $NameFeed -ErrorAction SilentlyContinue).$NameFeed
if ($null -eq $CurrentFeed) { $CurrentFeed = "Not_Set" }

Set-ItemProperty -Path $RegistryPath -Name $NameFeed -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Sync" -Action "Disabled Activity Feed" -OldValue $CurrentFeed -NewValue "0"

# 2. Disable Publishing User Activities
$NamePublish = "PublishUserActivities"
$CurrentPublish = (Get-ItemProperty -Path $RegistryPath -Name $NamePublish -ErrorAction SilentlyContinue).$NamePublish
if ($null -eq $CurrentPublish) { $CurrentPublish = "Not_Set" }

Set-ItemProperty -Path $RegistryPath -Name $NamePublish -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Sync" -Action "Disabled Publishing User Activities" -OldValue $CurrentPublish -NewValue "0"

Write-Host "`n[SUCCESS] Windows Activity History and Timeline tracking have been disabled." -ForegroundColor Green
Write-Host "Windows will no longer secretly track which files/apps you open." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
