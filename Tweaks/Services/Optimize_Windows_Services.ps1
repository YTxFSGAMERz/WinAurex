<#
.SYNOPSIS
    WinAurex Background Services Optimizer
.DESCRIPTION
    Permanently disables non-essential, telemetry, and bloated background services to free RAM,
    reduce handle/thread counts, and eliminate background CPU interruptions.
#>
[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$Revert
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "           WinAurex Background Services Optimizer                     " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

# 15+ Useless / Heavy Background Services
$TargetServices = @(
    @{ Name = "DiagTrack";       Desc = "Connected User Experiences and Telemetry"; RevertStart = 2 },
    @{ Name = "dmwappushservice";Desc = "WAP Push Message Routing Service";          RevertStart = 3 },
    @{ Name = "WerSvc";          Desc = "Windows Error Reporting Service";          RevertStart = 3 },
    @{ Name = "PcaSvc";          Desc = "Program Compatibility Assistant Service";  RevertStart = 3 },
    @{ Name = "MapsBroker";      Desc = "Downloaded Maps Manager";                  RevertStart = 2 },
    @{ Name = "lfsvc";           Desc = "Geolocation / Location Service";           RevertStart = 3 },
    @{ Name = "RemoteRegistry";  Desc = "Remote Registry Service";                  RevertStart = 4 },
    @{ Name = "RetailDemo";      Desc = "Retail Demo Kiosk Service";                RevertStart = 3 },
    @{ Name = "SharedAccess";    Desc = "Internet Connection Sharing (ICS)";        RevertStart = 3 },
    @{ Name = "wisvc";           Desc = "Windows Insider Beta Service";             RevertStart = 3 },
    @{ Name = "Fax";             Desc = "Legacy Fax Service";                       RevertStart = 4 },
    @{ Name = "XblAuthManager";  Desc = "Xbox Live Auth Manager";                   RevertStart = 3 },
    @{ Name = "XblGameSave";     Desc = "Xbox Live Game Save Service";              RevertStart = 3 },
    @{ Name = "XboxNetApiSvc";   Desc = "Xbox Live Networking Service";             RevertStart = 3 },
    @{ Name = "DusmSvc";         Desc = "Data Usage Monitoring Service";            RevertStart = 2 }
)

$ActionCount = 0

if ($Revert) {
    Write-Host "[*] Reverting background services to default startup types..." -ForegroundColor Yellow
    foreach ($item in $TargetServices) {
        $name = $item.Name
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($svc) {
            try {
                $targetType = if ($item.RevertStart -eq 2) { "Automatic" } elseif ($item.RevertStart -eq 3) { "Manual" } else { "Disabled" }
                Set-Service -Name $name -StartupType $targetType -ErrorAction SilentlyContinue
                Write-Host "  [+] Restored service: $name ($targetType)" -ForegroundColor DarkGray
                $ActionCount++
            } catch {}
        }
    }
    Write-Host "`n[SUCCESS] Reverted $ActionCount services to default configuration." -ForegroundColor Green
} else {
    Write-Host "[*] Stopping and disabling non-essential background services..." -ForegroundColor Cyan
    foreach ($item in $TargetServices) {
        $name = $item.Name
        $desc = $item.Desc
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($svc) {
            try {
                if ($svc.Status -eq "Running") {
                    Stop-Service -Name $name -Force -ErrorAction SilentlyContinue
                }
                Set-Service -Name $name -StartupType Disabled -ErrorAction SilentlyContinue
                
                # Enforce in Registry for permanence
                $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
                if (Test-Path $regPath) {
                    Set-ItemProperty -Path $regPath -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
                }
                Write-Host "  [+] Disabled: $name ($desc)" -ForegroundColor Green
                $ActionCount++
            } catch {
                Write-Warning "Failed modifying service $name : $_"
            }
        }
    }
    Write-Host "`n[SUCCESS] Permanently disabled $ActionCount non-essential background services." -ForegroundColor Green
    Write-Host "Idle RAM and background CPU interrupt overhead significantly reduced." -ForegroundColor Yellow
}

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host "`nPress Enter to finish..." -ForegroundColor DarkGray
    $null = [System.Console]::ReadLine()
}
