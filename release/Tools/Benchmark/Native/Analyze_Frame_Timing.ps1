[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Analyze Frame Timing & Queue Depth (Tools/Benchmark/Native/Analyze_Frame_Timing.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   NATIVE FRAME TIMING & QUEUE ANALYZER" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Inconsistent frame pacing is often caused by high"
Write-Host "CPU queue lengths or GPU engine bottlenecks."
Write-Host "Sampling system responsiveness over 15 seconds..."
Write-Host "=================================================`n"

# Performance Counters
$Counters = @(
    "\System\Processor Queue Length",
    "\Processor(_Total)\% Processor Time",
    "\Processor Information(_Total)\% DPC Time",
    "\PhysicalDisk(_Total)\Current Disk Queue Length"
)

# For GPU we must find the exact instance names
$GpuCounters = (Get-Counter -ListSet "GPU Engine" -ErrorAction SilentlyContinue).Counter | Where-Object { $_ -match "engtype_3D" } | Select-Object -First 1
if ($GpuCounters) {
    $Counters += $GpuCounters
}

$Samples = Get-Counter -Counter $Counters -SampleInterval 1 -MaxSamples 15 -ErrorAction SilentlyContinue

if (-not $Samples) {
    Write-Host "[ERROR] Could not read performance counters." -ForegroundColor Red
    Exit
}

$ProcessorQueue = @()
$DpcTime = @()
$DiskQueue = @()

foreach ($Sample in $Samples) {
    $ProcessorQueue += $Sample.CounterSamples | Where-Object Path -match "processor queue length" | Select-Object -ExpandProperty CookedValue
    $DpcTime += $Sample.CounterSamples | Where-Object Path -match "dpc time" | Select-Object -ExpandProperty CookedValue
    $DiskQueue += $Sample.CounterSamples | Where-Object Path -match "disk queue length" | Select-Object -ExpandProperty CookedValue
}

$AvgProcQueue = ($ProcessorQueue | Measure-Object -Average).Average
$MaxProcQueue = ($ProcessorQueue | Measure-Object -Maximum).Maximum
$AvgDpc = ($DpcTime | Measure-Object -Average).Average
$MaxDiskQueue = ($DiskQueue | Measure-Object -Maximum).Maximum

Write-Host "`n--- OBSERVABILITY RESULTS ---" -ForegroundColor Cyan
Write-Host "Average CPU Queue Length:  $([math]::Round($AvgProcQueue, 2)) threads waiting"
Write-Host "Peak CPU Queue Length:     $([math]::Round($MaxProcQueue, 2)) threads waiting"
Write-Host "Average DPC Time:          $([math]::Round($AvgDpc, 4)) %"
Write-Host "Peak Disk Queue Length:    $([math]::Round($MaxDiskQueue, 2)) IO ops waiting"

Write-Host "`n--- DIAGNOSTICS ---" -ForegroundColor Cyan

if ($AvgProcQueue -gt 2) {
    Write-Host "[WARNING] CPU Queue Length is high. Threads are starving for CPU cycles. This causes stuttering." -ForegroundColor Red
} else {
    Write-Host "[OK] CPU scheduling is responsive." -ForegroundColor Green
}

if ($AvgDpc -gt 3) {
    Write-Host "[WARNING] DPC Time is high. A driver is hogging execution time, delaying frames." -ForegroundColor Red
} else {
    Write-Host "[OK] DPC execution is within bounds." -ForegroundColor Green
}

if ($MaxDiskQueue -gt 5) {
    Write-Host "[WARNING] Disk Queue is peaking high. Games loading assets may stutter." -ForegroundColor Red
} else {
    Write-Host "[OK] NVMe/SSD IO is healthy." -ForegroundColor Green
}

Write-Host "`nFor absolute true frame-time variance analysis, we recommend installing Intel PresentMon." -ForegroundColor Yellow
Write-Host "`nPress any key to exit..."
if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }

