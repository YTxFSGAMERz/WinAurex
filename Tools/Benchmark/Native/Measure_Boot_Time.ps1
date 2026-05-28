[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Measure Boot Time (Tools/Benchmark/Native/Measure_Boot_Time.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   NATIVE BOOT TIME OBSERVABILITY" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Querying Event Viewer (Diagnostics-Performance) to"
Write-Host "extract the exact duration of your most recent boots."
Write-Host "=================================================`n"

$Events = Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -FilterXPath "*[System[EventID=100]]" -MaxEvents 5 -ErrorAction SilentlyContinue

if (-not $Events) {
    Write-Host "[ERROR] Could not find boot performance logs. The Diagnostics Tracking service may be disabled." -ForegroundColor Red
    Exit
}

Write-Host "--- RECENT BOOT TIMES ---" -ForegroundColor Yellow

foreach ($Event in $Events) {
    # Convert XML EventData into searchable objects
    $EventXml = [xml]$Event.ToXml()
    $BootTimeMS = $EventXml.Event.EventData.Data | Where-Object { $_.Name -eq "BootTime" } | Select-Object -ExpandProperty '#text'
    $MainPathMS = $EventXml.Event.EventData.Data | Where-Object { $_.Name -eq "MainPathBootTime" } | Select-Object -ExpandProperty '#text'
    
    if ($BootTimeMS) {
        $TotalSeconds = [math]::Round([int]$BootTimeMS / 1000, 2)
        $MainSeconds = [math]::Round([int]$MainPathMS / 1000, 2)
        
        Write-Host "Date: $($Event.TimeCreated)" -ForegroundColor Cyan
        Write-Host "Total Boot Time:       $TotalSeconds seconds"
        Write-Host "Main Path (to desktop): $MainSeconds seconds"
        Write-Host "-------------------------"
    }
}

Write-Host "`n[INFO] 'Main Path' is the time taken to reach the desktop and be usable."
Write-Host "[INFO] 'Total Boot Time' includes all background startup apps loading."
Write-Host "`nPress any key to exit..."
if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }

