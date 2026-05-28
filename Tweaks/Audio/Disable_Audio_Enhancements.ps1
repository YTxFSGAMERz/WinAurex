# Windows Configuration & Optimization Framework
# Disable Audio Enhancements (Tweaks/Audio/Disable_Audio_Enhancements.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore\Audio"

if (-not (Test-Path $SnapshotDir)) { New-Item -Path $SnapshotDir -ItemType Directory -Force | Out-Null }

Write-Host "================================================="
Write-Host "   AUDIO ENHANCEMENTS MANAGER (LATENCY FIX)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Windows and Audio Drivers (like Realtek) often inject 'Signal"
Write-Host "Enhancements' (APOs) that add artificial latency and color the"
Write-Host "sound. Disabling these is critical for pure audio delivery."
Write-Host "================================================="
Write-Host "1. Disable All Audio Enhancements (Recommended for Latency/Purity)"
Write-Host "2. Enable Audio Enhancements (Default)"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-FrameworkLog -ModuleName "Audio" -Action "Aborted Audio Enhancements config"
    Write-Host "`nAborted by user."
    Exit
}

Write-Host "`nScanning for Audio Endpoints..." -ForegroundColor Yellow
$RenderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
$CapturePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"

# Function to toggle DisableProtectedAudioDG and DisableSysFx
function Toggle-Enhancements {
    param([string]$KeyPath, [int]$Value)
    
    if (Test-Path $KeyPath) {
        $Devices = Get-ChildItem -Path $KeyPath
        foreach ($Device in $Devices) {
            $FxProperties = Join-Path -Path $Device.PSPath -ChildPath "FxProperties"
            if (Test-Path $FxProperties) {
                # Backup the specific FX key if disabling
                if ($Value -eq 1) {
                    $BackupFile = Join-Path -Path $SnapshotDir -ChildPath "AudioFX_$($Device.PSChildName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                    $RegPathClean = $FxProperties -replace "::", "" -replace "Microsoft.PowerShell.Core\\Registry::", ""
                    & reg export $RegPathClean $BackupFile /y 2>$null | Out-Null
                }

                # Set DisableSysFx (commonly {1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5)
                # Just loop through known property keys that disable effects
                $Props = Get-Item -Path $FxProperties
                foreach ($PropName in $Props.Property) {
                    if ($PropName -match "1da5d803-d492-4edd-8c23-e0c0ffee7f0e") {
                        Set-ItemProperty -Path $FxProperties -Name $PropName -Value $Value -Type DWord -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
}

if ($Choice -eq '1') {
    Write-Host "Disabling enhancements on Output devices..." -ForegroundColor Yellow
    Toggle-Enhancements -KeyPath $RenderPath -Value 1
    Write-Host "Disabling enhancements on Input devices..." -ForegroundColor Yellow
    Toggle-Enhancements -KeyPath $CapturePath -Value 1
    
    Write-FrameworkLog -ModuleName "Audio" -Action "Disabled Audio Enhancements globally"
    Write-Host "`n[SUCCESS] Audio Enhancements are DISABLED." -ForegroundColor Green
} else {
    Write-Host "Enabling enhancements on Output devices..." -ForegroundColor Yellow
    Toggle-Enhancements -KeyPath $RenderPath -Value 0
    Write-Host "Enabling enhancements on Input devices..." -ForegroundColor Yellow
    Toggle-Enhancements -KeyPath $CapturePath -Value 0

    Write-FrameworkLog -ModuleName "Audio" -Action "Enabled Audio Enhancements globally"
    Write-Host "`n[SUCCESS] Audio Enhancements are ENABLED." -ForegroundColor Green
}

Write-Host "Please restart the Windows Audio service or reboot to apply changes." -ForegroundColor Yellow
Start-Sleep -Seconds 3
