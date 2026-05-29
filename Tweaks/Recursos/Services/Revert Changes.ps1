# ========================================================================
#                    WinAurex - REVERT SERVICES TWEAK
# ========================================================================
# Restores optimized services back to Windows default Automatic startup.
# ========================================================================

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator! Please relaunch an elevated console."
    Exit
}

$services = @(
    "WbioSrvc",
    "FontCache",
    "FontCache3.0.0.0",
    "GraphicsPerfSvc",
    "stisvc",
    "WerSvc",
    "PcaSvc",
    "Wecsvc",
    "DiagTrack",
    "GpuEnergyDrv",
    "WSearch",
    "ShellHWDetection",
    "ssh-agent",
    "diagsvc",
    "DPS"
)

Write-Output "========================================================================"
Write-Output "                  REVERTING SERVICES TO AUTOMATIC"
Write-Output "========================================================================"

foreach ($service in $services) {
    if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
        Write-Host "Restoring: [ $service ] -> Automatic" -ForegroundColor Green
        Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $service -ErrorAction SilentlyContinue
    } else {
        Write-Host "Restoring: [ $service ] -> NOT DETECTED (Skipping)" -ForegroundColor Yellow
    }
}

Write-Output "========================================================================"
Write-Output "                     SERVICES REVERTED SUCCESSFULLY"
Write-Output "========================================================================"

Read-Host -Prompt "Press Enter to exit"
