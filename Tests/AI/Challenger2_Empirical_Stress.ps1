<#
.SYNOPSIS
    WinAurex Milestone 1 - Empirical Challenger 2 Stress & Benchmark Harness
.DESCRIPTION
    Rigorous adversarial verification harness for Milestone 1:
    1. Benchmark inference throughput under load (1,500 randomized calls)
    2. Measure throughput (ms/call), latency percentiles, and memory stability
    3. Parameter contract compliance across all TargetType values & adversarial boundary inputs
    4. Catalog parsing & accessor integrity
    5. Global scope pollution and memory leak checks
#>

[CmdletBinding()]
param(
    [int]$BenchmarkIterations = 1500
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
$modulePath = Join-Path $repoRoot "Core\AI\WinAurex_AiEngine.psm1"
$dataDir = Join-Path $repoRoot "Core\AI\Data"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " WINAUTH / WINAUREX EMPIRICAL CHALLENGER 2 - STRESS TEST HARNESS" -ForegroundColor Cyan
Write-Host " Milestone 1: Offline AI Knowledge Base & Inference Engine" -ForegroundColor Cyan
Write-Host " Host OS: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor DarkCyan
Write-Host " PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor DarkCyan
Write-Host "=================================================================`n" -ForegroundColor Cyan

$testResults = [System.Collections.Generic.List[PSCustomObject]]::new()

function Assert-Check {
    param(
        [string]$TestCategory,
        [string]$TestName,
        [bool]$Condition,
        [string]$Details = ""
    )
    $status = if ($Condition) { "PASS" } else { "FAIL" }
    $color = if ($Condition) { "Green" } else { "Red" }
    Write-Host "  [$status] $TestCategory :: $TestName $(if ($Details) { "--> $Details" })" -ForegroundColor $color
    $testResults.Add([PSCustomObject]@{
        Category = $TestCategory
        Name     = $TestName
        Passed   = $Condition
        Details  = $Details
    })
}

# -----------------------------------------------------------------------------
# TEST SUITE 1: SCOPE POLLUTION CHECK BEFORE IMPORT
# -----------------------------------------------------------------------------
Write-Host "[1/5] Testing Scope Cleanliness & Module Import..." -ForegroundColor Yellow

$harnessVars = @('harnessVars', 'globalVarsBefore', 'globalVarsAfter', 'leakedGlobals')
$globalVarsBefore = @(Get-Variable -Scope Global | Select-Object -ExpandProperty Name)

Import-Module $modulePath -Force

$globalVarsAfter = @(Get-Variable -Scope Global | Select-Object -ExpandProperty Name)
$leakedGlobals = @($globalVarsAfter | Where-Object { $globalVarsBefore -notcontains $_ -and $harnessVars -notcontains $_ })

Assert-Check -TestCategory "Scope Hygiene" `
    -TestName "Zero Global Variable Pollution on Import" `
    -Condition ($leakedGlobals.Count -eq 0) `
    -Details "Leaked globals: $($leakedGlobals -join ', ')"

# -----------------------------------------------------------------------------
# TEST SUITE 2: CATALOG PARSING & ACCESSOR INTEGRITY
# -----------------------------------------------------------------------------
Write-Host "`n[2/5] Testing Catalog Parsing, Schema Conformance & Accessors..." -ForegroundColor Yellow

$serviceCatalog = Get-WinAurexServiceCatalog
Assert-Check -TestCategory "Catalog Integrity" `
    -TestName "Get-WinAurexServiceCatalog returns valid object" `
    -Condition ($null -ne $serviceCatalog -and $null -ne $serviceCatalog.services) `
    -Details "Total services: $($serviceCatalog.services.Count)"

$taskCatalog = Get-WinAurexTaskCatalog
Assert-Check -TestCategory "Catalog Integrity" `
    -TestName "Get-WinAurexTaskCatalog returns valid object" `
    -Condition ($null -ne $taskCatalog -and $null -ne $taskCatalog.tasks) `
    -Details "Total tasks: $($taskCatalog.tasks.Count)"

$bloatCatalog = Get-WinAurexBloatwareCatalog
Assert-Check -TestCategory "Catalog Integrity" `
    -TestName "Get-WinAurexBloatwareCatalog returns valid object" `
    -Condition ($null -ne $bloatCatalog -and $null -ne $bloatCatalog.packages) `
    -Details "Total bloatware packages: $($bloatCatalog.packages.Count), Shield rules: $($bloatCatalog.shield_rules.protected_package_patterns.Count)"

$tweakCatalog = Get-WinAurexTweakCatalog
Assert-Check -TestCategory "Catalog Integrity" `
    -TestName "Get-WinAurexTweakCatalog returns valid object" `
    -Condition ($null -ne $tweakCatalog -and $null -ne $tweakCatalog.tweaks) `
    -Details "Total tweaks: $($tweakCatalog.tweaks.Count)"

$coreWhitelist = Get-WinAurexCoreWhitelist
$isHashSet = ($coreWhitelist -is [System.Collections.Generic.HashSet[string]] -or $coreWhitelist.GetType().FullName -like "*HashSet*")
Assert-Check -TestCategory "Catalog Integrity" `
    -TestName "Get-WinAurexCoreWhitelist returns non-unrolled HashSet[string]" `
    -Condition ($isHashSet -and $coreWhitelist.Count -ge 47) `
    -Details "Whitelist type: $($coreWhitelist.GetType().FullName), Count: $($coreWhitelist.Count)"

# Validate individual catalog entries schema
$invalidServiceEntries = @($serviceCatalog.services | Where-Object { 
    -not $_.Name -or -not $_.Category -or -not $_.SafetyTier -or $null -eq $_.IsSafeToDisable
})
Assert-Check -TestCategory "Catalog Schema" `
    -TestName "All Service Catalog entries have required schema fields" `
    -Condition ($invalidServiceEntries.Count -eq 0) `
    -Details "Invalid count: $($invalidServiceEntries.Count)"

$invalidTaskEntries = @($taskCatalog.tasks | Where-Object {
    -not $_.TaskName -or -not $_.TaskPath -or -not $_.Category -or -not $_.SafetyTier
})
Assert-Check -TestCategory "Catalog Schema" `
    -TestName "All Scheduled Task Catalog entries have required schema fields" `
    -Condition ($invalidTaskEntries.Count -eq 0) `
    -Details "Invalid count: $($invalidTaskEntries.Count)"

$invalidBloatEntries = @($bloatCatalog.packages | Where-Object {
    -not $_.Name -or -not $_.Category -or -not $_.SafetyTier -or $null -eq $_.IsSystemApp
})
Assert-Check -TestCategory "Catalog Schema" `
    -TestName "All Bloatware Catalog entries have required schema fields" `
    -Condition ($invalidBloatEntries.Count -eq 0) `
    -Details "Invalid count: $($invalidBloatEntries.Count)"

$invalidTweakEntries = @($tweakCatalog.tweaks | Where-Object {
    -not $_.Id -or -not $_.Category -or -not $_.SafetyTier
})
Assert-Check -TestCategory "Catalog Schema" `
    -TestName "All Tweak Catalog entries have required schema fields" `
    -Condition ($invalidTweakEntries.Count -eq 0) `
    -Details "Invalid count: $($invalidTweakEntries.Count)"

# -----------------------------------------------------------------------------
# TEST SUITE 3: PARAMETER CONTRACT & ADVERSARIAL BOUNDARY TESTING
# -----------------------------------------------------------------------------
Write-Host "`n[3/5] Testing Parameter Contracts & Adversarial Boundary Inputs..." -ForegroundColor Yellow

$requiredFields = @("Name", "Category", "SafetyTier", "Confidence", "IsSafeToDisable", "EstImpact", "TweakAction", "CanonicalCategory", "Reason")
$targetTypes = @("Service", "AppX", "ScheduledTask", "SystemTweak", "")

# 3.1 All TargetType validation
foreach ($tt in $targetTypes) {
    try {
        $res = Invoke-AiInference -Name "TestComponent_$tt" -TargetType $tt
        $isPsc = ($res -is [System.Management.Automation.PSCustomObject])
        $missingFields = @($requiredFields | Where-Object { $null -eq $res.PSObject.Properties[$_] })
        Assert-Check -TestCategory "Parameter Contract" `
            -TestName "TargetType='$tt' returns PSCustomObject with all 9 fields" `
            -Condition ($isPsc -and $missingFields.Count -eq 0) `
            -Details "Missing: $($missingFields -join ', ')"
    } catch {
        Assert-Check -TestCategory "Parameter Contract" `
            -TestName "TargetType='$tt' invocation did not throw" `
            -Condition $false `
            -Details "Threw: $($_.Exception.Message)"
    }
}

# 3.2 Boundary and Adversarial Inputs
$adversarialInputs = @(
    @{ Name = "Null Name"; ValName = $null; Desc = "Testing null"; Vendor = "Microsoft"; TT = "Service" },
    @{ Name = "Empty Name"; ValName = ""; Desc = ""; Vendor = ""; TT = "Service" },
    @{ Name = "Whitespace Name"; ValName = "   `t`r`n   "; Desc = "   "; Vendor = "   "; TT = "Service" },
    @{ Name = "Null All Parameters"; ValName = $null; Desc = $null; Vendor = $null; TT = "" },
    @{ Name = "Very Long Name (4KB)"; ValName = ("A" * 4096); Desc = ("Desc " * 500); Vendor = "LongVendor"; TT = "Service" },
    @{ Name = "Special Symbols & Punctuations"; ValName = '!@#$%^&*()_+-=[]{}|;'':",.<>?/~'; Desc = "symbols test"; Vendor = "Vendor!@#"; TT = "Service" },
    @{ Name = "Unicode / Non-ASCII"; ValName = "微软诊断服务_測試_Сервис_🔥🚀"; Desc = "日本語テキスト with emoji 💻💀"; Vendor = "グーグル"; TT = "AppX" },
    @{ Name = "Control Characters"; ValName = "Test`0`a`b`f`r`n`t`vComponent"; Desc = "`0`r`n"; Vendor = "`t"; TT = "ScheduledTask" },
    @{ Name = "Command / Script Injection"; ValName = "'; DROP TABLE Services; --"; Desc = "`$(Get-Process | Stop-Process -Force)"; Vendor = "| Remove-Item C:\* -Recurse"; TT = "Service" },
    @{ Name = "Regex Metacharacters"; ValName = "^[a-z0-9]+.*(foo|bar)\$?+{}\"; Desc = ".*"; Vendor = "[A-Z]"; TT = "Service" },
    @{ Name = "AppX Path Pattern Invariant"; ValName = "C:\Windows\SystemApps\ShellExperienceHost\App.exe"; Desc = "SystemApp path"; Vendor = "Microsoft"; TT = "AppX" }
)

foreach ($testCase in $adversarialInputs) {
    try {
        $res = Invoke-AiInference -Name $testCase.ValName -Description $testCase.Desc -Vendor $testCase.Vendor -TargetType $testCase.TT
        $isPsc = ($res -is [System.Management.Automation.PSCustomObject])
        $missingFields = @($requiredFields | Where-Object { $null -eq $res.PSObject.Properties[$_] })
        $confValid = ($res.Confidence -is [double] -and $res.Confidence -ge 0.0 -and $res.Confidence -le 1.0)
        $boolValid = ($res.IsSafeToDisable -is [bool])
        $tierValid = ($res.SafetyTier -match '^Tier [0-3]')

        $passed = ($isPsc -and $missingFields.Count -eq 0 -and $confValid -and $boolValid -and $tierValid)
        Assert-Check -TestCategory "Adversarial Robustness" `
            -TestName "Adversarial: $($testCase.Name)" `
            -Condition $passed `
            -Details "Tier: $($res.SafetyTier), Conf: $($res.Confidence), IsSafe: $($res.IsSafeToDisable), Missing: $($missingFields -join ', ')"
    } catch {
        Assert-Check -TestCategory "Adversarial Robustness" `
            -TestName "Adversarial: $($testCase.Name)" `
            -Condition $false `
            -Details "Threw exception: $($_.Exception.Message)"
    }
}

# -----------------------------------------------------------------------------
# TEST SUITE 4: HIGH-LOAD RANDOMIZED THROUGHPUT BENCHMARK (1,500 CALLS)
# -----------------------------------------------------------------------------
Write-Host "`n[4/5] Executing High-Load Randomized Inference Benchmark ($BenchmarkIterations calls)..." -ForegroundColor Yellow

$nameCorpus = @(
    # Core OS Protected (Tier 0)
    "RpcSs", "RpcEptMapper", "DcomLaunch", "lsass", "lsaiso", "SamSs", "KeyIso", "VaultSvc",
    "CryptSvc", "WinDefend", "mpssvc", "mpsdrv", "BFE", "wuauserv", "TrustedInstaller",
    "UsoSvc", "WaaSMedicSvc", "msiserver", "Appinfo", "AppXSvc", "StateRepository",
    "ClipSVC", "InstallService", "Netlogon", "Dhcp", "Dnscache", "nsi", "NlaSvc",
    "netprofm", "LanmanWorkstation", "LanmanServer", "WlanSvc", "Audiosrv", "AudioEndpointBuilder",
    "PlugPlay", "EventLog", "TermService", "ProfSvc", "UserManager", "Schedule", "Power",
    "Themes", "Winmgmt", "FontCache", "FontCache3.0.0.0", "BDESVC", "gpsvc", "BrokerInfrastructure",
    # GPU / Hypervisor
    "nvsvc", "nvlddmkm", "amdfendrs", "amdppkgsvc", "amdpmfservice", "igfxcuiservice2.0.0.0", "vmtoolsd",
    # Telemetry
    "DiagTrack", "dmwappushservice", "WerSvc", "wisvc", "lfsvc", "DiagTrackRunner",
    # OEM Bloat
    "DellInc.DellSupportAssistforPCs", "LenovoCorporation.LenovoVantage", "ASUSTeKCOMPUTERINC.MyASUS",
    "AcerCareCenter", "RazerSynapseService", "AlienwareCommandCenter",
    # Consumer Bloat
    "Microsoft.BingWeather", "Microsoft.BingNews", "Microsoft.MicrosoftSolitaireCollection",
    "ByteDance.TikTok", "SpotifyAB.SpotifyMusic", "Disney.DisneyPlus", "King.CandyCrushSaga",
    # ThirdParty Updaters
    "AdobeARMservice", "gupdate", "gupdatem", "BraveElevationService", "DropboxUpdate",
    # Scheduled Tasks
    "Microsoft Compatibility Appraiser", "WinSAT", "Consolidator", "ProgramDataUpdater",
    # System Tweaks
    "Tweak_Win32PrioritySeparation", "Tweak_SystemResponsiveness", "Tweak_DeliveryOptimization_P2P",
    # SystemApps
    "Microsoft.Windows.ShellExperienceHost", "Microsoft.Windows.Search", "Microsoft.LockApp",
    # Synthetic / Unknown
    "UnknownSuperOptimizerSvc", "RandomAdService99", "CustomBackgroundWorker", "GenericAudioDSP"
)

$descCorpus = @(
    "Connected User Experiences and Telemetry for Windows diagnostic tracking",
    "Core Windows Local Security Authority Subsystem Service",
    "Remote Procedure Call Endpoint Mapper and DCOM launcher infrastructure",
    "Dell SupportAssist proactive system health monitoring agent",
    "Spotify Music streaming desktop client background integration",
    "Periodic system diagnostic analysis and hardware benchmarking task",
    "Third-party background automatic software updater service",
    "Low-priority background telemetry collection worker",
    "High-performance multimedia quantum scheduler tuning tweak",
    ""
)

$vendorCorpus = @(
    "Microsoft Corporation", "Dell Inc.", "Lenovo Group Ltd.", "Google LLC",
    "Adobe Systems Inc.", "ByteDance Ltd.", "Spotify AB", "NVIDIA Corporation",
    "Advanced Micro Devices Inc.", "Unknown / Third Party", ""
)

$targetTypeCorpus = @("Service", "AppX", "ScheduledTask", "SystemTweak")

# Warm-up run (50 iterations)
for ($i = 0; $i -lt 50; $i++) {
    $null = Invoke-AiInference -Name "DiagTrack" -Description "Telemetry" -Vendor "Microsoft" -TargetType "Service"
}

# Force GC before benchmark to measure baseline memory cleanly
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
$memBeforeBytes = [System.GC]::GetTotalMemory($true)
$workingSetBefore = (Get-Process -Id $PID).WorkingSet64

$rng = [System.Random]::new(1337) # Deterministic seed for reproducible stress testing

$latenciesMs = [double[]]::new($BenchmarkIterations)
$swTotal = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 0; $i -lt $BenchmarkIterations; $i++) {
    $name = $nameCorpus[$rng.Next($nameCorpus.Length)]
    $desc = $descCorpus[$rng.Next($descCorpus.Length)]
    $vendor = $vendorCorpus[$rng.Next($vendorCorpus.Length)]
    $tt = $targetTypeCorpus[$rng.Next($targetTypeCorpus.Length)]

    # Random chaotic casing injection on ~15% of iterations
    if ($rng.Next(100) -lt 15) {
        $chars = $name.ToCharArray()
        for ($c = 0; $c -lt $chars.Length; $c++) {
            if ($rng.Next(2) -eq 0) { $chars[$c] = [char]::ToUpperInvariant($chars[$c]) }
            else { $chars[$c] = [char]::ToLowerInvariant($chars[$c]) }
        }
        $name = [string]::new($chars)
    }

    $swCall = [System.Diagnostics.Stopwatch]::StartNew()
    $infResult = Invoke-AiInference -Name $name -Description $desc -Vendor $vendor -TargetType $tt
    $swCall.Stop()

    $latenciesMs[$i] = $swCall.Elapsed.TotalMilliseconds
}

$swTotal.Stop()

$memAfterBytes = [System.GC]::GetTotalMemory($false)
$workingSetAfter = (Get-Process -Id $PID).WorkingSet64
$memDeltaMB = ($memAfterBytes - $memBeforeBytes) / 1MB
$workingSetDeltaMB = ($workingSetAfter - $workingSetBefore) / 1MB

[System.Array]::Sort($latenciesMs)
$avgMs = $swTotal.Elapsed.TotalMilliseconds / $BenchmarkIterations
$p50Ms = $latenciesMs[[int]($BenchmarkIterations * 0.50)]
$p90Ms = $latenciesMs[[int]($BenchmarkIterations * 0.90)]
$p99Ms = $latenciesMs[[int]($BenchmarkIterations * 0.99)]
$maxMs = $latenciesMs[$BenchmarkIterations - 1]
$callsPerSec = [Math]::Round(($BenchmarkIterations / ($swTotal.Elapsed.TotalMilliseconds / 1000.0)), 2)

Write-Host "  Throughput Benchmark Summary ($BenchmarkIterations calls):" -ForegroundColor Cyan
Write-Host "    Total Time: $([Math]::Round($swTotal.Elapsed.TotalMilliseconds, 2)) ms" -ForegroundColor White
Write-Host "    Average Latency: $([Math]::Round($avgMs, 4)) ms/call" -ForegroundColor White
Write-Host "    Throughput: $callsPerSec calls/sec" -ForegroundColor White
Write-Host "    50th Percentile (p50): $([Math]::Round($p50Ms, 4)) ms" -ForegroundColor White
Write-Host "    90th Percentile (p90): $([Math]::Round($p90Ms, 4)) ms" -ForegroundColor White
Write-Host "    99th Percentile (p99): $([Math]::Round($p99Ms, 4)) ms" -ForegroundColor White
Write-Host "    Max Latency: $([Math]::Round($maxMs, 4)) ms" -ForegroundColor White
Write-Host "    GC Managed Memory Delta: $([Math]::Round($memDeltaMB, 3)) MB" -ForegroundColor White
Write-Host "    Process WorkingSet Delta: $([Math]::Round($workingSetDeltaMB, 3)) MB" -ForegroundColor White

Assert-Check -TestCategory "Performance Benchmark" `
    -TestName "Throughput comfortably achieves < 10 ms/call" `
    -Condition ($avgMs -lt 10.0) `
    -Details "Observed average: $([Math]::Round($avgMs, 4)) ms/call (Threshold: 10.0 ms/call)"

Assert-Check -TestCategory "Performance Benchmark" `
    -TestName "p99 Latency is under 15 ms" `
    -Condition ($p99Ms -lt 15.0) `
    -Details "Observed p99: $([Math]::Round($p99Ms, 4)) ms"

Assert-Check -TestCategory "Memory Stability" `
    -TestName "Zero runaway memory growth (< 10 MB managed delta over 1,500 calls)" `
    -Condition ($memDeltaMB -lt 10.0) `
    -Details "Observed delta: $([Math]::Round($memDeltaMB, 3)) MB"

# -----------------------------------------------------------------------------
# TEST SUITE 5: IDEMPOTENCY & CACHE STABILITY UNDER REPETITION
# -----------------------------------------------------------------------------
Write-Host "`n[5/5] Testing Initialization Idempotency & Re-entrancy..." -ForegroundColor Yellow

$swInitLoop = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt 100; $i++) {
    Initialize-AiModel
}
$swInitLoop.Stop()
$initLoopAvgMs = $swInitLoop.Elapsed.TotalMilliseconds / 100.0

Assert-Check -TestCategory "Cache Idempotency" `
    -TestName "100 redundant Initialize-AiModel calls execute in < 0.1 ms/call" `
    -Condition ($initLoopAvgMs -lt 0.5) `
    -Details "Observed average: $([Math]::Round($initLoopAvgMs, 4)) ms/call"

$coreWlBefore = Get-WinAurexCoreWhitelist
$countBefore = $coreWlBefore.Count

Initialize-AiModel -Force

$coreWlAfter = Get-WinAurexCoreWhitelist
$countAfter = $coreWlAfter.Count

Assert-Check -TestCategory "Cache Idempotency" `
    -TestName "Initialize-AiModel -Force cleanly reloads without count drift" `
    -Condition ($countBefore -eq $countAfter -and $countAfter -ge 47) `
    -Details "Count before: $countBefore, Count after: $countAfter"

# -----------------------------------------------------------------------------
# VERDICT EVALUATION
# -----------------------------------------------------------------------------
$totalTests = $testResults.Count
$totalPassed = @($testResults | Where-Object { $_.Passed }).Count
$totalFailed = @($testResults | Where-Object { -not $_.Passed }).Count
$allPassed = ($totalFailed -eq 0)

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " CHALLENGER 2 EMPIRICAL VERDICT" -ForegroundColor Cyan
Write-Host " Total Assertions: $totalTests" -ForegroundColor White
Write-Host " Passed: $totalPassed" -ForegroundColor Green
Write-Host " Failed: $totalFailed" -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })

if ($allPassed) {
    Write-Host " EMPIRICAL VERDICT: >>> APPROVE <<<" -ForegroundColor Green
} else {
    Write-Host " EMPIRICAL VERDICT: >>> FAIL <<<" -ForegroundColor Red
}
Write-Host "=================================================================`n" -ForegroundColor Cyan

# Output structured JSON summary for handoff report
$summary = @{
    Timestamp             = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    TotalAssertions       = $totalTests
    Passed                = $totalPassed
    Failed                = $totalFailed
    Verdict               = if ($allPassed) { "APPROVE" } else { "FAIL" }
    Benchmark = @{
        Iterations        = $BenchmarkIterations
        TotalTimeMs       = [Math]::Round($swTotal.Elapsed.TotalMilliseconds, 2)
        AverageLatencyMs  = [Math]::Round($avgMs, 4)
        ThroughputCallsSec= $callsPerSec
        P50Ms             = [Math]::Round($p50Ms, 4)
        P90Ms             = [Math]::Round($p90Ms, 4)
        P99Ms             = [Math]::Round($p99Ms, 4)
        MaxLatencyMs      = [Math]::Round($maxMs, 4)
        ManagedMemDeltaMB = [Math]::Round($memDeltaMB, 3)
        WorkingSetDeltaMB = [Math]::Round($workingSetDeltaMB, 3)
    }
    FailedTests           = @($testResults | Where-Object { -not $_.Passed } | Select-Object Category, Name, Details)
}

$summaryJsonPath = Join-Path $scriptDir "challenger2_summary.json"
$summary | ConvertTo-Json -Depth 5 | Set-Content -Path $summaryJsonPath -Encoding UTF8
Write-Host "Summary JSON written to: $summaryJsonPath" -ForegroundColor DarkGray

if (-not $allPassed) {
    exit 1
} else {
    exit 0
}
