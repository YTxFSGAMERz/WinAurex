# ⚡ Windows Optimisations ⚡

<p align="center">
  <a href="https://windows-optimizations.netlify.app/">
    <img src="https://img.shields.io/badge/LIVE_WEBSITE-Visit_Now-00bcd4?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Live Website">
  </a>
  <a href="https://github.com/YTxFSGAMERz/Windows-Optimisations" target="_blank">
    <img src="https://img.shields.io/github/stars/YTxFSGAMERz/Windows-Optimisations?style=for-the-badge&color=00bcd4&logo=github" alt="Stars">
  </a>
  <a href="https://github.com/YTxFSGAMERz/Windows-Optimisations/fork" target="_blank">
    <img src="https://img.shields.io/github/forks/YTxFSGAMERz/Windows-Optimisations?style=for-the-badge&color=00bcd4&logo=github" alt="Forks">
  </a>
  <a href="https://github.com/YTxFSGAMERz/Windows-Optimisations/blob/master/LICENSE" target="_blank">
    <img src="https://img.shields.io/badge/license-MIT-00bcd4?style=for-the-badge" alt="License">
  </a>
</p>

This repository contains a comprehensive, curated collection of high-performance tools, registry tweaks, automation scripts, and pre-configured setup templates designed to optimize Windows 10 & 11. Built with gaming performance, privacy, and system debloating as primary goals, this suite bridges the gap between hardware limitations and operating system overhead.

> [!WARNING]
> These optimization scripts apply system-wide changes, alter service parameters, and disable telemetry/security configurations. Always create a **System Restore Point** before running scripts, and backup critical files.

---

## 🚀 Key Features

*   **Performance Engineering:** Tailored registry tweaks for CPU priorities, SSD alignment, network latency, and advanced power plans.
*   **Privacy & Bloatware Control:** Broad-spectrum telemetry blocking, service adjustments, and deep removal of pre-installed background apps.
*   **Unattended OS Setup:** Automated Windows 11 installation templates that bypass RAM/TPM/Secure Boot checks automatically.
*   **Essential Diagnostic Toolkit:** Hand-picked open-source utilities for hardware monitoring, latency analysis, and driver stability.

---

## 📂 Repository Structure

```
Windows-Optimisations/
├── Activators/                 # Windows & Microsoft Office activation tools
├── Antivirus/                  # ESET, Kaspersky, and MalwareBytes security tools
├── Browsers/                   # Performance and privacy browser installers
├── Drivers/                    # Automatic driver detection and update tools
├── Extra/                      # File management, screen capture, and network utilities
├── Hardware/                   # Real-time hardware monitoring (CPU-Z, GPU-Z, HWMonitor)
├── Tweaks/                     # Core system optimizations
│   ├── Appearance/             # Light/dark theme and transparency controls
│   ├── Background/             # Telemetry-blocking background app controls
│   ├── Browser/                # Edge browser background telemetry removal
│   ├── Display/                # Windowed optimization, GPU preference, and Auto SR guides
│   ├── Gaming/                 # Windows Game Mode configurations
│   ├── Network/                # Delivery optimization bandwidth capping scripts
│   ├── Privacy/                # Camera, location, microphone, and metadata locks
│   ├── Recursos/               # Standard resources (Priorities, SSD, services, MemReduct)
│   ├── Resources/              # Duplicate resource mapping for retro-compatibility
│   ├── Startup/                # Startup program management tools
│   ├── Storage/                # Temp cleaning scripts and Storage Sense tools
│   ├── Storage-Aggressive/     # Aggressive DISM / component cleanup scripts
│   ├── Troubleshooting/        # Clean boot and diagnostic script tools
│   └── Apply Optimizations.bat # Core Interactive Admin Optimizer Script
├── Windows Update/             # Instant toggle batch files for Windows Update
├── WebView - IMPORTANT/        # Important notices on WebView2 rendering runtimes
├── autounattend.xml            # Automated, pre-debloated Windows 11 setup XML
└── README.md                   # This home page
```

---

## 📖 Live Website & Documentation

Visit our **[Premium Documentation Website](https://windows-optimizations.netlify.app/)** for a modern reading experience with sleek interactive guides.

Alternatively, browse the documents directly:

*   [**System Tweaks & Optimizations**](docs/TWEAKS.md) — Walkthrough of all 13 tweaks subdirectories.
*   [**Driver Management**](docs/DRIVERS.md) — Essential guides for GPU and motherboard updates.
*   [**Antivirus & Security**](docs/ANTIVIRUS.md) — Anti-malware guidance and safe habits.
*   [**Web Browsers**](docs/BROWSERS.md) — Browser comparisons for gaming and privacy.
*   [**Windows Update Control**](docs/WINDOWS_UPDATE.md) — Controlling background update schedules.
*   [**WebView2 Runtimes**](docs/WEBVIEW.md) — Handling WebView dependencies safely.
*   [**Hardware Diagnostics**](docs/HARDWARE.md) — Measuring temperatures and thermal bottlenecks.
*   [**Extra System Tools**](docs/EXTRA.md) — Rufus, TCP Optimizer, and MSI utility walkthroughs.
*   [**OS Activators**](docs/ACTIVATORS.md) — Safe KMS38 and HWID activation details.
*   [**Unattended Installation**](docs/AUTOUNATTEND.md) — Setting up pre-debloated Windows 11.

---

## 🛠️ Quick Start Guide

1.  **System Preparation:** Before running any tweak, launch Windows PowerShell as Administrator and run:
    ```powershell
    Checkpoint-Computer -Description "Pre-Optimization Backup"
    ```
2.  **Run the Main Optimizer:** Navigate to the `Tweaks/` folder, right-click `Apply Optimizations.bat`, and select **Run as administrator**. Select your optimization profile from the interactive menu.
3.  **Ensure Stable Drivers:** Run the utilities inside `Drivers/` to detect hardware and update core display and chipset systems.
4.  **Debloat Temporary Files:** Run `Tweaks\Storage\Safe Temporary Cleanup.bat` to clear systemic caches, prefetch stores, and temp files.

---

## 👑 Maintainer & Community

> **Farhan | Windows Optimization Expert**
> My goal is to maximize performance on both high-end and legacy computer systems by trimming software excess and restoring user privacy control.
>
> - **GitHub:** [@YTxFSGAMERz](https://github.com/YTxFSGAMERz)
> - **Telegram News:** [Telegram Channel](https://t.me/YTxFSGAMERz)
> - **WhatsApp Direct:** [WhatsApp (+91 7778906798)](https://wa.me/917778906798)

---

## ⚖️ Legal & Ethical Notice

This project is intended for educational, testing, and customization purposes. The scripts are provided "as-is" without warranty. Users are fully responsible for acquiring proper software licensing and understanding that aggressive modifications may void official vendor support agreements.

<p align="center" style="font-style: italic; color: #888;">~ Made By Farhan</p>
