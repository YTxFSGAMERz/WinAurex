# Windows Optimisations

<p align="center">
  <img src="https://img.shields.io/github/stars/YTxFSGAMERz/Windows-Optimisations?style=for-the-badge&color=00bcd4&logo=github" alt="Stars">
  <img src="https://img.shields.io/github/forks/YTxFSGAMERz/Windows-Optimisations?style=for-the-badge&color=00bcd4&logo=github" alt="Forks">
  <img src="https://img.shields.io/github/license/YTxFSGAMERz/Windows-Optimisations?style=for-the-badge&color=00bcd4" alt="License">
</p>

!!! info "Ultimate Windows Performance & Privacy Suite"
    This repository is a curated collection of high-performance scripts, registry tweaks, and essential tools designed to transform your Windows 10/11 experience. Whether you're a gamer seeking maximum FPS or a power user prioritizing privacy, this suite provides the tools you need.

## 🚀 Key Features

<div class="grid cards" markdown>

-   :material-rocket-launch:{ .lg .middle } __Performance First__

    ---

    Registry tweaks for CPU priority, SSD optimization, and custom power plans.

-   :material-shield-lock:{ .lg .middle } __Privacy Focused__

    ---

    Comprehensive telemetry disabling and deep bloatware removal.

-   :material-auto-fix:{ .lg .middle } __Automated Setup__

    ---

    Unattended installation configs that bypass TPM/RAM checks automatically.

-   :material-tools:{ .lg .middle } __Curated Toolset__

    ---

    Hand-picked utilities for hardware monitoring, drivers, and system management.

</div>

## 📂 Repository Structure

```
Windows-Optimisations/
├── Activators/                 # Windows activation tools
│   └── Windows Activators/
│       ├── AAct_x64.exe       # KMS activator for Windows/Office
│       └── MassGrave.cmd      # Alternative activation script
├── Antivirus/                  # Antivirus tools and recommendations
│   ├── eset_internet_security_live_installer.exe
│   ├── Kaspersky.exe
│   ├── MBSetup.exe            # MalwareBytes setup
│   └── HELP.txt               # Antivirus recommendations
├── Browsers/                   # Popular web browsers installers
│   ├── BraveBrowserSetup-BRV010.exe
│   ├── ChromeSetup.exe
│   ├── Firefox Installer.exe
│   ├── OperaGXSetup.exe
│   ├── OperaSetup.exe
│   ├── Internet Explorer 11.bat # IE11 installation script
│   └── RECOMMENDATIONS.txt    # Browser recommendations
├── Drivers/                    # Driver installation and management tools
│   ├── 3DP Chip.exe           # Driver detection utility
│   ├── Driver Booster.exe     # Driver updater
│   ├── driveridentifier_setup.exe # Driver identifier tool
│   └── RECOMMENDATION.txt     # Driver recommendations
├── Extra/                      # Additional useful utilities
│   ├── 7z2501-x64.exe         # File archiver
│   ├── 7z2501.exe
│   ├── AnyDesk.exe            # Remote desktop tool
│   ├── CRU.exe                # Custom Resolution Utility
│   ├── Everything-1.4.1.1024.x86-Setup.exe # File search utility
│   ├── IObit Unlocker/        # File unlocker tool
│   ├── Lightshot.exe          # Screenshot tool
│   ├── memreduct-3.4-setup.exe # RAM optimization tool
│   ├── serv iwin.exe          # Service manager
│   ├── SteamSetup.exe         # Steam installer
│   ├── TCPOptimizer.exe       # TCP/IP settings optimizer
│   ├── uwd.exe                # Unknown utility
│   ├── winrar-x64-623.exe     # File archiver
│   └── Winaero Tweaker.exe    # Windows customization tool
├── Hardware/                   # Hardware monitoring and information tools
│   ├── CPU-Z.exe              # CPU information utility
│   ├── GPU-Z.exe              # GPU information utility
│   └── HW-Monitor.exe         # Hardware monitoring tool
├── Tweaks/                     # System tweaks and optimizations
│   ├── Apply Optimizations.bat # Main optimization script
│   ├── Recursos/
│   │   ├── CPU Priority/      # CPU priority adjustment registry files
│   │   ├── CPU Mitigations/   # Spectre/Meltdown mitigation toggles
│   │   │   └── InSpectre.exe  # Mitigation control utility
│   │   ├── CPU Power Plan/    # Custom power plans
│   │   ├── Mem Reduct RAM/    # Memory reduction tool
│   │   ├── Optimize SSD/      # SSD optimization registry tweaks
│   │   ├── RAM Compression/   # RAM compression/scripts
│   │   ├── Services/          # Service optimization registry files
│   │   ├── Telemetry/         # Windows telemetry disabling
│   │   └── Appearance/        # Visual/theme tweaks
│   └── Resources/             # Duplicate of Recursos (likely symlink)
├── Windows Update/             # Windows Update control scripts
│   ├── Enable Windows Update.bat
│   ├── Disable Windows Update.bat
│   └── RECOMMENDATIONS.txt
├── WebView - IMPORTANT/        # Information about WebView component
│   └── DATA AND PURPOSE.txt
├── autounattend.xml            # Unattended Windows 11 installation configuration
├── README AND PROBLEMS.txt     # Basic usage instructions
└── .gitattributes              # Git LFS configuration for large files
```

## Key Components

### 1. System Optimization Tweaks
The `Tweaks/` directory contains various registry files and scripts to:
- Disable Windows telemetry and data collection
- Optimize visual effects for performance
- Adjust CPU priority settings for games and applications
- Disable unnecessary Windows services
- Optimize SSD performance
- Manage RAM compression
- Customize power plans

### 2. Driver Management
The `Drivers/` directory includes tools to:
- Detect outdated or missing drivers (Driver Identifier, 3DP Chip)
- Automatically update drivers (Driver Booster)
- Recommend essential drivers for optimal hardware performance

### 3. Privacy and Security Tools
- Antivirus recommendations focusing on lightweight, effective solutions
- Scripts to disable Windows Defender (for low-end systems)
- Tools to remove bloatware and telemetry
- Recommendations for privacy-focused browsing

### 4. Unattended Windows Installation
The `autounattend.xml` file provides a completely automated Windows 11 Pro installation with:
- Pre-configured settings to bypass TPM/Secure Boot/RAM checks
- Built-in scripts to remove bloatware apps and features
- Registry tweaks for performance and privacy
- Custom user configuration (Auto-login for Admin account)
- Disabled Windows Defender, telemetry, and data collection

### 5. Essential Utilities
Collection of useful tools including:
- File archivers (7-Zip, WinRAR)
- System monitoring (CPU-Z, GPU-Z, HW-Monitor)
- Remote desktop (AnyDesk)
- Screenshot tools (Lightshot)
- File search (Everything)
- Registry and system tweakers (Winaero Tweaker)

## Detailed Documentation

For more in-depth information on specific components of this repository, please refer to the following guides:

- [**System Tweaks & Optimizations**](TWEAKS.md) - Detailed breakdown of registry tweaks and performance scripts.
- [**Driver Management**](DRIVERS.md) - Guide on installing and updating essential hardware drivers.
- [**Antivirus & Security**](ANTIVIRUS.md) - Recommendations for lightweight security and online scanners.
- [**Web Browsers**](BROWSERS.md) - Performance-based browser comparisons and installers.
- [**Windows Update Management**](WINDOWS_UPDATE.md) - How to manage updates and their impact on features like the Microsoft Store.
- [**WebView2 Information**](WEBVIEW.md) - Understanding the resource impact of the WebView2 component.
- [**Hardware Monitoring**](HARDWARE.md) - Tools for monitoring temperatures, voltages, and specifications.
- [**Extra Utilities**](EXTRA.md) - A collection of additional tools for system management and customization.
- [**Windows Activators**](ACTIVATORS.md) - Tools for Windows and Office activation.
- [**Unattended Installation**](AUTOUNATTEND.md) - Features and usage of the automated Windows 11 installation script.

## Usage Instructions

### Basic Optimization
1. Run `Tweaks\Apply Optimizations.bat` as administrator to apply recommended system tweaks
2. Use tools from `Drivers\` to ensure all hardware has optimal drivers
3. Install preferred browsers from `Browsers\`
4. Install useful utilities from `Extra\` as needed

### Privacy-Focused Setup
1. Apply telemetry disabling tweaks from `Tweaks\Recursos\Telemetry\`
2. Consider disabling Windows Update if not using Microsoft Store (see `WebView - IMPORTANT\DATA AND PURPOSE.txt`)
3. Use recommended antivirus alternatives or online scanners (VirusTotal, tria.ge)
4. Disable unnecessary Windows features and apps using provided scripts

### Performance Optimization
1. Apply CPU priority tweaks for gaming/workloads from `Tweaks\Recursos\CPU Priority\`
2. Optimize power plans from `Tweaks\Recursos\CPU Power Plan\`
3. Apply SSD optimizations from `Tweaks\Recursos\Optimize SSD\`
4. Manage RAM usage with tools from `Tweaks\Recursos\Mem Reduct RAM\` and `Tweaks\Recursos\RAM Compression\`

### Clean Installation
For a completely fresh, optimized Windows installation:
1. Use the `autounattend.xml` file with Windows Setup
2. This will create a system with:
   - Admin account with auto-login
   - Pre-applied performance and privacy tweaks
   - Removed bloatware apps and features
   - Disabled telemetry and data collection
   - Optimized visual effects and services

## Important Notes

### Antivirus Recommendations
As noted in multiple files in this repository:
- Traditional antivirus may not be necessary for careful users
- Recommended alternatives: MalwareBytes, NOD32 (ESET), Kaspersky
- Avoid: AVG, Avast, Avira (considered ineffective or potentially harmful)
- Use online scanners like VirusTotal or tria.ge for file analysis

### Windows Update and Microsoft Store
- Disabling Windows Update may break Microsoft Store functionality
- If you need Store apps, keep Windows Update enabled
- See `WebView - IMPORTANT\DATA AND PURPOSE.txt` for more details

### Driver Installation
- Always create a system restore point before installing new drivers
- Driver Booster from the `Drivers\` folder is recommended for automatic updates
- Video drivers are particularly important for gaming and visual performance

### Safety Precautions
- Backup important data before applying system tweaks
- Some optimizations may affect system stability on certain hardware configurations
- Test changes incrementally to isolate any issues
- The unattended installation includes aggressive tweaks that may not suit all users

## Legal and Ethical Notice
This repository contains tools for system optimization and customization. Users are responsible for:
- Ensuring they have rights to use any activated software
- Following local laws and regulations regarding software usage
- Creating backups before making system changes
- Understanding that some modifications may void warranties or support agreements

## Contributing
Feel free to suggest additional tools, scripts, or optimizations that could benefit Windows users looking to improve their system performance, privacy, or usability.

---

*Last updated: May 2026*
*For Windows 10/11 optimization and customization*