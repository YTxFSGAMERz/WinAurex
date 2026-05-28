[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Analyze SSD Health (Tweaks/Storage-Advanced/Analyze_SSD_Health.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   SSD & NVME HEALTH ANALYZER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Gathering physical disk SMART data and wear indicators..."
Write-Host "=================================================`n"

$Disks = Get-PhysicalDisk | Where-Object MediaType -in @("SSD", "Unspecified")

if ($Disks.Count -eq 0) {
    Write-Host "[INFO] No SSDs detected by the Windows storage subsystem." -ForegroundColor Yellow
}

foreach ($Disk in $Disks) {
    Write-Host "Drive: $($Disk.FriendlyName)" -ForegroundColor Cyan
    Write-Host "Health Status: $($Disk.HealthStatus)"
    Write-Host "Operational Status: $($Disk.OperationalStatus)"
    Write-Host "Bus Type: $($Disk.BusType)"
    
    # Storage Reliability Counters (Requires StorageSpaces or proper NVMe drivers)
    $Counters = $Disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
    
    if ($Counters) {
        Write-Host "Temperature: $($Counters.Temperature) C"
        
        if ($Counters.Wear -ne $null) {
            Write-Host "Wear Indicator: $($Counters.Wear)%"
            if ($Counters.Wear -lt 10) {
                Write-Host "-> Drive is heavily worn." -ForegroundColor Red
            } else {
                Write-Host "-> Drive wear is acceptable." -ForegroundColor Green
            }
        } else {
            Write-Host "Wear Indicator: Not reported by firmware." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "SMART/Reliability Counters: Not exposed to Windows (generic driver or RAID)." -ForegroundColor DarkGray
    }
    Write-Host "-------------------------------------------------"
}

if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}

