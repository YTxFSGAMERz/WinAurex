[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Apply Privacy Master Profile (Tweaks/Profiles/Apply_Privacy_Master_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY MAXIMUM PRIVACY MASTER PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile is designed for MAXIMUM DATA PROTECTION."
Write-Host "It will:"
Write-Host "- Disable all OS-level Diagnostic Data & Telemetry"
Write-Host "- Disable Telemetry Scheduled Tasks and Services"
Write-Host "- Disable Cloud Clipboard and Sync"
Write-Host "- Disable Settings Sync & Activity History"
Write-Host "- Disable Lock Screen & App Camera Access"
Write-Host "- Remove Sponsored Apps (Debloat)"
if (-not $Force) {
    Write-Host "Press 'Y' to continue or any other key to abort..."
    if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }
    if ($Confirm -notmatch 'y') {
        Write-FrameworkLog -ModuleName "Profiles" -Action "Aborted Privacy Master Profile Deployment"
        Write-Host "`nAborted by user."
        Exit
    }
}

Write-FrameworkLog -ModuleName "Profiles" -Action "Starting Privacy Master Profile Deployment" -Level WARNING
$TweaksDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Tweaks"

# 1. Core Diagnostics
Write-Host "`n[1/6] Disabling OS Diagnostic Data & Ads..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Diagnostics\Apply_Diagnostics_Privacy_Profile.ps1") -Force:$Force

# 2. Services & Tasks
Write-Host "`n[2/6] Disabling Telemetry Background Tasks & Services..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Services\Apply_Clean_Services_Profile.ps1") -Force:$Force
& (Join-Path -Path $TweaksDir -ChildPath "Tasks\Apply_Clean_Tasks_Profile.ps1") -Force:$Force

# 3. Data Sync
Write-Host "`n[3/6] Disabling Cloud Sync & Activity History..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Sync\Apply_Privacy_Sync_Profile.ps1") -Force:$Force

# 4. Clipboard
Write-Host "`n[4/6] Disabling Cloud Clipboard..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Clipboard\Apply_Privacy_Clipboard_Profile.ps1") -Force:$Force

# 5. Hardware Privacy
Write-Host "`n[5/6] Restricting Camera Access..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Camera\Apply_Privacy_Camera_Profile.ps1") -Force:$Force

# 6. Apps Debloat
Write-Host "`n[6/6] Removing Sponsored Bloatware..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Apps\Remove_Sponsored_Apps.ps1") -Force:$Force

Write-FrameworkLog -ModuleName "Profiles" -Action "Completed Privacy Master Profile Deployment" -Level WARNING

Write-Host "`n[SUCCESS] Maximum Privacy Master Profile deployment complete!" -ForegroundColor Green
Write-Host "Please RESTART YOUR COMPUTER for all changes to take effect." -ForegroundColor Yellow
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

