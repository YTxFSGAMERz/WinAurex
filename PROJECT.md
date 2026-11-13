# Project: WinAurex Production-Grade Machine-Understanding AI Engine

## Architecture
The WinAurex AI Engine is a pure PowerShell, zero-external-dependency, offline machine-understanding optimization subsystem. It operates across three core layers:
1. **Offline Knowledge & Model Matrix Layer (`Core/AI/Data/` & `Core/AI/WinAurex_AiEngine.psm1`)**:
   - Classification weights and feature matrices for Windows 10/11 services, scheduled tasks, AppX packages, and system tweaks.
   - Absolute Zero False-Positive Critical Core Services whitelist (boot, RPC, DCOM, LSASS, CryptSvc, Windows Update, network, audio, security).
   - SystemApp & Non-Removable protection rules.
2. **Live Machine Inspection & Workload Profiling Layer (`Core/AI/WinAurex_AiEngine.psm1`)**:
   - Hardware detection: CPU (cores/clock), RAM (capacity/usage), GPU (model/vendor), Storage (NVMe SSD / SATA SSD / HDD), Form Factor / Power (Desktop AC vs Laptop Battery).
   - Active workload profiling: CPU/RAM pressure, top resource-draining processes, active gaming or rendering process detection.
   - System inspection: Service states, scheduled task states, startup items.
3. **Dynamic Recommendation & Integration Layer (`WinAurex_AiEngine.psm1`, `AI_Dynamic_System_Optimizer.ps1`, `Dashboard.xaml`, `Launch_Dashboard.ps1`)**:
   - Contextual tweak recommendations based on hardware profile + active load.
   - Safe remediation with accurate state detection (`IsAlreadyApplied` verified by startup mode and running state), empty-collection safety, and rollback support.
   - Seamless CLI interface with deterministic exit codes and formatted output.
   - WPF GUI Dashboard AI Tab integration with live hardware overview, candidate lists, and 1-click optimization.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Offline Knowledge Base & Feature Matrix | Offline dataset and classification matrices for Windows services, tasks, telemetry, and debloat tweaks | M1 | R1, survey |
| 2 | Zero-False-Positive Core Service Whitelist | Guaranteed immunity for boot, LSASS, RPC, network, audio, Windows Update, and security core services | M1 | R1, R2, survey |
| 3 | SystemApp & Non-Removable Package Shield | Strict filtering of non-removable Windows SystemApps to prevent COMException 0x80070032 | M1 | R2, survey |
| 4 | Live Hardware Inspector | Native CIM/WMI hardware detection (CPU, RAM, GPU, storage type, power source) | M2 | R2, survey |
| 5 | Active Workload & Process Drainer Profiler | Real-time CPU/RAM pressure monitoring, memory hogs, CPU spikes, and gaming process detection | M2 | R2, survey |
| 6 | Candidate State Accuracy & Scan Engine | Accurate candidate scanning ensuring `IsAlreadyApplied` reflects both StartMode and Running state | M3 | R2, survey |
| 7 | Dynamic Contextual Tweak Recommender | Prioritized recommendations (safe tweaks, gaming boosts, bloat removal) tailored to hardware & workload | M3 | R3, survey |
| 8 | Remediation Core & Rollback Engine | Safe execution with empty-collection tolerance, progress callbacks, and reversal tracking | M3 | R3, survey |
| 9 | CLI Optimizer Overhaul | `AI_Dynamic_System_Optimizer.ps1` with accurate summaries, clean zero-candidate handling, `-Revert`, and exit codes | M4 | R4, survey |
| 10 | WPF Dashboard AI Tab Integration | Rich GUI integration in `Launch_Dashboard.ps1` and `GUI/Dashboard.xaml` with hardware stats and 1-click optimization | M4 | R4, survey |
| 11 | Comprehensive E2E Verification & Hardening | 100% passing automated Pester test suite across Tiers 1-4, followed by Tier 5 adversarial stress testing | M5 | Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Offline AI Knowledge Base, Model Weights & Classification Matrices | Core dataset, zero-FP whitelist, SystemApp protection, offline feature matrix & evaluation in `WinAurex_AiEngine.psm1` | none | DONE |
| M2 | Live Host Machine Inspector & Workload Profiler | Hardware detection, workload profiling, process drainer identification in `WinAurex_AiEngine.psm1` | M1 | IN_PROGRESS |
| M3 | Dynamic Recommendation Engine & Remediation Core | Contextual recommendations, accurate state detection, safe remediation, empty-collection handling | M2 | PLANNED |
| M4 | WinAurex CLI & WPF Dashboard Integration | `AI_Dynamic_System_Optimizer.ps1` overhaul, `Launch_Dashboard.ps1` / `Dashboard.xaml` AI tab integration | M3 | PLANNED |
| M5 | E2E Verification & Adversarial Coverage Hardening | Phase 1: 100% E2E test suite pass (Tiers 1-4); Phase 2: Tier 5 adversarial coverage hardening | M4, TEST_READY.md | PLANNED |

## Interface Contracts

### M1 ↔ M2 / M3: Model Inference & Classification
```powershell
# Function: Invoke-AiInference
# Inputs:
#   [string]$Name
#   [string]$Description
#   [string]$Vendor
#   [string]$TargetType ("Service", "AppX", "ScheduledTask", "SystemTweak")
# Returns:
#   [PSCustomObject]@{
#       Name            = [string]
#       Category        = [string] ("Core_OS_Required", "Telemetry", "Consumer_Bloatware", "OEM_Bloatware", "High_Overhead_Task", "Gaming_Bottleneck", "Safe_Optimization")
#       SafetyTier      = [string] ("Tier 0 (Protected)", "Tier 1 (Safe)", "Tier 2 (Recommended)", "Tier 3 (Advanced)")
#       Confidence      = [double] (0.00 - 1.00)
#       IsSafeToDisable = [bool]
#       EstImpact       = [string]
#       TweakAction     = [string]
#   }
```

### M2 ↔ M3 / M4: System Profiler
```powershell
# Function: Get-WinAurexSystemProfile
# Returns:
#   [PSCustomObject]@{
#       Hardware = @{
#           CpuName      = [string]
#           CpuCores     = [int]
#           CpuThreads   = [int]
#           TotalRamGB   = [double]
#           GpuName      = [string]
#           GpuVendor    = [string] ("NVIDIA", "AMD", "Intel", "Other")
#           StorageType  = [string] ("NVMe SSD", "SATA SSD", "HDD")
#           IsLaptop     = [bool]
#           OnBattery    = [bool]
#       }
#       Workload = @{
#           CpuLoadPercent = [double]
#           RamUsedPercent = [double]
#           IsGamingActive = [bool]
#           ActiveGameName = [string]
#           TopDrainers    = [array]
#       }
#       Timestamp = [datetime]
#   }
```

### M3 ↔ M4: Recommendations & Remediation
```powershell
# Function: Get-WinAurexAiRecommendations
# Inputs:
#   [PSCustomObject]$Profile (optional, gathered if null)
#   [array]$Findings (optional, scanned if null)
# Returns:
#   [array] of [PSCustomObject]@{
#       Id          = [string]
#       Title       = [string]
#       Description = [string]
#       Category    = [string]
#       Priority    = [string] ("High", "Medium", "Low")
#       SafetyTier  = [string]
#       EstimatedBenefit = [string]
#       TargetItems = [array]
#   }

# Function: Invoke-WinAurexAiRemediation
# Inputs:
#   [AllowEmptyCollection()][array]$SelectedItems = @()
#   [scriptblock]$ProgressCallback = $null
#   [switch]$Force
# Returns:
#   [hashtable]@{
#       Applied = [int]
#       Skipped = [int]
#       Failed  = [int]
#       Details = [array]
#   }
```

## Code Layout
- `Core/AI/WinAurex_AiEngine.psm1` — AI Engine Module (Knowledge base, matrices, profiling, inference, scanning, remediation)
- `Core/AI/Data/` — Offline model matrices, service catalogs, tweak datasets (embedded / JSON format)
- `Tweaks/Services/AI_Dynamic_System_Optimizer.ps1` — WinAurex CLI AI Optimizer
- `GUI/Dashboard.xaml` — WPF GUI Dashboard layout
- `Launch_Dashboard.ps1` — GUI logic & event bindings
- `Tests/AI/` — Automated Pester test suites (Unit, Integration, E2E Tiers 1-4, Adversarial Tier 5)
