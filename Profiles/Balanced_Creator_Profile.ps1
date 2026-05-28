# Windows Configuration & Optimization Framework
# Balanced Creator Profile (Profiles/Balanced_Creator_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$EngineDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Core\Restore\Engine"
Import-Module (Join-Path -Path $EngineDir -ChildPath "SnapshotEngine.psm1") -Force
$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   DEPLOYING: BALANCED CREATOR PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Target: Software Developers, Video Editors, Power Users"
Write-Host "This will optimize Explorer, manage pagefiles, disable"
Write-Host "ads/bloatware, but keep Windows Update and driver"
Write-Host "servicing fully functional."
Write-Host "=================================================`n"

$Confirm = Read-Host "Are you sure you want to apply this profile? A transactional snapshot will be created. (Y/N)"
if ($Confirm -notmatch '^[yY]') { Exit }

# 1. Initialize Transaction
$TxnID = New-Transaction -ModuleName "Profiles" -ProfileName "BalancedCreator"
Write-Host "Capturing system state to transaction $TxnID ..." -ForegroundColor Yellow

# 2. Explorer Optimization (Classic Context Menus, Disable Ads)
$CUExplorer = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if (-not (Test-Path $CUExplorer)) { New-Item -Path $CUExplorer -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $CUExplorer -ValueName "(Default)" -NewValue ""
Set-ItemProperty -Path $CUExplorer -Name "(Default)" -Value "" -Type String -Force

$AdsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Snapshot-RegistryKey -KeyPath $AdsKey -ValueName "ShowSyncProviderNotifications" -NewValue 0
Set-ItemProperty -Path $AdsKey -Name "ShowSyncProviderNotifications" -Value 0 -Type DWord -Force

# 3. Disable Visual Bloat (Transparency) but keep animations
$ThemesKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Snapshot-RegistryKey -KeyPath $ThemesKey -ValueName "EnableTransparency" -NewValue 0
Set-ItemProperty -Path $ThemesKey -Name "EnableTransparency" -Value 0 -Type DWord -Force

# 4. Storage / SSD Trim Assurance
$Fsutil = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
Snapshot-RegistryKey -KeyPath $Fsutil -ValueName "DisableDeleteNotify" -NewValue 0
Set-ItemProperty -Path $Fsutil -Name "DisableDeleteNotify" -Value 0 -Type DWord -Force

# 5. Disable Web Search in Start Menu (Crucial for all profiles)
$SearchKey = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $SearchKey)) { New-Item -Path $SearchKey -Force | Out-Null }
Snapshot-RegistryKey -KeyPath $SearchKey -ValueName "DisableSearchBoxSuggestions" -NewValue 1
Set-ItemProperty -Path $SearchKey -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force

# 6. Close Transaction
Close-Transaction
Write-FrameworkLog -ModuleName "Profiles" -Action "Applied Balanced Creator Profile"

Write-Host "`n[SUCCESS] Balanced Creator Profile deployed successfully!" -ForegroundColor Green
Write-Host "Please restart Windows Explorer or reboot to apply changes." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
