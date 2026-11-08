---
title: "FAQ — Windows 11 Optimization, Debloat & Custom ISO Questions"
description: "Answers to common questions about Windows 11 debloating, Recall removal, silent BitLocker prevention, custom ISO building, and gaming performance."
head:
  - tag: script
    attrs:
      type: application/ld+json
    content: |
      {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
          {
            "@type": "Question",
            "name": "Which Windows versions does WinAurex support?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "WinAurex supports Windows 11 (24H2, 23H2, and upcoming builds) as well as Windows 10. It includes dedicated modules to neutralize Windows Recall snapshots, prevent automatic BitLocker device encryption, purge Copilot background runtimes, and support cumulative updates."
            }
          },
          {
            "@type": "Question",
            "name": "How does WinAurex disable Windows Recall on Windows 11?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "WinAurex applies DisableAIDataAnalysis = 1 to the WindowsAI policy hive, stops and unregisters background AI indexing services, and provides a DISM command to safely disable the Recall optional feature package without breaking Windows Update."
            }
          },
          {
            "@type": "Question",
            "name": "Why does modern Windows 11 enable BitLocker automatically and how does WinAurex fix it?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "During clean installs, modern Windows 11 automatically enables device encryption by default on supported hardware, causing overhead in random 4K NVMe SSD operations and lockout risks. WinAurex injects PreventDeviceEncryption = 1 via autounattend.xml and registry tweaks to preserve full hardware drive performance."
            }
          },
          {
            "@type": "Question",
            "name": "What does debloating Windows 11 actually mean?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "Debloating refers to stripping away pre-installed bloatware apps, disabling intrusive background telemetry services, and unhooking continuous disk indexing. This frees up CPU cycles, lowers RAM usage, and significantly improves gaming latency."
            }
          },
          {
            "@type": "Question",
            "name": "Can I build a Custom Windows 11 ISO without TPM, Secure Boot or CPU restrictions?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "Yes. The WinAurex OS Builder uses native LabConfig registry injection to bypass TPM 2.0, Secure Boot, CPU checks, and RAM checks during setup, allowing you to install a debloated Windows 11 on any PC."
            }
          }
        ]
      }
---

This section covers the most common questions regarding **Windows 11 Optimization**, **Debloating**, **Windows Recall Neutralization**, and maximizing your PC's speed and gaming performance.

---

### Which Windows versions does WinAurex support?
**Yes.** WinAurex provides full support for **Windows 11 (24H2, 23H2, and upcoming builds)** as well as **Windows 10**:
1. **Windows Recall Neutralization**: Stops continuous photographic snapshotting and AI vector indexing.
2. **Silent BitLocker Prevention**: Stops Windows setup from automatically encrypting your SSDs.
3. **Checkpoint Servicing Compatibility**: Uses standard Microsoft DISM APIs that respect checkpoint cumulative updates.

### How does WinAurex disable Windows Recall on Windows 11?
WinAurex takes a multi-layer approach to eliminate Recall:
- **Registry & Policy**: Injects `DisableAIDataAnalysis = 1` under `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI`.
- **DISM Package Disablement**: Unregisters the `Recall` optional feature using `Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -NoRestart`.
- **Task Termination**: Terminates and disables the background snapshot daemons (`recall.exe`, `ai.exe`).

### Why does Windows 11 enable BitLocker automatically, and how does WinAurex stop it?
In clean installations, Microsoft turns on automatic device encryption (BitLocker) across all internal storage drives by default on both Home and Pro editions.
- **The Issue**: Testing demonstrates speed penalties in random 4K NVMe read/write operations, higher CPU storage wait states, and lockout risks when using offline local accounts.
- **The WinAurex Fix**: Injects `PreventDeviceEncryption = 1` into `HKLM\SYSTEM\CurrentControlSet\Control\BitLocker` both during unattended setup (`autounattend.xml`) and through the live registry optimization suite.

### What does "debloating" Windows 11 actually mean?
Debloating refers to the process of stripping away pre-installed, non-essential applications (bloatware), disabling intrusive background AI indexing, and turning off telemetry (Microsoft's diagnostic data collection). By removing these, Windows 11 frees up CPU cycles, lowers idle RAM usage from ~5.2GB down to ~2.3GB, and eliminates system stutter.

### Is it safe to debloat Windows 11 using scripts?
**Yes, when using safe tools like WinAurex.** Many generic "one-click" debloat scripts from the internet blindly delete critical system files, which can break the Microsoft Store, corrupt Windows Update, and cause blue screens. 
The **WinAurex** suite is specifically engineered to be safe. It uses Microsoft's native tools (like DISM and Group Policy) to elegantly disable bloatware without corrupting the underlying OS components. Always create a System Restore point before applying live tweaks.

### How do I get maximum performance for gaming in Windows 11?
For low-latency gaming performance, you need to minimize DPC latency and prevent background tasks from interrupting your CPU:
1. Use the [OS Builder](/os_builder/) or [Web Studio](/studio/) to craft a clean Windows installation.
2. Apply the **Multimedia Class Scheduler (MMCSS)** registry tweaks to allocate up to 80% CPU priority directly to your game.
3. Prevent silent BitLocker encryption to unlock full NVMe drive bandwidth.
4. Enable **Windowed Game Optimizations** (flip model) in display tweaks.
5. Import the `QuickCPU.pow` custom power plan to prevent CPU core parking during intensive loads.

### Can I build a Custom Windows 11 ISO without TPM or Secure Boot?
Yes. The **WinAurex OS Builder** uses native `LabConfig` registry injection (`BypassTPMCheck`, `BypassSecureBootCheck`, `BypassCPUCheck`, `BypassRAMCheck`) during the WinPE setup phase. This allows you to install a modern, debloated Windows 11 on legacy or unsupported hardware.
