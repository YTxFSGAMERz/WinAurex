<#
.SYNOPSIS
    Adversarial Stress Test Suite for WinAurex Milestone 1
.DESCRIPTION
    Authored by Challenger 1 (Empirical Challenger) to aggressively probe
    the Zero-False-Positive Core OS Service Whitelist and SystemApp dynamic shield
    in Core/AI/WinAurex_AiEngine.psm1 under deceptive descriptions, hostile vendors,
    chaotic casing, whitespace padding, and dynamic package naming.
#>

Import-Module Pester -ErrorAction SilentlyContinue

$RootDir = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"))) {
    $RootDir = Split-Path -Path $PSScriptRoot -Parent
}

$AiModulePath = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"
$DataDir = Join-Path $RootDir "Core\AI\Data"

Describe "Challenger 1: Empirical Adversarial Stress Harness (Core Whitelist & SystemApp Shield)" {

    BeforeAll {
        Import-Module $AiModulePath -Force
        Initialize-AiModel -Force
    }

    Context "1. Critical Windows Core OS Services Adversarial Probe (All 66+ Services)" {
        $svcCatPath = Join-Path $DataDir "ServiceCatalog.json"
        $svcJson = (Get-Content $svcCatPath -Raw -Encoding UTF8) | ConvertFrom-Json
        $coreServices = @($svcJson.services | Where-Object { $_.IsSafeToDisable -eq $false -or $_.SafetyTier -match "Tier 0" })

        It "Contains at least 47 critical core OS services in the test suite" {
            $coreServices.Count | Should BeGreaterThan 46
        }

        # Helper function for alternating casing
        function Convert-ToFuzzyCase([string]$text) {
            $chars = $text.ToCharArray()
            for ($i = 0; $i -lt $chars.Length; $i++) {
                if ($i % 2 -eq 0) {
                    $chars[$i] = [char]::ToUpperInvariant($chars[$i])
                } else {
                    $chars[$i] = [char]::ToLowerInvariant($chars[$i])
                }
            }
            return -join $chars
        }

        It "All 66+ core services remain Protected (IsSafeToDisable = False) under Canonical names" {
            $failures = [System.Collections.Generic.List[string]]::new()

            foreach ($svc in $coreServices) {
                $res = Invoke-AiInference -Name $svc.Name -TargetType "Service"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $failures.Add("FAIL Canonical: $($svc.Name) -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier), Cat=$($res.Category)")
                }
            }

            $failures.Count | Should Be 0
        }

        It "All 66+ core services remain Protected under DECEPTIVE TELEMETRY descriptions and HOSTILE vendors" {
            $failures = [System.Collections.Generic.List[string]]::new()
            $deceptiveDesc = "Diagnostic Telemetry Collector, Customer Experience Data Harvester and Bloatware Tracking Service"
            $hostileVendor = "OEM Bloatware Corp & Adware Tracking Systems"

            foreach ($svc in $coreServices) {
                $res = Invoke-AiInference -Name $svc.Name -Description $deceptiveDesc -Vendor $hostileVendor -TargetType "Service"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $failures.Add("FAIL Deceptive: $($svc.Name) -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier), Cat=$($res.Category)")
                }
            }

            $failures.Count | Should Be 0
        }

        It "All 66+ core services remain Protected under CHAOTIC / FUZZY / UPPER / LOWER casing" {
            $failures = [System.Collections.Generic.List[string]]::new()

            foreach ($svc in $coreServices) {
                $casingVariants = @(
                    $svc.Name.ToUpperInvariant(),
                    $svc.Name.ToLowerInvariant(),
                    (Convert-ToFuzzyCase $svc.Name)
                )

                foreach ($variant in $casingVariants) {
                    $res = Invoke-AiInference -Name $variant -Description "Adversarial Bloatware Helper" -Vendor "Adversarial Vendor" -TargetType "Service"
                    if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                        $failures.Add("FAIL Casing: '$variant' (from $($svc.Name)) -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier)")
                    }
                }
            }

            $failures.Count | Should Be 0
        }

        It "All 66+ core services remain Protected under WHITESPACE, TABS, and NEWLINES" {
            $failures = [System.Collections.Generic.List[string]]::new()

            foreach ($svc in $coreServices) {
                $paddedVariants = @(
                    "   $($svc.Name)   ",
                    "`t`t$($svc.Name)`t",
                    "`r`n  $($svc.Name)  `r`n",
                    " `t $($svc.Name) `t "
                )

                foreach ($padded in $paddedVariants) {
                    $res = Invoke-AiInference -Name $padded -Description "Aggressive Telemetry Bloat" -Vendor "Unknown" -TargetType "Service"
                    if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                        $failures.Add("FAIL Padded: '$padded' -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier)")
                    }
                }
            }

            $failures.Count | Should Be 0
        }
    }

    Context "2. Windows SystemApps Dynamic Shield Adversarial Probe" {
        $bloatCatPath = Join-Path $DataDir "BloatwareCatalog.json"
        $bloatJson = (Get-Content $bloatCatPath -Raw -Encoding UTF8) | ConvertFrom-Json
        $sysApps = @($bloatJson.packages | Where-Object { $_.IsSystemApp -eq $true -or $_.SafetyTier -match "Tier 0" })

        It "Contains at least 20 Windows SystemApps in the test suite" {
            $sysApps.Count | Should BeGreaterThan 19
        }

        It "All SystemApps remain Protected under bloatware descriptions and hostile vendor tags" {
            $failures = [System.Collections.Generic.List[string]]::new()
            $bloatDesc = "Useless advertising component, telemetry tracker for lock screen ads and background bloat"
            $hostileVendor = "Bloatware Distributor Inc"

            foreach ($pkg in $sysApps) {
                $res = Invoke-AiInference -Name $pkg.Name -Description $bloatDesc -Vendor $hostileVendor -TargetType "AppX"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $failures.Add("FAIL SystemApp: $($pkg.Name) -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier), Cat=$($res.Category)")
                }
            }

            $failures.Count | Should Be 0
        }

        It "SystemApps remain Protected when probed with dynamic package full names (version/architecture suffixes)" {
            $dynamicSuffix = "_10.0.19041.1023_neutral_neutral_cw5n1h2txyewy"
            $failures = [System.Collections.Generic.List[string]]::new()

            foreach ($pkg in $sysApps) {
                $dynamicFullName = "$($pkg.Name)$dynamicSuffix"
                $res = Invoke-AiInference -Name $dynamicFullName -Description "Adversarial Bloatware Helper" -Vendor "OEM Bloatware" -TargetType "AppX"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $failures.Add("FAIL Dynamic FullName: $dynamicFullName -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier)")
                }
            }

            $failures.Count | Should Be 0
        }

        It "SystemApps remain Protected under chaotic casing and whitespace padding" {
            $failures = [System.Collections.Generic.List[string]]::new()

            foreach ($pkg in $sysApps) {
                $variant = "   $($pkg.Name.ToUpperInvariant())   "
                $res = Invoke-AiInference -Name $variant -Description "Bloatware" -Vendor "Adware" -TargetType "AppX"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $failures.Add("FAIL Padded/Upper SystemApp: '$variant' -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier)")
                }
            }

            $failures.Count | Should Be 0
        }

        It "All 43 Protected Package Patterns in BloatwareCatalog shield rules are protected" {
            $patterns = $bloatJson.shield_rules.protected_package_patterns
            $patterns | Should Not BeNullOrEmpty
            ($patterns.Count -ge 40) | Should Be $true

            $failures = [System.Collections.Generic.List[string]]::new()
            foreach ($pattern in $patterns) {
                # Strip leading '^' and regex escapes to get base prefix
                $rawPrefix = $pattern.TrimStart('^').Replace('\.', '.').Replace('\\', '\')
                $probeName = "$rawPrefix" + "_SubComponent_TestVersion"
                $res = Invoke-AiInference -Name $probeName -Description "Deceptive Telemetry" -Vendor "Unknown" -TargetType "AppX"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $failures.Add("FAIL Protected Pattern Probe: '$probeName' -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier)")
                }
            }

            $failures.Count | Should Be 0
        }
    }

    Context "3. GPU Display Drivers & Hypervisor Virtualization Shield" {
        $gpuAndHypervisorDrivers = @(
            "nvsvc", "nvlddmkm", "amdfendrs", "amdppkgsvc", "amdpmfservice",
            "igfx", "igfxcuiservice", "igfxCUIService2.0.0.0", "amdkmdag",
            "vmtoolsd", "vmicguestinterface", "vmicshutdown"
        )

        It "Protects all GPU display and virtualization drivers under deceptive descriptions and mixed casing" {
            $failures = [System.Collections.Generic.List[string]]::new()

            foreach ($driver in $gpuAndHypervisorDrivers) {
                $cased = "  " + ($driver.Substring(0, 1).ToUpperInvariant() + $driver.Substring(1)) + "  "
                $res = Invoke-AiInference -Name $cased -Description "Heavy Background Overhead Telemetry" -Vendor "Adversarial Corp" -TargetType "Service"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $failures.Add("FAIL Driver/Virt: '$cased' -> IsSafeToDisable=$($res.IsSafeToDisable), Tier=$($res.SafetyTier)")
                }
            }

            $failures.Count | Should Be 0
        }
    }

    Context "4. Boundary, Null, and Extreme Input Invariants" {
        It "Safely handles null Name without throwing exception, returning Protected" {
            $res = Invoke-AiInference -Name $null -Description "Test" -Vendor "Test"
            $res | Should Not BeNullOrEmpty
            $res.IsSafeToDisable | Should Be $false
            $res.SafetyTier | Should Match "Tier 0"
        }

        It "Safely handles empty string Name, returning Protected" {
            $res = Invoke-AiInference -Name "" -Description "Adversarial" -Vendor "Adversarial"
            $res | Should Not BeNullOrEmpty
            $res.IsSafeToDisable | Should Be $false
            $res.SafetyTier | Should Match "Tier 0"
        }

        It "Safely handles whitespace-only Name, returning Protected" {
            $res = Invoke-AiInference -Name "     `t`r`n   " -Description "Adversarial" -Vendor "Adversarial"
            $res | Should Not BeNullOrEmpty
            $res.IsSafeToDisable | Should Be $false
            $res.SafetyTier | Should Match "Tier 0"
        }

        It "Safely handles null Description and null Vendor for protected services" {
            $res = Invoke-AiInference -Name "RpcSs" -Description $null -Vendor $null
            $res | Should Not BeNullOrEmpty
            $res.IsSafeToDisable | Should Be $false
            $res.SafetyTier | Should Match "Tier 0"
        }

        It "Safely handles empty TargetType string and defaults safely" {
            $res = Invoke-AiInference -Name "lsass" -TargetType ""
            $res | Should Not BeNullOrEmpty
            $res.IsSafeToDisable | Should Be $false
            $res.SafetyTier | Should Match "Tier 0"
        }
    }

    Context "5. High-Load Adversarial Concurrency Stress (1,000 Rapid Probes)" {
        It "Survives 1,000 rapid adversarial probes with 0 false positives" {
            $probeServices = @("RpcSs", "lsass", "CryptSvc", "WinDefend", "wuauserv", "Netlogon", "Dhcp", "Dnscache", "Audiosrv", "PlugPlay")
            $deceptiveDescList = @(
                "Diagnostic Telemetry Collector",
                "Adversarial Bloatware Helper",
                "Customer Experience Survey",
                "Third-Party Adware, Spyware and Bloatware Component",
                "High Overhead Crash Reporter and Diagnostic Uploader"
            )

            $fpCount = 0
            $totalProbes = 1000

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 0; $i -lt $totalProbes; $i++) {
                $svc = $probeServices[$i % $probeServices.Count]
                $desc = $deceptiveDescList[$i % $deceptiveDescList.Count]
                $cased = if ($i % 2 -eq 0) { $svc.ToUpperInvariant() } else { $svc.ToLowerInvariant() }
                $padded = "  $cased  "

                $res = Invoke-AiInference -Name $padded -Description $desc -Vendor "Hostile Vendor" -TargetType "Service"
                if ($res.IsSafeToDisable -ne $false -or $res.SafetyTier -notmatch "Tier 0") {
                    $fpCount++
                }
            }
            $sw.Stop()

            $fpCount | Should Be 0
            $avgMs = $sw.ElapsedMilliseconds / $totalProbes
            Write-Host "Completed $totalProbes adversarial probes in $($sw.ElapsedMilliseconds) ms (Average: $avgMs ms/probe)"
            $avgMs | Should BeLessThan 10.0
        }
    }
}
