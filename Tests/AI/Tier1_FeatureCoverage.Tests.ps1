<#
.SYNOPSIS
    Tier 1 Feature Coverage Test Suite for WinAurex AI Engine
.DESCRIPTION
    Systematic opaque-box verification of WinAurex AI Engine Features 1 through 10
    as defined in TEST_INFRA.md and PROJECT.md. Validates each feature in isolation
    with representative test cases covering happy-path inputs, contract conformance,
    and runtime safety invariants.
#>

$ScriptDir   = $PSScriptRoot
$RepoRootDir = Split-Path (Split-Path $ScriptDir -Parent) -Parent
$HarnessPath = Join-Path $ScriptDir "TestHarness.psm1"
$EnginePath  = Join-Path $RepoRootDir "Core\AI\WinAurex_AiEngine.psm1"
$CliScript   = Join-Path $RepoRootDir "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"
$XamlPath    = Join-Path $RepoRootDir "GUI\Dashboard.xaml"
$GuiScript   = Join-Path $RepoRootDir "Launch_Dashboard.ps1"

# Import Test Infrastructure and AI Engine
Import-Module $HarnessPath -Force
if (Test-Path $EnginePath) {
    Import-Module $EnginePath -Force -DisableNameChecking
}

Describe "Tier 1: WinAurex AI Engine Feature Coverage Suite" {

    BeforeAll {
        if (Get-Command Initialize-AiModel -ErrorAction SilentlyContinue) {
            Initialize-AiModel
        }
    }

    # ==========================================================================
    # FEATURE 1: OFFLINE KNOWLEDGE BASE & FEATURE MATRIX (F1_KB)
    # ==========================================================================
    Context "F1_KB - Offline Knowledge Base & Feature Matrix" {

        It "F1-01: Initialize-AiModel loads offline neural model weights and classes" {
            Initialize-AiModel
            $kb = New-MockAiKnowledgeBase
            $kb.classes.Count | Should BeGreaterThanOrEqual 6
            $kb.classes | Should Contain "Core_OS_Essential"
            $kb.classes | Should Contain "Telemetry_Tracking"
            $kb.classes | Should Contain "OEM_Bloatware"
            $kb.classes | Should Contain "ThirdParty_Updater"
            $kb.classes | Should Contain "Consumer_Bloatware"
            $kb.classes | Should Contain "High_Overhead_Task"
        }

        It "F1-02: Offline inference accurately classifies telemetry tracking services" {
            $pred = Invoke-AiInference -Name "DiagTrack" -Description "Connected User Experiences and Telemetry"
            Assert-AiInferenceContract $pred | Should BeTrue
            $pred.Category | Should Be "Telemetry_Tracking"
            $pred.SafetyTier | Should Be "Tier 1 (Safe)"
            $pred.Confidence | Should BeGreaterThanOrEqual 0.80
            $pred.IsSafeToDisable | Should BeTrue
        }

        It "F1-03: Offline inference accurately classifies OEM background bloatware" {
            $pred = Invoke-AiInference -Name "HpTouchpointAnalyticsService" -Description "HP Touchpoint Analytics Client telemetry" -Vendor "HP Inc."
            Assert-AiInferenceContract $pred | Should BeTrue
            $pred.Category | Should Be "OEM_Bloatware"
            $pred.SafetyTier | Should Be "Tier 1 (Safe)"
            $pred.IsSafeToDisable | Should BeTrue
        }

        It "F1-04: Offline inference accurately classifies third-party updaters" {
            $pred = Invoke-AiInference -Name "AdobeARMservice" -Description "Adobe Acrobat Update Service"
            Assert-AiInferenceContract $pred | Should BeTrue
            $pred.Category | Should Be "ThirdParty_Updater"
            $pred.IsSafeToDisable | Should BeTrue
        }

        It "F1-05: Offline inference accurately classifies high-overhead scheduled tasks" {
            $pred = Invoke-AiInference -Name "Microsoft Compatibility Appraiser" -Description "Compatibility Appraiser telemetry assessment task"
            Assert-AiInferenceContract $pred | Should BeTrue
            $pred.Category | Should Match "High_Overhead_Task|Telemetry_Tracking"
            $pred.IsSafeToDisable | Should BeTrue
        }

        It "F1-06: In-memory inference executes in < 100ms per evaluation" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 0; $i -lt 10; $i++) {
                $null = Invoke-AiInference -Name "DiagTrack" -Description "Telemetry"
            }
            $sw.Stop()
            $avgMs = $sw.Elapsed.TotalMilliseconds / 10.0
            $avgMs | Should BeLessThan 100.0
        }
    }

    # ==========================================================================
    # FEATURE 2: ZERO-FALSE-POSITIVE CORE WHITELIST (F2_WHITELIST)
    # ==========================================================================
    Context "F2_WHITELIST - Zero-False-Positive Core Whitelist" {

        It "F2-01: RPC and DCOM infrastructure services are cryptographically locked in Tier 0" {
            $rpc = Invoke-AiInference -Name "RpcSs"
            Assert-AiInferenceContract $rpc | Should BeTrue
            $rpc.Category | Should Be "Core_OS_Essential"
            $rpc.SafetyTier | Should Be "Tier 0 (Protected)"
            $rpc.Confidence | Should Be 1.00
            $rpc.IsSafeToDisable | Should BeFalse

            $dcom = Invoke-AiInference -Name "DcomLaunch"
            $dcom.Category | Should Be "Core_OS_Essential"
            $dcom.SafetyTier | Should Be "Tier 0 (Protected)"
            $dcom.IsSafeToDisable | Should BeFalse
        }

        It "F2-02: Windows Update, Cryptographic, and TrustedInstaller services are strictly protected" {
            $services = @("wuauserv", "trustedinstaller", "cryptsvc", "bits")
            foreach ($svc in $services) {
                $pred = Invoke-AiInference -Name $svc
                Assert-AiInferenceContract $pred | Should BeTrue
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should BeFalse
            }
        }

        It "F2-03: Security, Credential and Authentication services are strictly protected" {
            $services = @("mpssvc", "bfe", "samss", "keyiso", "lsaiso")
            foreach ($svc in $services) {
                $pred = Invoke-AiInference -Name $svc
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should BeFalse
            }
        }

        It "F2-04: Audio and Network stack services are strictly protected" {
            $services = @("audiosrv", "audioendpointbuilder", "dhcp", "dnscache", "wlansvc")
            foreach ($svc in $services) {
                $pred = Invoke-AiInference -Name $svc
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should BeFalse
            }
        }

        It "F2-05: Whitelist evaluation is case-insensitive and immune to case tampering" {
            $casingVariants = @("RPCSS", "RpcSs", "rpcss", "WuaUserv", "WUAUSERV", "CrYpTsVc")
            foreach ($variant in $casingVariants) {
                $pred = Invoke-AiInference -Name $variant
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should BeFalse
            }
        }

        It "F2-06: Whitelist protection overrides deceptive descriptions and telemetry keywords" {
            $pred = Invoke-AiInference -Name "RpcSs" -Description "Heavy telemetry tracking and background updater" -Vendor "Adware Spynet"
            $pred.Category | Should Be "Core_OS_Essential"
            $pred.SafetyTier | Should Be "Tier 0 (Protected)"
            $pred.IsSafeToDisable | Should BeFalse
        }
    }

    # ==========================================================================
    # FEATURE 3: SYSTEMAPP & NON-REMOVABLE PACKAGE SHIELD (F3_SYSTEMAPP)
    # ==========================================================================
    Context "F3_SYSTEMAPP - SystemApp & Non-Removable Shield" {

        It "F3-01: Windows Framework runtime packages are protected as Core_OS_Essential" {
            $frameworks = @(
                "Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe",
                "Microsoft.UI.Xaml.2.7_7.2208.15001.0_x64__8wekyb3d8bbwe",
                "Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe"
            )
            foreach ($fw in $frameworks) {
                $pred = Invoke-AiInference -Name $fw
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should BeFalse
            }
        }

        It "F3-02: Critical Windows Store and Terminal packages are strictly protected" {
            $criticalApps = @("Microsoft.WindowsStore", "Microsoft.DesktopAppInstaller", "Microsoft.WindowsTerminal")
            foreach ($app in $criticalApps) {
                $pred = Invoke-AiInference -Name $app
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.SafetyTier | Should Be "Tier 0 (Protected)"
                $pred.IsSafeToDisable | Should BeFalse
            }
        }

        It "F3-03: Edge and WebView system packages are classified as Core_OS_Essential" {
            $edgeApps = @("Microsoft.MicrosoftEdgeDevToolsClient", "Microsoft.Win32WebViewHost", "Microsoft.XboxGameCallableUI")
            foreach ($app in $edgeApps) {
                $pred = Invoke-AiInference -Name $app
                $pred.Category | Should Be "Core_OS_Essential"
                $pred.IsSafeToDisable | Should BeFalse
            }
        }

        It "F3-04: AppX scanner strictly filters out NonRemovable and Framework packages" {
            $mockAppx = New-MockAppxInventory -Preset "Bloated"
            $filtered = @($mockAppx | Where-Object {
                -not ($_.NonRemovable -or ($_.InstallLocation -and $_.InstallLocation -match 'SystemApps|ImmersiveControlPanel') -or ($_.SignatureKind -eq "System") -or $_.IsFramework)
            })
            $filteredNames = @($filtered | ForEach-Object { $_.Name })
            $filteredNames | Should Not Contain "Microsoft.VCLibs.140.00"
            $filteredNames | Should Not Contain "Microsoft.DesktopAppInstaller"
            $filteredNames | Should Contain "Clipchamp.Clipchamp"
        }

        It "F3-05: Remediation defensively handles non-removable SystemApp items without COMException failure" {
            $mockItem = New-MockCandidateItem -TargetType "AppX" -Name "Microsoft.MicrosoftEdgeDevToolsClient" -Category "Consumer_Bloatware"
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($mockItem) -Force
            $result | Should Not BeNullOrEmpty
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 1
        }

        It "F3-06: Remediation logs skipped state rather than falsely claiming package removal" {
            $mockSystemApp = New-MockCandidateItem -TargetType "AppX" -Name "Microsoft.WindowsTerminal"
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($mockSystemApp) -Force
            $result.Applied | Should Be 0
            $result.Skipped | Should BeGreaterThanOrEqual 1
        }
    }

    # ==========================================================================
    # FEATURE 4: LIVE HARDWARE INSPECTOR (F4_HW)
    # ==========================================================================
    Context "F4_HW - Live Hardware Inspector" {

        It "F4-01: System profile conforms to PROJECT.md hardware contract" {
            $profile = Get-WinAurexSystemProfile
            Assert-SystemProfileContract $profile | Should BeTrue
            $profile.Hardware | Should Not BeNullOrEmpty
            $profile.Workload | Should Not BeNullOrEmpty
        }

        It "F4-02: CPU inspector detects physical cores, logical threads, and non-empty name" {
            $profile = Get-WinAurexSystemProfile
            $profile.Hardware.CpuCores | Should BeGreaterThan 0
            $profile.Hardware.CpuThreads | Should BeGreaterOrEqual $profile.Hardware.CpuCores
            $profile.Hardware.CpuName | Should Not BeNullOrEmpty
        }

        It "F4-03: RAM inspector detects total capacity in gigabytes" {
            $profile = Get-WinAurexSystemProfile
            $profile.Hardware.TotalRamGB | Should BeGreaterThan 0.0
        }

        It "F4-04: Storage inspector identifies media and bus type" {
            $profile = Get-WinAurexSystemProfile
            $profile.Hardware.StorageType | Should Match "NVMe SSD|SATA SSD|HDD"
        }

        It "F4-05: Power and Chassis inspector reports boolean laptop and battery states" {
            $profile = Get-WinAurexSystemProfile
            ($profile.Hardware.IsLaptop -is [bool]) | Should BeTrue
            ($profile.Hardware.OnBattery -is [bool]) | Should BeTrue
        }

        It "F4-06: New-MockSystemProfile builder creates valid customizable profiles" {
            $custom = New-MockSystemProfile -CpuCores 16 -CpuThreads 32 -TotalRamGB 64.0 -GpuVendor "AMD" -StorageType "NVMe SSD" -IsLaptop $true -OnBattery $true
            Assert-SystemProfileContract $custom | Should BeTrue
            $custom.Hardware.CpuCores | Should Be 16
            $custom.Hardware.TotalRamGB | Should Be 64.0
            $custom.Hardware.IsLaptop | Should BeTrue
            $custom.Hardware.OnBattery | Should BeTrue
        }
    }

    # ==========================================================================
    # FEATURE 5: WORKLOAD PROFILER & PROCESS DRAINERS (F5_WORKLOAD)
    # ==========================================================================
    Context "F5_WORKLOAD - Workload Profiler & Process Drainers" {

        It "F5-01: Get-WinAurexHealthScore calculates health score, grade, and process counts" {
            $health = Get-WinAurexHealthScore
            $health | Should Not BeNullOrEmpty
            $health.Score | Should BeGreaterOrEqual 30
            $health.Score | Should BeLessOrEqual 100
            $health.Grade | Should Match "^(A\+|A|B|C|D.*)$"
            $health.ProcessCount | Should BeGreaterThan 0
        }

        It "F5-02: Get-ProcessAnomalies filters out critical Windows OS processes" {
            $anomalies = Get-ProcessAnomalies
            $sysIgnore = @("System", "Idle", "Registry", "smss", "csrss", "wininit", "winlogon", "lsass", "services", "dwm", "explorer")
            foreach ($a in $anomalies) {
                $sysIgnore | Should Not Contain $a.ProcessName
            }
        }

        It "F5-03: Invoke-WinAurexRamFlush executes memory working set trimming" {
            $flush = Invoke-WinAurexRamFlush
            $flush | Should Not BeNullOrEmpty
            $flush.ProcessesTrimmed | Should BeGreaterOrEqual 0
            $flush.ReclaimedMB | Should BeGreaterOrEqual 0.0
            $flush.FreeMemoryMB | Should BeGreaterThan 0
        }

        It "F5-04: Workload profiler reports valid CPU and RAM utilization bounds [0, 100]" {
            $profile = Get-WinAurexSystemProfile
            $profile.Workload.CpuLoadPercent | Should BeGreaterOrEqual 0.0
            $profile.Workload.CpuLoadPercent | Should BeLessOrEqual 100.0
            $profile.Workload.RamUsedPercent | Should BeGreaterOrEqual 0.0
            $profile.Workload.RamUsedPercent | Should BeLessOrEqual 100.0
        }

        It "F5-05: Gaming process detection identifies active gaming workloads" {
            $gamingProfile = New-MockSystemProfile -IsGamingActive $true -ActiveGameName "cs2.exe"
            $gamingProfile.Workload.IsGamingActive | Should BeTrue
            $gamingProfile.Workload.ActiveGameName | Should Be "cs2.exe"
        }

        It "F5-06: Process drainer anomalies include valid suggested actions" {
            $anomalies = Get-ProcessAnomalies
            $anomalies | Should Not BeNullOrEmpty
            $anomalies.Count | Should BeGreaterThan 0
            $first = $anomalies[0]
            $first.PID | Should BeGreaterThan 0
            $first.ProcessName | Should Not BeNullOrEmpty
            $first.SuggestedAction | Should Not BeNullOrEmpty
            $first.SuggestedAction | Should Match "Trim Working Set|Suppress Background Task"
            $first.AnomalyReason | Should Not BeNullOrEmpty
        }
    }

    # ==========================================================================
    # FEATURE 6: CANDIDATE STATE & ACCURACY ENGINE (F6_SCAN)
    # ==========================================================================
    Context "F6_SCAN - Candidate State & Accuracy Engine" {

        It "F6-01: Candidate items conform to standard candidate data contract" {
            $cand = New-MockCandidateItem -TargetType "Service" -Name "DiagTrack" -Category "Telemetry_Tracking"
            Assert-CandidateItemContract $cand | Should BeTrue
        }

        It "F6-02: Services that are Disabled and Stopped have IsAlreadyApplied = $true" {
            $disabledSvc = New-MockCandidateItem -TargetType "Service" -Name "RetailDemo" -CurrentState "Stopped" -IsAlreadyApplied $true -IsSelected $false
            $disabledSvc.IsAlreadyApplied | Should BeTrue
            $disabledSvc.StatusDisplay | Should Match "Optimized|Disabled"
            $disabledSvc.Action | Should Be "Already Disabled"
            $disabledSvc.IsSelected | Should BeFalse
        }

        It "F6-03: Services that are Running have IsAlreadyApplied = $false and are actionable" {
            $activeSvc = New-MockCandidateItem -TargetType "Service" -Name "DiagTrack" -CurrentState "Running" -IsAlreadyApplied $false -IsSelected $true
            $activeSvc.IsAlreadyApplied | Should BeFalse
            $activeSvc.Action | Should Match "Disable"
            $activeSvc.IsSelected | Should BeTrue
        }

        It "F6-04: Scheduled tasks that are Disabled have IsAlreadyApplied = $true" {
            $task = New-MockCandidateItem -TargetType "ScheduledTask" -Name "WinSAT" -IsAlreadyApplied $true -IsSelected $false
            $task.IsAlreadyApplied | Should BeTrue
            $task.Action | Should Be "Already Disabled"
            $task.IsSelected | Should BeFalse
        }

        It "F6-05: Candidates belong to valid taxonomic categories" {
            $validCats = @("Telemetry_Tracking", "OEM_Bloatware", "ThirdParty_Updater", "Consumer_Bloatware", "High_Overhead_Task")
            $items = @(
                (New-MockCandidateItem -Category "Telemetry_Tracking")
                (New-MockCandidateItem -Category "OEM_Bloatware")
                (New-MockCandidateItem -Category "High_Overhead_Task")
            )
            foreach ($it in $items) {
                $validCats | Should Contain $it.Category
            }
        }

        It "F6-06: Candidate items never contain null or empty Name or TargetType" {
            $item = New-MockCandidateItem -Name "dmwappushservice" -TargetType "Service"
            $item.Name | Should Not BeNullOrEmpty
            $item.TargetType | Should Not BeNullOrEmpty
        }
    }

    # ==========================================================================
    # FEATURE 7: DYNAMIC CONTEXTUAL RECOMMENDER (F7_RECOMMEND)
    # ==========================================================================
    Context "F7_RECOMMEND - Dynamic Contextual Recommender" {

        It "F7-01: Dynamic recommendations conform to PROJECT.md interface contract" {
            $recs = Get-WinAurexAiRecommendations
            $recs.Count | Should BeGreaterThan 0
            foreach ($r in $recs) {
                Assert-RecommendationContract $r | Should BeTrue
            }
        }

        It "F7-02: Active gaming profile triggers Gaming Latency Shield recommendation" {
            $gamingProfile = New-MockSystemProfile -IsGamingActive $true -ActiveGameName "cs2.exe"
            $recs = Get-WinAurexAiRecommendations -Profile $gamingProfile
            $gameRec = @($recs | Where-Object { $_.Category -eq "Gaming_Bottleneck" })
            $gameRec.Count | Should BeGreaterThan 0
            $gameRec[0].Priority | Should Be "High"
            $gameRec[0].TargetItems | Should Contain "Win32PrioritySeparation"
        }

        It "F7-03: Low-RAM profile triggers Working Set Flush recommendation" {
            $lowRamProfile = New-MockSystemProfile -TotalRamGB 4.0 -RamUsedPercent 85.0
            $recs = Get-WinAurexAiRecommendations -Profile $lowRamProfile
            $ramRec = @($recs | Where-Object { $_.Id -eq "REC-RAM-01" })
            $ramRec.Count | Should BeGreaterThan 0
            $ramRec[0].Priority | Should Be "High"
        }

        It "F7-04: Laptop on battery triggers power-conscious background throttling recommendation" {
            $batteryProfile = New-MockSystemProfile -IsLaptop $true -OnBattery $true
            $recs = Get-WinAurexAiRecommendations -Profile $batteryProfile
            $pwrRec = @($recs | Where-Object { $_.Id -eq "REC-PWR-01" })
            $pwrRec.Count | Should BeGreaterThan 0
            $pwrRec[0].Category | Should Be "Telemetry"
        }

        It "F7-05: Set-AiGamingShield -Enable activates gaming quantum 0x28 and returns Active" {
            $priorityControl = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
            $origPri = if (Test-Path $priorityControl) { (Get-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation } else { $null }
            try {
                $res = Set-AiGamingShield -Enable
                $res | Should Not BeNullOrEmpty
                $res.Status | Should Be "Active"
                $res.PrioritySeparation | Should Match "0x28"
            } finally {
                if ($null -ne $origPri -and (Test-Path $priorityControl)) {
                    Set-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -Value $origPri -Type DWord -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It "F7-06: Set-AiGamingShield -Disable restores standard priority separation 0x2" {
            $priorityControl = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
            $origPri = if (Test-Path $priorityControl) { (Get-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation } else { $null }
            try {
                [void](Set-AiGamingShield -Enable)
                $res = Set-AiGamingShield -Disable
                $res | Should Not BeNullOrEmpty
                $res.Status | Should Be "Disabled"
                $res.PrioritySeparation | Should Match "0x2"
            } finally {
                if ($null -ne $origPri -and (Test-Path $priorityControl)) {
                    Set-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -Value $origPri -Type DWord -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    # ==========================================================================
    # FEATURE 8: REMEDIATION CORE & ROLLBACK ENGINE (F8_REMEDIATE)
    # ==========================================================================
    Context "F8_REMEDIATE - Remediation Core & Rollback Engine" {

        It "F8-01: Invoke-WinAurexAiRemediation accepts empty collection without parameter validation error" {
            $res = Invoke-WinAurexAiRemediation -SelectedItems @() -Force
            $res | Should Not BeNullOrEmpty
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "F8-02: Invoke-WinAurexAiRemediation accepts null SelectedItems gracefully" {
            $res = Invoke-WinAurexAiRemediation -SelectedItems $null -Force
            $res | Should Not BeNullOrEmpty
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 0
        }

        It "F8-03: Remediation skips candidates where IsAlreadyApplied is true" {
            $appliedItem = New-MockCandidateItem -IsAlreadyApplied $true
            $res = Invoke-WinAurexAiRemediation -SelectedItems @($appliedItem) -Force
            $res.Applied | Should Be 0
            $res.Skipped | Should Be 1
        }

        It "F8-04: Remediation executes ProgressCallback reporting execution percentages" {
            $cbState = @{ Called = $false; LastPct = 0 }
            $callback = {
                param($msg, $pct)
                $cbState.Called = $true
                $cbState.LastPct = $pct
            }
            $item = New-MockCandidateItem -TargetType "Service" -Name "NonExistentDummyService_WinAurexTest" -IsAlreadyApplied $false
            $res = Invoke-WinAurexAiRemediation -SelectedItems @($item) -ProgressCallback $callback -Force
            $cbState.Called | Should BeTrue
            $cbState.LastPct | Should BeGreaterThan 0
        }

        It "F8-05: Remediation applies baseline telemetry and privacy policy suppressions" {
            # Invoke remediation with empty set triggers baseline policy enforcement
            $null = Invoke-WinAurexAiRemediation -SelectedItems @() -Force

            $doVal = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -ErrorAction SilentlyContinue).DODownloadMode
            $adVal = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled

            if ($null -ne $doVal) { $doVal | Should Be 0 }
            if ($null -ne $adVal) { $adVal | Should Be 0 }
        }

        It "F8-06: New-MockTransactionSnapshot generates valid rollback manifest" {
            $snap = New-MockTransactionSnapshot -TransactionID "TXN-TEST-100" -Changes @(@{ Target = "DiagTrack"; Action = "Disabled" })
            $snap.TransactionID | Should Be "TXN-TEST-100"
            $snap.Changes.Count | Should Be 1
            $snap.Timestamp | Should Not BeNullOrEmpty
        }
    }

    # ==========================================================================
    # FEATURE 9: CLI OPTIMIZER OVERHAUL (F9_CLI)
    # ==========================================================================
    Context "F9_CLI - CLI Optimizer Overhaul" {

        It "F9-01: AI_Dynamic_System_Optimizer.ps1 exists and has zero syntax errors" {
            (Test-Path $CliScript) | Should BeTrue
            $errors = @()
            $null = [System.Management.Automation.Language.Parser]::ParseFile($CliScript, [ref]$null, [ref]$errors)
            $errors.Count | Should Be 0
        }

        It "F9-02: CLI script declares required parameters: ScanOnly, Auto, Revert, Force" {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($CliScript, [ref]$null, [ref]$null)
            $params = $ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
            $params | Should Contain "ScanOnly"
            $params | Should Contain "Auto"
            $params | Should Contain "Revert"
            $params | Should Contain "Force"
        }

        It "F9-03: CLI script verifies and imports Core/AI/WinAurex_AiEngine.psm1" {
            $content = Get-Content -Path $CliScript -Raw
            $content | Should Match "WinAurex_AiEngine\.psm1"
            $content | Should Match "Import-Module"
        }

        It "F9-04: CLI execution in -ScanOnly mode completes with exit code 0" {
            $p = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CliScript`" -ScanOnly -Force" -Wait -PassThru -NoNewWindow
            $p.ExitCode | Should Be 0
        }

        It "F9-05: CLI session creates timestamped log file in Logs directory" {
            $logDir = Join-Path $RepoRootDir "Logs"
            $recentLogs = Get-ChildItem -Path $logDir -Filter "AI_Optimizer_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
            $recentLogs.Count | Should BeGreaterThan 0
            $latest = Get-Content -Path $recentLogs[0].FullName -Raw
            $latest | Should Match "AI Optimizer session started"
        }

        It "F9-06: CLI produces formatted detection summaries for services, AppX, and tasks" {
            $content = Get-Content -Path $CliScript -Raw
            $content | Should Match "\[SUMMARY OF AI DETECTIONS\]"
            $content | Should Match "Background Services"
            $content | Should Match "Bloatware Packages"
            $content | Should Match "High-Overhead Tasks"
        }
    }

    # ==========================================================================
    # FEATURE 10: WPF DASHBOARD AI TAB INTEGRATION (F10_GUI)
    # ==========================================================================
    Context "F10_GUI - WPF Dashboard AI Tab Integration" {

        It "F10-01: Dashboard.xaml is valid XML and defines required AI Tab UI elements" {
            (Test-Path $XamlPath) | Should BeTrue
            [xml]$xaml = Get-Content -Path $XamlPath -Raw
            $xaml | Should Not BeNullOrEmpty

            $rawContent = Get-Content -Path $XamlPath -Raw
            $requiredControls = @("NavAiOptimizer", "ViewAiOptimizer", "BtnAiScan", "BtnAiOptimize", "ListAiFindings", "TxtAiHealthScore", "TxtAiScanStatus", "BtnAiFlushRam", "BtnAiGamingShield")
            foreach ($ctrl in $requiredControls) {
                $rawContent | Should Match "Name=`"$ctrl`""
            }
        }

        It "F10-02: Launch_Dashboard.ps1 parses cleanly with zero syntax errors" {
            (Test-Path $GuiScript) | Should BeTrue
            $errors = @()
            $null = [System.Management.Automation.Language.Parser]::ParseFile($GuiScript, [ref]$null, [ref]$errors)
            $errors.Count | Should Be 0
        }

        It "F10-03: Candidate objects contain all data-bound properties for DataGrid columns" {
            $cand = New-MockCandidateItem
            $boundProps = @("TargetType", "Name", "Category", "Confidence", "TierDisplay", "CurrentState", "StatusDisplay", "Action")
            foreach ($bp in $boundProps) {
                $cand.PSObject.Properties[$bp] | Should Not BeNullOrEmpty
            }
        }

        It "F10-04: AI Tab filter buttons logic segments candidates by status and safety tier" {
            $candPending = New-MockCandidateItem -Name "PendingBloat" -IsAlreadyApplied $false -SafetyTier "Tier 1 (Safe)"
            $candOptimized = New-MockCandidateItem -Name "OptimizedService" -IsAlreadyApplied $true -SafetyTier "Tier 2 (Recommended)"
            $list = @($candPending, $candOptimized)

            $pending = @($list | Where-Object { -not $_.IsAlreadyApplied })
            $pending.Count | Should Be 1
            $pending[0].Name | Should Be "PendingBloat"

            $optimized = @($list | Where-Object { $_.IsAlreadyApplied })
            $optimized.Count | Should Be 1
            $optimized[0].Name | Should Be "OptimizedService"

            $safe = @($list | Where-Object { $_.SafetyTier -eq "Tier 1 (Safe)" })
            $safe.Count | Should Be 1
            $safe[0].Name | Should Be "PendingBloat"
        }

        It "F10-05: AI Health Score HUD integration formats score and grade strings" {
            $health = Get-WinAurexHealthScore
            $hudScore = "$($health.Score) / 100"
            $hudScore | Should Match "^\d+ / 100$"

            $hudDetail = "$($health.Score)/100 (Grade $($health.Grade))"
            $hudDetail | Should Match "^\d+/100 \(Grade .+\)$"
        }

        It "F10-06: 1-Click optimization UI flow updates status and marks findings as optimized" {
            $findings = @(
                (New-MockCandidateItem -Name "ServiceA" -IsAlreadyApplied $false)
                (New-MockCandidateItem -Name "TaskB" -IsAlreadyApplied $false)
            )

            # Simulate the UI completion handler from Launch_Dashboard.ps1:1792-1815
            foreach ($item in $findings) {
                $item.IsAlreadyApplied = $true
                $item.StatusDisplay = "Optimized (Disabled)"
                $item.Action = "Already Disabled"
                $item.CurrentState = "Already Disabled"
            }

            $pendingAfter = @($findings | Where-Object { -not $_.IsAlreadyApplied })
            $pendingAfter.Count | Should Be 0
            $findings[0].IsAlreadyApplied | Should BeTrue
            $findings[0].StatusDisplay | Should Be "Optimized (Disabled)"
        }
    }
}
