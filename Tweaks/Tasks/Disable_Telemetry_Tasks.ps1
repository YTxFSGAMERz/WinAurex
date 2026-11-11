[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Telemetry Tasks (Tweaks/Tasks/Disable_Telemetry_Tasks.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

# Array of known heavy telemetry/CEIP tasks
$TelemetryTasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
)

$DisabledCount = 0

foreach ($TaskPath in $TelemetryTasks) {
    $parent = Split-Path $TaskPath -Parent
    $leaf = Split-Path $TaskPath -Leaf
    $Task = Get-ScheduledTask -TaskPath "$parent\" -TaskName $leaf -ErrorAction SilentlyContinue
    
    if ($Task) {
        $CurrentState = $Task.State
        
        if ($CurrentState -ne "Disabled") {
            Disable-ScheduledTask -TaskPath "$parent\" -TaskName $leaf -ErrorAction SilentlyContinue | Out-Null
            $DisabledCount++
        }
    }
}

if ($DisabledCount -eq 0) {
    Write-Host "  [-] Telemetry scheduled tasks (CEIP / Compatibility Appraiser) are already disabled (Skipping)." -ForegroundColor DarkGray
} else {
    Write-Host "`n[SUCCESS] Successfully disabled $DisabledCount background telemetry tasks." -ForegroundColor Green
    Write-Host "This will reduce background CPU spikes and disk I/O." -ForegroundColor Yellow
}
