# Windows Configuration & Optimization Framework
# Analyze DPC Latency (Tweaks/Drivers/Analyze_DPC_Latency.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   DPC LATENCY & ISR ANALYZER (NATIVE)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "High DPC (Deferred Procedure Call) time causes audio crackling,"
Write-Host "mouse stutters, and frame drops. This script monitors the CPU"
Write-Host "for DPC/ISR spikes over a 10-second window."
Write-Host "=================================================`n"

Write-Host "Sampling DPC and ISR processor times for 10 seconds. Do not move your mouse..." -ForegroundColor Yellow

# Collect performance counters for Processor Time, DPC Time, and Interrupt Time
$Counters = "\Processor Information(_Total)\% DPC Time", "\Processor Information(_Total)\% Interrupt Time", "\Processor Information(_Total)\% Processor Time"
$Samples = Get-Counter -Counter $Counters -SampleInterval 1 -MaxSamples 10 -ErrorAction SilentlyContinue

if (-not $Samples) {
    Write-Host "[ERROR] Could not read performance counters. Performance counters may be disabled/corrupt." -ForegroundColor Red
    Exit
}

$DpcValues = @()
$IsrValues = @()

foreach ($Sample in $Samples) {
    $DpcValues += $Sample.CounterSamples | Where-Object Path -match "dpc" | Select-Object -ExpandProperty CookedValue
    $IsrValues += $Sample.CounterSamples | Where-Object Path -match "interrupt" | Select-Object -ExpandProperty CookedValue
}

$AvgDPC = ($DpcValues | Measure-Object -Average).Average
$MaxDPC = ($DpcValues | Measure-Object -Maximum).Maximum
$AvgISR = ($IsrValues | Measure-Object -Average).Average

Write-Host "`n--- ANALYSIS RESULTS ---" -ForegroundColor Cyan
Write-Host "Average DPC Time: $([math]::Round($AvgDPC, 4)) %"
Write-Host "Maximum DPC Spike: $([math]::Round($MaxDPC, 4)) %"
Write-Host "Average ISR Time: $([math]::Round($AvgISR, 4)) %"

if ($MaxDPC -gt 5.0) {
    Write-Host "`n[WARNING] High DPC latency spikes detected!" -ForegroundColor Red
    Write-Host "A driver is taking too long to execute. Common culprits:"
    Write-Host "- Outdated NVIDIA/AMD GPU Drivers (use DDU)"
    Write-Host "- Realtek Audio Drivers"
    Write-Host "- Wi-Fi or Ethernet network drivers"
    Write-Host "Recommendation: Download 'LatencyMon' for deep driver-level analysis."
} else {
    Write-Host "`n[SUCCESS] Your DPC execution times are well within normal bounds." -ForegroundColor Green
    Write-Host "System should be responsive and free of audio crackling."
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
