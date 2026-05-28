[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Exclusive Mode Manager (Tweaks/Audio/Exclusive_Mode_Manager.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore\Audio"

if (-not (Test-Path $SnapshotDir)) { New-Item -Path $SnapshotDir -ItemType Directory -Force | Out-Null }

Write-Host "================================================="
Write-Host "   WASAPI EXCLUSIVE MODE MANAGER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "WASAPI Exclusive Mode allows applications (games, DAWs)"
Write-Host "to bypass the Windows audio mixer, communicating directly"
Write-Host "with the audio driver for the lowest possible latency."
Write-Host "================================================="
Write-Host "1. Enable Exclusive Mode (Recommended for Gamers/Producers)"
Write-Host "2. Disable Exclusive Mode (Forces all audio through Windows Mixer)"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-FrameworkLog -ModuleName "Audio" -Action "Aborted Exclusive Mode config"
    Write-Host "`nAborted by user."
    Exit
}

Write-Host "`nScanning for Audio Endpoints..." -ForegroundColor Yellow
$RenderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
$CapturePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"

function Toggle-ExclusiveMode {
    param([string]$KeyPath, [int]$Value)
    
    if (Test-Path $KeyPath) {
        $Devices = Get-ChildItem -Path $KeyPath
        foreach ($Device in $Devices) {
            $Properties = Join-Path -Path $Device.PSPath -ChildPath "Properties"
            if (Test-Path $Properties) {
                # Property {b3f8fa53-0004-438e-9003-51a46e139bfc},3 corresponds to "Allow applications to take exclusive control of this device"
                # Property {b3f8fa53-0004-438e-9003-51a46e139bfc},4 corresponds to "Give exclusive mode applications priority"
                
                Set-ItemProperty -Path $Properties -Name "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" -Value $Value -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $Properties -Name "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" -Value $Value -Type DWord -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($Choice -eq '1') {
    Write-Host "Enabling Exclusive Mode on Output devices..." -ForegroundColor Yellow
    Toggle-ExclusiveMode -KeyPath $RenderPath -Value 1
    Write-Host "Enabling Exclusive Mode on Input devices..." -ForegroundColor Yellow
    Toggle-ExclusiveMode -KeyPath $CapturePath -Value 1
    
    Write-FrameworkLog -ModuleName "Audio" -Action "Enabled WASAPI Exclusive Mode"
    Write-Host "`n[SUCCESS] Exclusive Mode is ENABLED." -ForegroundColor Green
} else {
    Write-Host "Disabling Exclusive Mode on Output devices..." -ForegroundColor Yellow
    Toggle-ExclusiveMode -KeyPath $RenderPath -Value 0
    Write-Host "Disabling Exclusive Mode on Input devices..." -ForegroundColor Yellow
    Toggle-ExclusiveMode -KeyPath $CapturePath -Value 0

    Write-FrameworkLog -ModuleName "Audio" -Action "Disabled WASAPI Exclusive Mode"
    Write-Host "`n[SUCCESS] Exclusive Mode is DISABLED." -ForegroundColor Red
}

Write-Host "Please restart the Windows Audio service or reboot to apply changes." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
