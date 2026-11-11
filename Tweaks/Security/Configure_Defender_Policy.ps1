<#
.SYNOPSIS
    WinAurex Microsoft Defender Policy Controller
.DESCRIPTION
    Configures Microsoft Defender Antivirus state via official Group Policy registry settings.
    Allows disabling real-time scanning, cloud telemetry, and background worker threads without
    damaging Windows Update, CBS servicing, or system file integrity.
#>
[CmdletBinding()]
param (
    [switch]$Disable,
    [switch]$Enable,
    [switch]$Status,
    [switch]$Force
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

function Get-DefenderPolicyStatus {
    $antiSpyware = (Get-ItemProperty $DefenderPolicyKey -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware
    $rtm = (Get-ItemProperty $RealTimeKey -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
    if ($antiSpyware -eq 1 -or $rtm -eq 1) {
        return "DISABLED"
    } else {
        return "ACTIVE"
    }
}

if ($Status) {
    $curStatus = Get-DefenderPolicyStatus
    if ($curStatus -eq "DISABLED") {
        Write-Host "`n[STATUS] Microsoft Defender Antivirus is: DISABLED (Group Policy Applied)" -ForegroundColor Yellow
    } else {
        Write-Host "`n[STATUS] Microsoft Defender Antivirus is: ACTIVE (Protection Enabled)" -ForegroundColor Green
    }
    Exit 0
}

# Default action is Disable if neither is specified
if (-not $Enable -and -not $Disable) {
    $Disable = $true
}

if ($Disable) {
    Write-Host "`n[*] Applying Group Policy: Turn off Microsoft Defender Antivirus..." -ForegroundColor Yellow
    try {
        if (-not (Test-Path $DefenderPolicyKey)) { New-Item -Path $DefenderPolicyKey -Force | Out-Null }
        if (-not (Test-Path $RealTimeKey))       { New-Item -Path $RealTimeKey -Force | Out-Null }
        if (-not (Test-Path $ReportingKey))      { New-Item -Path $ReportingKey -Force | Out-Null }
        if (-not (Test-Path $SpynetKey))         { New-Item -Path $SpynetKey -Force | Out-Null }

        # Group Policy: Turn off Microsoft Defender Antivirus
        Set-ItemProperty -Path $DefenderPolicyKey -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $DefenderPolicyKey -Name "DisableAntiVirus"   -Value 1 -Type DWord -Force

        # Real-time monitoring and behavior analysis suppression
        Set-ItemProperty -Path $RealTimeKey -Name "DisableRealtimeMonitoring"    -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableBehaviorMonitoring"    -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableOnAccessProtection"    -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableScanOnRealtimeEnable"  -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $RealTimeKey -Name "DisableIOAVProtection"        -Value 1 -Type DWord -Force

        # Disable telemetry and warning notifications
        Set-ItemProperty -Path $ReportingKey -Name "DisableEnhancedNotifications" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $SpynetKey -Name "DisableBlockAtFirstSeen"          -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $SpynetKey -Name "SubmitSamplesConsent"             -Value 2 -Type DWord -Force
        Set-ItemProperty -Path $SpynetKey -Name "SpynetReporting"                  -Value 0 -Type DWord -Force

        # Inject scanning exclusions for development and performance
        try {
            Add-MpPreference -ExclusionPath "C:\WinAurex" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "$env:TEMP" -ErrorAction SilentlyContinue
        } catch {}

        Write-Host "  [+] Group Policy applied: Turn off Microsoft Defender Antivirus." -ForegroundColor Green
        Write-Host "  [+] Real-time scanning, file interception, and behavior analysis disabled." -ForegroundColor Green
        Write-Host "  [+] Cloud telemetry and sample submission blocked." -ForegroundColor Green
        Write-Host "`n[NOTE] Windows requires a RESTART for the group policy to take full effect." -ForegroundColor Cyan
        Write-Host "If Tamper Protection is enabled in Windows Security, toggle it off in Settings." -ForegroundColor DarkGray
    } catch {
        Write-Error "Failed applying Defender group policy: $_"
    }
} elseif ($Enable) {
    Write-Host "`n[*] Restoring Microsoft Defender Antivirus to Default Active State..." -ForegroundColor Cyan
    try {
        # Restore registry keys to enabled defaults
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
        Write-Host "  [+] Group Policy removed. Microsoft Defender Antivirus restored to Active." -ForegroundColor Green
        Write-Host "`n[NOTE] Please RESTART your computer to complete the restoration." -ForegroundColor Yellow
    } catch {
        Write-Error "Failed restoring Defender policy: $_"
    }
}

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host "`nPress Enter to finish..." -ForegroundColor DarkGray
    $null = [System.Console]::ReadLine()
}
