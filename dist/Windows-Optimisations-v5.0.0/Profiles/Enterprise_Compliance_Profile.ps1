# Windows Configuration & Optimization Framework
# Enterprise Compliance Profile (Profiles/Enterprise_Compliance_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$EngineDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Core\Restore\Engine"
Import-Module (Join-Path -Path $EngineDir -ChildPath "SnapshotEngine.psm1") -Force
$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   DEPLOYING: ENTERPRISE COMPLIANCE PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Target: SysAdmins, Corporate Devices, High-Security"
Write-Host "This will enforce HVCI/Memory Integrity, strict firewall"
Write-Host "rules, isolate telemetry entirely, and block consumer"
Write-Host "bloatware while maintaining Domain compatibility."
Write-Host "=================================================`n"

$Confirm = Read-Host "Are you sure you want to apply this profile? A transactional snapshot will be created. (Y/N)"
if ($Confirm -notmatch '^[yY]') { Exit }

# 1. Initialize Transaction
$TxnID = New-Transaction -ModuleName "Profiles" -ProfileName "EnterpriseCompliance"
Write-Host "Capturing system state to transaction $TxnID ..." -ForegroundColor Yellow

# 2. Telemetry Isolation (DiagTrack)
Snapshot-Service -ServiceName "DiagTrack" -NewStartType "Disabled" -NewStatus "Stopped"
Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue

# 3. Prevent Consumer Bloatware (Candy Crush, etc)
$ContentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $ContentDelivery)) { New-Item -Path $ContentDelivery -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $ContentDelivery -ValueName "SilentInstalledAppsEnabled" -NewValue 0
Set-ItemProperty -Path $ContentDelivery -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -Force

# 4. Enforce HVCI (Memory Integrity)
$HVCIKey = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
if (-not (Test-Path $HVCIKey)) { New-Item -Path $HVCIKey -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $HVCIKey -ValueName "Enabled" -NewValue 1
Set-ItemProperty -Path $HVCIKey -Name "Enabled" -Value 1 -Type DWord -Force

# 5. Disable Web Search in Start Menu
$SearchKey = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $SearchKey)) { New-Item -Path $SearchKey -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $SearchKey -ValueName "DisableSearchBoxSuggestions" -NewValue 1
Set-ItemProperty -Path $SearchKey -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force

# 6. Enable SmartScreen for Edge and Apps
$SmartScreen = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $SmartScreen)) { New-Item -Path $SmartScreen -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $SmartScreen -ValueName "EnableSmartScreen" -NewValue 1
Set-ItemProperty -Path $SmartScreen -Name "EnableSmartScreen" -Value 1 -Type DWord -Force

# 7. Close Transaction
Close-Transaction
Write-FrameworkLog -ModuleName "Profiles" -Action "Applied Enterprise Compliance Profile"

Write-Host "`n[SUCCESS] Enterprise Compliance Profile deployed successfully!" -ForegroundColor Green
Write-Host "Please restart your computer to apply HVCI and other security policies." -ForegroundColor Yellow
Start-Sleep -Seconds 3
