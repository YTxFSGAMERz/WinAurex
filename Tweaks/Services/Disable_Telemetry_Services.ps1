[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Telemetry Services (Tweaks/Services/Disable_Telemetry_Services.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

# Array of known heavy telemetry services
$TelemetryServices = @(
    "DiagTrack",       # Connected User Experiences and Telemetry
    "dmwappushservice" # WAP Push Message Routing
)

$DisabledCount = 0

foreach ($ServiceName in $TelemetryServices) {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if ($Service) {
        $CurrentState = $Service.StartType
        
        if ($CurrentState -ne "Disabled" -or $Service.Status -eq "Running") {
            # Stop the service if running
            if ($Service.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            }
            
            # Disable startup
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
            $DisabledCount++
        }
    }
}

if ($DisabledCount -eq 0) {
    Write-Host "  [-] Background telemetry services (DiagTrack) are already disabled (Skipping)." -ForegroundColor DarkGray
} else {
    Write-Host "`n[SUCCESS] Successfully disabled $DisabledCount background telemetry services." -ForegroundColor Green
    Write-Host "This will reduce idle RAM usage and block Microsoft data collection." -ForegroundColor Yellow
}
