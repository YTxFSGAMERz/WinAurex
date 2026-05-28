[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Recent Files and Frequent Folders (Tweaks/Explorer/Disable_Recent_Frequent.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Explorer" -Action "Initiating Recent/Frequent Tracking Cleanup"

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"

# Setting 1: Show Recent Files (0 = Hide, 1 = Show)
$RecentVal = (Get-ItemProperty -Path $RegistryPath -Name "ShowRecent" -ErrorAction SilentlyContinue).ShowRecent
if ($null -eq $RecentVal) { $RecentVal = "Not_Set" }
Set-ItemProperty -Path $RegistryPath -Name "ShowRecent" -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Explorer" -Action "Disable Show Recent Files" -OldValue $RecentVal -NewValue "0"

# Setting 2: Show Frequent Folders (0 = Hide, 1 = Show)
$FrequentVal = (Get-ItemProperty -Path $RegistryPath -Name "ShowFrequent" -ErrorAction SilentlyContinue).ShowFrequent
if ($null -eq $FrequentVal) { $FrequentVal = "Not_Set" }
Set-ItemProperty -Path $RegistryPath -Name "ShowFrequent" -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Explorer" -Action "Disable Show Frequent Folders" -OldValue $FrequentVal -NewValue "0"

Write-Host "`n[SUCCESS] Recent files and Frequent folders have been hidden from Explorer." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
