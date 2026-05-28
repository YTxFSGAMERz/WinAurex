# Windows Configuration & Optimization Framework
# Max Performance Profile (Profiles/Max_Performance_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$EngineDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Core\Restore\Engine"
Import-Module (Join-Path -Path $EngineDir -ChildPath "SnapshotEngine.psm1") -Force
$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   DEPLOYING: MAX PERFORMANCE PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Target: Esports Gamers, Audio Producers, Latency Obsessives"
Write-Host "This will strip telemetry, disable mouse acceleration,"
Write-Host "enforce WASAPI exclusive mode, and optimize Explorer."
Write-Host "=================================================`n"

$Confirm = Read-Host "Are you sure you want to apply this profile? A transactional snapshot will be created. (Y/N)"
if ($Confirm -notmatch '^[yY]') { Exit }

# 1. Initialize Transaction
$TxnID = New-Transaction -ModuleName "Profiles" -ProfileName "MaxPerformance"
Write-Host "Capturing system state to transaction $TxnID ..." -ForegroundColor Yellow

# 2. Telemetry Isolation (DiagTrack)
Snapshot-Service -ServiceName "DiagTrack" -NewStartType "Disabled" -NewStatus "Stopped"
Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue

# 3. Disable Mouse Acceleration (EPP)
$MouseKey = "HKCU:\Control Panel\Mouse"
if (-not (Test-Path $MouseKey)) { New-Item -Path $MouseKey -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $MouseKey -ValueName "MouseSpeed" -NewValue "0"
Snapshot-RegistryKey -KeyPath $MouseKey -ValueName "MouseThreshold1" -NewValue "0"
Snapshot-RegistryKey -KeyPath $MouseKey -ValueName "MouseThreshold2" -NewValue "0"
Set-ItemProperty -Path $MouseKey -Name "MouseSpeed" -Value "0" -Type String -Force
Set-ItemProperty -Path $MouseKey -Name "MouseThreshold1" -Value "0" -Type String -Force
Set-ItemProperty -Path $MouseKey -Name "MouseThreshold2" -Value "0" -Type String -Force

$SmoothCurve = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x15,0x6e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x01,0x00,0x00,0x00,0x00,0x00,0x29,0xdc,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x00,0x00)
Snapshot-RegistryKey -KeyPath $MouseKey -ValueName "SmoothMouseXCurve"
Snapshot-RegistryKey -KeyPath $MouseKey -ValueName "SmoothMouseYCurve"
Set-ItemProperty -Path $MouseKey -Name "SmoothMouseXCurve" -Value $SmoothCurve -Type Binary -Force
Set-ItemProperty -Path $MouseKey -Name "SmoothMouseYCurve" -Value $SmoothCurve -Type Binary -Force

# 4. Disable Automatic Driver Replacement
$WUKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (-not (Test-Path $WUKey)) { New-Item -Path $WUKey -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $WUKey -ValueName "ExcludeWUDriversInQualityUpdate" -NewValue 1
Set-ItemProperty -Path $WUKey -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force

# 5. Disable Web Search in Start Menu
$SearchKey = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $SearchKey)) { New-Item -Path $SearchKey -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $SearchKey -ValueName "DisableSearchBoxSuggestions" -NewValue 1
Set-ItemProperty -Path $SearchKey -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force

# 6. WASAPI Exclusive Mode Enforce (Render)
$RenderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
if (Test-Path $RenderPath) {
    $Devices = Get-ChildItem -Path $RenderPath
    foreach ($Device in $Devices) {
        $Props = Join-Path -Path $Device.PSPath -ChildPath "Properties"
        if (Test-Path $Props) {
            Snapshot-RegistryKey -KeyPath $Props -ValueName "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" -NewValue 1
            Snapshot-RegistryKey -KeyPath $Props -ValueName "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" -NewValue 1
            Set-ItemProperty -Path $Props -Name "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $Props -Name "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }
}

# 7. Close Transaction
Close-Transaction
Write-FrameworkLog -ModuleName "Profiles" -Action "Applied Max Performance Profile"

Write-Host "`n[SUCCESS] Max Performance Profile deployed successfully!" -ForegroundColor Green
Write-Host "Please restart your computer to apply all state changes." -ForegroundColor Yellow
Start-Sleep -Seconds 3
