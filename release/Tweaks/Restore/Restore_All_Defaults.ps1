[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Restore All Defaults (Core/Restore/Restore_All_Defaults.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Initiating Master Default Restoration" -Level WARNING

Write-Host "================================================="
Write-Host "   WARNING: MASTER DEFAULT RESTORATION INIT" -ForegroundColor Yellow
Write-Host "================================================="
Write-Host "This will restore Windows back to its unoptimized default state."
Write-Host "Press 'Y' to continue or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Aborted Master Default Restoration"
    Write-Host "`nAborted by user."
    Exit
}

# Example restorations to implement:
# 1. Reset Power Plan to Balanced
Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Restoring Power Plan" -NewValue "Balanced"
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

# 2. Re-enable Fast Startup
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1 -ErrorAction SilentlyContinue

# 3. Reset Visual Effects to default (Let Windows Choose)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -ErrorAction SilentlyContinue

# 4. Restore Search/Cortana web results
Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -ErrorAction SilentlyContinue

Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Completed Master Default Restoration"

Write-Host "`n[SUCCESS] Critical systems restored to default. A reboot is highly recommended." -ForegroundColor Green
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

