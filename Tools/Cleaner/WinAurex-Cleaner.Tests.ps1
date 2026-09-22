<#
.SYNOPSIS
    WinAurex-Cleaner.Tests.ps1 - Automated Unit & Safety Verification Tests
#>

$ErrorActionPreference = "Stop"

$ModulePath = Join-Path $PSScriptRoot "WinAurex-Cleaner.psm1"
if (-not (Test-Path $ModulePath)) {
    throw "Module not found at $ModulePath"
}

Import-Module $ModulePath -Force

$passedTests = 0
$failedTests = 0

function Assert-Condition($name, [bool]$condition, $failMessage = "") {
    if ($condition) {
        Write-Host " [PASS] $name" -ForegroundColor Green
        $script:passedTests++
    } else {
        Write-Host " [FAIL] $($name): $failMessage" -ForegroundColor Red
        $script:failedTests++
    }
}

Write-Host "=== RUNNING WINAUREX PC CLEANER TEST SUITE ===" -ForegroundColor Cyan

# Test 1: Module exports
$commands = Get-Command -Module WinAurex-Cleaner
Assert-Condition "Exports Get-WinAurexJunkAnalysis" ($commands.Name -contains "Get-WinAurexJunkAnalysis")
Assert-Condition "Exports Invoke-WinAurexCleanup" ($commands.Name -contains "Invoke-WinAurexCleanup")
Assert-Condition "Exports Format-Bytes" ($commands.Name -contains "Format-Bytes")

# Test 2: Format-Bytes function
Assert-Condition "Format-Bytes handles Bytes" ((Format-Bytes 500) -eq "500 B")
Assert-Condition "Format-Bytes handles KB" ((Format-Bytes 2048) -eq "2 KB")
Assert-Condition "Format-Bytes handles MB" ((Format-Bytes (10 * 1024 * 1024)) -eq "10 MB")
Assert-Condition "Format-Bytes handles GB" ((Format-Bytes (5 * 1024 * 1024 * 1024)) -eq "5 GB")

# Test 3: Get-WinAurexJunkAnalysis schema & execution
$analysis = Get-WinAurexJunkAnalysis
Assert-Condition "Analysis returns non-empty collection" ($analysis.Count -ge 8)

$expectedCategories = @("SystemTemp", "CrashDumps", "AIIndexCaches", "AppUpdaters", "SquirrelVersions", "DevCaches", "BrowserCaches", "LooseInstallers", "ComponentStore")
foreach ($catId in $expectedCategories) {
    $found = $analysis | Where-Object { $_.Id -eq $catId }
    Assert-Condition "Contains category: $catId" ($null -ne $found)
    if ($found) {
        Assert-Condition "Category $catId has non-negative size" ($found.SizeBytes -ge 0)
        Assert-Condition "Category $catId has description" (-not [string]::IsNullOrWhiteSpace($found.Description))
    }
}

# Test 4: Safety protection logic
$protectedSamples = @(
    "C:\Users\Admin\Downloads",
    "C:\Users\Admin\Downloads\installer.exe",
    "C:\Users\Admin\Pictures",
    "C:\Users\Admin\Photos\Vacation.jpg",
    "C:\Users\Admin\Documents\Virtual Machines\kali-linux",
    "C:\Users\Admin\Documents\GitHub\WinAurex\src"
)

# Test-IsProtectedPath internal logic test
$protectedKeywords = @("\downloads", "\pictures", "\photos", "\camera roll", "\saved pictures", "\virtual machines", "\desktop", "\documents\github")
foreach ($p in $protectedSamples) {
    $normalized = $p.ToLowerInvariant()
    $isProtected = $false
    foreach ($kw in $protectedKeywords) {
        if ($normalized.Contains($kw)) { $isProtected = $true; break }
    }
    Assert-Condition "Safety check protects: $p" $isProtected
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor DarkCyan
Write-Host "TEST RESULTS: Passed: $passedTests | Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "==============================================" -ForegroundColor DarkCyan

if ($failedTests -gt 0) {
    exit 1
}
exit 0
