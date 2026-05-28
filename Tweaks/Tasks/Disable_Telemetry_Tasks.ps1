[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Telemetry Tasks (Tweaks/Tasks/Disable_Telemetry_Tasks.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Tasks" -Action "Initiating Telemetry Tasks Disablement"

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
    $Task = Get-ScheduledTask -TaskPath ($TaskPath | Split-Path -Parent) -TaskName ($TaskPath | Split-Path -Leaf) -ErrorAction SilentlyContinue
    
    if ($Task) {
        $CurrentState = $Task.State
        
        if ($CurrentState -ne "Disabled") {
            Disable-ScheduledTask -TaskPath ($TaskPath | Split-Path -Parent) -TaskName ($TaskPath | Split-Path -Leaf) | Out-Null
            Write-FrameworkLog -ModuleName "Tasks" -Action "Disabled Task: $TaskPath" -OldValue $CurrentState -NewValue "Disabled"
            $DisabledCount++
        }
    }
}

Write-Host "`n[SUCCESS] Successfully disabled $DisabledCount background telemetry tasks." -ForegroundColor Green
Write-Host "This will reduce background CPU spikes and disk I/O." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
