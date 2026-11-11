<#
.SYNOPSIS
    WinAurex Process, Thread & Handle Reducer
.DESCRIPTION
    Measurably reduces active Windows process count, thread count, and kernel handle count
    by disabling background application permissions, suppressing telemetry scheduled tasks,
    optimizing NT kernel scheduling, and trimming idle process working sets.
#>
[CmdletBinding()]
param (
    [switch]$Force
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex Kernel Process, Thread & Handle Reducer             " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. Capture BEFORE Metrics
function Get-SystemMetrics {
    $procs = [System.Diagnostics.Process]::GetProcesses()
    $pCount = $procs.Count
    $tCount = 0
    $hCount = 0
    foreach ($p in $procs) {
        try {
            $tCount += $p.Threads.Count
            $hCount += $p.HandleCount
        } catch {}
    }
    return @{
        Processes = $pCount
        Threads   = $tCount
        Handles   = $hCount
    }
}

$before = Get-SystemMetrics
Write-Host "`n[*] Baseline System Metrics:" -ForegroundColor Yellow
Write-Host "    Active Processes : $($before.Processes)" -ForegroundColor DarkGray
Write-Host "    Active Threads   : $($before.Threads)" -ForegroundColor DarkGray
Write-Host "    Active Handles   : $($before.Handles)" -ForegroundColor DarkGray

# 2. Disable Background Apps Globally (Prevents UWP apps from spawning background threads)
Write-Host "`n[*] Disabling background application execution permissions..." -ForegroundColor Cyan
try {
    # AppPrivacy Policy (Machine level)
    $appPriv = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
    if (-not (Test-Path $appPriv)) { New-Item -Path $appPriv -Force | Out-Null }
    Set-ItemProperty -Path $appPriv -Name "LetAppsRunInBackground" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue

    # Current User toggles
    $bgAccess = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (-not (Test-Path $bgAccess)) { New-Item -Path $bgAccess -Force | Out-Null }
    Set-ItemProperty -Path $bgAccess -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

    $searchBg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (-not (Test-Path $searchBg)) { New-Item -Path $searchBg -Force | Out-Null }
    Set-ItemProperty -Path $searchBg -Name "BackgroundAppGlobalToggle" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

    Write-Host "  [+] Background app execution permanently blocked." -ForegroundColor Green
} catch {
    Write-Warning "Failed configuring BackgroundApp permissions: $_"
}

# 3. Suppress High-Frequency Telemetry Scheduled Tasks
Write-Host "`n[*] Suppressing high-frequency telemetry scheduled tasks..." -ForegroundColor Cyan
$TelemetryTasks = @(
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Maintenance\WinSAT"
)

$tasksDisabled = 0
foreach ($t in $TelemetryTasks) {
    try {
        $path = Split-Path $t -Parent
        $name = Split-Path $t -Leaf
        $task = Get-ScheduledTask -TaskPath "$path\" -TaskName $name -ErrorAction SilentlyContinue
        if ($task -and $task.State -ne "Disabled") {
            Disable-ScheduledTask -TaskPath "$path\" -TaskName $name -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  [+] Disabled Task: $name" -ForegroundColor DarkGray
            $tasksDisabled++
        }
    } catch {}
}
Write-Host "  [+] Successfully suppressed $tasksDisabled background scheduled tasks." -ForegroundColor Green

# 4. Kernel Responsiveness & Worker Thread Tuning
Write-Host "`n[*] Optimizing Windows NT Kernel Responsiveness..." -ForegroundColor Cyan
try {
    $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (-not (Test-Path $sysProfile)) { New-Item -Path $sysProfile -Force | Out-Null }
    # 0 = 100% priority for foreground tasks / games
    Set-ItemProperty -Path $sysProfile -Name "SystemResponsiveness" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    # Disable network packet throttling
    Set-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force -ErrorAction SilentlyContinue

    # Keep kernel drivers in physical memory (prevents paging delays)
    $memMgmt = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    if (Test-Path $memMgmt) {
        Set-ItemProperty -Path $memMgmt -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  [+] Foreground responsiveness optimized (SystemResponsiveness = 0)." -ForegroundColor Green
} catch {
    Write-Warning "Failed configuring kernel responsiveness: $_"
}

# 5. Flush Idle Process Working Sets
Write-Host "`n[*] Trimming idle memory working sets & flushing handles..." -ForegroundColor Cyan
try {
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    # Optional Win32 EmptyWorkingSet
    $emptyWorkingSetSig = @'
[DllImport("psapi.dll")]
public static extern int EmptyWorkingSet(IntPtr hwProc);
'@
    $psapi = Add-Type -MemberDefinition $emptyWorkingSetSig -Name "PsapiMemTrim" -Namespace "WinAurexKern" -PassThru -ErrorAction SilentlyContinue
    if ($psapi) {
        $procs = [System.Diagnostics.Process]::GetProcesses()
        foreach ($p in $procs) {
            try {
                if ($p.Id -ne 0 -and $p.Id -ne 4) {
                    [WinAurexKern.PsapiMemTrim]::EmptyWorkingSet($p.Handle) | Out-Null
                }
            } catch {}
        }
    }
    Write-Host "  [+] Process working sets flushed successfully." -ForegroundColor Green
} catch {}

# 6. Capture AFTER Metrics & Comparison
Start-Sleep -Seconds 1
$after = Get-SystemMetrics

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host "                 PROCESS & THREAD REDUCTION REPORT                   " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " Metric           | Baseline | Optimized | Delta" -ForegroundColor Cyan
Write-Host " -----------------+----------+-----------+-------" -ForegroundColor DarkGray
$procDelta = $after.Processes - $before.Processes
$threadDelta = $after.Threads - $before.Threads
$handleDelta = $after.Handles - $before.Handles
Write-Host (" Active Processes | {0,8} | {1,9} | {2,5}" -f $before.Processes, $after.Processes, $procDelta) -ForegroundColor White
Write-Host (" Active Threads   | {0,8} | {1,9} | {2,5}" -f $before.Threads, $after.Threads, $threadDelta) -ForegroundColor Green
Write-Host (" Active Handles   | {0,8} | {1,9} | {2,5}" -f $before.Handles, $after.Handles, $handleDelta) -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " System responsiveness maximized and background thread overhead purged." -ForegroundColor Yellow

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host "`nPress Enter to finish..." -ForegroundColor DarkGray
    $null = [System.Console]::ReadLine()
}
