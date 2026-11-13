<#
.SYNOPSIS
    Pester Integration for WinAurex Milestone 1 Empirical Challenger 2 Harness
.DESCRIPTION
    Integrates the empirical stress testing, throughput benchmark,
    boundary verification, and catalog integrity checks into Pester.
#>

Import-Module Pester -ErrorAction SilentlyContinue

$RootDir = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"))) {
    $RootDir = Split-Path -Path $PSScriptRoot -Parent
}

$AiModulePath = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"

Describe "Milestone 1 Empirical Challenger 2: Throughput, Contracts & Stability" {

    BeforeAll {
        Import-Module $AiModulePath -Force
        Initialize-AiModel
    }

    Context "1. High-Load Randomized Inference Throughput Benchmark (1,000+ iterations)" {
        It "Achieves < 10 ms/call throughput across 1,000 randomized inference calls" {
            $nameCorpus = @(
                "RpcSs", "lsass", "CryptSvc", "WinDefend", "wuauserv", "PlugPlay",
                "DiagTrack", "dmwappushservice", "WerSvc", "wisvc",
                "DellInc.DellSupportAssistforPCs", "LenovoCorporation.LenovoVantage",
                "Microsoft.BingWeather", "ByteDance.TikTok", "SpotifyAB.SpotifyMusic",
                "AdobeARMservice", "gupdate", "BraveElevationService",
                "Microsoft Compatibility Appraiser", "WinSAT", "Tweak_Win32PrioritySeparation"
            )
            $rng = [System.Random]::new(42)
            $iterations = 1000

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 0; $i -lt $iterations; $i++) {
                $n = $nameCorpus[$rng.Next($nameCorpus.Length)]
                $res = Invoke-AiInference -Name $n
                $res | Should Not BeNullOrEmpty
            }
            $sw.Stop()

            $avgMs = $sw.Elapsed.TotalMilliseconds / $iterations
            Write-Host "    [Benchmark] Pester 1000 iterations: Total $($sw.ElapsedMilliseconds) ms, Avg $($avgMs) ms/call"
            ($avgMs -lt 10.0) | Should Be $true
        }
    }

    Context "2. Parameter Contract Conformance Across All TargetTypes" {
        $requiredProps = @("Name", "Category", "SafetyTier", "Confidence", "IsSafeToDisable", "EstImpact", "TweakAction", "CanonicalCategory", "Reason")

        It "Conforms to PSCustomObject contract for TargetType: Service" {
            $res = Invoke-AiInference -Name "DiagTrack" -TargetType "Service"
            $res -is [System.Management.Automation.PSCustomObject] | Should Be $true
            foreach ($prop in $requiredProps) {
                $res.PSObject.Properties[$prop] | Should Not BeNullOrEmpty
            }
        }

        It "Conforms to PSCustomObject contract for TargetType: AppX" {
            $res = Invoke-AiInference -Name "Microsoft.BingWeather" -TargetType "AppX"
            $res -is [System.Management.Automation.PSCustomObject] | Should Be $true
            foreach ($prop in $requiredProps) {
                $res.PSObject.Properties[$prop] | Should Not BeNullOrEmpty
            }
        }

        It "Conforms to PSCustomObject contract for TargetType: ScheduledTask" {
            $res = Invoke-AiInference -Name "Microsoft Compatibility Appraiser" -TargetType "ScheduledTask"
            $res -is [System.Management.Automation.PSCustomObject] | Should Be $true
            foreach ($prop in $requiredProps) {
                $res.PSObject.Properties[$prop] | Should Not BeNullOrEmpty
            }
        }

        It "Conforms to PSCustomObject contract for TargetType: SystemTweak" {
            $res = Invoke-AiInference -Name "Tweak_Win32PrioritySeparation" -TargetType "SystemTweak"
            $res -is [System.Management.Automation.PSCustomObject] | Should Be $true
            foreach ($prop in $requiredProps) {
                $res.PSObject.Properties[$prop] | Should Not BeNullOrEmpty
            }
        }
    }

    Context "3. Adversarial Boundary Inputs & Resilience" {
        It "Handles null and empty string inputs gracefully returning Tier 0 protected object" {
            $nullRes = Invoke-AiInference -Name $null
            $nullRes.SafetyTier | Should Be "Tier 0 (Protected)"
            $nullRes.IsSafeToDisable | Should Be $false

            $emptyRes = Invoke-AiInference -Name ""
            $emptyRes.SafetyTier | Should Be "Tier 0 (Protected)"
            $emptyRes.IsSafeToDisable | Should Be $false

            $wsRes = Invoke-AiInference -Name "   `t`n   "
            $wsRes.SafetyTier | Should Be "Tier 0 (Protected)"
            $wsRes.IsSafeToDisable | Should Be $false
        }

        It "Handles long strings and unicode without exceptions" {
            $longRes = Invoke-AiInference -Name ("A" * 2048) -Description ("Desc " * 200)
            $longRes | Should Not BeNullOrEmpty
            $longRes.Confidence -is [double] | Should Be $true

            $unicodeRes = Invoke-AiInference -Name "微软诊断服务_テスト_Сервис_🔥" -Description "Emoji 🚀💻"
            $unicodeRes | Should Not BeNullOrEmpty
            $unicodeRes.Confidence -is [double] | Should Be $true
        }
    }

    Context "4. Catalog Integrity and Scope Hygiene" {
        It "Accessors return non-null collections" {
            (Get-WinAurexServiceCatalog).services.Count -ge 47 | Should Be $true
            (Get-WinAurexTaskCatalog).tasks.Count -ge 22 | Should Be $true
            (Get-WinAurexBloatwareCatalog).packages.Count -ge 30 | Should Be $true
            (Get-WinAurexTweakCatalog).tweaks.Count -ge 10 | Should Be $true
        }

        It "Get-WinAurexCoreWhitelist returns non-unrolled HashSet with case-insensitive containment" {
            $wl = Get-WinAurexCoreWhitelist
            ($wl -is [System.Collections.Generic.HashSet[string]] -or $wl.GetType().FullName -like "*HashSet*") | Should Be $true
            $wl.Contains("rpcss") | Should Be $true
            $wl.Contains("RPCSS") | Should Be $true
            $wl.Contains("lsass") | Should Be $true
        }
    }
}
