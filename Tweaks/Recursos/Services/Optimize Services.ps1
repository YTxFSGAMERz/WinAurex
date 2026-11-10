# ========================================================================
#                  WinAurex - OPTIMIZE SERVICES TWEAK
# ========================================================================
# Enforces safe service states via Service Control Manager (SCM).
# Critical OS services (FontCache, ShellHWDetection, DPS, PlugPlay)
# are strictly preserved to maintain system stability and app rendering.
# ========================================================================

param (
    [switch]$Force
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator! Please relaunch an elevated console."
    Exit
}

$services = @{
    "DiagTrack"        = "Disabled"
    "dmwappushservice" = "Disabled"
    "WerSvc"           = "Disabled"
    "PcaSvc"           = "Disabled"
    "Wecsvc"           = "Disabled"
    "GraphicsPerfSvc"  = "Manual"
    "GpuEnergyDrv"     = "Manual"
}

Write-Output "========================================================================"
Write-Output "                  APPLYING SERVICES OPTIMIZATION"
Write-Output "========================================================================"

foreach ($service in $services.Keys) {
    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
        Write-Host "Configuring: [ $service ] -> $($services[$service])" -ForegroundColor Cyan
        if ($services[$service] -eq "Disabled") {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        }
        Set-Service -Name $service -StartupType $services[$service] -ErrorAction SilentlyContinue
    } else {
        Write-Host "Configuring: [ $service ] -> NOT DETECTED (Skipping)" -ForegroundColor Yellow
    }
}

Write-Output "========================================================================"
Write-Output "                     SERVICES OPTIMIZATION APPLIED"
Write-Output "========================================================================"
if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $null = Read-Host "`nPress Enter to return..."
}
