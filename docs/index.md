# Windows Optimisations

<p align="center">
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

!!! info "Ultimate Windows Performance, Debloating, and Privacy Suite"
    Welcome to the official documentation site for the **Windows Optimisations** repository. This suite provides a curated, high-performance ecosystem of registry tweaks, automated installation files (`autounattend.xml`), toggle scripts, and utility configurations. Whether you want to boost gaming FPS, debloat background processes, or regain complete privacy on Windows 10/11, you'll find comprehensive step-by-step guides here.

---

## 🚀 Key Optimization Areas

<div class="grid cards" markdown="1">

-   :material-rocket-launch:{ .lg .middle } **Performance First**

    ---

    Registry tweaks for thread priority alignment, SSD alignments, network routing, and custom power plans (`QuickCPU`).

-   :material-shield-lock:{ .lg .middle } **Privacy & Telemetry**

    ---

    Broad-spectrum telemetry disablement, background app execution filters, and Edge telemetry cleanups.

-   :material-auto-fix:{ .lg .middle } **Automated OS Setup**

    ---

    `autounattend.xml` automation templates that bypass TPM, Secure Boot, and RAM restrictions automatically.

-   :material-toolbox:{ .lg .middle } **Curated Toolset**

    ---

    Hand-picked utilities for latency optimization (MSI Utility), custom resolutions (CRU), and hardware temperature tracking.

</div>

---

## 👑 About the Author

!!! abstract "Farhan | Windows Optimization Specialist"
    Hi! I'm **Farhan**, the designer and maintainer of this optimization catalog. My passion is to streamline Windows performance and eliminate background bloat, enabling high-responsiveness computing even on legacy hardware configurations.
    
    - :octicons-mark-github-16: **GitHub Profile:** [@YTxFSGAMERz](https://github.com/YTxFSGAMERz)
    - :fontawesome-brands-telegram: **Telegram Channel:** [Telegram News Feed](https://t.me/YTxFSGAMERz)
    - :material-whatsapp: **WhatsApp Direct:** [WhatsApp Channel Support (+91 7778906798)](https://wa.me/917778906798)

---

## 📂 Repository Layout

```
Windows-Optimisations/
├── Activators/                 # Activation utilities (MAS & AAct)
├── Antivirus/                  # Lightweight, resident security installers (NOD32, Kaspersky, MalwareBytes)
├── Browsers/                   # Performance installers (Brave, Chrome, Firefox, Opera GX)
├── Core/                       # Framework Infrastructure (Logging, Snapshots, Restore)
├── Drivers/                    # Core hardware driver updaters (3DP Chip, Driver Booster)
├── Extra/                      # File compression, screenshotting, and TCP tuning tools
├── GUI/                        # XAML layout files for the WPF Dashboard
├── Hardware/                   # Monitoring tools (CPU-Z, GPU-Z, HWMonitor)
├── Launchers/                  # PowerShell controllers and initializers
├── Tools/                      # Standalone native performance utilities
├── Tweaks/                     # Primary registry modifications and scripts
│   ├── Appearance/             # Light/dark theme, transparency, Action Center, and Cortana
│   ├── Background/             # Telemetry background task execution filters
│   ├── Browser/                # Edge browser background telemetry removal
│   ├── Display/                # HDR keyboard bindings, graphics adjustments, GPU preferences
│   ├── Gaming/                 # Windows Game Mode configurations
│   ├── Network/                # Bandwidth throttle reduction registry tweaks
│   ├── Privacy/                # System permissions locks (Location, Camera, Microphone)
│   ├── Startup/                # Startup program management tools
│   ├── Storage/                # Temp cleaning scripts and Storage Sense tools
│   └── Windows/                # Core OS scheduler and task prioritization hooks
├── Windows Update/             # Instant toggle batch files for Windows Update
├── autounattend.xml            # Automated, pre-debloated Windows 11 setup XML
├── Start.bat                   # Core Zero-Friction GUI Launcher
├── CONTRIBUTING.md             # Guidelines for pull requests and adding modules
├── SECURITY.md                 # Vulnerability reporting protocols
├── CODE_OF_CONDUCT.md          # Open-source community guidelines
└── README.md                   # Home page
```

---

## 🎯 Guided Paths by Use Case

To help you get the most out of your optimization process, identify your use case below and follow the linked documentation paths:

### 🎮 Gamers (Maximum FPS & Low Latency)
1. Apply CPU priorities and the custom power plan via [**System Tweaks**](TWEAKS.md).
2. Configure Message Signaled-Based Interrupts using the guide in [**Extra Utilities**](EXTRA.md).
3. Ensure display optimizations are active by consulting [**Display Tweaks**](TWEAKS.md#4-display-tweaks).
4. Update display and chipset drivers via [**Driver Management**](DRIVERS.md).

### 💻 Legacy / Low-End PCs (<8GB RAM & Weak CPUs)
1. Turn off visual transparency and animations using [**Appearance Tweaks**](TWEAKS.md#1-appearance-tweaks).
2. Configure automatic RAM cleaning with [**Mem Reduct Guide**](TWEAKS.md#memory-reduction).
3. Switch update routines off using [**Windows Update Controls**](WINDOWS_UPDATE.md) if you do not use the Microsoft Store.
4. Clean bloated caches using the [**Aggressive Storage Cleanup**](TWEAKS.md#11-storage-aggressive-tweaks) guide.

### 🔒 Privacy-Minded Users (Zero Telemetry)
1. Stop data collection routines using [**Telemetry Tweaks**](TWEAKS.md#telemetry-data-collection).
2. Restrict systemic access permissions via [**Privacy Tweaks**](TWEAKS.md#7-privacy-tweaks).
3. Transition to a telemetry-free browser by reading the [**Web Browsers Guide**](BROWSERS.md).
4. Consider performing a clean, fully-privatized OS setup using the [**Unattended Installation XML**](AUTOUNATTEND.md).

---

## ⚠️ Important Precautions

> [!WARNING]
> - Always perform a **System Restore Point** creation before running any scripts.
> - Some tweaks disable core security components (Windows Defender, SmartScreen). Only apply these modifications if you have alternative safeguards active or operate in secure isolated environments.
> - Read the [**Antivirus Guide**](ANTIVIRUS.md) to understand recommended modern scanning setups.

---

*For additional support or specific system optimization queries, join our Telegram Channel or contact Farhan directly.*
*Last updated: May 2026*