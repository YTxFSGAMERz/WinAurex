[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Unnecessary Animations (Tweaks/Visual/Disable_Unnecessary_Animations.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Visual" -Action "Initiating UI Animation Disablement"

# 1. Disable Window Minimize/Maximize Animations
$RegPathWindow = "HKCU:\Control Panel\Desktop\WindowMetrics"
$NameWindow = "MinAnimate"

$CurrentValWindow = (Get-ItemProperty -Path $RegPathWindow -Name $NameWindow -ErrorAction SilentlyContinue).$NameWindow
if ($null -eq $CurrentValWindow) { $CurrentValWindow = "Not_Set" }

Set-ItemProperty -Path $RegPathWindow -Name $NameWindow -Value "0" -Type String -Force
Write-FrameworkLog -ModuleName "Visual" -Action "Disabled Window Animations" -OldValue $CurrentValWindow -NewValue "0"

# 2. Disable Taskbar Animations
$RegPathTaskbar = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$NameTaskbar = "TaskbarAnimations"

$CurrentValTaskbar = (Get-ItemProperty -Path $RegPathTaskbar -Name $NameTaskbar -ErrorAction SilentlyContinue).$NameTaskbar
if ($null -eq $CurrentValTaskbar) { $CurrentValTaskbar = "Not_Set" }

Set-ItemProperty -Path $RegPathTaskbar -Name $NameTaskbar -Value 0 -Type DWord -Force
Write-FrameworkLog -ModuleName "Visual" -Action "Disabled Taskbar Animations" -OldValue $CurrentValTaskbar -NewValue "0"

Write-Host "`n[SUCCESS] Unnecessary window and taskbar animations disabled." -ForegroundColor Green


$null = Read-Host "Press Enter to exit..."
