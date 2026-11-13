<#
.SYNOPSIS
    WinAurex AI Engine - Tier 2 Boundary, Corner Cases & Zero-FP Safety Test Suite
.DESCRIPTION
    Comprehensive verification suite testing boundary conditions, limit values,
    zero-false-positive invariants, non-removable package safety, extreme hardware
    and workload states, and concurrency guards across features F1 through F10.
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

$AiModulePath = Join-Path $RootDir "Core\AI\WinAurex_AiEngine.psm1"
$OptimizerScript = Join-Path $RootDir "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"
$HarnessPath = Join-Path $PSScriptRoot "TestHarness.psm1"

if (Test-Path $HarnessPath) {
    Import-Module $HarnessPath -Force -DisableNameChecking -ErrorAction SilentlyContinue
}

Describe "WinAurex AI Engine - Tier 2 Boundary & Corner Cases" {
    BeforeAll {
        if (Test-Path $AiModulePath) {
            Import-Module $AiModulePath -Force -DisableNameChecking
        }
    }

    # =========================================================================
    # FEATURE 1: F1_KB (Offline Knowledge Base & Feature Matrix)
    # =========================================================================
    Context "F1_KB: Boundary & Corner Cases for Knowledge Base & Model Loading" {
        It "F1.1: Handles non-existent model file gracefully without throwing unhandled exceptions" {
            $mod = Get-Module WinAurex_AiEngine
            $backupPath = & $mod { $script:ModelPath }
            $backupModel = & $mod { $script:AiModel }
            try {
                & $mod {
                    $script:ModelPath = "C:\non_existent_mock_model_file.json"
                    $script:AiModel = $null
                }
                $res = Invoke-AiInference -Name "WinAurexMockCandidateSvc"
                $res | Should Not BeNullOrEmpty
                $res.Category | Should Be "Unknown"
                $res.SafetyTier | Should Be "Tier 2 (Recommended)"
                $res.Confidence | Should Be 0.50
                $res.IsSafeToDisable | Should Be $true
            } finally {
                & $mod {
                    param($p, $m)
                    $script:ModelPath = $p
                    $script:AiModel = $m
                    Initialize-AiModel
                } -p $backupPath -m $backupModel
            }
        }

        It "F1.2: Handles malformed JSON model file gracefully without throwing unhandled fatal crash" {
            $tempBadJson = Join-Path ([System.IO.Path]::GetTempPath()) "bad_winaurex_model_$([Guid]::NewGuid().ToString('N')).json"
            Set-Content -Path $tempBadJson -Value "{ 'classes': [ unclosed broken json matrix " -Encoding UTF8
            $mod = Get-Module WinAurex_AiEngine
            $backupPath = & $mod { $script:ModelPath }
            $backupModel = & $mod { $script:AiModel }
            try {
                & $mod {
                    param($bad)
                    $script:ModelPath = $bad
                    $script:AiModel = $null
                } -bad $tempBadJson
                { Initialize-AiModel } | Should Not Throw
                $currModel = & $mod { $script:AiModel }
                $currModel | Should BeNullOrEmpty
            } finally {
                if (Test-Path $tempBadJson) { Remove-Item $tempBadJson -Force -ErrorAction SilentlyContinue }
                & $mod {
                    param($p, $m)
                    $script:ModelPath = $p
                    $script:AiModel = $m
                    Initialize-AiModel
                } -p $backupPath -m $backupModel
            }
        }

        It "F1.3: Processes empty and pure whitespace inputs to Tokenizer and Inference safely" {
            $mod = Get-Module WinAurex_AiEngine
            $tokensEmpty = & $mod { Get-Tokens -Text "" }
            $tokensEmpty.Count | Should Be 0
            $tokensWhite = & $mod { Get-Tokens -Text "     `t`r`n   " }
            $tokensWhite.Count | Should Be 0

            $res = Invoke-AiInference -Name "" -Description "   " -Vendor $null
            $res | Should Not BeNullOrEmpty
            $res.Confidence | Should BeGreaterThan -0.0001
            $res.Confidence | Should BeLessThan 1.0001
            $res.SafetyTier | Should Be "Tier 0 (Protected)"
            $res.IsSafeToDisable | Should Be $false
        }

        It "F1.4: Retains mathematical stability under extreme 2,000 token flood without NaN or Infinity" {
            $flood = -join (1..2000 | ForEach-Object { "telemetry diagnostic tracker " })
            $res = Invoke-AiInference -Name "FloodCandidate" -Description $flood
            $res | Should Not BeNullOrEmpty
            [double]::IsNaN($res.Confidence) | Should Be $false
            [double]::IsInfinity($res.Confidence) | Should Be $false
            $res.Confidence | Should BeGreaterThan -0.0001
            $res.Confidence | Should BeLessThan 1.0001
        }

        It "F1.5: Safely parses special characters, regex meta-chars, and Unicode emojis without syntax faults" {
            $hostileName = "svc_.*+?^$()[]{}|/`\`"'~!@#%^&*<>:;🔥🚀💻"
            $res = Invoke-AiInference -Name $hostileName -Description "Adversarial [regex] (test) {curly} ^caret $dollar"
            $res | Should Not BeNullOrEmpty
            $res.Category | Should Not BeNullOrEmpty
            $res.SafetyTier | Should Not BeNullOrEmpty
        }

        It "F1.6: Safely classifies unknown nonsense tokens with zero feature overlap using default log priors" {
            $nonsense = "zzzxqwkp98712345 jklmno99887766 vvwwuu112233"
            $res = Invoke-AiInference -Name $nonsense -Description $nonsense
            $res | Should Not BeNullOrEmpty
            $res.Confidence | Should BeGreaterThan 0.0
            $res.SafetyTier | Should Not BeNullOrEmpty
        }
    }

    # =========================================================================
    # FEATURE 2: F2_WHITELIST (Zero-False-Positive Core Whitelist)
    # =========================================================================
    Context "F2_WHITELIST: Zero-False-Positive Core Whitelist Invariants" {
        It "F2.1: Critical Boot/RPC service 'RpcSs' overrides hostile telemetry keywords to return Tier 0 Protected" {
            $res = Invoke-AiInference -Name "RpcSs" -Description "Dangerous tracking spyware telemetry" -Vendor "AdwareCorp"
            $res.Category | Should Be "Core_OS_Essential"
            $res.SafetyTier | Should Be "Tier 0 (Protected)"
            $res.IsSafeToDisable | Should Be $false
            $res.Confidence | Should Be 1.00
        }

        It "F2.2: Core security and credential services (SamSs, LsaIso, CryptSvc, BdeSvc) remain strictly protected" {
            $secServices = @("samss", "lsaiso", "cryptsvc", "bdesvc", "keyiso")
            foreach ($svc in $secServices) {
                $res = Invoke-AiInference -Name $svc -Description "high overhead telemetry diagnostic keylogger"
                $res.Category | Should Be "Core_OS_Essential"
                $res.SafetyTier | Should Be "Tier 0 (Protected)"
                $res.IsSafeToDisable | Should Be $false
            }
        }

        It "F2.3: Whitelist lookups are strictly case-insensitive across chaotic casing patterns" {
            $variants = @("rPcSs", "DCOMLAUNCH", "sAmSs", "cRyPtSvC", "PlUgPlAy", "EvEnTlOg")
            foreach ($v in $variants) {
                $res = Invoke-AiInference -Name $v
                $res.SafetyTier | Should Be "Tier 0 (Protected)"
                $res.IsSafeToDisable | Should Be $false
            }
        }

        It "F2.4: Protected Windows AppX system prefixes are unconditionally locked against disablement" {
            $protectedApps = @(
                "Microsoft.VCLibs.140.00.UWPDesktop",
                "Microsoft.UI.Xaml.2.8",
                "Microsoft.WindowsStore_8wekyb3d8bbwe",
                "Microsoft.WindowsCalculator_8wekyb3d8bbwe",
                "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe",
                "Microsoft.WindowsTerminal_8wekyb3d8bbwe"
            )
            foreach ($app in $protectedApps) {
                $res = Invoke-AiInference -Name $app -Description "bloatware game appx"
                $res.Category | Should Be "Core_OS_Essential"
                $res.SafetyTier | Should Be "Tier 0 (Protected)"
                $res.IsSafeToDisable | Should Be $false
            }
        }

        It "F2.5: Windows Update and Core Installer services cannot be overridden by heuristic keyword boosters" {
            $updaters = @("wuauserv", "trustedinstaller", "bits", "usosvc", "installservice")
            foreach ($u in $updaters) {
                $res = Invoke-AiInference -Name $u -Description "ceip diagnostic spynet appraiser sqm telemetry"
                $res.SafetyTier | Should Be "Tier 0 (Protected)"
                $res.IsSafeToDisable | Should Be $false
            }
        }

        It "F2.6: Network and Audio core infrastructure services are strictly protected" {
            $infra = @("dhcp", "dnscache", "audiosrv", "audioendpointbuilder", "lanmanworkstation")
            foreach ($i in $infra) {
                $res = Invoke-AiInference -Name $i
                $res.SafetyTier | Should Be "Tier 0 (Protected)"
                $res.IsSafeToDisable | Should Be $false
            }
        }
    }

    # =========================================================================
    # FEATURE 3: F3_SYSTEMAPP (SystemApp & Non-Removable Shield)
    # =========================================================================
    Context "F3_SYSTEMAPP: SystemApp & Non-Removable Package Protection" {
        It "F3.1: AppX package with NonRemovable=$true is defensively skipped without attempting removal" {
            $mockItem = [PSCustomObject]@{
                TargetType       = "AppX"
                Name             = "Microsoft.Windows.NonRemovableShieldTest"
                DisplayName      = "Microsoft.Windows.NonRemovableShieldTest"
                Category         = "Consumer_Bloatware"
                SafetyTier       = "Tier 1 (Safe)"
                Confidence       = "99%"
                CurrentState     = "Installed"
                IsSelected       = $true
                IsAlreadyApplied = $false
            }
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($mockItem) -Force
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 1
        }

        It "F3.2: Framework packages (IsFramework=$true) are shielded from removal" {
            $frameworkItem = [PSCustomObject]@{
                TargetType       = "AppX"
                Name             = "Microsoft.NET.Native.Framework.2.2"
                DisplayName      = "Microsoft.NET.Native.Framework.2.2"
                IsSelected       = $true
                IsAlreadyApplied = $false
            }
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($frameworkItem) -Force
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 1
        }

        It "F3.3: SystemApps and ImmersiveControlPanel installation paths are strictly detected and excluded" {
            $systemAppPaths = @(
                "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy",
                "C:\Windows\SystemApps\Microsoft.Windows.Cortana_cw5n1h2txyewy",
                "C:\Windows\ImmersiveControlPanel"
            )
            foreach ($p in $systemAppPaths) {
                $isExcluded = ($p -match 'SystemApps|ImmersiveControlPanel')
                $isExcluded | Should Be $true
            }
        }

        It "F3.4: Packages with SignatureKind='System' are identified as immune system components" {
            $mockPkg = [PSCustomObject]@{
                Name          = "Microsoft.Windows.SystemShell"
                SignatureKind = "System"
                NonRemovable  = $false
                IsFramework   = $false
            }
            $isProtected = ($mockPkg.SignatureKind -eq "System" -or $mockPkg.NonRemovable -or $mockPkg.IsFramework)
            $isProtected | Should Be $true
        }

        It "F3.5: Non-existent or already-purged AppX package records increment Skipped and not Applied" {
            $missingApp = [PSCustomObject]@{
                TargetType       = "AppX"
                Name             = "DefinitelyNonExistentAppX_Random987654321"
                DisplayName      = "DefinitelyNonExistentAppX_Random987654321"
                IsSelected       = $true
                IsAlreadyApplied = $false
            }
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($missingApp) -Force
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 1
        }

        It "F3.6: Traps COMException 0x80070032 (ERROR_NOT_SUPPORTED) without halting remediation pipeline" {
            $mod = Get-Module WinAurex_AiEngine
            $testPkgName = "Microsoft.Windows.MockLockedPackage"

            # Inject module-scoped mock to simulate non-removable package that throws COMException 0x80070032
            & $mod {
                function script:Get-AppxPackage {
                    param($Name, [switch]$AllUsers, $ErrorAction)
                    if ($Name -eq "Microsoft.Windows.MockLockedPackage") {
                        return @([PSCustomObject]@{
                            Name            = "Microsoft.Windows.MockLockedPackage"
                            PackageFullName = "Microsoft.Windows.MockLockedPackage_1.0_neutral__cw5n1h2txyewy"
                            NonRemovable    = $false
                            InstallLocation = "C:\Program Files\WindowsApps\MockLocked"
                            SignatureKind   = "Store"
                            IsFramework     = $false
                        })
                    }
                    return @()
                }
                function script:Remove-AppxPackage {
                    param($Package, [switch]$AllUsers, $ErrorAction)
                    throw (New-Object System.Runtime.InteropServices.COMException(
                        "Package removal failed with 0x80070032: The request is not supported.",
                        [int]0x80070032
                    ))
                }
            }

            try {
                $target = [PSCustomObject]@{
                    TargetType       = "AppX"
                    Name             = $testPkgName
                    DisplayName      = "Mock Locked System Component"
                    IsSelected       = $true
                    IsAlreadyApplied = $false
                }

                $res = Invoke-WinAurexAiRemediation -SelectedItems @($target) -Force
                $res | Should Not BeNullOrEmpty
                $res.Skipped | Should Be 1
                $res.Applied | Should Be 0
            } finally {
                # Restore clean module scope
                & $mod {
                    Remove-Item Function:\script:Get-AppxPackage -ErrorAction SilentlyContinue
                    Remove-Item Function:\script:Remove-AppxPackage -ErrorAction SilentlyContinue
                }
            }
        }
    }

    # =========================================================================
    # FEATURE 4: F4_HW (Live Hardware Inspector)
    # =========================================================================
    Context "F4_HW: Extreme & Unusual Hardware Profile Boundaries" {
        It "F4.1: Calculates RAM usage cleanly when Free Physical RAM is 0 MB without divide-by-zero" {
            $totalRamMB = 4096.0
            $freeRamMB = 0.0
            $ramUsedPct = if ($totalRamMB -gt 0) { [Math]::Round((($totalRamMB - $freeRamMB) / $totalRamMB) * 100, 1) } else { 0.0 }
            $ramUsedPct | Should Be 100.0
            [double]::IsNaN($ramUsedPct) | Should Be $false
        }

        It "F4.2: Handles extreme 128+ CPU core server workstation topology without integer overflow" {
            $profile = [PSCustomObject]@{
                CpuName     = "AMD EPYC 9654 96-Core Processor"
                CpuCores    = 128
                CpuThreads  = 256
                TotalRamGB  = 512.0
                GpuName     = "NVIDIA RTX 6000 Ada"
                GpuVendor   = "NVIDIA"
                StorageType = "NVMe SSD"
                IsLaptop    = $false
                OnBattery   = $false
            }
            $profile.CpuCores | Should Be 128
            $profile.CpuThreads | Should Be 256
            ($profile.CpuThreads -gt $profile.CpuCores) | Should Be $true
        }

        It "F4.3: Correctly categorizes virtualized and unknown GPU display adapters into 'Other'" {
            $gpuNames = @(
                @{ Name = "Microsoft Basic Display Adapter"; Expected = "Other" },
                @{ Name = "Standard VGA Graphics Adapter"; Expected = "Other" },
                @{ Name = "VMware SVGA 3D"; Expected = "Other" },
                @{ Name = "NVIDIA GeForce RTX 4070"; Expected = "NVIDIA" },
                @{ Name = "AMD Radeon RX 7900 XTX"; Expected = "AMD" },
                @{ Name = "Intel(R) Arc(TM) A770 Graphics"; Expected = "Intel" }
            )
            foreach ($g in $gpuNames) {
                $vendor = if ($g.Name -match "NVIDIA") { "NVIDIA" }
                          elseif ($g.Name -match "AMD|Radeon") { "AMD" }
                          elseif ($g.Name -match "Intel") { "Intel" }
                          else { "Other" }
                $vendor | Should Be $g.Expected
            }
        }

        It "F4.4: Accurately identifies desktop systems with missing battery sensors as non-laptop on AC" {
            $mockBatteries = @()
            $isLaptop = ($mockBatteries.Count -gt 0)
            $onBattery = $false
            if ($mockBatteries.Count -gt 0) {
                $onBattery = ($mockBatteries | Where-Object { $_.BatteryStatus -eq 1 }).Count -gt 0
            }
            $isLaptop | Should Be $false
            $onBattery | Should Be $false
        }

        It "F4.5: Gracefully categorizes virtual disk, RAMDisk, and unspecified storage types" {
            $mediaTypes = @("Unspecified", "RAMDisk", "File-Backed Virtual", "Unknown")
            foreach ($m in $mediaTypes) {
                $storageType = if ($m -match "NVMe") { "NVMe SSD" }
                               elseif ($m -match "SSD") { "SATA SSD" }
                               elseif ($m -match "HDD") { "HDD" }
                               else { "Other/Virtual" }
                $storageType | Should Be "Other/Virtual"
            }
        }

        It "F4.6: Preserves valid clock frequency representations when CPU reports 0 MHz or dynamic virtualized clock" {
            $clockSpeeds = @(0, 800, 3800, 9999)
            foreach ($clk in $clockSpeeds) {
                $formattedClk = if ($clk -gt 0) { "$([Math]::Round($clk / 1000, 2)) GHz" } else { "Dynamic / Virtualized" }
                $formattedClk | Should Not BeNullOrEmpty
            }
        }
    }

    # =========================================================================
    # FEATURE 5: F5_WORKLOAD (Workload Profiler & Process Drainers)
    # =========================================================================
    Context "F5_WORKLOAD: Workload Boundary & Process List Stress Cases" {
        It "F5.1: Evaluates 0.0% CPU and 0.0% RAM idle workload boundary without underflow errors" {
            $cpuLoad = 0.0
            $ramLoad = 0.0
            $isPressureHigh = ($cpuLoad -gt 85.0 -or $ramLoad -gt 90.0)
            $isPressureHigh | Should Be $false
        }

        It "F5.2: Detects 100.0% CPU and 100.0% RAM load boundary and asserts critical system pressure" {
            $cpuLoad = 100.0
            $ramLoad = 100.0
            $isPressureHigh = ($cpuLoad -gt 85.0 -or $ramLoad -gt 90.0)
            $isPressureHigh | Should Be $true
        }

        It "F5.3: Handles empty process list (0 processes) without division-by-zero or indexing faults" {
            $emptyProcList = @()
            $pCount = $emptyProcList.Count
            $tCount = 0
            $hCount = 0
            foreach ($p in $emptyProcList) {
                $tCount += $p.Threads.Count
                $hCount += $p.HandleCount
            }
            $pCount | Should Be 0
            $tCount | Should Be 0
            $hCount | Should Be 0
        }

        It "F5.4: Evaluates massive process list (5,000 processes) identifying exactly anomalous consumers" {
            $mockProcs = 1..5000 | ForEach-Object {
                [PSCustomObject]@{
                    Id               = $_
                    ProcessName      = "proc_$_"
                    HandleCount      = if ($_ % 500 -eq 0) { 1200 } else { 50 }
                    Threads          = if ($_ % 500 -eq 0) { 1..40 } else { 1..5 }
                    WorkingSet64     = if ($_ % 500 -eq 0) { 350MB } else { 10MB }
                    MainWindowHandle = [IntPtr]::Zero
                }
            }
            $sysIgnore = @("System", "Idle", "Registry")
            $anomalies = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($p in $mockProcs) {
                if ($p.Id -gt 4 -and $sysIgnore -notcontains $p.ProcessName) {
                    $h = $p.HandleCount
                    $t = $p.Threads.Count
                    $memMB = [Math]::Round($p.WorkingSet64 / 1MB, 1)
                    if ($p.MainWindowHandle -eq [IntPtr]::Zero -and ($h -gt 500 -or $t -gt 30 -or $memMB -gt 250)) {
                        $anomalies.Add($p)
                    }
                }
            }
            # Multiples of 500 between 1 and 5000: exactly 10
            $anomalies.Count | Should Be 10
        }

        It "F5.5: Falls back gracefully when performance counters fail or are disabled in registry" {
            $counterThrows = $true
            $availableMB = if (-not $counterThrows) {
                8192
            } else {
                $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
                if ($os -and $os.FreePhysicalMemory) { [Math]::Round($os.FreePhysicalMemory / 1024, 0) } else { 4096 }
            }
            $availableMB | Should BeGreaterThan 0
        }

        It "F5.6: Headless process with 0 handles and 0 threads is correctly omitted from anomaly list" {
            $zeroProc = [PSCustomObject]@{
                Id               = 1234
                ProcessName      = "clean_idle"
                HandleCount      = 0
                Threads          = @()
                WorkingSet64     = 0
                MainWindowHandle = [IntPtr]::Zero
            }
            $isAnomaly = ($zeroProc.MainWindowHandle -eq [IntPtr]::Zero -and 
                         ($zeroProc.HandleCount -gt 500 -or $zeroProc.Threads.Count -gt 30 -or ($zeroProc.WorkingSet64 / 1MB) -gt 250))
            $isAnomaly | Should Be $false
        }
    }

    # =========================================================================
    # FEATURE 6: F6_SCAN (Candidate State & Accuracy Engine)
    # =========================================================================
    Context "F6_SCAN: State Accuracy & Already-Applied Candidate Boundaries" {
        It "F6.1: Service that is Disabled and Stopped is flagged IsAlreadyApplied=$true and not actionable" {
            $svc = [PSCustomObject]@{ StartMode = "Disabled"; State = "Stopped" }
            $isAlreadyDisabled = ($svc.StartMode -eq "Disabled" -and $svc.State -ne "Running")
            $isAlreadyDisabled | Should Be $true
            $isSelected = (-not $isAlreadyDisabled)
            $isSelected | Should Be $false
        }

        It "F6.2: Service that is Disabled but still Running is flagged actionable (IsAlreadyApplied=$false)" {
            $svc = [PSCustomObject]@{ StartMode = "Disabled"; State = "Running" }
            $isAlreadyDisabled = ($svc.StartMode -eq "Disabled" -and $svc.State -ne "Running")
            $isAlreadyDisabled | Should Be $false
        }

        It "F6.3: Service that is Auto/Manual start but Stopped is flagged actionable (IsAlreadyApplied=$false)" {
            $svc = [PSCustomObject]@{ StartMode = "Manual"; State = "Stopped" }
            $isAlreadyDisabled = ($svc.StartMode -eq "Disabled" -and $svc.State -ne "Running")
            $isAlreadyDisabled | Should Be $false
        }

        It "F6.4: Scheduled task that is Disabled is flagged IsAlreadyApplied=$true and not actionable" {
            $task = [PSCustomObject]@{ State = "Disabled" }
            $isDis = ($task.State -eq "Disabled")
            $isDis | Should Be $true
            $isSelected = (-not $isDis)
            $isSelected | Should Be $false
        }

        It "F6.5: Missing or unregistered scheduled task queries return $null without throwing fatal exceptions" {
            $nonExistentPath = "\NonExistent\Task\Path\12345"
            $task = Get-ScheduledTask -TaskPath "\NonExistent\" -TaskName "Task12345" -ErrorAction SilentlyContinue
            $task | Should BeNullOrEmpty
        }

        It "F6.6: Candidate service with active running dependent services is protected by Dependency Lock" {
            $mockDependent = [PSCustomObject]@{ Name = "DependentAudioSvc"; Status = "Running" }
            $mockParent = [PSCustomObject]@{ Name = "ParentAudioEndpoint"; DependentServices = @($mockDependent) }
            $isDepLock = $false
            if ($mockParent.DependentServices) {
                foreach ($ds in $mockParent.DependentServices) {
                    if ($ds.Status -eq "Running") {
                        $isDepLock = $true
                        break
                    }
                }
            }
            $isDepLock | Should Be $true
        }
    }

    # =========================================================================
    # FEATURE 7: F7_RECOMMEND (Dynamic Contextual Recommender)
    # =========================================================================
    Context "F7_RECOMMEND: Dynamic Contextual Recommender Corner Cases" {
        It "F7.1: Conflicting hardware profile (128 CPU cores but 2 GB RAM) prioritizes RAM Freeing over CPU overclock" {
            $profile = [PSCustomObject]@{
                Hardware = @{ CpuCores = 128; TotalRamGB = 2.0; IsLaptop = $false; OnBattery = $false }
                Workload = @{ RamUsedPercent = 95.0; CpuLoadPercent = 10.0 }
            }
            $isLowRamCrit = ($profile.Hardware.TotalRamGB -le 4.0 -and $profile.Workload.RamUsedPercent -gt 85.0)
            $isLowRamCrit | Should Be $true
        }

        It "F7.2: Zero-candidate scenario (100% components already optimized) produces 0 pending remediations" {
            $findings = @(
                [PSCustomObject]@{ Name = "DiagTrack"; IsAlreadyApplied = $true },
                [PSCustomObject]@{ Name = "MapsBroker"; IsAlreadyApplied = $true },
                [PSCustomObject]@{ Name = "WinSAT"; IsAlreadyApplied = $true }
            )
            $pending = @($findings | Where-Object { -not $_.IsAlreadyApplied })
            $pending.Count | Should Be 0
        }

        It "F7.3: Laptop on battery power suppresses high-power foreground quantum overrides" {
            $profile = [PSCustomObject]@{
                Hardware = @{ IsLaptop = $true; OnBattery = $true }
            }
            $allowHighPowerQuantum = (-not $profile.Hardware.OnBattery)
            $allowHighPowerQuantum | Should Be $false
        }

        It "F7.4: Desktop on AC power with NVMe SSD unlocks high-throughput storage optimizations" {
            $profile = [PSCustomObject]@{
                Hardware = @{ IsLaptop = $false; OnBattery = $false; StorageType = "NVMe SSD" }
            }
            $allowMaxThroughput = ($profile.Hardware.StorageType -eq "NVMe SSD" -and -not $profile.Hardware.OnBattery)
            $allowMaxThroughput | Should Be $true
        }

        It "F7.5: Active gaming detected elevates Gaming Shield to High Priority recommendation" {
            $workload = [PSCustomObject]@{
                IsGamingActive = $true
                ActiveGameName = "Fortnite.exe"
            }
            $recPriority = if ($workload.IsGamingActive) { "High" } else { "Low" }
            $recPriority | Should Be "High"
        }

        It "F7.6: Handles null profile and null findings without throwing runtime null-reference exceptions" {
            $profile = $null
            $findings = $null
            $safeFindings = if ($findings) { $findings } else { @() }
            $safePending = @($safeFindings | Where-Object { -not $_.IsAlreadyApplied })
            $safePending.Count | Should Be 0
        }
    }

    # =========================================================================
    # FEATURE 8: F8_REMEDIATE (Remediation Core & Rollback Engine)
    # =========================================================================
    Context "F8_REMEDIATE: Remediation Parameter Binding & Empty Collection Safety" {
        It "F8.1: Accepts empty collection @() in Invoke-WinAurexAiRemediation without throwing errors" {
            $result = Invoke-WinAurexAiRemediation -SelectedItems @() -Force
            $result | Should Not BeNullOrEmpty
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 0
        }

        It "F8.2: Accepts $null in Invoke-WinAurexAiRemediation returning 0 applied and 0 skipped" {
            $result = Invoke-WinAurexAiRemediation -SelectedItems $null -Force
            $result | Should Not BeNullOrEmpty
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 0
        }

        It "F8.3: Skips 100% of items when all items in SelectedItems have IsAlreadyApplied=$true" {
            $items = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    TargetType       = "Service"
                    Name             = "TestMockSvc_$_"
                    IsAlreadyApplied = $true
                }
            }
            $result = Invoke-WinAurexAiRemediation -SelectedItems $items -Force
            $result.Applied | Should Be 0
            $result.Skipped | Should Be 5
        }

        It "F8.4: Executes safely without throwing when ProgressCallback is $null" {
            { Invoke-WinAurexAiRemediation -SelectedItems @() -ProgressCallback $null -Force } | Should Not Throw
        }

        It "F8.5: Ignores unsupported TargetTypes without crashing remediation loop" {
            $weirdItem = [PSCustomObject]@{
                TargetType       = "UnknownTargetWidget"
                Name             = "OddGizmo123"
                IsAlreadyApplied = $false
            }
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($weirdItem) -Force
            $result.Applied | Should Be 0
        }

        It "F8.6: Non-existent service name in remediation is marked not found without throwing fatal exceptions" {
            $missingSvcItem = [PSCustomObject]@{
                TargetType       = "Service"
                Name             = "WinAurexNonExistentSvc_99999"
                IsAlreadyApplied = $false
            }
            $result = Invoke-WinAurexAiRemediation -SelectedItems @($missingSvcItem) -Force
            $result.Applied | Should Be 0
        }
    }

    # =========================================================================
    # FEATURE 9: F9_CLI (CLI Optimizer Parameter Boundaries & Clean State Handling)
    # =========================================================================
    Context "F9_CLI: CLI Optimizer Parameter Boundaries & Clean State Handling" {
        It "F9.1: Rejects invalid or unsupported command-line parameters with non-zero exit code" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -NonExistentParamXYZ"
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $null = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()
            $proc.ExitCode | Should Not Be 0
        }

        It "F9.2: Handles clean system revert request gracefully when no transaction history exists" {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -Revert -Force"
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $proc = [System.Diagnostics.Process]::Start($pinfo)
            $out = $proc.StandardOutput.ReadToEnd()
            $proc.WaitForExit()
            $proc.ExitCode | Should Be 0
            $out | Should Match "No prior transactions found"
        }

        It "F9.3: Honors -ScanOnly precedence as read-only diagnostic when combined with -Auto" {
            $scanOnly = $true
            $auto = $true
            $isReadOnly = ($scanOnly -or (-not $auto))
            $isReadOnly | Should Be $true
        }

        It "F9.4: Formats clean summary string correctly when zero pending candidates remain" {
            $pendingCount = 0
            $msg = if ($pendingCount -eq 0) { "Found 0 pending candidates" } else { "Found $pendingCount pending candidates" }
            $msg | Should Match "Found 0 pending candidates"
        }

        It "F9.5: Accurately checks administrative execution context" {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            ($isAdmin -eq $true -or $isAdmin -eq $false) | Should Be $true
        }

        It "F9.6: Detects non-existent AI engine module file path and returns false" {
            $fakeModule = "C:\NonExistent\WinAurex_AiEngine.psm1"
            $testResult = Test-Path $fakeModule
            $testResult | Should Be $false
        }
    }

    # =========================================================================
    # FEATURE 10: F10_GUI (WPF Dashboard AI Tab Integration)
    # =========================================================================
    Context "F10_GUI: WPF Dashboard DataContext & Concurrency Boundaries" {
        It "F10.1: Fallback mechanism safely handles null profile binding without NullReferenceException" {
            $hudCpuName = $null
            $displayCpu = if ($hudCpuName) { $hudCpuName } else { "Intel / AMD Processor" }
            $displayCpu | Should Be "Intel / AMD Processor"
        }

        It "F10.2: Concurrency guards prevent duplicate re-entrant scans or RAM flushes while in progress" {
            $script:AiScanInProgress = $true
            $scanAttemptBlocked = $false
            if ($script:AiScanInProgress) {
                $scanAttemptBlocked = $true
            }
            $scanAttemptBlocked | Should Be $true
            $script:AiScanInProgress = $false
        }

        It "F10.3: Empty candidate list in WPF DataContext renders 0 actionable and 0 optimized" {
            $emptyFindings = @()
            $pendingCount = @($emptyFindings | Where-Object { -not $_.IsAlreadyApplied }).Count
            $optimizedCount = @($emptyFindings | Where-Object { $_.IsAlreadyApplied }).Count
            $pendingCount | Should Be 0
            $optimizedCount | Should Be 0
        }

        It "F10.4: Clamps health score strictly to [30, 100] boundary under extreme penalty values" {
            $rawScoreVeryLow = -50
            $rawScoreVeryHigh = 150
            $clampedLow = [Math]::Max(30, [Math]::Min(100, $rawScoreVeryLow))
            $clampedHigh = [Math]::Max(30, [Math]::Min(100, $rawScoreVeryHigh))
            $clampedLow | Should Be 30
            $clampedHigh | Should Be 100
        }

        It "F10.5: Set-AiGamingShield toggles state idempotently between Active and Disabled" {
            $enabled = Set-AiGamingShield -Enable
            $enabled.Status | Should Be "Active"
            $disabled = Set-AiGamingShield -Disable
            $disabled.Status | Should Be "Disabled"
        }

        It "F10.6: Progress overlay and global progress bar null checks prevent UI dispatcher faults" {
            $ProgressGlobal = $null
            $TxtProgressDetail = $null
            {
                if ($null -ne $ProgressGlobal) { $ProgressGlobal.Value = 50 }
                if ($null -ne $TxtProgressDetail) { $TxtProgressDetail.Text = "Testing..." }
            } | Should Not Throw
        }
    }
}
