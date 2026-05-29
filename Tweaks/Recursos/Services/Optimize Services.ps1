# ========================================================================
#                  WinAurex - OPTIMIZE SERVICES TWEAK
# ========================================================================
# Enforces service states via Service Control Manager (SCM) to bypass
# strict registry key ACLs and permissions issues.
# ========================================================================

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator! Please relaunch an elevated console."
    Exit
}

$services = @{
    "WbioSrvc"         = "Disabled"
    "FontCache"        = "Disabled"
    "FontCache3.0.0.0" = "Disabled"
    "GraphicsPerfSvc"  = "Disabled"
    "stisvc"           = "Disabled"
    "WerSvc"           = "Disabled"
    "PcaSvc"           = "Disabled"
    "Wecsvc"           = "Disabled"
    "DiagTrack"        = "Disabled"
    "GpuEnergyDrv"     = "Disabled"
    "WSearch"          = "Disabled"
    "ShellHWDetection" = "Disabled"
    "ssh-agent"        = "Disabled"
    "diagsvc"          = "Disabled"
    "DPS"              = "Disabled"
}

Write-Output "========================================================================"
Write-Output "                  APPLYING SERVICES OPTIMIZATION"
Write-Output "========================================================================"

foreach ($service in $services.Keys) {
    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
        Write-Host "Configuring: [ $service ] -> $($services[$service])" -ForegroundColor Cyan
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType $services[$service] -ErrorAction SilentlyContinue
    } else {
        Write-Host "Configuring: [ $service ] -> NOT DETECTED (Skipping)" -ForegroundColor Yellow
    }
}

Write-Output "========================================================================"
Write-Output "                     SERVICES OPTIMIZATION APPLIED"
Write-Output "========================================================================"
