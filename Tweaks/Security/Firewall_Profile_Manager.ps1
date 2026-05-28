# Windows Configuration & Optimization Framework
# Firewall Profile Manager (Tweaks/Security/Firewall_Profile_Manager.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   FIREWALL PROFILE MANAGER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Manage Windows Defender Firewall states across all profiles."
Write-Host "WARNING: Disabling the firewall exposes your system to"
Write-Host "network attacks. Only disable for specific testing."
Write-Host "================================================="
Write-Host "1. Restore Default Firewall State (ON for all profiles)"
Write-Host "2. Disable Firewall entirely (DANGEROUS)"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-FrameworkLog -ModuleName "Security" -Action "Aborted Firewall config"
    Write-Host "`nAborted by user."
    Exit
}

if ($Choice -eq '1') {
    Write-Host "`nRestoring Firewall defaults..." -ForegroundColor Yellow
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-FrameworkLog -ModuleName "Security" -Action "Enabled Windows Firewall across all profiles"
    Write-Host "[SUCCESS] Windows Firewall is now ENABLED for all profiles." -ForegroundColor Green
} else {
    Write-Host "`nDisabling Windows Firewall..." -ForegroundColor Yellow
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Write-FrameworkLog -ModuleName "Security" -Action "Disabled Windows Firewall" -Level WARNING
    Write-Host "[WARNING] Windows Firewall is now DISABLED. Your system is vulnerable." -ForegroundColor Red
}

Start-Sleep -Seconds 2
