<#
.SYNOPSIS
    WinAurex Microsoft Defender Policy Controller
.DESCRIPTION
    Configures Microsoft Defender Antivirus state via official Group Policy and Set-MpPreference.
    Detects Tamper Protection, real-time protection, and guides users through modern Windows 11 security constraints.
#>
[CmdletBinding()]
param (
    [switch]$Disable,
    [switch]$Enable,
    [switch]$Status,
    [switch]$Force,
    [switch]$ForceReapply,
    [switch]$OpenSettings
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex Microsoft Defender Policy Controller                " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

$DefenderPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$RealTimeKey       = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
$ReportingKey      = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting"
$SpynetKey         = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"

function Get-LiveDefenderStatus {
    $mp = $null
    try { $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue } catch {}
    
    $antiSpyware = (Get-ItemProperty $DefenderPolicyKey -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware
    $rtmPolicy   = (Get-ItemProperty $RealTimeKey -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue).DisableRealtimeMonitoring

    return @{
        IsTamperProtected         = if ($mp) { [bool]$mp.IsTamperProtected } else { $false }
        RealTimeProtectionEnabled = if ($mp) { [bool]$mp.RealTimeProtectionEnabled } else { $true }
        AntivirusEnabled          = if ($mp) { [bool]$mp.AntivirusEnabled } else { $true }
        GroupPolicyApplied        = ($antiSpyware -eq 1 -or $rtmPolicy -eq 1)
    }
}

if ($OpenSettings) {
    Write-Host "`n[*] Opening Windows Security Threat Settings..." -ForegroundColor Cyan
    Start-Process "windowsdefender://threatsettings"
    Exit 0
}

if ($Status) {
    $st = Get-LiveDefenderStatus
    Write-Host "`n[LIVE STATUS REPORT]" -ForegroundColor Yellow
    Write-Host "  Real-Time Protection : $(if ($st.RealTimeProtectionEnabled) { 'ACTIVE (Scanning)' } else { 'DISABLED (Off)' })" -ForegroundColor $(if ($st.RealTimeProtectionEnabled) { 'Green' } else { 'Yellow' })
    Write-Host "  Tamper Protection    : $(if ($st.IsTamperProtected) { 'ON (Blocking script changes)' } else { 'OFF (Allows modifications)' })" -ForegroundColor $(if ($st.IsTamperProtected) { 'Red' } else { 'Green' })
    Write-Host "  Group Policy Keys    : $(if ($st.GroupPolicyApplied) { 'TurnOff Policies Present' } else { 'Default (None)' })" -ForegroundColor Cyan
    Write-Host "  Antivirus Engine     : $(if ($st.AntivirusEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
    Exit 0
}

# Default action is Disable if neither is specified
if (-not $Enable -and -not $Disable) {
    $Disable = $true
}

if ($Disable) {
    $st = Get-LiveDefenderStatus
    
    # Check if already fully disabled
    if (-not $st.RealTimeProtectionEnabled -and $st.GroupPolicyApplied -and -not $ForceReapply) {
        Write-Host "`n  [-] Microsoft Defender Real-Time Protection is already DISABLED (Skipping)." -ForegroundColor DarkGray
        Exit 0
    }

    # Warn if Tamper Protection is blocking
    if ($st.IsTamperProtected) {
        Write-Warning "TAMPER PROTECTION IS CURRENTLY ON!"
        Write-Host "In Windows 11, Tamper Protection actively blocks Group Policy from turning off Defender." -ForegroundColor Red
        Write-Host "You must toggle 'Tamper Protection' to OFF in Windows Security settings for Defender to be disabled." -ForegroundColor Yellow
        Write-Host "Opening Windows Security directly to the Tamper Protection toggle..." -ForegroundColor Cyan
        try { Start-Process "windowsdefender://threatsettings" } catch {}
    }

    Write-Host "`n[*] Disabling Microsoft Defender Antivirus & Real-Time Monitoring..." -ForegroundColor Yellow
    try {
        # 1. Apply Set-MpPreference (takes immediate effect when Tamper Protection is OFF)
        try {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
            Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
        } catch {}

        # 2. Apply Official Group Policy Keys
        if (-not (Test-Path $DefenderPolicyKey)) { New-Item -Path $DefenderPolicyKey -Force | Out-Null }
        if (-not (Test-Path $RealTimeKey))       { New-Item -Path $RealTimeKey -Force | Out-Null }
        if (-not (Test-Path $ReportingKey))      { New-Item -Path $ReportingKey -Force | Out-Null }
        if (-not (Test-Path $SpynetKey))         { New-Item -Path $SpynetKey -Force | Out-Null }

        Set-ItemProperty -Path $DefenderPolicyKey -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $DefenderPolicyKey -Name "DisableAntiVirus"   -Value 1 -Type DWord -Force

        Set-ItemProperty -Path $RealTimeKey -Name "DisableRealtimeMonitoring"    -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableBehaviorMonitoring"    -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableOnAccessProtection"    -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableScanOnRealtimeEnable"  -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableIOAVProtection"        -Value 1 -Type DWord -Force

        Set-ItemProperty -Path $ReportingKey -Name "DisableEnhancedNotifications" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $SpynetKey -Name "DisableBlockAtFirstSeen"          -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $SpynetKey -Name "SubmitSamplesConsent"             -Value 2 -Type DWord -Force
        Set-ItemProperty -Path $SpynetKey -Name "SpynetReporting"                  -Value 0 -Type DWord -Force

        # Exclusions
        try {
            Add-MpPreference -ExclusionPath "C:\WinAurex" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "$env:TEMP" -ErrorAction SilentlyContinue
        } catch {}

        Write-Host "  [+] Set-MpPreference applied: Real-time, behavior, and IOAV monitoring stopped." -ForegroundColor Green
        Write-Host "  [+] Group Policy applied: Turn off Microsoft Defender Antivirus." -ForegroundColor Green
        Write-Host "  [+] Cloud telemetry and sample submission blocked." -ForegroundColor Green
        
        $newSt = Get-LiveDefenderStatus
        if ($newSt.IsTamperProtected) {
            Write-Host "`n[ACTION REQUIRED] In the Windows Security window that just opened:" -ForegroundColor Yellow
            Write-Host "  1. Click 'Manage settings' under Virus & threat protection settings." -ForegroundColor White
            Write-Host "  2. Scroll down and toggle 'Tamper Protection' to OFF." -ForegroundColor White
            Write-Host "  3. Re-run this script (or click 'Disable Defender' again in the dashboard)." -ForegroundColor White
        } else {
            Write-Host "`n[SUCCESS] Microsoft Defender Real-Time Protection is now DISABLED!" -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed applying Defender disablement: $_"
    }
} elseif ($Enable) {
    Write-Host "`n[*] Restoring Microsoft Defender Antivirus to Default Active State..." -ForegroundColor Cyan
    try {
        # Restore Set-MpPreference
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
            Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
        } catch {}

        # Restore registry keys
        if (Test-Path $DefenderPolicyKey) {
            Remove-ItemProperty -Path $DefenderPolicyKey -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $DefenderPolicyKey -Name "DisableAntiVirus" -ErrorAction SilentlyContinue
        }
        if (Test-Path $RealTimeKey) {
            Remove-ItemProperty -Path $RealTimeKey -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $RealTimeKey -Name "DisableBehaviorMonitoring" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $RealTimeKey -Name "DisableOnAccessProtection" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $RealTimeKey -Name "DisableScanOnRealtimeEnable" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $RealTimeKey -Name "DisableIOAVProtection" -ErrorAction SilentlyContinue
        }
        if (Test-Path $ReportingKey) {
            Remove-ItemProperty -Path $ReportingKey -Name "DisableEnhancedNotifications" -ErrorAction SilentlyContinue
        }
        if (Test-Path $SpynetKey) {
            Remove-ItemProperty -Path $SpynetKey -Name "DisableBlockAtFirstSeen" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $SpynetKey -Name "SubmitSamplesConsent" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $SpynetKey -Name "SpynetReporting" -ErrorAction SilentlyContinue
        }
        Write-Host "  [+] Real-time monitoring enabled and Group Policy overrides removed." -ForegroundColor Green
        Write-Host "  [+] Microsoft Defender Antivirus restored to Active defaults." -ForegroundColor Green
    } catch {
        Write-Error "Failed restoring Defender policy: $_"
    }
}

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host "`nPress Enter to finish..." -ForegroundColor DarkGray
    $null = [System.Console]::ReadLine()
}
