<#
.SYNOPSIS
    WinAurex AI Engine Unified Test Runner
.DESCRIPTION
    Discovers and executes all *.Tests.ps1 suites in Tests/AI/, aggregates test counts,
    and formats comprehensive console reports. Exits with 0 on 100% pass, 1 on test failure,
    or 2 on syntax/initialization error.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestFilter = "Tier*.Tests.ps1",

    [Parameter(Mandatory = $false)]
    [switch]$UsePester,

    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput,

    [Parameter(Mandatory = $false)]
    [string]$Tier = ""
)

$Host.UI.RawUI.WindowTitle = "WinAurex AI Engine Test Runner"

$ScriptDir   = $PSScriptRoot
$TestsAiDir  = $ScriptDir
$RepoRootDir = Split-Path (Split-Path $ScriptDir -Parent) -Parent
$HarnessPath = Join-Path $TestsAiDir "TestHarness.psm1"
$EnginePath  = Join-Path $RepoRootDir "Core\AI\WinAurex_AiEngine.psm1"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex AI Engine - Unified E2E Test Suite Runner           " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  Directory     : $TestsAiDir" -ForegroundColor DarkGray
Write-Host "  Filter        : $TestFilter $(if ($Tier) { "(Tier: $Tier)" })" -ForegroundColor DarkGray
Write-Host "  PowerShell    : $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray

# 1. Dependency and Syntax Preflight
if (-not (Test-Path $HarnessPath)) {
    Write-Host "[ERROR] Test Harness not found at: $HarnessPath" -ForegroundColor Red
    exit 2
}

# Verify Harness Syntax
$harnessParseErrors = @()
$null = [System.Management.Automation.Language.Parser]::ParseFile($HarnessPath, [ref]$null, [ref]$harnessParseErrors)
if ($harnessParseErrors.Count -gt 0) {
    Write-Host "[FATAL] Syntax error detected in TestHarness.psm1:" -ForegroundColor Red
    foreach ($err in $harnessParseErrors) {
        Write-Host "  $($err.Message) at line $($err.Extent.StartLineNumber):$($err.Extent.StartColumnNumber)" -ForegroundColor Red
    }
    exit 2
}

# 2. Discover Test Suites
$allTestFiles = @(Get-ChildItem -Path $TestsAiDir -Filter $TestFilter -File | Sort-Object Name)
if ($Tier) {
    $allTestFiles = @($allTestFiles | Where-Object { $_.Name -like "*$Tier*" })
}

if ($allTestFiles.Count -eq 0) {
    Write-Host "[WARNING] No test files matching '$TestFilter' found in $TestsAiDir" -ForegroundColor Yellow
    exit 1
}

Write-Host "  Suites Found  : $($allTestFiles.Count) test suite file(s)" -ForegroundColor DarkGray
Write-Host "======================================================================`n" -ForegroundColor Cyan

# 3. Preflight Syntax Verification across all discovered test suites
$syntaxFailed = $false
foreach ($tf in $allTestFiles) {
    $fileParseErrors = @()
    $null = [System.Management.Automation.Language.Parser]::ParseFile($tf.FullName, [ref]$null, [ref]$fileParseErrors)
    if ($fileParseErrors.Count -gt 0) {
        Write-Host "[FATAL] Syntax error in $($tf.Name):" -ForegroundColor Red
        foreach ($err in $fileParseErrors) {
            Write-Host "  $($err.Message) at line $($err.Extent.StartLineNumber):$($err.Extent.StartColumnNumber)" -ForegroundColor Red
        }
        $syntaxFailed = $true
    }
}

if ($syntaxFailed) {
    Write-Host "`n[ABORT] Preflight syntax verification failed. Aborting test execution." -ForegroundColor Red
    exit 2
}

# 4. Import Test Harness and Dependencies
Import-Module $HarnessPath -Force
if (Test-Path $EnginePath) {
    Import-Module $EnginePath -Force -DisableNameChecking
}

# Determine Runner Mode
$isPesterMode = $false
if ($UsePester) {
    if (Get-Module -ListAvailable -Name Pester) {
        Import-Module Pester -Force
        $isPesterMode = $true
        Write-Host "[MODE] Executing via Pester Module ($((Get-Module Pester).Version))`n" -ForegroundColor Cyan
    } else {
        Write-Host "[WARN] Pester module not found on host. Falling back to Standalone Native Engine.`n" -ForegroundColor Yellow
    }
} else {
    Write-Host "[MODE] Executing via Standalone Portable Assertion Engine`n" -ForegroundColor Cyan
}

$suiteSummaries = [System.Collections.Generic.List[PSObject]]::new()
$allFailures    = [System.Collections.Generic.List[PSObject]]::new()
$globalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# 5. Execute Discovered Test Suites
foreach ($tf in $allTestFiles) {
    Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ">> SUITE: $($tf.Name)" -ForegroundColor Magenta
    Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray

    $suiteSw = [System.Diagnostics.Stopwatch]::StartNew()

    if ($isPesterMode) {
        # Pester Execution
        $pesterResult = Invoke-Pester -Path $tf.FullName -PassThru
        $suiteSw.Stop()

        $sTotal   = $pesterResult.TotalCount
        $sPassed  = $pesterResult.PassedCount
        $sFailed  = $pesterResult.FailedCount
        $sSkipped = $pesterResult.SkippedCount

        if ($pesterResult.TestResult) {
            foreach ($tr in ($pesterResult.TestResult | Where-Object { $_.Result -eq "Failed" })) {
                $allFailures.Add([PSCustomObject]@{
                    Suite    = $tf.Name
                    Describe = $tr.Describe
                    Context  = $tr.Context
                    Name     = $tr.Name
                    Error    = $tr.FailureMessage
                    Location = $tr.StackTrace
                })
            }
        }
    } else {
        # Standalone Native Engine Execution
        Reset-TestResults
        try {
            & $tf.FullName
        } catch {
            Write-Host "  [UNHANDLED RUNTIME ERROR in $($tf.Name)]: $_" -ForegroundColor Red
            Write-Host "  $($_.ScriptStackTrace)" -ForegroundColor DarkRed
            $allFailures.Add([PSCustomObject]@{
                Suite    = $tf.Name
                Describe = "Suite Initialization / Execution"
                Context  = "Unhandled Runtime Exception"
                Name     = $tf.Name
                Error    = $_.Exception.Message
                Location = $_.ScriptStackTrace
            })
            $sFailed++
        }
        $suiteSw.Stop()

        $res = Get-TestResultSummary
        $sTotal   = $res.Total
        $sPassed  = $res.Passed
        $sFailed  = $res.Failed
        $sSkipped = $res.Skipped

        if ($res.Failures) {
            foreach ($f in $res.Failures) {
                $allFailures.Add([PSCustomObject]@{
                    Suite    = $tf.Name
                    Describe = $f.Describe
                    Context  = $f.Context
                    Name     = $f.Name
                    Error    = $f.Error
                    Location = $f.Location
                })
            }
        }
    }

    $suiteSummaries.Add([PSCustomObject]@{
        SuiteName = $tf.Name
        Total     = $sTotal
        Passed    = $sPassed
        Failed    = $sFailed
        Skipped   = $sSkipped
        Duration  = [math]::Round($suiteSw.Elapsed.TotalSeconds, 2)
    })

    Write-Host "`n  -> Finished $($tf.Name): $sPassed Passed, $sFailed Failed, $sSkipped Skipped in $([math]::Round($suiteSw.Elapsed.TotalSeconds, 2))s`n" -ForegroundColor $(if ($sFailed -eq 0) { "Green" } else { "Red" })
}

$globalStopwatch.Stop()
$totalElapsedSec = [math]::Round($globalStopwatch.Elapsed.TotalSeconds, 2)

# 6. Overall Summary Formatting
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                       TEST EXECUTION SUMMARY                         " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host (" {0,-36} | {1,5} | {2,5} | {3,5} | {4,5} | {5,6}" -f "SUITE", "TOTAL", "PASS", "FAIL", "SKIP", "TIME") -ForegroundColor DarkGray
Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray

$totalAll     = 0
$totalPassed  = 0
$totalFailed  = 0
$totalSkipped = 0

foreach ($ss in $suiteSummaries) {
    $color = if ($ss.Failed -eq 0) { "Green" } else { "Red" }
    Write-Host (" {0,-36} | {1,5} | {2,5} | {3,5} | {4,5} | {5,5}s" -f `
        $ss.SuiteName, $ss.Total, $ss.Passed, $ss.Failed, $ss.Skipped, $ss.Duration) -ForegroundColor $color
    $totalAll     += $ss.Total
    $totalPassed  += $ss.Passed
    $totalFailed  += $ss.Failed
    $totalSkipped += $ss.Skipped
}

Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
$summaryColor = if ($totalFailed -eq 0) { "Green" } else { "Red" }
Write-Host (" {0,-36} | {1,5} | {2,5} | {3,5} | {4,5} | {5,5}s" -f `
    "TOTAL", $totalAll, $totalPassed, $totalFailed, $totalSkipped, $totalElapsedSec) -ForegroundColor $summaryColor
Write-Host "======================================================================`n" -ForegroundColor Cyan

# 7. Failure Diagnostics Report
if ($allFailures.Count -gt 0) {
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "                       FAILURE DIAGNOSTIC LOG                         " -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    $fIdx = 0
    foreach ($f in $allFailures) {
        $fIdx++
        Write-Host "[$fIdx] [$($f.Suite)] $($f.Describe) > $($f.Context) > $($f.Name)" -ForegroundColor Yellow
        Write-Host "    Error   : $($f.Error)" -ForegroundColor Red
        if ($f.Location) {
            Write-Host "    Location: $($f.Location)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    Write-Host "======================================================================`n" -ForegroundColor Red
}

# 8. Final Exit Gate
if ($totalFailed -eq 0 -and $totalAll -gt 0) {
    $passRate = [math]::Round(($totalPassed / $totalAll) * 100, 1)
    Write-Host "[PASS] 100% SUCCESS: All $totalPassed tests passed cleanly across $($allTestFiles.Count) test suite(s)! ($passRate% Pass Rate in ${totalElapsedSec}s)`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAIL] TEST RUN FAILED: $totalFailed test(s) failed out of $totalAll total tests ($totalPassed passed).`n" -ForegroundColor Red
    exit 1
}
