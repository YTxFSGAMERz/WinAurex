---
title: "Frequently Asked Questions (FAQ)"
description: "Answers to the most commonly asked questions regarding Windows 11 optimization, debloating, and custom ISO building."
---

# ❓ Frequently Asked Questions

This section covers the most common questions regarding **Windows 11 Optimization**, **Debloating**, and maximizing your PC's speed and gaming performance. These answers apply to both the live optimization scripts and the OS Builder.

---

### What does "debloating" Windows 11 actually mean?
Debloating refers to the process of stripping away pre-installed, non-essential applications (bloatware), disabling intrusive background services, and turning off telemetry (Microsoft's data collection). By removing these, Windows 11 frees up CPU cycles, lowers RAM usage, and significantly improves system responsiveness.

### Why is my Windows 11 so slow or lagging?
Windows 11 comes packed with heavy background features such as Copilot, Widgets, Edge background preloading, and aggressive telemetry tasks. These processes run continuously and consume valuable system resources, especially on systems with older CPUs or less than 16GB of RAM. Applying the [System Tweaks](./TWEAKS.md) disables these resource hogs.

### Is it safe to debloat Windows 11 using scripts?
**Yes, but caution is required.** Many generic "one-click" debloat scripts from the internet blindly delete critical system files, which can break the Microsoft Store, Windows Update, and cause blue screens. 
The **WinAurex** suite is specifically engineered to be safe. It uses Microsoft's native tools (like DISM and Group Policy) to elegantly disable bloatware without corrupting the underlying OS components. Always create a System Restore point before applying live tweaks.

### How do I get maximum performance for gaming in Windows 11?
For elite gaming performance, you need to minimize input lag and prevent background tasks from interrupting your CPU. 
1. Use the [OS Builder](./os_builder.md) to create a totally clean Windows installation.
2. Apply the **Multimedia Class Scheduler (MMCSS)** registry tweaks to force 80% of CPU allocation directly to your game.
3. Enable **Windowed Game Optimizations** (flip model) in display tweaks.
4. Import the `QuickCPU.pow` custom power plan to prevent CPU core parking during intensive loads.

### Does disabling visual effects actually make Windows 11 faster?
**Absolutely.** Disabling UI transparency (acrylic/mica effects) and window animations offloads significant work from your Graphics Processing Unit (GPU) and Desktop Window Manager (DWM). This is crucial for low-end PCs or gamers wanting to redirect every ounce of GPU power to rendering game frames instead of the desktop interface.

### How do I safely remove bloatware and unnecessary startup apps?
The safest manual method is using the `Manage Startup Apps.ps1` script included in the WinAurex Tweaks folder. This script identifies heavy third-party auto-starting applications in the registry and safely disables their launch triggers without deleting the apps themselves.

### Can I build a Custom Windows 11 ISO without TPM or Secure Boot?
Yes. The **WinAurex OS Builder** uses native `LabConfig` registry injection to completely bypass TPM 2.0, Secure Boot, and the 4GB RAM minimum requirements during the WinPE setup phase. This allows you to install a modern, debloated Windows 11 on legacy hardware.
