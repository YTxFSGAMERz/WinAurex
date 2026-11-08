---
title: "WinAurex System Blueprint — Framework Architecture & Safety Standard"
description: "High-level technical blueprint of the WinAurex framework, modular folder structure, safety systems, and coding standards."
---

# Architecture Blueprint: WinAurex System Framework

## Executive Summary
**WinAurex** is a modular, transparent, and user-centric Windows optimization and debloating suite. This blueprint defines the repository structure, script standards, logging, rollback safety, and user-experience principles required to build a safe, scalable, and trusted framework.

---

## Core Tenets
1. **Transparency Over Magic:** No black-box executables for core tasks. Everything is readable, documented, and auditable PowerShell, batch, or registry scripts.
2. **Safety First, Always:** Every change must have a corresponding, verified revert mechanism. No aggressive or destructive defaults.
3. **Modular by Design:** Users should be able to run individual, isolated tweaks or curated profiles without system-wide side effects.
4. **Data-Driven & Realistic:** Grounded in real Windows internals, not placebo myths (e.g., no aggressive memory purging that slows down caching, no disabling core security components blindly).

---

## Repository Directory Architecture

```text
WinAurex/
├── bin/                          # Production CLI entrypoints
├── Core/                         # Core execution engine, rollback, logging, and elevation
│   ├── Elevate/                  # Admin privilege validation & UAC helpers
│   ├── Logging/                  # Centralized logging engine
│   ├── Restore/                  # System state capture & rollback engine
│   └── Telemetry/                # Diagnostic data helpers (local only)
├── Tweaks/                       # Atomic tweaks organized by functional area
│   ├── Appearance/               # UI, themes, transparency, visual effects
│   ├── Background/               # Background apps, background task execution
│   ├── Browser/                  # Edge optimization, tab sleeping
│   ├── Display/                  # GPU preferences, Windowed Optimizations, Auto SR
│   ├── Gaming/                   # Game Mode, MMCSS scheduling, DirectSR
│   ├── Network/                  # Delivery optimization, bandwidth limits
│   ├── Privacy/                  # Telemetry, camera, mic, location, 26H2 Recall neutralization
│   ├── Recursos/                 # CPU priority, power plans, SSD TRIM, service debloat
│   ├── Startup/                  # Autorun auditing and startup program controls
│   ├── Storage/                  # Temp cleanups, Storage Sense
│   ├── Storage-Aggressive/       # Component Store (WinSxS) cleanups
│   └── Troubleshooting/          # Clean Boot manager
├── Profiles/                     # Pre-packaged orchestration workflows
│   ├── Gaming.ps1                # Low latency, maximum gaming priority
│   ├── Minimal.ps1               # Safe, essential debloat for general desktop
│   └── Workstation.ps1           # High productivity, development, WSL2 focus
├── Tools/                        # External, audited diagnostic tools
│   ├── Hardware/                 # InSpectre, Core Temp, HWMonitor
│   └── Browsers/                 # Curated open-source browsers
├── docs/                         # Astro / Starlight documentation portal
├── Start.bat                     # Root launcher
└── Launch_Dashboard.ps1          # Native WPF XAML Desktop Graphical Dashboard
```

---

## Architectural Systems & Patterns

### 1. Atomic Tweaks
- Every tweak in `Tweaks/` operates on a single system facet.
- Must include both an **Apply** and a **Revert** script (or paired registry files).
- Must verify current registry states before applying to prevent redundant writes.

### 2. Event-Sourced Rollback Engine (`Core/Restore/`)
- Before any profile or batch tweak executes, the engine captures a **Pre-Execution Snapshot** in JSON format:
  ```json
  {
    "timestamp": "2026-11-08T12:00:00Z",
    "module": "Tweaks/Privacy",
    "changes": [
      {
        "type": "Registry",
        "path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI",
        "value": "DisableAIDataAnalysis",
        "old_data": 0,
        "new_data": 1
      }
    ]
  }
  ```
- A restore action replays the recorded `old_data` values to return the system to its exact previous state.

### 3. Native DISM Servicing
- For UWP bloatware and Windows Recall removal, WinAurex uses standard Microsoft DISM commands (`/Remove-ProvisionedAppxPackage` and `Disable-WindowsOptionalFeature`).
- Ensures component store integrity across 26H2 checkpoint cumulative updates.

---

## Operational Standards

### Script Standards & Naming Strategy
- **Naming Convention:** `Action_Target.ps1` (e.g., `Disable_Copilot_Taskbar.ps1`, `Export_Current_Settings.ps1`).
- **Metadata Headers:** Every script must declare its purpose, OS support, risk level, restore path, and required privileges.
- **Validation:** Scripts must detect OS build, validate Admin rights, and capture the current state before modification.
- **Automation:** All PowerShell scripts must support the `-Force` argument to bypass any interactive `Read-Host` or `ReadKey` pauses, enabling seamless integration into deployment pipelines.

### Logging & Restore Strategy
- **Logging (`Logs/`):** Centralized `Write-FrameworkLog` function. Captures Timestamp, Module, Severity, OS Build, Old Value, and New Value. Format: `YYYY-MM-DD_ModuleName.log`.
- **Restore:** Pre-execution snapshots are mandatory for advanced packs. Users must be able to restore via `.reg` backups or system restore points easily.

### Compatibility Strategy
- Scripts must distinguish between Windows 10, Windows 11, and specific feature updates (e.g., 26H2, Copilot+ Recall).
- Use `Try/Catch` and feature-gating to fail gracefully if an OS does not support a specific registry key or API.

### Documentation Strategy (`docs/`)
- **Structure:** Architecture, Safety, Profiles, Diagnostics, FAQ.
- **Myths & Anti-Patterns:** A dedicated section debunking fake RAM boosters, blind service disabling, placebo latency folklore, and dangerous Defender hacks to build user trust.

---

## Conclusion
The WinAurex architecture establishes a new benchmark for open-source Windows optimization: safe, fully auditable, OS-aware for Windows 11 26H2, and backed by transactional rollback protection.
