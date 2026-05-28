# Windows Configuration & Optimization Framework
# Apply Workstation Master Profile (Tweaks/Profiles/Apply_Workstation_Master_Profile.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   APPLY WORKSTATION MASTER PROFILE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This profile is designed for PRODUCTIVITY AND STABILITY."
Write-Host "It will:"
Write-Host "- Apply the Productivity Explorer Layout"
Write-Host "- Apply Balanced Aesthetic Visuals"
Write-Host "- Disable heavy background telemetry and tracking"
Write-Host "- Disable web search in the Start Menu for faster local searches"
Write-Host "- Keep power settings balanced and driver updates enabled for stability"
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Profiles" -Action "Aborted Workstation Master Profile Deployment"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Profiles" -Action "Starting Workstation Master Profile Deployment" -Level WARNING
$TweaksDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Tweaks"

# 1. Explorer
Write-Host "`n[1/4] Applying Productivity Explorer Layout..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Explorer\Apply_Productivity_Explorer_Profile.ps1")

# 2. Visuals
Write-Host "`n[2/4] Applying Balanced Aesthetic Visuals..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Visual\Apply_Balanced_Aesthetic_Profile.ps1")

# 3. Telemetry & Services
Write-Host "`n[3/4] Disabling Heavy Telemetry & Background Tasks..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Services\Apply_Clean_Services_Profile.ps1")
& (Join-Path -Path $TweaksDir -ChildPath "Tasks\Apply_Clean_Tasks_Profile.ps1")

# 4. Search
Write-Host "`n[4/4] Disabling Web Search in Start Menu..." -ForegroundColor Cyan
& (Join-Path -Path $TweaksDir -ChildPath "Search\Disable_Web_Search.ps1")

Write-FrameworkLog -ModuleName "Profiles" -Action "Completed Workstation Master Profile Deployment" -Level WARNING

Write-Host "`n[SUCCESS] Workstation Master Profile deployment complete!" -ForegroundColor Green
Write-Host "Please RESTART YOUR COMPUTER for all changes to take effect." -ForegroundColor Yellow
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
