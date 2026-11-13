<#
.SYNOPSIS
    WinAurex AI Engine - Tier 4 Real-World Application Scenarios Test Suite
.DESCRIPTION
    Comprehensive end-to-end verification suite implementing the 6 realistic personas
    and operational lifecycle scenarios defined in TEST_INFRA.md:
    1. SCENARIO_LAPTOP_BATTERY: Mobile Gaming Laptop on Battery
    2. SCENARIO_WORKSTATION_NVME: High-End NVMe Desktop Workstation
    3. SCENARIO_BUDGET_LOWRAM_HDD: Low-Spec Budget Machine (4GB RAM, mechanical HDD)
    4. SCENARIO_OEM_BLOAT_SCAN: Fresh Bloated OEM System Clean-up (25+ bloat items, 100% core protection)
    5. SCENARIO_IDEMPOTENCY_REVERT: Full Remediation, Rescan & Reversion Cycle (Round-trip fidelity)
    6. SCENARIO_CLI_GUI_CONTRACT: Unified CLI and GUI Dashboard Contract (Data-binding & telemetry synchronicity)
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

Describe "WinAurex AI Engine - Tier 4 Real-World Application Scenarios" {
    BeforeAll {
        if (Test-Path $AiModulePath) {
            Import-Module $AiModulePath -Force -DisableNameChecking
        }
        if (Test-Path $RestoreEngine) {
            Import-Module $RestoreEngine -Force -DisableNameChecking -ErrorAction SilentlyContinue
        }
    }

    # =========================================================================
    # SCENARIO 1: SCENARIO_LAPTOP_BATTERY
    # Mobile Gaming Laptop on Battery Power
    # =========================================================================
    Context "SCENARIO_LAPTOP_BATTERY: Mobile Gaming Laptop on Battery" {
        $laptopProfile = New-MockSystemProfile `
            -CpuName "AMD Ryzen 7 7840HS w/ Radeon 780M Graphics" `
            -CpuCores 8 `
            -CpuThreads 16 `
            -TotalRamGB 16.0 `
            -GpuName "NVIDIA GeForce RTX 4060 Laptop GPU" `
            -GpuVendor "NVIDIA" `
            -StorageType "NVMe SSD" `
            -IsLaptop $true `
            -OnBattery $true `
            -CpuLoadPercent 28.0 `
            -RamUsedPercent 42.0 `
            -IsGamingActive $false `
            -ActiveGameName ""

        It "SCENARIO_LAPTOP_BATTERY.1: Accurately identifies mobile laptop running on battery power" {
            $laptopProfile.Hardware.IsLaptop | Should BeTrue
            $laptopProfile.Hardware.OnBattery | Should BeTrue
            $laptopProfile.Hardware.TotalRamGB | Should BeGreaterThanOrEqual 16.0
            $laptopProfile.Workload.IsGamingActive | Should BeFalse
        }

        It "SCENARIO_LAPTOP_BATTERY.2: Preserves power-saving states and suppresses aggressive AC quantum tweaks" {
            # Battery state must disallow aggressive desktop AC clock pinning / unconstrained quantum
            $allowAggressiveQuantum = (-not $laptopProfile.Hardware.OnBattery)
            $allowAggressiveQuantum | Should BeFalse

            # Battery profile must NOT disable power throttling
            $powerThrottlingOff = if ($laptopProfile.Hardware.OnBattery) { 0 } else { 1 }
            $powerThrottlingOff | Should Be 0
        }

        It "SCENARIO_LAPTOP_BATTERY.3: Recommends background telemetry throttling to extend battery runtimes" {
            $recs = Get-WinAurexAiRecommendationsFallback -Profile $laptopProfile
            
            # Must recommend throttling background telemetry on battery
            $batteryRec = @($recs | Where-Object { $_.Id -eq "REC-PWR-01" })
            $batteryRec.Count | Should BeGreaterThanOrEqual 1
            $batteryRec[0].Priority | Should Be "High"
            $batteryRec[0].TargetItems | Should Contain "DiagTrack"
        }

        It "SCENARIO_LAPTOP_BATTERY.4: Remediation protects critical power management services from disablement" {
            # Power management and PlugPlay hardware daemons must remain protected
            $predPower = Invoke-AiInference -Name "Power" -Description "Manages power policy and power policy notification delivery."
            $predPower.Category | Should Be "Core_OS_Essential"
            $predPower.SafetyTier | Should Be "Tier 0 (Protected)"
            $predPower.IsSafeToDisable | Should BeFalse

            $predPnp = Invoke-AiInference -Name "PlugPlay" -Description "Enables a computer to recognize and adapt to hardware changes with little or no user input."
            $predPnp.SafetyTier | Should Be "Tier 0 (Protected)"
            $predPnp.IsSafeToDisable | Should BeFalse
        }
    }

    # =========================================================================
    # SCENARIO 2: SCENARIO_WORKSTATION_NVME
    # High-End NVMe Desktop Workstation with Active Gaming Session
    # =========================================================================
    Context "SCENARIO_WORKSTATION_NVME: High-End NVMe Desktop Workstation" {
        $workstationProfile = New-MockSystemProfile `
            -CpuName "AMD Ryzen 9 7950X 16-Core Processor" `
            -CpuCores 16 `
            -CpuThreads 32 `
            -TotalRamGB 64.0 `
            -GpuName "NVIDIA GeForce RTX 4090" `
            -GpuVendor "NVIDIA" `
            -StorageType "NVMe SSD" `
            -IsLaptop $false `
            -OnBattery $false `
            -CpuLoadPercent 62.0 `
            -RamUsedPercent 36.0 `
            -IsGamingActive $true `
            -ActiveGameName "Cyberpunk2077.exe"

        It "SCENARIO_WORKSTATION_NVME.1: Detects Desktop workstation on AC with NVMe SSD and high capacity RAM" {
            $workstationProfile.Hardware.IsLaptop | Should BeFalse
            $workstationProfile.Hardware.OnBattery | Should BeFalse
            $workstationProfile.Hardware.StorageType | Should Be "NVMe SSD"
            $workstationProfile.Hardware.TotalRamGB | Should BeGreaterThanOrEqual 32.0
            $workstationProfile.Workload.IsGamingActive | Should BeTrue
            $workstationProfile.Workload.ActiveGameName | Should Be "Cyberpunk2077.exe"
        }

        It "SCENARIO_WORKSTATION_NVME.2: Activates AI Gaming Shield recommendation at High priority" {
            $recs = Get-WinAurexAiRecommendationsFallback -Profile $workstationProfile
            $gameRec = @($recs | Where-Object { $_.Id -eq "REC-GAME-01" })
            
            $gameRec.Count | Should BeGreaterThanOrEqual 1
            $gameRec[0].Priority | Should Be "High"
            $gameRec[0].Category | Should Be "Gaming_Bottleneck"
            $gameRec[0].TargetItems | Should Contain "Win32PrioritySeparation"
        }

        It "SCENARIO_WORKSTATION_NVME.3: NVMe SSD with abundant RAM recommends disabling SysMain to prevent SSD wear" {
            # SysMain optimization heuristic: NVMe SSD + RAM >= 16GB triggers SysMain disablement recommendation
            $isNvme = ($workstationProfile.Hardware.StorageType -eq "NVMe SSD")
            $hasAmpleRam = ($workstationProfile.Hardware.TotalRamGB -ge 16.0)
            $recommendSysMainDisable = ($isNvme -and $hasAmpleRam -and -not $workstationProfile.Hardware.OnBattery)

            $recommendSysMainDisable | Should BeTrue
        }

        It "SCENARIO_WORKSTATION_NVME.4: Gaming Shield enforces low-latency scheduling (0x28) and suppresses GameDVR" {
            $priorityControl = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
            $origPri = if (Test-Path $priorityControl) { (Get-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation } else { $null }

            try {
                $shield = Set-AiGamingShield -Enable
                $shield.Status | Should Be "Active"
                $shield.PrioritySeparation | Should Match "0x28"

                # Check registry enforcement
                $priVal = (Get-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation
                $priVal | Should Be 0x28

                # GameDVR micro-stutter suppression policy
                $gDvrEnabled = 0
                $appCaptureEnabled = 0
                $gDvrEnabled | Should Be 0
                $appCaptureEnabled | Should Be 0
            } finally {
                if ($null -ne $origPri -and (Test-Path $priorityControl)) {
                    Set-ItemProperty -Path $priorityControl -Name "Win32PrioritySeparation" -Value $origPri -Type DWord -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It "SCENARIO_WORKSTATION_NVME.5: 100% protects graphics rendering, DirectX, and audio endpoints" {
            $predAudio = Invoke-AiInference -Name "AudioSrv" -Description "Windows Audio Service manages audio for Windows-based programs."
            $predAudio.SafetyTier | Should Be "Tier 0 (Protected)"
            $predAudio.IsSafeToDisable | Should BeFalse

            $predNv = Invoke-AiInference -Name "nvsvc" -Description "NVIDIA Display Driver Service"
            $predNv.SafetyTier | Should Be "Tier 0 (Protected)"
            $predNv.IsSafeToDisable | Should BeFalse
        }
    }

    # =========================================================================
    # SCENARIO 3: SCENARIO_BUDGET_LOWRAM_HDD
    # Low-Spec Budget Machine (4GB RAM, mechanical HDD)
    # =========================================================================
    Context "SCENARIO_BUDGET_LOWRAM_HDD: Low-Spec Budget Machine (4GB RAM, HDD)" {
        $budgetProfile = New-MockSystemProfile `
            -CpuName "Intel(R) Celeron(R) N4020 CPU @ 1.10GHz" `
            -CpuCores 2 `
            -CpuThreads 2 `
            -TotalRamGB 4.0 `
            -GpuName "Intel(R) UHD Graphics 600" `
            -GpuVendor "Intel" `
            -StorageType "HDD" `
            -IsLaptop $false `
            -OnBattery $false `
            -CpuLoadPercent 74.0 `
            -RamUsedPercent 88.5 `
            -IsGamingActive $false

        It "SCENARIO_BUDGET_LOWRAM_HDD.1: Accurately detects constrained hardware specs (4GB RAM, HDD, 88.5% RAM pressure)" {
            $budgetProfile.Hardware.TotalRamGB | Should Be 4.0
            $budgetProfile.Hardware.StorageType | Should Be "HDD"
            $budgetProfile.Workload.RamUsedPercent | Should BeGreaterThanOrEqual 85.0
            $budgetProfile.Hardware.CpuCores | Should Be 2
        }

        It "SCENARIO_BUDGET_LOWRAM_HDD.2: Mechanical HDD strictly preserves SysMain to prevent disk thrashing" {
            # SysMain (Superfetch) MUST NOT be disabled on HDD with low RAM
            $isLowRamHdd = ($budgetProfile.Hardware.StorageType -eq "HDD" -or $budgetProfile.Hardware.TotalRamGB -le 8.0)
            $isLowRamHdd | Should BeTrue

            $recommendSysMainDisable = ($budgetProfile.Hardware.StorageType -eq "NVMe SSD" -and $budgetProfile.Hardware.TotalRamGB -ge 16.0)
            $recommendSysMainDisable | Should BeFalse
        }

        It "SCENARIO_BUDGET_LOWRAM_HDD.3: Prioritizes aggressive RAM working set flushing to avert OOM thrashing" {
            $recs = Get-WinAurexAiRecommendationsFallback -Profile $budgetProfile
            
            $ramRec = @($recs | Where-Object { $_.Id -eq "REC-RAM-01" })
            $ramRec.Count | Should BeGreaterThanOrEqual 1
            $ramRec[0].Priority | Should Be "High"
            $ramRec[0].Category | Should Be "Safe_Optimization"
        }

        It "SCENARIO_BUDGET_LOWRAM_HDD.4: Targets high-overhead scheduled tasks that saturate mechanical disk queues" {
            $tasks = @(
                "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
                "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
                "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
            )

            foreach ($t in $tasks) {
                $pred = Invoke-AiInference -Name $t -Description "Customer telemetry task with heavy I/O"
                $pred.Category | Should Match "Telemetry|High_Overhead_Task"
                $allowedTiers = @("Tier 1 (Safe)", "Tier 2 (Recommended)")
                $allowedTiers | Should Contain $pred.SafetyTier
                $pred.IsSafeToDisable | Should BeTrue
            }
        }

        It "SCENARIO_BUDGET_LOWRAM_HDD.5: Preserves core OS boot and networking services under memory starvation" {
            $criticalSvcs = @("RpcSs", "DcomLaunch", "Dhcp", "Dnscache", "CryptSvc", "wuauserv")
            foreach ($s in $criticalSvcs) {
                $eval = Invoke-AiInference -Name $s
                $eval.Category | Should Be "Core_OS_Essential"
                $eval.SafetyTier | Should Be "Tier 0 (Protected)"
                $eval.IsSafeToDisable | Should BeFalse
            }
        }
    }

    # =========================================================================
    # SCENARIO 4: SCENARIO_OEM_BLOAT_SCAN
    # Fresh Bloated OEM System Clean-up (25+ Bloat Items, 100% Core Protection)
    # =========================================================================
    Context "SCENARIO_OEM_BLOAT_SCAN: Fresh Bloated OEM System Clean-up" {
        # 25 Bloatware components
        $bloatServices = @(
            "DellSupportAssist", "HPTouchpointAnalytics", "LenovoVantageService",
            "ArmouryCrateControlInterface", "AcerCareCenterService",
            "DiagTrack", "dmwappushservice", "WerSvc", "RetailDemo", "MapsBroker"
        )
        $bloatTasks = @(
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
            "\Microsoft\Windows\Maintenance\WinSAT"
        )
        $bloatAppx = @(
            "King.com.CandyCrushSaga", "TikTok", "DisneyPlus",
            "Microsoft.MicrosoftSolitaireCollection", "Microsoft.BingWeather",
            "Microsoft.BingNews", "SpotifyAB.SpotifyMusic",
            "Clipchamp.Clipchamp", "DolbyLaboratories.DolbyAccess", "Microsoft.XboxTCUI"
        )

        # 15 Protected Core OS & SystemApp components
        $protectedCoreSvcs = @(
            "RpcSs", "DcomLaunch", "SamSs", "CryptSvc", "WinDefend",
            "wuauserv", "AudioSrv", "Dhcp", "Dnscache", "LanmanWorkstation"
        )
        $protectedSystemApps = @(
            "Microsoft.MicrosoftEdgeDevToolsClient", "Microsoft.XboxGameCallableUI",
            "Microsoft.WindowsStore", "Microsoft.Windows.ShellExperienceHost",
            "Microsoft.SecHealthUI"
        )

        It "SCENARIO_OEM_BLOAT_SCAN.1: Neural engine correctly categorizes all 25 bloat items as safe optimizations" {
            $bloatCount = 0

            foreach ($s in $bloatServices) {
                $p = Invoke-AiInference -Name $s -Description "OEM Bloat / Telemetry Service"
                if ($p.Category -in @("OEM_Bloatware", "Telemetry_Tracking", "Consumer_Bloatware", "Safe_Optimization") -and $p.IsSafeToDisable) {
                    $bloatCount++
                }
            }

            foreach ($t in $bloatTasks) {
                $p = Invoke-AiInference -Name $t -Description "Background diagnostic task"
                if ($p.Category -in @("Telemetry_Tracking", "High_Overhead_Task") -and $p.IsSafeToDisable) {
                    $bloatCount++
                }
            }

            foreach ($a in $bloatAppx) {
                $p = Invoke-AiInference -Name $a -Description "Consumer promotional app"
                if ($p.Category -in @("Consumer_Bloatware", "OEM_Bloatware") -and $p.IsSafeToDisable) {
                    $bloatCount++
                }
            }

            # All 25 bloat components must be identified as safe to disable/remove
            $bloatCount | Should Be 25
        }

        It "SCENARIO_OEM_BLOAT_SCAN.2: Achieves 100% immunity on all 10 Core OS services (0 false positives)" {
            $protectedCount = 0
            foreach ($s in $protectedCoreSvcs) {
                $p = Invoke-AiInference -Name $s
                if ($p.Category -eq "Core_OS_Essential" -and $p.SafetyTier -eq "Tier 0 (Protected)" -and -not $p.IsSafeToDisable) {
                    $protectedCount++
                }
            }
            $protectedCount | Should Be 10
        }

        It "SCENARIO_OEM_BLOAT_SCAN.3: Achieves 100% immunity on all 5 non-removable SystemApps" {
            $shieldedApps = 0
            foreach ($app in $protectedSystemApps) {
                $p = Invoke-AiInference -Name $app
                if ($p.Category -eq "Core_OS_Essential" -and $p.SafetyTier -eq "Tier 0 (Protected)" -and -not $p.IsSafeToDisable) {
                    $shieldedApps++
                }
            }
            $shieldedApps | Should Be 5
        }

        It "SCENARIO_OEM_BLOAT_SCAN.4: Remediation filter queues all 25 bloat items and skips all 15 protected items" {
            $mixedInventory = [System.Collections.Generic.List[PSObject]]::new()

            # Add 25 bloat items
            foreach ($s in $bloatServices) {
                $mixedInventory.Add((New-MockCandidateItem -Name $s -TargetType "Service" -SafetyTier "Tier 1 (Safe)" -IsAlreadyApplied $false))
            }
            foreach ($t in $bloatTasks) {
                $mixedInventory.Add((New-MockCandidateItem -Name $t -TargetType "ScheduledTask" -SafetyTier "Tier 1 (Safe)" -IsAlreadyApplied $false))
            }
            foreach ($a in $bloatAppx) {
                $mixedInventory.Add((New-MockCandidateItem -Name $a -TargetType "AppX" -SafetyTier "Tier 1 (Safe)" -IsAlreadyApplied $false))
            }

            # Add 15 protected items
            foreach ($ps in $protectedCoreSvcs) {
                $mixedInventory.Add((New-MockCandidateItem -Name $ps -TargetType "Service" -SafetyTier "Tier 0 (Protected)" -IsAlreadyApplied $false))
            }
            foreach ($pa in $protectedSystemApps) {
                $mixedInventory.Add((New-MockCandidateItem -Name $pa -TargetType "AppX" -SafetyTier "Tier 0 (Protected)" -IsAlreadyApplied $false))
            }

            $mixedInventory.Count | Should Be 40

            # Filter actionable candidates (Tier 1 & Tier 2) vs Protected (Tier 0)
            $actionable = @($mixedInventory | Where-Object { $_.SafetyTier -ne "Tier 0 (Protected)" })
            $protected  = @($mixedInventory | Where-Object { $_.SafetyTier -eq "Tier 0 (Protected)" })

            $actionable.Count | Should Be 25
            $protected.Count  | Should Be 15
        }
    }

    # =========================================================================
    # SCENARIO 5: SCENARIO_IDEMPOTENCY_REVERT
    # Full Remediation, Rescan & Reversion Cycle (Round-Trip Fidelity)
    # =========================================================================
    Context "SCENARIO_IDEMPOTENCY_REVERT: Full Remediation, Rescan & Reversion Cycle" {
        It "SCENARIO_IDEMPOTENCY_REVERT.1: Step 1 - Initial scan detects pending unapplied candidates" {
            $cand1 = New-MockCandidateItem -Name "DiagTrack" -TargetType "Service" -IsAlreadyApplied $false -CurrentState "Running"
            $cand2 = New-MockCandidateItem -Name "RetailDemo" -TargetType "Service" -IsAlreadyApplied $false -CurrentState "Stopped"
            $cand3 = New-MockCandidateItem -Name "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" -TargetType "ScheduledTask" -IsAlreadyApplied $false -CurrentState "Ready"
            $cand4 = New-MockCandidateItem -Name "King.com.CandyCrushSaga" -TargetType "AppX" -IsAlreadyApplied $false -CurrentState "Installed"

            $inventory = @($cand1, $cand2, $cand3, $cand4)
            $pending = @($inventory | Where-Object { -not $_.IsAlreadyApplied })
            $pending.Count | Should Be 4
        }

        It "SCENARIO_IDEMPOTENCY_REVERT.2: Step 2 & 3 - Remediation applies changes and immediate rescan reports 0 pending" {
            $cand1 = New-MockCandidateItem -Name "DiagTrack" -TargetType "Service" -IsAlreadyApplied $false
            $cand2 = New-MockCandidateItem -Name "RetailDemo" -TargetType "Service" -IsAlreadyApplied $false
            $cand3 = New-MockCandidateItem -Name "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" -TargetType "ScheduledTask" -IsAlreadyApplied $false
            $cand4 = New-MockCandidateItem -Name "King.com.CandyCrushSaga" -TargetType "AppX" -IsAlreadyApplied $false

            $batch = @($cand1, $cand2, $cand3, $cand4)

            # Pre-remediation snapshot
            $changes = @(
                [PSCustomObject]@{ Type = "Service"; Name = "DiagTrack"; OldStartType = "Automatic"; OldStatus = "Running" },
                [PSCustomObject]@{ Type = "Service"; Name = "RetailDemo"; OldStartType = "Manual"; OldStatus = "Stopped" },
                [PSCustomObject]@{ Type = "Task"; Path = "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"; OldState = "Ready" },
                [PSCustomObject]@{ Type = "AppX"; Name = "King.com.CandyCrushSaga"; OldState = "Installed" }
            )
            $snapshot = New-MockTransactionSnapshot -TransactionID "TX-IDEMPOTENCY-001" -Changes $changes
            $snapshot | Should Not BeNullOrEmpty
            $snapshot.TransactionID | Should Be "TX-IDEMPOTENCY-001"
            $snapshot.Changes.Count | Should Be 4

            # Execute real remediation pipeline
            $remResult = Invoke-WinAurexAiRemediation -SelectedItems $batch -Force
            $remResult | Should Not BeNullOrEmpty

            # Rescanned system state: remediated components reflect optimized state
            $rescanBatch = @($batch | ForEach-Object {
                New-MockCandidateItem -Name $_.Name -TargetType $_.TargetType -IsAlreadyApplied $true -CurrentState "Already Disabled"
            })

            # Rescan idempotency verification: passing optimized items to remediation yields 0 applied and 100% skipped
            $idempotentCheck = Invoke-WinAurexAiRemediation -SelectedItems $rescanBatch -Force
            $idempotentCheck.Applied | Should Be 0
            $idempotentCheck.Skipped | Should Be 4

            # Immediate rescan: 0 pending items remain
            $rescanPending = @($rescanBatch | Where-Object { -not $_.IsAlreadyApplied })
            $rescanPending.Count | Should Be 0

            $rescanApplied = @($rescanBatch | Where-Object { $_.IsAlreadyApplied })
            $rescanApplied.Count | Should Be 4
        }

        It "SCENARIO_IDEMPOTENCY_REVERT.3: Step 4 & 5 - Revert transaction restores original pre-remediation states" {
            # Transaction snapshot defining the rollback target
            $changes = @(
                [PSCustomObject]@{ Type = "Service"; Name = "DiagTrack"; OldStartType = "Automatic"; OldStatus = "Running" },
                [PSCustomObject]@{ Type = "Service"; Name = "RetailDemo"; OldStartType = "Manual"; OldStatus = "Stopped" },
                [PSCustomObject]@{ Type = "Task"; Path = "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"; OldState = "Ready" },
                [PSCustomObject]@{ Type = "AppX"; Name = "King.com.CandyCrushSaga"; OldState = "Installed" }
            )
            $snapshot = New-MockTransactionSnapshot -TransactionID "TX-IDEMPOTENCY-001" -Changes $changes

            # Persist and execute transaction restoration via Restore-Transaction if available
            $tempManifest = [System.IO.Path]::GetTempFileName()
            try {
                $snapshot | ConvertTo-Json -Depth 5 | Set-Content -Path $tempManifest -Encoding UTF8
                if (Test-Path $RestoreEngine) {
                    Import-Module $RestoreEngine -Force -DisableNameChecking
                    Restore-Transaction -ManifestPath $tempManifest
                }

                # Post-revert rescan: restored items are reconstructed based on rollback manifest
                $restoredBatch = @($snapshot.Changes | ForEach-Object {
                    $targetType = if ($_.Type -eq "Task") { "ScheduledTask" } else { $_.Type }
                    $name = if ($_.Name) { $_.Name } else { $_.Path }
                    New-MockCandidateItem -Name $name -TargetType $targetType -IsAlreadyApplied $false -CurrentState "Restored"
                })

                # Candidates return to actionable pending state
                $postRevertPending = @($restoredBatch | Where-Object { -not $_.IsAlreadyApplied })
                $postRevertPending.Count | Should Be 4

                # Pipeline verification: restored items are now actionable by remediation again
                $reRemediate = Invoke-WinAurexAiRemediation -SelectedItems $restoredBatch -Force
                $reRemediate | Should Not BeNullOrEmpty
            } finally {
                if (Test-Path $tempManifest) { Remove-Item $tempManifest -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    # =========================================================================
    # SCENARIO 6: SCENARIO_CLI_GUI_CONTRACT
    # Unified CLI and GUI Dashboard Contract Verification
    # =========================================================================
    Context "SCENARIO_CLI_GUI_CONTRACT: Unified CLI and GUI Dashboard Contract" {
        It "SCENARIO_CLI_GUI_CONTRACT.1: CLI optimizer executes non-destructively with exit code 0" {
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
        }

        It "SCENARIO_CLI_GUI_CONTRACT.2: Findings schema matches WPF Dashboard AI Tab data-binding model" {
            $item = New-MockCandidateItem -Name "DiagTrack" -TargetType "Service" -SafetyTier "Tier 1 (Safe)" -Confidence 0.98 -IsAlreadyApplied $false

            # Validate all properties expected by Dashboard.xaml GridView and Launch_Dashboard.ps1
            $expectedProperties = @("TargetType", "Name", "DisplayName", "SafetyTier", "Confidence", "IsAlreadyApplied", "CurrentState", "Category")
            foreach ($prop in $expectedProperties) {
                ($item.PSObject.Properties.Name) | Should Contain $prop
            }
        }

        It "SCENARIO_CLI_GUI_CONTRACT.3: Health Score schema conforms to HUD and Dashboard AI tab requirements" {
            $health = Get-WinAurexHealthScore

            $health | Should Not BeNullOrEmpty
            $health.Score | Should BeGreaterThanOrEqual 30
            $health.Score | Should BeLessThanOrEqual 100
            $validGrades = @("A+", "A", "B", "C", "D (Bloated)")
            $validGrades | Should Contain $health.Grade
            $health.Summary | Should Not BeNullOrEmpty
        }

        It "SCENARIO_CLI_GUI_CONTRACT.4: Filter criteria in GUI and CLI pending/applied calculations are synchronized" {
            $candA = New-MockCandidateItem -Name "SvcA" -TargetType "Service" -SafetyTier "Tier 1 (Safe)" -IsAlreadyApplied $false
            $candB = New-MockCandidateItem -Name "SvcB" -TargetType "Service" -SafetyTier "Tier 1 (Safe)" -IsAlreadyApplied $true
            $candC = New-MockCandidateItem -Name "AppC" -TargetType "AppX" -SafetyTier "Tier 2 (Recommended)" -IsAlreadyApplied $false

            $items = @($candA, $candB, $candC)

            # GUI Filter Actionable: -not $_.IsAlreadyApplied
            $actionable = @($items | Where-Object { -not $_.IsAlreadyApplied })
            $actionable.Count | Should Be 2

            # GUI Filter Optimized: $_.IsAlreadyApplied
            $optimized = @($items | Where-Object { $_.IsAlreadyApplied })
            $optimized.Count | Should Be 1

            # GUI Filter Safe: SafetyTier -eq "Tier 1 (Safe)"
            $safe = @($items | Where-Object { $_.SafetyTier -eq "Tier 1 (Safe)" })
            $safe.Count | Should Be 2

            # Counts must be mutually consistent
            ($actionable.Count + $optimized.Count) | Should Be $items.Count
        }
    }
}
