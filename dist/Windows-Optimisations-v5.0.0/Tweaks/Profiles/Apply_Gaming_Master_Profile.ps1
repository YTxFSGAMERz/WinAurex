# Windows Configuration & Optimization Framework
# Apply Gaming Master Profile (Tweaks/Profiles/Apply_Gaming_Master_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY GAMING MASTER PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile is designed for MAXIMUM GAMING PERFORMANCE."
Write-Host "It will:"
Write-Host "- Enable Ultimate Performance Power Plan and Game Mode"
Write-Host "- Enable Hardware Accelerated GPU Scheduling"
Write-Host "- Disable visual animations for maximum responsiveness"
Write-Host "- Disable heavy background telemetry and services"
Write-Host "- Disable Windows Update driver downloads"
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Profiles" -Action "Aborted Gaming Master Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Profiles" -Action "Starting Gaming Master Profile Deployment" -Level WARNING
$TweaksDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Tweaks"

# 1. Power
Write-Host "`n[1/6] Applying Power Optimizations..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Power\Enable_Ultimate_Performance_Plan.ps1")
& (Join-Path -Path $TweaksDir -ChildPath "Power\Disable_USB_Selective_Suspend.ps1")

# 2. GPU
Write-Host "`n[2/6] Applying GPU Optimizations..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "GPU\Apply_Gaming_GPU_Profile.ps1")

# 3. Visuals
Write-Host "`n[3/6] Applying Visual Optimizations..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Visual\Apply_Max_Performance_Profile.ps1")

# 4. Telemetry & Services
Write-Host "`n[4/6] Disabling Heavy Telemetry & Background Tasks..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Services\Apply_Clean_Services_Profile.ps1")
& (Join-Path -Path $TweaksDir -ChildPath "Tasks\Apply_Clean_Tasks_Profile.ps1")

# 5. Updates Control
Write-Host "`n[5/6] Disabling Driver Updates & Delivery Optimization..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Updates\Apply_Update_Control_Profile.ps1")

# 6. Search
Write-Host "`n[6/6] Disabling Web Search in Start Menu..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Search\Disable_Web_Search.ps1")

Write-FrameworkLog -ModuleName "Profiles" -Action "Completed Gaming Master Profile Deployment" -Level WARNING

Write-Host "`n[SUCCESS] Gaming Master Profile deployment complete!" -ForegroundColor Green
Write-Host "Please RESTART YOUR COMPUTER for all changes to take effect." -ForegroundColor Yellow
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
