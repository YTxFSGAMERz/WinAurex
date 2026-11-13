# E2E Test Infra: WinAurex AI Engine

## Test Philosophy
- **Opaque-Box & Requirement-Driven**: Tests derive directly from `ORIGINAL_REQUEST.md` and user-facing requirements (`PROJECT.md`), exercising modules via public PowerShell interfaces (`Core/AI/WinAurex_AiEngine.psm1`, `Tweaks/Services/AI_Dynamic_System_Optimizer.ps1`, `Launch_Dashboard.ps1`), not internal private state.
- **Systematic 4-Tier Methodology**:
  - **Tier 1 (Feature Coverage)**: Validates each feature in isolation with >=5 representative test cases covering expected happy-path inputs and contract conformance.
  - **Tier 2 (Boundary & Corner Cases)**: Validates limits, zero-false-positive safety invariants, empty collections, non-removable packages, already-applied idempotency, and extreme resource values.
  - **Tier 3 (Cross-Feature Combinations)**: Validates pairwise feature interactions (hardware profile + workload load + recommendation prioritization; scan -> remediation -> rescan idempotency).
  - **Tier 4 (Real-World Application Scenarios)**: Validates realistic operational personas (e.g. gaming laptop on battery, high-end creator workstation, low-spec HDD machine, clean OEM bloatware scan, full rollback verification).

---

## Feature Inventory & Architectural Contracts
Enriched with empirical system inspection specifications from Survey Explorer 3:

| # | Feature Code | Feature Name | Requirement Source | Key Data Contracts & Test Invariants | Tier 1 (≥5) | Tier 2 (≥5) | Tier 3 (Pairwise) | Tier 4 (Scenarios) |
|---|:------------:|--------------|--------------------|--------------------------------------|:-----------:|:-----------:|:-----------------:|:------------------:|
| 1 | `F1_KB` | Offline Knowledge Base & Feature Matrix | R1, PROJECT §1 | Offline JSON model matrices, classification across 6 categories (`Core_OS_Essential`, `Telemetry_Tracking`, `OEM_Bloatware`, `ThirdParty_Updater`, `Consumer_Bloatware`, `High_Overhead_Task`), confidence score $\in [0, 1]$, offline execution time < 500ms. | 5 | 5 | ✓ | ✓ |
| 2 | `F2_WHITELIST` | Zero-False-Positive Core Whitelist | R1, R2, PROJECT §2 | Absolute protection for core boot, LSASS, RPC (`RpcSs`, `DcomLaunch`), Crypto (`CryptSvc`), Windows Update (`wuauserv`, `trustedinstaller`), Audio (`audiosrv`), and Security (`WinDefend`). Zero false positives guaranteed. In-memory dependent service check. | 5 | 5 | ✓ | ✓ |
| 3 | `F3_SYSTEMAPP` | SystemApp & Non-Removable Shield | R2, PROJECT §3 | Prevention of COMException `0x80070032` and `0x80073CFA` by filtering `NonRemovable=$true`, `SignatureKind=System`, and core AppX frameworks (`VCLibs`, `UI.Xaml`, `DesktopAppInstaller`). | 5 | 5 | ✓ | ✓ |
| 4 | `F4_HW` | Live Hardware Inspector | R2, PROJECT §4 | CPU (sockets, physical cores, threads, clock, tier), RAM (GB capacity, SMBIOS DDR3/4/5 generation, SODIMM vs DIMM, capacity tier: LowRAM $\le 8$GB, MidRAM 16GB, HighRAM $\ge 32$GB), GPU (64-bit VRAM resolution via registry `qwMemorySize` to avoid 4GB truncation, Discrete vs Integrated dual-GPU), Storage (MediaType: SSD vs HDD, BusType: NVMe vs SATA), Chassis/Power (`[System.Windows.Forms.SystemInformation]::PowerStatus` AC vs Battery, Mobile vs Desktop). | 5 | 5 | ✓ | ✓ |
| 5 | `F5_WORKLOAD` | Workload Profiler & Process Drainers | R2, PROJECT §5 | Real-time CPU pressure %, RAM pressure %, Commit pressure %, game detection (signatures: `cs2`, `valorant`, `dota2`, etc., and 3D runtimes), rendering detection, and headless process drain scoring ($w = [0.35, 0.25, 0.15, 0.15, 0.10]$ for CPU, RAM, threads, handles, headless). | 5 | 5 | ✓ | ✓ |
| 6 | `F6_SCAN` | Candidate State & Accuracy Engine | R2, PROJECT §6 | Startup items from `Win32_StartupCommand` + `StartupApproved\Run` registry flags (`0x02` enabled, `0x03` disabled). `IsAlreadyApplied` verified by checking both StartMode (Disabled) and State (Stopped). Zero ghost candidates. | 5 | 5 | ✓ | ✓ |
| 7 | `F7_RECOMMEND` | Dynamic Contextual Recommender | R3, PROJECT §7 | Workload & Hardware-conditioned recommendations: LowRAM/HDD -> aggressive RAM flush & `SysMain`/Search disablement; NVMe SSD -> preserve `SysMain`; Laptop on Battery -> throttle background updaters & suppress telemetry polling without aggressive power-state tampering; Active Gaming -> `Win32PrioritySeparation = 0x28` & disable GameDVR/network throttling. | 5 | 5 | ✓ | ✓ |
| 8 | `F8_REMEDIATE` | Remediation Core & Rollback Engine | R3, PROJECT §8 | Safe batch execution with empty-collection tolerance (`[AllowEmptyCollection()]`), progress callback support, snapshot transaction creation (`New-Transaction`, `Export-ServiceSnapshot`, `Export-TaskSnapshot`, `Export-RegistrySnapshot`), and full reversal tracking via `-Revert`. | 5 | 5 | ✓ | ✓ |
| 9 | `F9_CLI` | CLI Optimizer Overhaul | R4, PROJECT §9 | `AI_Dynamic_System_Optimizer.ps1` supporting `-ScanOnly`, `-Auto`, `-Revert`, `-Force`, `-JsonOutput`, structured exit codes (0 = success, 1 = failure), ASCII progress tables, and log output. | 5 | 5 | ✓ | ✓ |
| 10 | `F10_GUI` | WPF Dashboard AI Tab Integration | R4, PROJECT §10 | UI controls (`TxtAiHealthScore`, `TxtAiScanStatus`, `ListAiFindings`), background PowerShell Runspace execution, synchronized hashtable for progress, non-blocking UI dispatcher, and DataGrid property binding (`StatusDisplay`, `TargetType`, `Name`, `Category`, `Confidence`, `TierDisplay`, `Action`). | 5 | 5 | ✓ | ✓ |

---

## Test Architecture & Organization

### Directory Layout
```
Tests/AI/
├── TestHarness.psm1               # Shared mock fixtures, system profile builders, and assertions
├── RunAllTests.ps1                # Unified standalone & Pester test runner (Exit code 0 on 100% pass)
├── Tier1_FeatureCoverage.Tests.ps1 # Tier 1: 50+ isolated feature tests (F1-F10)
├── Tier2_BoundaryCases.Tests.ps1   # Tier 2: 50+ boundary, corner, and zero-FP tests (F1-F10)
├── Tier3_Interactions.Tests.ps1    # Tier 3: 12+ pairwise interaction tests
└── Tier4_RealWorldScenarios.Tests.ps1 # Tier 4: 6+ realistic end-to-end persona scenarios
```

### Test Invocation & Runner Semantics
- **Command**:
  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tests/AI/RunAllTests.ps1
  ```
- **Exit Codes**:
  - `0`: All tests passed (100% pass rate across all tiers).
  - `1`: One or more tests failed.
  - `2`: Syntax or initialization error in test harness / dependencies.
- **Runner Flexibility**:
  `RunAllTests.ps1` supports execution via installed Pester (v4 or v5) OR a self-contained fallback assertion runner if Pester module is not installed on the system, guaranteeing 100% portability in any CI/CD or offline environment.

---

## Real-World Application Scenarios (Tier 4)
| # | Scenario ID | Scenario Name | Features Exercised | Description & Validation Goal | Complexity |
|---|:-----------:|---------------|--------------------|--------------------------------|:----------:|
| 1 | `SCENARIO_LAPTOP_BATTERY` | Mobile Gaming Laptop on Battery | F4, F5, F7, F8 | Verifies that battery power profile curbs aggressive background tweaks, preserves power-efficiency services, while safely deprioritizing heavy telemetry drainers without disabling CPU power throttling. | High |
| 2 | `SCENARIO_WORKSTATION_NVME` | High-End NVMe Desktop Workstation | F4, F5, F7, F8 | Verifies that desktop AC profile unlocks high-throughput tweaks (NVMe-tuned prefetch, network throttling disablement), identifies gaming processes, and prioritizes max FPS optimizations (`Win32PrioritySeparation = 0x28`). | High |
| 3 | `SCENARIO_BUDGET_LOWRAM_HDD` | Low-Spec Budget Machine (4GB RAM, HDD) | F4, F5, F7, F8 | Verifies extreme memory and I/O pressure adaptations, recommending aggressive RAM freeing, disabling heavy scheduled tasks and `SysMain` without breaking boot stability. | High |
| 4 | `SCENARIO_OEM_BLOAT_SCAN` | Fresh Bloated OEM System Clean-up | F1, F2, F3, F6, F8 | Verifies end-to-end scan on a simulated heavily-bloated Windows 11 installation with 25+ bloat services/tasks/AppX (OEM daemons, sponsored apps), ensuring 100% protection of core OS services and non-removable packages. | High |
| 5 | `SCENARIO_IDEMPOTENCY_REVERT` | Full Remediation, Rescan & Reversion Cycle | F6, F8, F9 | Executes full remediation -> rescans system (verifying zero remaining unapplied candidates) -> executes `-Revert` -> rescans system (verifying restoration to pre-remediation state via backup manifest). | Critical |
| 6 | `SCENARIO_CLI_GUI_CONTRACT` | Unified CLI and GUI Dashboard Contract | F9, F10 | Executes CLI optimizer with `-ScanOnly` and `-JsonOutput`, and verifies that WPF Dashboard data-binding models receive identical, synchronized profile and recommendation datasets without UI thread blocking. | High |

---

## Coverage Thresholds & Target Counts
- **Tier 1 (Feature Coverage)**: ≥ 5 test cases per feature (10 features = 50 test cases)
- **Tier 2 (Boundary & Corner Cases)**: ≥ 5 test cases per feature (10 features = 50 test cases)
- **Tier 3 (Cross-Feature Combinations)**: ≥ 12 pairwise interaction test cases
- **Tier 4 (Real-World Scenarios)**: ≥ 6 realistic application scenarios
- **Total Minimum Target**: ≥ 118 test cases with 100% passing threshold.
