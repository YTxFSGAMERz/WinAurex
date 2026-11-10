<#
.SYNOPSIS
    WinAurex Automated VM Tier Testing & Log Harness
.DESCRIPTION
    Runs a specified WinAurex safety tier (1 = Safe, 2 = Advanced, 3 = Critical),
    captures full before-and-after system telemetry (processes, RAM, services, Appx packages),
    diffs the changes, verifies Store and OS health, and generates an HTML test report + transcripts.
.PARAMETER Tier
    The safety tier to test: 1 (Safe), 2 (Advanced), or 3 (Critical).
.PARAMETER OutputDir
    Custom output directory for logs. Defaults to WinAurex\Logs\TestReports\TierX_<timestamp>.
.EXAMPLE
    .\Test_WinAurex_Tier.ps1 -Tier 1
    .\Test_WinAurex_Tier.ps1 -Tier 3 -RiskAccepted
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet(1, 2, 3)]
    [int]$Tier,

    [string]$OutputDir,

    [switch]$RiskAccepted
)

# 1. Administrator Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "VM Test Harness requires Administrator privileges to test system-wide services and policies."
    Write-Warning "Please relaunch PowerShell as Administrator."
    Exit 1
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$RepoRoot = (Get-Item (Join-Path $PSScriptRoot "..\..")).FullName

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $RepoRoot "Logs\TestReports\Tier${Tier}_${Timestamp}"
}
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

$TranscriptFile = Join-Path $OutputDir "execution_transcript.log"
Start-Transcript -Path $TranscriptFile -Append

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "          WinAurex Automated VM Tier Testing & Telemetry Harness        " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Target Tier  : Tier $Tier" -ForegroundColor Yellow
Write-Host " Output Dir   : $OutputDir" -ForegroundColor Yellow
Write-Host " Timestamp    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host " OS Build     : $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild)" -ForegroundColor Yellow
Write-Host "======================================================================`n"

# Helper for memory sizing
function Get-SystemMetrics {
    $os = Get-CimInstance Win32_OperatingSystem
    $procs = Get-Process
    $services = Get-Service
    [PSCustomObject]@{
        Timestamp          = (Get-Date).ToString("o")
        ProcessCount       = $procs.Count
        RunningServices    = ($services | Where-Object Status -eq 'Running').Count
        StoppedServices    = ($services | Where-Object Status -eq 'Stopped').Count
        DisabledServices   = ($services | Where-Object StartType -eq 'Disabled').Count
        TotalRAM_MB        = [math]::Round($os.TotalVisibleMemorySize / 1024, 2)
        FreeRAM_MB         = [math]::Round($os.FreePhysicalMemory / 1024, 2)
        UsedRAM_MB         = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024, 2)
        RAMUsagePercent    = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
    }
}

# ------------------------------------------------------------------------------
# PHASE 1: PRE-RUN BASELINE TELEMETRY CAPTURE
# ------------------------------------------------------------------------------
Write-Host "[1/4] Capturing pre-run baseline telemetry..." -ForegroundColor Cyan

$BaselineMetrics = Get-SystemMetrics
$BaselineMetrics | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputDir "metrics_before.json")

$BaselineServices = Get-Service | Select-Object Name, DisplayName, Status, StartType
$BaselineServices | Export-Csv -Path (Join-Path $OutputDir "services_before.csv") -NoTypeInformation -Encoding UTF8

$BaselineProcesses = Get-Process | Select-Object Id, ProcessName, @{N='MemoryMB';E={[math]::Round($_.WorkingSet64 / 1MB, 2)}}
$BaselineProcesses | Export-Csv -Path (Join-Path $OutputDir "processes_before.csv") -NoTypeInformation -Encoding UTF8

$BaselineAppx = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object Name, PackageFullName, Version
$BaselineAppx | Export-Csv -Path (Join-Path $OutputDir "appx_before.csv") -NoTypeInformation -Encoding UTF8

Write-Host " [+] Baseline: $($BaselineMetrics.ProcessCount) processes, $($BaselineMetrics.RunningServices) services running, $($BaselineMetrics.UsedRAM_MB) MB RAM used." -ForegroundColor Green

# ------------------------------------------------------------------------------
# PHASE 2: TIER EXECUTION
# ------------------------------------------------------------------------------
Write-Host "`n[2/4] Executing Tier $Tier optimizations..." -ForegroundColor Cyan

$StartTime = [System.Diagnostics.Stopwatch]::StartNew()

switch ($Tier) {
    1 {
        Write-Host ">>> Executing Tier 1 (Safe Suite)..." -ForegroundColor Green
        $SafeRunner = Join-Path $RepoRoot "Apply_Curated_Safe_Suite.ps1"
        & $SafeRunner -Force
    }
    2 {
        Write-Host ">>> Executing Tier 2 (Advanced Suite)..." -ForegroundColor Yellow
        # Apply Tier 1 Safe base first
        $SafeRunner = Join-Path $RepoRoot "Apply_Curated_Safe_Suite.ps1"
        & $SafeRunner -Force

        # Run Tier 2 Advanced modules
        Write-Host ">>> Applying Advanced Tuning Modules..." -ForegroundColor Yellow
        $edgeReg = Join-Path $RepoRoot "Tweaks\Browser\Configure Edge Performance.reg"
        if (Test-Path $edgeReg) { reg.exe import $edgeReg }

        $hibScript = Join-Path $RepoRoot "Tweaks\Power\Disable_Hibernation.ps1"
        if (Test-Path $hibScript) { & $hibScript -Force }

        $pagefileScript = Join-Path $RepoRoot "Tweaks\Storage-Advanced\Optimize_Pagefile_Configuration.ps1"
        if (Test-Path $pagefileScript) { & $pagefileScript -Force }

        $usbScript = Join-Path $RepoRoot "Tweaks\Power\Disable_USB_Selective_Suspend.ps1"
        if (Test-Path $usbScript) { & $usbScript -Force }
    }
    3 {
        Write-Host ">>> Executing Tier 3 (Critical / Heavy Tester Lab)..." -ForegroundColor Red
        $ExtremeDebloat = Join-Path $RepoRoot "Tweaks\System\Extreme_Debloat.ps1"
        & $ExtremeDebloat -Force -RiskAccepted

        $AggroServices = Join-Path $RepoRoot "Tweaks\Recursos\Services\Optimize Services.ps1"
        if (Test-Path $AggroServices) { & $AggroServices -Force }
    }
}

$StartTime.Stop()
$ExecutionDurationSeconds = [math]::Round($StartTime.Elapsed.TotalSeconds, 2)
Write-Host "`n[+] Tier $Tier execution completed in $ExecutionDurationSeconds seconds." -ForegroundColor Green

# ------------------------------------------------------------------------------
# PHASE 3: POST-RUN TELEMETRY CAPTURE
# ------------------------------------------------------------------------------
Write-Host "`n[3/4] Capturing post-run telemetry..." -ForegroundColor Cyan
Start-Sleep -Seconds 3 # Let process counters settle

$PostMetrics = Get-SystemMetrics
$PostMetrics | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputDir "metrics_after.json")

$PostServices = Get-Service | Select-Object Name, DisplayName, Status, StartType
$PostServices | Export-Csv -Path (Join-Path $OutputDir "services_after.csv") -NoTypeInformation -Encoding UTF8

$PostProcesses = Get-Process | Select-Object Id, ProcessName, @{N='MemoryMB';E={[math]::Round($_.WorkingSet64 / 1MB, 2)}}
$PostProcesses | Export-Csv -Path (Join-Path $OutputDir "processes_after.csv") -NoTypeInformation -Encoding UTF8

$PostAppx = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object Name, PackageFullName, Version
$PostAppx | Export-Csv -Path (Join-Path $OutputDir "appx_after.csv") -NoTypeInformation -Encoding UTF8

# ------------------------------------------------------------------------------
# PHASE 4: DIFFERENTIAL ANALYSIS & HEALTH AUDIT
# ------------------------------------------------------------------------------
Write-Host "`n[4/4] Performing differential telemetry analysis..." -ForegroundColor Cyan

# Service state changes
$ServiceChanges = @()
foreach ($bSvc in $BaselineServices) {
    $pSvc = $PostServices | Where-Object Name -eq $bSvc.Name
    if ($pSvc) {
        if ($bSvc.Status -ne $pSvc.Status -or $bSvc.StartType -ne $pSvc.StartType) {
            $ServiceChanges += [PSCustomObject]@{
                Service      = $bSvc.Name
                DisplayName  = $bSvc.DisplayName
                OldStatus    = $bSvc.Status
                NewStatus    = $pSvc.Status
                OldStartType = $bSvc.StartType
                NewStartType = $pSvc.StartType
            }
        }
    }
}
$ServiceChanges | Export-Csv -Path (Join-Path $OutputDir "services_diff.csv") -NoTypeInformation -Encoding UTF8

# Appx packages removed
$RemovedPackages = @()
foreach ($bPkg in $BaselineAppx) {
    if (-not ($PostAppx | Where-Object Name -eq $bPkg.Name)) {
        $RemovedPackages += $bPkg.Name
    }
}
$RemovedPackages | Out-File -FilePath (Join-Path $OutputDir "appx_removed.txt") -Encoding UTF8

# OS Health Check
$StorePkg = Get-AppxPackage -AllUsers -Name "*WindowsStore*" -ErrorAction SilentlyContinue
$StoreStatus = if ($StorePkg) { "PASSED (Present)" } else { "NOT FOUND" }

$WuSvc = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
$WuStatus = if ($WuSvc) { "$($WuSvc.Status) ($($WuSvc.StartType))" } else { "MISSING" }

$BitsSvc = Get-Service -Name "bits" -ErrorAction SilentlyContinue
$BitsStatus = if ($BitsSvc) { "$($BitsSvc.Status) ($($BitsSvc.StartType))" } else { "MISSING" }

$AppXSvc = Get-Service -Name "AppXSvc" -ErrorAction SilentlyContinue
$AppXStatus = if ($AppXSvc) { "$($AppXSvc.Status) ($($AppXSvc.StartType))" } else { "MISSING" }

$DnsHealthy = $false
try {
    if ([System.Net.Dns]::GetHostAddresses("dns.google")) { $DnsHealthy = $true }
} catch { }

# Process & RAM delta
$ProcessDelta = $PostMetrics.ProcessCount - $BaselineMetrics.ProcessCount
$RAMDeltaMB = [math]::Round($PostMetrics.UsedRAM_MB - $BaselineMetrics.UsedRAM_MB, 2)
$RunningServicesDelta = $PostMetrics.RunningServices - $BaselineMetrics.RunningServices

# ------------------------------------------------------------------------------
# GENERATE HTML REPORT
# ------------------------------------------------------------------------------
$TierNames = @{ 1 = "Tier 1: Safe (Daily Driver)"; 2 = "Tier 2: Advanced (Power User)"; 3 = "Tier 3: Critical (Heavy Tester)" }
$TierBadges = @{ 1 = "#00adb5"; 2 = "#ffb300"; 3 = "#ff2a6d" }

$ReportFile = Join-Path $OutputDir "Test_Report_Tier${Tier}_${Timestamp}.html"

$serviceDiffRows = ""
foreach ($sc in $ServiceChanges) {
    $serviceDiffRows += "<tr><td>$($sc.Service)</td><td>$($sc.DisplayName)</td><td>$($sc.OldStatus) ($($sc.OldStartType))</td><td>$($sc.NewStatus) ($($sc.NewStartType))</td></tr>"
}
if ($serviceDiffRows -eq "") { $serviceDiffRows = "<tr><td colspan='4'>No service states changed.</td></tr>" }

$appxRemovedItems = ""
foreach ($rp in $RemovedPackages) {
    $appxRemovedItems += "<li>$rp</li>"
}
if ($appxRemovedItems -eq "") { $appxRemovedItems = "<li>No Appx packages removed.</li>" }

$HtmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>WinAurex VM Test Report - Tier $Tier</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0b0c10; color: #c5c6c7; margin: 30px; }
        h1 { color: #66fcf1; border-bottom: 2px solid #45a29e; padding-bottom: 8px; }
        h2 { color: #45a29e; margin-top: 25px; }
        .badge { display: inline-block; padding: 4px 10px; border-radius: 4px; font-weight: bold; background-color: $($TierBadges[$Tier]); color: #000; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 15px; margin-top: 15px; }
        .card { background-color: #1f2833; border: 1px solid #333; border-radius: 6px; padding: 15px; }
        .card h3 { margin-top: 0; color: #66fcf1; font-size: 14px; text-transform: uppercase; }
        .metric-val { font-size: 24px; font-weight: bold; color: #fff; }
        .delta-good { color: #4ef037; font-size: 14px; }
        .delta-bad { color: #ff5252; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; background: #1f2833; border-radius: 6px; overflow: hidden; }
        th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #2f3e46; font-size: 13px; }
        th { background-color: #121820; color: #66fcf1; }
        tr:hover { background-color: #263238; }
        ul { background-color: #1f2833; padding: 15px 30px; border-radius: 6px; list-style-type: square; }
    </style>
</head>
<body>
    <h1>WinAurex VM Telemetry & Health Test Report</h1>
    <p>
        <span class="badge">$($TierNames[$Tier])</span>
        &nbsp;&bull;&nbsp; Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        &nbsp;&bull;&nbsp; Execution Duration: <b>${ExecutionDurationSeconds}s</b>
    </p>

    <h2>System Delta (Before vs After)</h2>
    <div class="grid">
        <div class="card">
            <h3>Process Count</h3>
            <div class="metric-val">$($PostMetrics.ProcessCount)</div>
            <div class="$(if ($ProcessDelta -le 0) {'delta-good'} else {'delta-bad'})">Delta: $ProcessDelta processes</div>
        </div>
        <div class="card">
            <h3>Running Services</h3>
            <div class="metric-val">$($PostMetrics.RunningServices)</div>
            <div class="$(if ($RunningServicesDelta -le 0) {'delta-good'} else {'delta-bad'})">Delta: $RunningServicesDelta running</div>
        </div>
        <div class="card">
            <h3>Used RAM</h3>
            <div class="metric-val">$($PostMetrics.UsedRAM_MB) MB</div>
            <div class="$(if ($RAMDeltaMB -le 0) {'delta-good'} else {'delta-bad'})">Delta: $RAMDeltaMB MB</div>
        </div>
        <div class="card">
            <h3>RAM Usage %</h3>
            <div class="metric-val">$($PostMetrics.RAMUsagePercent)%</div>
            <div>Total: $($PostMetrics.TotalRAM_MB) MB</div>
        </div>
    </div>

    <h2>Critical Health Indicators</h2>
    <table>
        <tr><th>Subsystem</th><th>Status</th><th>Integrity Check</th></tr>
        <tr><td>Microsoft Store Package</td><td>$StoreStatus</td><td>$(if ($StoreStatus -match 'PASSED') {'<span class="delta-good">OK</span>'} else {'<span class="delta-bad">FAIL</span>'})</td></tr>
        <tr><td>Windows Update (wuauserv)</td><td>$WuStatus</td><td>$(if ($WuStatus -match 'Running|demand|auto') {'<span class="delta-good">OK</span>'} else {'<span class="delta-bad">FAIL</span>'})</td></tr>
        <tr><td>BITS (Background Transfer)</td><td>$BitsStatus</td><td>$(if ($BitsStatus -match 'Running|demand|auto|Manual') {'<span class="delta-good">OK</span>'} else {'<span class="delta-bad">FAIL</span>'})</td></tr>
        <tr><td>AppX Deployment Service</td><td>$AppXStatus</td><td>$(if ($AppXStatus -match 'Running|auto') {'<span class="delta-good">OK</span>'} else {'<span class="delta-bad">FAIL</span>'})</td></tr>
        <tr><td>DNS Resolution</td><td>$(if ($DnsHealthy) {'Online (dns.google OK)'} else {'Offline / Error'})</td><td>$(if ($DnsHealthy) {'<span class="delta-good">OK</span>'} else {'<span class="delta-bad">WARN</span>'})</td></tr>
    </table>

    <h2>Service State Transitions ($($ServiceChanges.Count) modified)</h2>
    <table>
        <tr><th>Service</th><th>Display Name</th><th>Before</th><th>After</th></tr>
        $serviceDiffRows
    </table>

    <h2>Appx Packages Removed ($($RemovedPackages.Count) total)</h2>
    <ul>
        $appxRemovedItems
    </ul>

    <p style="text-align: center; color: #666; margin-top: 40px;">
        Generated by WinAurex Automated VM Test Harness
    </p>
</body>
</html>
"@

$HtmlReport | Set-Content -Path $ReportFile -Encoding UTF8

Stop-Transcript

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] VM Test & Telemetry Capture Complete!" -ForegroundColor Green
Write-Host " Output Directory: $OutputDir" -ForegroundColor White
Write-Host " HTML Report     : $ReportFile" -ForegroundColor Cyan
Write-Host " Transcript Log  : $TranscriptFile" -ForegroundColor Cyan
Write-Host " Diff CSVs       : services_diff.csv, metrics_before.json, metrics_after.json" -ForegroundColor Cyan
Write-Host "======================================================================`n"
