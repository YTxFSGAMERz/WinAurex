[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Generate System Performance Report (Tools/Benchmark/Native/Generate_System_Performance_Report.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$ReportDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Reports"
if (-not (Test-Path $ReportDir)) { New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null }

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path -Path $ReportDir -ChildPath "System_Health_Report_$Timestamp.html"

Write-Host "================================================="
Write-Host "   SYSTEM HEALTH & PERFORMANCE REPORT GENERATOR" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Gathering native telemetry... This will take ~10 seconds." -ForegroundColor Yellow

# 1. System Info
$OSInfo = Get-CimInstance Win32_OperatingSystem
$CpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
$MemInfo = Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory, TotalVisibleMemorySize

# 2. Performance Counters (DPC, Queue, Threads)
$Samples = Get-Counter -Counter "\Processor Information(_Total)\% DPC Time", "\System\Processor Queue Length", "\System\Threads" -SampleInterval 1 -MaxSamples 5 -ErrorAction SilentlyContinue
$AvgDpc = 0; $AvgQueue = 0; $AvgThreads = 0
if ($Samples) {
    $AvgDpc = ($Samples | ForEach-Object { $_.CounterSamples | Where Path -match "dpc" | Select -Expand CookedValue } | Measure-Object -Average).Average
    $AvgQueue = ($Samples | ForEach-Object { $_.CounterSamples | Where Path -match "processor queue" | Select -Expand CookedValue } | Measure-Object -Average).Average
    $AvgThreads = ($Samples | ForEach-Object { $_.CounterSamples | Where Path -match "threads" | Select -Expand CookedValue } | Measure-Object -Average).Average
}

# 3. Services & Processes
$ActiveServices = (Get-Service | Where-Object Status -eq 'Running').Count
$TotalProcesses = (Get-Process).Count

# 4. Boot Time
$Events = Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -FilterXPath "*[System[EventID=100]]" -MaxEvents 1 -ErrorAction SilentlyContinue
$BootTime = "N/A"
if ($Events) {
    $EventXml = [xml]$Events[0].ToXml()
    $BootTimeMS = $EventXml.Event.EventData.Data | Where-Object { $_.Name -eq "BootTime" } | Select-Object -ExpandProperty '#text'
    if ($BootTimeMS) { $BootTime = "$([math]::Round([int]$BootTimeMS / 1000, 2)) seconds" }
}

Write-Host "Generating HTML Report..." -ForegroundColor Cyan

$Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Health Report ($Timestamp)</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #121212; color: #e0e0e0; margin: 40px; }
        h1 { border-bottom: 2px solid #00adb5; padding-bottom: 10px; color: #00adb5; }
        h2 { color: #eeeeee; margin-top: 30px; }
        .card { background-color: #1e1e1e; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); margin-bottom: 20px; }
        .metric { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #333; }
        .metric:last-child { border-bottom: none; }
        .label { font-weight: bold; color: #a0a0a0; }
        .value { color: #00adb5; font-weight: bold; }
        .warning { color: #ff5722; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Windows-Optimisations System Health Report</h1>
    
    <div class="card">
        <h2>Hardware & OS</h2>
        <div class="metric"><span class="label">OS Version:</span> <span class="value">$($OSInfo.Caption) ($($OSInfo.Version))</span></div>
        <div class="metric"><span class="label">CPU:</span> <span class="value">$($CpuInfo.Name)</span></div>
        <div class="metric"><span class="label">Total Memory:</span> <span class="value">$([math]::Round($MemInfo.TotalVisibleMemorySize / 1024 / 1024, 2)) GB</span></div>
        <div class="metric"><span class="label">Free Memory:</span> <span class="value">$([math]::Round($MemInfo.FreePhysicalMemory / 1024 / 1024, 2)) GB</span></div>
    </div>

    <div class="card">
        <h2>Observability & Latency Metrics</h2>
        <div class="metric"><span class="label">Average DPC Time:</span> <span class="value">$([math]::Round($AvgDpc, 4)) %</span></div>
        <div class="metric"><span class="label">CPU Queue Length:</span> <span class="value">$([math]::Round($AvgQueue, 2))</span></div>
        <div class="metric"><span class="label">Active Threads:</span> <span class="value">$([math]::Round($AvgThreads, 0))</span></div>
        <div class="metric"><span class="label">Running Services:</span> <span class="value">$ActiveServices</span></div>
        <div class="metric"><span class="label">Active Processes:</span> <span class="value">$TotalProcesses</span></div>
        <div class="metric"><span class="label">Last Boot Time:</span> <span class="value">$BootTime</span></div>
    </div>
    
    <div style="text-align: center; margin-top: 40px; color: #777;">
        Generated by the Windows Configuration & Optimization Framework
    </div>
</body>
</html>
"@

$Html | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "`n[SUCCESS] Report generated: $ReportFile" -ForegroundColor Green
Write-Host "Open this file in your browser to view."

Write-Host "`nPress any key to exit..."
if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }

