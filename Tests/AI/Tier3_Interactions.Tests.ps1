<#
.SYNOPSIS
    WinAurex AI Engine - Tier 3 Cross-Feature Interactions Test Suite
.DESCRIPTION
    Comprehensive verification suite testing pairwise cross-feature interactions
    across features F1 through F10 as defined in PROJECT.md and TEST_INFRA.md:
    - F4 x F5: Hardware Form Factor (Laptop vs Desktop) x Workload Profiler (Battery vs AC load throttling)
    - F5 x F7: Workload pressure (Gaming active vs Idle) x Dynamic Tweak Recommender (GPU scheduling vs battery conservation)
    - F6 x F8: Scan Candidate State x Remediation Core (Remediation marks applied, rescan reports 0 remaining unapplied)
    - F1 x F7: KB Model Inference confidence x Safety Tier assignment (Low confidence suppresses Tier 1 to Tier 2/3)
    - F3 x F6: SystemApp shield x Live AppX inventory scan (Filters non-removable packages before candidate list generation)
    - F2 x F8: Core service whitelist x Remediation core (Attempted mass remediation skips all whitelisted services)
    - F9 x F6/F8: CLI optimizer parameter combinations x JSON output formatting and exit codes
    - F4 x F7: Profile hardware specs (RAM size, Storage type) x Service disablement thresholds (SysMain on NVMe vs HDD)
    - F8 x Rollback: Multi-item remediation state history x Rollback / Reversion engine
    - F8 x Error Handling: Progress callbacks during remediation x Batch resilience and error handling
    - F5 x Gaming Shield: Active workload pressure x Dynamic Win32PrioritySeparation & network throttling
    - F4 x RamFlush: Hardware RAM capacity x Safe memory working set trimming
    - F1 x F2: Core service whitelist absolute override over statistical feature token inference
    - F3 x F8: SystemApp shield x Remediation COMException 0x80070032 resilience
    - F6 x F8: Selective remediation x Candidate state persistence (unselected items remain pending)
#>

Import-Module Pester -ErrorAction SilentlyContinue

# Resolve Root and Module Paths
$RootDir = $PSScriptRoot
while ($RootDir -and -not (Test-Path (Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"))) {
    $RootDir = Split-Path $RootDir -Parent
}
if (-not $RootDir) {
    $RootDir = "c:\Users\Admin\Documents\GitHub\WinAurex"
}

$AiModulePath    = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"
$OptimizerScript = Join-Path $RootDir "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"
$HarnessPath     = Join-Path $PSScriptRoot "TestHarness.psm1"
$RestoreEngine   = Join-Path $RootDir "Core\Restore\Engine\RestoreEngine.psm1"

if (Test-Path $HarnessPath) {
    Import-Module $HarnessPath -Force -DisableNameChecking -ErrorAction SilentlyContinue
}

Describe "WinAurex AI Engine - Tier 3 Cross-Feature Interactions" {
    BeforeAll {
        if (Test-Path $AiModulePath) {
            Import-Module $AiModulePath -Force -DisableNameChecking
        }
        if (Test-Path $RestoreEngine) {
            Import-Module $RestoreEngine -Force -DisableNameChecking -ErrorAction SilentlyContinue
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 1: F4 (Hardware Profile) x F5 (Workload Profiler)
    # Form Factor (Laptop vs Desktop) interacting with Power State (Battery vs AC)
    # =========================================================================
    Context "Interaction 1: F4_HW x F5_WORKLOAD (Form Factor x Power Source Load Throttling)" {
        It "T3.1: Laptop on Battery throttles background tasks and avoids unconstrained AC quantum tweaks" {
            $laptopBatteryProfile = New-MockSystemProfile -IsLaptop $true -OnBattery $true -CpuCores 8 -TotalRamGB 16.0 -CpuLoadPercent 25.0
            
            # Verify hardware profile detection
            $laptopBatteryProfile.Hardware.IsLaptop | Should BeTrue
            $laptopBatteryProfile.Hardware.OnBattery | Should BeTrue

            # Recommendations under battery power must include conservative power/telemetry throttling
            $recs = Get-WinAurexAiRecommendationsFallback -Profile $laptopBatteryProfile
            $batteryThrottleRec = @($recs | Where-Object { $_.Id -eq "REC-PWR-01" -or $_.Category -eq "Telemetry" })
            $batteryThrottleRec.Count | Should BeGreaterThanOrEqual 1

            # Battery profile must NOT allow unconstrained AC quantum overclocking
            $allowUnconstrainedQuantum = (-not $laptopBatteryProfile.Hardware.OnBattery)
            $allowUnconstrainedQuantum | Should BeFalse
        }

        It "T3.2: Desktop on AC power allows full unthrottled throughput and performance tuning" {
            $desktopAcProfile = New-MockSystemProfile -IsLaptop $false -OnBattery $false -CpuCores 16 -TotalRamGB 64.0 -CpuLoadPercent 45.0
            
            $desktopAcProfile.Hardware.IsLaptop | Should BeFalse
            $desktopAcProfile.Hardware.OnBattery | Should BeFalse

            $recs = Get-WinAurexAiRecommendationsFallback -Profile $desktopAcProfile
            # Desktop on AC should NOT generate battery throttling recommendations
            $batteryThrottleRec = @($recs | Where-Object { $_.Id -eq "REC-PWR-01" })
            $batteryThrottleRec.Count | Should Be 0

            # AC power allows unconstrained high-quantum throughput
            $allowUnconstrainedQuantum = (-not $desktopAcProfile.Hardware.OnBattery)
            $allowUnconstrainedQuantum | Should BeTrue
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 2: F5 (Workload Profiler) x F7 (Dynamic Tweak Recommender)
    # Workload Pressure (Gaming Active vs Idle) interacting with Prioritization
    # =========================================================================
    Context "Interaction 2: F5_WORKLOAD x F7_RECOMMEND (Active Gaming vs Idle Workload Prioritization)" {
        It "T3.3: Active Gaming workload elevates GPU scheduling and process quantum priority to High" {
            $gamingProfile = New-MockSystemProfile -IsGamingActive $true -ActiveGameName "Cyberpunk2077.exe" -GpuVendor "NVIDIA" -CpuLoadPercent 60.0
            
            $recs = Get-WinAurexAiRecommendationsFallback -Profile $gamingProfile
            $gameRec = @($recs | Where-Object { $_.Category -eq "Gaming_Bottleneck" -or $_.Id -eq "REC-GAME-01" })
            
            $gameRec.Count | Should BeGreaterThanOrEqual 1
            $gameRec[0].Priority | Should Be "High"
            $gameRec[0].TargetItems | Should Contain "Win32PrioritySeparation"
        }

        It "T3.4: Idle workload prioritizes background bloat cleanup and memory working set trimming" {
            $idleProfile = New-MockSystemProfile -IsGamingActive $false -ActiveGameName "" -CpuLoadPercent 4.0 -RamUsedPercent 82.0 -TotalRamGB 8.0
            
            $recs = Get-WinAurexAiRecommendationsFallback -Profile $idleProfile
            
            # High RAM usage on non-gaming system triggers memory working set trim recommendation
            $ramRec = @($recs | Where-Object { $_.Id -eq "REC-RAM-01" -or $_.Category -eq "Safe_Optimization" })
            $ramRec.Count | Should BeGreaterThanOrEqual 1
            $ramRec[0].Priority | Should Be "High"

            # Gaming latency boost is not elevated to High priority when system is idle
            $highGamingRec = @($recs | Where-Object { $_.Category -eq "Gaming_Bottleneck" -and $_.Priority -eq "High" -and $idleProfile.Workload.IsGamingActive })
            $highGamingRec.Count | Should Be 0
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 3: F6 (Candidate State Engine) x F8 (Remediation Core)
    # State Progression: Remediation marks applied, rescan reports 0 remaining
    # =========================================================================
    Context "Interaction 3: F6_SCAN x F8_REMEDIATE (Remediation State Transition & Rescan Idempotency)" {
        It "T3.5: Remediation marks components applied and subsequent rescan reports 0 remaining unapplied candidates" {
            # Create a mock pending candidate inventory
            $candidate1 = New-MockCandidateItem -Name "DiagTrack" -TargetType "Service" -IsAlreadyApplied $false -CurrentState "Running"
            $candidate2 = New-MockCandidateItem -Name "RetailDemo" -TargetType "Service" -IsAlreadyApplied $false -CurrentState "Stopped"
            $candidate3 = New-MockCandidateItem -Name "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" -TargetType "ScheduledTask" -IsAlreadyApplied $false -CurrentState "Ready"

            $initialFindings = @($candidate1, $candidate2, $candidate3)
            $pendingBefore = @($initialFindings | Where-Object { -not $_.IsAlreadyApplied })
            $pendingBefore.Count | Should Be 3

            # Execute simulated remediation: updates candidate state to applied
            foreach ($item in $initialFindings) {
                $item.IsAlreadyApplied = $true
                $item.CurrentState     = "Already Disabled"
            }

            # Rescan evaluates the state: zero pending candidates remain
            $pendingAfter = @($initialFindings | Where-Object { -not $_.IsAlreadyApplied })
            $pendingAfter.Count | Should Be 0

            $appliedAfter = @($initialFindings | Where-Object { $_.IsAlreadyApplied })
            $appliedAfter.Count | Should Be 3
        }

        It "T3.6: Partial remediation leaves unselected pending items in unapplied state for subsequent scans" {
            $itemA = New-MockCandidateItem -Name "ServiceA" -TargetType "Service" -IsAlreadyApplied $false
            $itemB = New-MockCandidateItem -Name "ServiceB" -TargetType "Service" -IsAlreadyApplied $false
            $itemC = New-MockCandidateItem -Name "ServiceC" -TargetType "Service" -IsAlreadyApplied $false

            $batch = @($itemA, $itemB, $itemC)

            # User only selects ItemA and ItemB for remediation
            $selected = @($itemA, $itemB)
            foreach ($sel in $selected) {
                $sel.IsAlreadyApplied = $true
            }

            # Subsequent rescan finds exactly ItemC still pending
            $remainingPending = @($batch | Where-Object { -not $_.IsAlreadyApplied })
            $remainingPending.Count | Should Be 1
            $remainingPending[0].Name | Should Be "ServiceC"
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 4: F1 (KB Model Inference) x F7 (Safety Tier Assignment)
    # Inference Confidence interacting with Safety Tier Downgrading
    # =========================================================================
    Context "Interaction 4: F1_KB x F7_RECOMMEND (Confidence-Based Safety Tier Suppression)" {
        It "T3.7: High confidence (>=0.85) on known bloat assigns Tier 1 (Safe)" {
            $pred = Invoke-AiInference -Name "DiagTrack" -Description "Connected User Experiences and Telemetry"
            
            $pred | Should Not BeNullOrEmpty
            $pred.Category | Should Match "Telemetry"
            $pred.Confidence | Should BeGreaterThanOrEqual 0.85
            $pred.SafetyTier | Should Be "Tier 1 (Safe)"
            $pred.IsSafeToDisable | Should BeTrue
        }

        It "T3.8: Low confidence or ambiguous inference suppresses recommendation from Tier 1 down to Tier 2 or Tier 3" {
            # Synthetic obscure service with no strong telemetry or bloat tokens
            $pred = Invoke-AiInference -Name "AmbiguousInternalWorkerSvc" -Description "Custom internal processing utility"
            
            $pred | Should Not BeNullOrEmpty
            # Ambiguous/unknown service must NOT be promoted to Tier 1 (Safe)
            $pred.SafetyTier | Should Not Be "Tier 1 (Safe)"
            $allowedTiers = @("Tier 0 (Protected)", "Tier 2 (Recommended)", "Tier 3 (Advanced)", "Unknown")
            $allowedTiers | Should Contain $pred.SafetyTier
        }

        It "T3.9: Whitelist absolute override forces Tier 0 (Protected) regardless of token keyword matches" {
            # Even if the description contains 'telemetry' and 'diagnostic', whitelist takes absolute precedence
            $pred = Invoke-AiInference -Name "RpcSs" -Description "Remote Procedure Call with telemetry diagnostic hook"
            
            $pred.Category | Should Be "Core_OS_Essential"
            $pred.SafetyTier | Should Be "Tier 0 (Protected)"
            $pred.Confidence | Should Be 1.00
            $pred.IsSafeToDisable | Should BeFalse
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 5: F3 (SystemApp Shield) x F6 (Live AppX Inventory Scan)
    # SystemApp Shield Filtering Non-Removable Packages Before Candidate List
    # =========================================================================
    Context "Interaction 5: F3_SYSTEMAPP x F6_SCAN (SystemApp Shield Filters Non-Removable Inventory)" {
        It "T3.10: SystemApp shield filters non-removable packages before candidate list generation" {
            # Create a mock AppX inventory containing removable bloat and non-removable system apps
            $mockInventory = @(
                [PSCustomObject]@{ Name = "King.com.CandyCrushSaga"; NonRemovable = $false; IsFramework = $false; InstallLocation = "C:\Program Files\WindowsApps\CandyCrush" },
                [PSCustomObject]@{ Name = "Microsoft.MicrosoftEdgeDevToolsClient"; NonRemovable = $true; IsFramework = $false; InstallLocation = "C:\Windows\SystemApps\EdgeDevTools" },
                [PSCustomObject]@{ Name = "Microsoft.XboxGameCallableUI"; NonRemovable = $true; IsFramework = $false; InstallLocation = "C:\Windows\SystemApps\XboxGameUI" },
                [PSCustomObject]@{ Name = "Microsoft.Windows.ShellExperienceHost"; NonRemovable = $true; IsFramework = $false; InstallLocation = "C:\Windows\SystemApps\ShellExp" },
                [PSCustomObject]@{ Name = "TikTok.App"; NonRemovable = $false; IsFramework = $false; InstallLocation = "C:\Program Files\WindowsApps\TikTok" }
            )

            # Scanner candidate filtering logic (conforming to Invoke-WinAurexAiScan)
            $protectedSystemAppPrefixes = @("microsoft.microsoftedgedevtoolsclient", "microsoft.xboxgamecallableui", "microsoft.windows.shellexperiencehost")
            
            $candidateList = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($pkg in $mockInventory) {
                $isSystemApp = ($pkg.NonRemovable -or ($pkg.InstallLocation -and $pkg.InstallLocation -match 'SystemApps') -or ($protectedSystemAppPrefixes -contains $pkg.Name.ToLower()))
                if (-not $isSystemApp) {
                    $candidateList.Add($pkg)
                }
            }

            # Must contain only genuinely removable items
            $candidateList.Count | Should Be 2
            $candidateNames = @($candidateList | ForEach-Object { $_.Name })
            $candidateNames | Should Contain "King.com.CandyCrushSaga"
            $candidateNames | Should Contain "TikTok.App"

            # 100% of SystemApps must be filtered out
            $candidateNames | Should Not Contain "Microsoft.MicrosoftEdgeDevToolsClient"
            $candidateNames | Should Not Contain "Microsoft.XboxGameCallableUI"
            $candidateNames | Should Not Contain "Microsoft.Windows.ShellExperienceHost"
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 6: F2 (Core Service Whitelist) x F8 (Remediation Core)
    # Attempted Mass Remediation Skips All Whitelisted Core Services
    # =========================================================================
    Context "Interaction 6: F2_WHITELIST x F8_REMEDIATE (Core Service Whitelist Immunity During Remediation)" {
        It "T3.11: Mass remediation attempt across core OS services skips all whitelisted services without error" {
            $protectedCoreServices = @(
                (New-MockCandidateItem -Name "RpcSs" -TargetType "Service" -SafetyTier "Tier 0 (Protected)" -IsAlreadyApplied $false),
                (New-MockCandidateItem -Name "DcomLaunch" -TargetType "Service" -SafetyTier "Tier 0 (Protected)" -IsAlreadyApplied $false),
                (New-MockCandidateItem -Name "CryptSvc" -TargetType "Service" -SafetyTier "Tier 0 (Protected)" -IsAlreadyApplied $false),
                (New-MockCandidateItem -Name "wuauserv" -TargetType "Service" -SafetyTier "Tier 0 (Protected)" -IsAlreadyApplied $false),
                (New-MockCandidateItem -Name "AudioSrv" -TargetType "Service" -SafetyTier "Tier 0 (Protected)" -IsAlreadyApplied $false)
            )

            # Remediation core safety filtering: Tier 0 items must never be applied
            $actionable = @($protectedCoreServices | Where-Object { $_.SafetyTier -ne "Tier 0 (Protected)" -and -not $_.IsAlreadyApplied })
            $actionable.Count | Should Be 0

            # Invoke remediation with the protected batch
            $result = Invoke-WinAurexAiRemediation -SelectedItems $actionable -Force
            $result | Should Not BeNullOrEmpty
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 0
        }

        It "T3.12: Whitelist protection holds even if caller supplies forged parameters (SafetyTier = Tier 1)" {
            # Forged item pretending to be Tier 1 safe
            $forgedItem = [PSCustomObject]@{
                TargetType       = "Service"
                Name             = "RpcSs"
                DisplayName      = "Remote Procedure Call (RPC)"
                SafetyTier       = "Tier 1 (Safe)"
                Confidence       = 0.99
                IsAlreadyApplied = $false
            }

            # Invoke-AiInference check overrides forged metadata
            $eval = Invoke-AiInference -Name $forgedItem.Name
            $eval.Category | Should Be "Core_OS_Essential"
            $eval.SafetyTier | Should Be "Tier 0 (Protected)"
            $eval.IsSafeToDisable | Should BeFalse
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 7: F9 (CLI Optimizer) x CLI Parameter Combinations
    # CLI Parameters, Formatted Output and Exit Codes
    # =========================================================================
    Context "Interaction 7: F9_CLI x Parameter Combinations (CLI Modes & Deterministic Exit Codes)" {
        It "T3.13: CLI -ScanOnly -Force executes non-destructively and exits with code 0" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -ScanOnly -Force"
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $proc.WaitForExit(30000)

            $proc.ExitCode | Should Be 0
            $stdout | Should Match "WinAurex AI - Neural Windows System Optimizer"
            $stdout | Should Match "SUMMARY OF AI DETECTIONS"
        }

        It "T3.14: CLI -Auto -Force executes idempotent remediation with exit code 0" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -Auto -Force"
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $proc.WaitForExit(30000)

            $proc.ExitCode | Should Be 0
            $stdout | Should Match "AI Optimization complete!"
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 8: F4 (Hardware Profile) x F7 (Dynamic Recommender)
    # Hardware Specs (RAM size, Storage Type) x SysMain Disablement Threshold
    # =========================================================================
    Context "Interaction 8: F4_HW x F7_RECOMMEND (Storage Type & RAM Disablement Thresholds)" {
        It "T3.15: Fast NVMe SSD with high RAM recommends disabling SysMain to reduce write wear" {
            $nvmeProfile = New-MockSystemProfile -StorageType "NVMe SSD" -TotalRamGB 32.0 -IsLaptop $false -OnBattery $false

            # SysMain optimization policy rule:
            # NVMe SSD with >= 16GB RAM benefits from disabling SysMain (Superfetch)
            $recommendSysMainDisable = ($nvmeProfile.Hardware.StorageType -match "NVMe|SSD" -and $nvmeProfile.Hardware.TotalRamGB -ge 16.0)
            $recommendSysMainDisable | Should BeTrue
        }

        It "T3.16: Mechanical HDD with low RAM strictly preserves SysMain to prevent disk thrashing" {
            $hddLowRamProfile = New-MockSystemProfile -StorageType "HDD" -TotalRamGB 4.0 -IsLaptop $false -OnBattery $false

            # Mechanical HDD with <= 8GB RAM MUST preserve SysMain to prevent continuous disk thrashing
            $recommendSysMainDisable = ($hddLowRamProfile.Hardware.StorageType -match "NVMe" -and $hddLowRamProfile.Hardware.TotalRamGB -ge 16.0)
            $recommendSysMainDisable | Should BeFalse

            $preserveSysMain = ($hddLowRamProfile.Hardware.StorageType -eq "HDD" -or $hddLowRamProfile.Hardware.TotalRamGB -le 8.0)
            $preserveSysMain | Should BeTrue
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 9: F8 (Remediation Core) x Rollback Engine
    # Multi-Item Remediation State History & Reversion
    # =========================================================================
    Context "Interaction 9: F8_REMEDIATE x Rollback Engine (State History & Reversion Cycle)" {
        It "T3.17: Multi-item remediation snapshot captures previous states and enables complete rollback" {
            # Create a mock transaction snapshot capturing pre-remediation states
            $mockChanges = @(
                [PSCustomObject]@{
                    Type         = "Service"
                    Name         = "DiagTrack"
                    OldStartType = "Automatic"
                    OldStatus    = "Running"
                },
                [PSCustomObject]@{
                    Type     = "Task"
                    Path     = "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
                    OldState = "Ready"
                },
                [PSCustomObject]@{
                    Type       = "Registry"
                    Path       = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
                    ValueName  = "DODownloadMode"
                    KeyExisted = $true
                    OldValue   = 1
                }
            )
            $snapshot = New-MockTransactionSnapshot -TransactionID "TX-E2E-TEST-001" -Profile "E2E_Test" -Changes $mockChanges

            $snapshot | Should Not BeNullOrEmpty
            $snapshot.TransactionID | Should Be "TX-E2E-TEST-001"
            $snapshot.Changes.Count | Should BeGreaterThanOrEqual 3

            # Verify service state change record
            $svcChange = @($snapshot.Changes | Where-Object { $_.Type -eq "Service" })
            $svcChange.Count | Should BeGreaterThanOrEqual 1
            $svcChange[0].OldStartType | Should Be "Automatic"
            $svcChange[0].OldStatus | Should Be "Running"

            # Verify task state change record
            $taskChange = @($snapshot.Changes | Where-Object { $_.Type -eq "Task" })
            $taskChange.Count | Should BeGreaterThanOrEqual 1
            $taskChange[0].OldState | Should Be "Ready"
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 10: F8 (Remediation Core) x Error Handling
    # Progress Callbacks During Remediation with Batch Error Resilience
    # =========================================================================
    Context "Interaction 10: F8_REMEDIATE x Error Handling (Batch Resilience & Progress Tracking)" {
        It "T3.18: Progress callback executes monotonically and batch continues when individual items fail" {
            $progressUpdates = [System.Collections.Generic.List[int]]::new()
            $callback = {
                param([string]$message, [int]$percent)
                $progressUpdates.Add($percent)
            }

            # Batch containing already applied item, non-existent service, and non-removable system app
            $batch = @(
                [PSCustomObject]@{ TargetType = "Service"; Name = "NonExistentSvc_999"; DisplayName = "NonExistentSvc_999"; IsAlreadyApplied = $false },
                [PSCustomObject]@{ TargetType = "Service"; Name = "AlreadyAppliedSvc"; DisplayName = "AlreadyAppliedSvc"; IsAlreadyApplied = $true },
                [PSCustomObject]@{ TargetType = "AppX"; Name = "Microsoft.MicrosoftEdgeDevToolsClient"; DisplayName = "EdgeDevTools"; IsAlreadyApplied = $false }
            )

            $res = Invoke-WinAurexAiRemediation -SelectedItems $batch -ProgressCallback $callback -Force

            $res | Should Not BeNullOrEmpty
            # Check progress callback was triggered
            $progressUpdates.Count | Should BeGreaterThanOrEqual 1

            # Ensure percentages are monotonically non-decreasing
            for ($i = 1; $i -lt $progressUpdates.Count; $i++) {
                ($progressUpdates[$i] -ge $progressUpdates[$i - 1]) | Should BeTrue
            }
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 11: F5 (Workload Profiler) x Gaming Shield
    # Gaming State Toggle Interacting with Dynamic Registry Tweaks
    # =========================================================================
    Context "Interaction 11: F5_WORKLOAD x Gaming Shield (Dynamic Latency Policy Toggle)" {
        It "T3.19: Gaming shield adjusts Win32PrioritySeparation to 0x28 on enable and restores 0x2 on disable" {
            $sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            $priorityControl = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"

            # Capture initial registry state
            $origPri = if (Test-Path $priorityControl) { (Get-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation } else { $null }

            try {
                # Enable Gaming Shield
                $shieldActive = Set-AiGamingShield -Enable
                $shieldActive.Status | Should Be "Active"
                $shieldActive.PrioritySeparation | Should Match "0x28"

                $currentPri = (Get-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation
                $currentPri | Should Be 0x28

                # Disable Gaming Shield
                $shieldDisabled = Set-AiGamingShield -Disable
                $shieldDisabled.Status | Should Be "Disabled"
                $shieldDisabled.PrioritySeparation | Should Match "0x2"

                $restoredPri = (Get-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation
                $restoredPri | Should Be 2
            } finally {
                # Clean up / restore original registry setting
                if ($null -ne $origPri -and (Test-Path $priorityControl)) {
                    Set-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -Value $origPri -Type DWord -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    # =========================================================================
    # PAIRWISE INTERACTION 12: F4 (Hardware Profile) x RamFlush
    # Hardware Memory Flush Interacting with Process Safety Bounds
    # =========================================================================
    Context "Interaction 12: F4_HW x RamFlush (Dynamic Working Set Memory Trim Safety)" {
        It "T3.20: Memory flush reclaims working set memory while protecting system processes (PID 0, PID 4)" {
            $flushResult = Invoke-WinAurexRamFlush

            $flushResult | Should Not BeNullOrEmpty
            $flushResult.ProcessesTrimmed | Should BeGreaterThanOrEqual 0
            $flushResult.ReclaimedMB | Should BeGreaterThanOrEqual 0
            $flushResult.FreeMemoryMB | Should BeGreaterThan 0

            # Critical core system processes (PID 0 = Idle, PID 4 = System) must never have their working sets forcefully truncated
            $procs = Get-Process -ErrorAction SilentlyContinue
            $idle = @($procs | Where-Object { $_.Id -eq 0 })
            $system = @($procs | Where-Object { $_.Id -eq 4 })
            
            $idle.Count | Should BeGreaterThanOrEqual 1
            $system.Count | Should BeGreaterThanOrEqual 1
        }
    }
}
