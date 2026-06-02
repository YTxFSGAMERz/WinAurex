# 🛠️ Windows Tweaks & Optimizations Guide

This document provides a highly detailed, comprehensive guide to all system modifications, registry tweaks, and shell scripts located in the `Tweaks/` directory. These configurations are designed to optimize Windows 10 & 11 for maximum responsiveness, privacy, and gaming efficiency. **All PowerShell scripts in this suite support zero-prompt, unattended execution simply by appending the `-Force` argument.**

---

## 📂 Folder Directory Structure
The `Tweaks/` directory is organized into functional categories to allow targeted optimizations:
1. [**Appearance**](#1-appearance-tweaks): Interface adjustments, themes, and Cortana.
2. [**Background**](#2-background-tweaks): Power and execution control for background tasks.
3. [**Browser**](#3-browser-tweaks): Optimizing Microsoft Edge and disabling browser preloads.
4. [**Display**](#4-display-tweaks): Custom GPU assignments, Auto SR, HDR, and Windowed Optimizations.
5. [**Gaming**](#5-gaming-tweaks): Windows Game Mode configurations.
6. [**Network**](#6-network-tweaks): Delivery Optimization bandwidth capping and P2P updates.
7. [**Privacy**](#7-privacy-tweaks): Core application permissions lockdowns.
8. [**Recursos & Resources**](#8-recursos-resources-standard-tweaks): Hardware priority tweaks, mitigations, custom power plans, SSD tunings, RAM cleaners, and services.
9. [**Startup**](#9-startup-tweaks): Trimming auto-start software.
10. [**Storage**](#10-storage-tweaks): Safe temporary folder cleaners and Storage Sense toggles.
11. [**Storage-Aggressive**](#11-storage-aggressive-tweaks): System component store and WinSXS cleanups via DISM.
12. [**Troubleshooting**](#12-troubleshooting-tweaks): Diagnostic Clean Boot management.
13. [**WPF Dashboard Walkthrough**](#13-wpf-dashboard-walkthrough): The main interactive control suite.

---

## 1. Appearance Tweaks
*   **Path**: `Tweaks/Appearance/`
*   **Purpose**: Disables taxing visual transitions and unnecessary system components to free up CPU and GPU cycles on older systems.

### Available Registry Tweaks
*   `Dark Theme.reg` / `Light Theme.reg`: Swaps the Windows system and app themes between dark and light modes.
*   `Disable Transparency.reg` / `Enable Transparency.reg`: Turns off transparency effects on the taskbar, start menu, and action center. Disabling transparency significantly reduces GPU load in windowed modes.
*   `Disable Action Center.reg` / `Enable Action Center.reg`: Deactivates the system notifications tray.
*   `Disable Cortana.reg` / `Enable Cortana.reg`: Fully blocks the Cortana digital assistant search indexing and background services.

> [!TIP]
> Disabling transparency and transitions is highly recommended for legacy systems with integrated graphics cards (such as Intel HD Graphics) to prevent interface stuttering.

---

## 2. Background Tweaks
*   **Path**: `Tweaks/Background/`
*   **Purpose**: Restricts system processes from spinning up background activities when not in use.

### Active Utility
*   `Manage Background Apps.ps1`: A PowerShell script that configures group policies and registry flags to stop Microsoft Store applications from executing background loops when closed.
*   **Registry Affected**: 
    `HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications`
    `GlobalUserDisabled = 1`

---

## 3. Browser Tweaks
*   **Path**: `Tweaks/Browser/`
*   **Purpose**: Prevents telemetry and keeps the Edge browser from eating up memory behind the scenes.

### Available Registry Tweaks
*   `Configure Edge Performance.reg`: Stops Microsoft Edge from running background extensions and preloading tabs during startup. It also disables built-in shopping helpers and diagnostic tracking.
*   `Revert Edge Performance (Restore).reg`: Restores default Microsoft Edge preloading features.

---

## 4. Display Tweaks
*   **Path**: `Tweaks/Display/`
*   **Purpose**: Minimizes graphics latency, configures high-refresh layouts, and guides super-resolution setup.

### Components
*   `Enable Windowed Game Optimizations.reg` / `Disable Windowed Game Optimizations (Restore).reg`: Enables flip model presentation for windowed DirectX 10/11 games, improving latency and unlocking features like Auto HDR.
*   `Manage GPU Preference.ps1`: Automates setting specific gaming binaries to "High Performance" GPU preference via Windows Graphics settings.
*   `Open Graphics Settings.bat`: Quick launcher to open the Windows 10/11 graphics properties control directly.
*   `Auto SR Settings Guide.txt` (Automatic Super Resolution): Setup manual detailing hardware requirements (Copilot+ PCs, Snapdragon processors) and system settings for AI-powered game upscaling.
*   `HDR Settings & Keyboard Shortcut.txt`: Notes on enabling Windows HDR and using `Win + Alt + B` to instantly toggle HDR on/off to avoid washed-out colors on standard desktops.

---

## 5. Gaming Tweaks
*   **Path**: `Tweaks/Gaming/`
*   **Purpose**: Optimizes OS process scheduling for active full-screen video games.

### Available Registry Tweaks
*   `Enable Game Mode.reg` / `Disable Game Mode (Restore).reg`: Toggles Windows Game Mode. When active, it prioritizes CPU resources for the foreground game, minimizes background notification interruptions, and suspends background updates during play.

---

## 6. Network Tweaks
*   **Path**: `Tweaks/Network/`
*   **Purpose**: Frees up local network bandwidth and stops background update uploads.

### Available Registry Tweaks
*   `Cap Delivery Optimization Bandwidth.reg` / `Remove Bandwidth Caps (Restore).reg`: Caps background download/upload bandwidth used for Windows Update delivery optimizations to prevent network spikes while gaming.
*   `Disable Peer to Peer Updates.reg` / `Enable Peer to Peer Updates (Restore).reg`: Prevents Windows from uploading updates to other PCs on the internet (which severely chokes home upload bandwidth).

---

## 7. Privacy Tweaks
*   **Path**: `Tweaks/Privacy/`
*   **Purpose**: System-wide blockades to prevent background telemetry transmission and device snooping.

### Available Registry Tweaks
*   `Disable App Metadata Access.reg` / `Enable App Metadata Access.reg`: Stops Windows from scanning app configurations.
*   `Disable Camera.reg` / `Enable Camera.reg`: Blocks camera sensor access for standard desktop/UWP apps globally.
*   `Disable Location.reg` / `Enable Location.reg`: Deactivates Windows Location tracking services.
*   `Disable Microphone.reg` / `Enable Microphone.reg`: Turns off microphone capture access globally.
*   `Disable Notifications.reg` / `Enable Notifications.reg`: Blocks UWP system toast notification popups.

---

## 8. Recursos & Resources (Standard Tweaks)
*   **Path**: `Tweaks/Recursos/` & `Tweaks/Resources/`
*   **Purpose**: The traditional performance tweaks folder.

### Key Components

#### CPU Priorities
*   `Games Priority.reg`: Modifies the Multimedia Class Scheduler (MMCSS) to allocate up to 80% CPU resources directly to active games and applications.
*   `Windows Priority.reg` / `Revert Changes.reg`: Restores balanced desktop thread priority parameters.
*   **Registry Paths Modifed**:
    `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games`

#### CPU Mitigations
*   `InSpectre.exe`: A lightweight diagnostic utility that allows the safe enabling/disabling of Meltdown and Spectre hardware mitigations.
    *   *Mitigations OFF*: Restores lost CPU performance (highly noticeable on 8th Gen Intel processors and older), but exposes the system to theoretical security exploits.
    *   *Mitigations ON*: Maximum security configuration, but reduces disk read/write throughput and raw execution speeds.

#### CPU Power Plans
*   `QuickCPU.pow`: A custom-engineered system power configuration optimized to minimize CPU core parking, maintain high frequency scales longer, and disable standard power savings when processing active loads.
*   `Aplicar.bat` / `Apply.bat`: Shell scripts to import and active the custom power plan via command line.
    ```cmd
    powercfg -import "%~dp0QuickCPU.pow"
    ```

#### SSD Optimizations
*   `Optimizar SSD.reg` / `Revert Changes.reg`: Applies SSD-specific settings:
    *   Enables **TRIM** to ensure even wear on NAND flash cells.
    *   Disables **Superfetch / Prefetch** (redundant on solid-state drives, saves excess disk write cycles).
    *   Optimizes standard disk write caching values.

#### Memory Reduction
*   `Mem Reduct RAM` (Portable): A light memory management utility.
    *   Cleans system caches, working sets, and pagefiles on command.
    *   Configures cleanups when memory saturation crosses specific benchmarks (e.g., 85%).
    *   Essential for legacy hardware configurations equipped with less than 8GB of RAM.

#### RAM Compression
*   `Disable Compression.cmd` / `Revert Changes.bat`: Toggles Windows virtual memory compression.
    *   *Compression Disabled*: Eliminates CPU processing latency associated with compressing inactive RAM pages. Best for systems with 16GB+ RAM.
    *   *Compression Enabled*: Compress pages to conserve capacity. Recommended for systems with 4GB/8GB RAM to prevent immediate swapfile thrashing on slow HDDs.

#### System Services
*   `Optimize Services.reg`: Disables or sets to Manual a wide array of legacy, enterprise, and telemetry-related background services (e.g., Bluetooth, print spooling if unused, faxing, remote registries).

#### Telemetry & Data Collection
*   `Disable Telemetry.reg`: Blocks telemetry routines, CEIP diagnostic collection, and Windows feedback prompts.

---

## 9. Startup Tweaks
*   **Path**: `Tweaks/Startup/`
*   **Purpose**: Manages software launch profiles during system startup.

### Active Utility
*   `Manage Startup Apps.ps1`: PowerShell script to scan, identify, and disable heavy third-party auto-starting applications in registry locations like:
    `HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
    `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`

---

## 10. Storage Tweaks
*   **Path**: `Tweaks/Storage/`
*   **Purpose**: Automates standard garbage collection and frees up wasted gigabytes.

### Tools
*   `Enable Storage Sense.reg` / `Disable Storage Sense (Restore).reg`: Toggles Windows Storage Sense utility, which automatically deletes temporary files, clears the Recycle Bin, and cleans downloaded items at set intervals.
*   `Safe Temporary Cleanup.bat`: A non-destructive shell script that purges the following cache directories safely:
    *   `%temp%` (User Temporary directory)
    *   `C:\Windows\Temp` (System Temporary directory)
    *   `C:\Windows\Prefetch` (Prefetch system files)

---

## 11. Storage-Aggressive Tweaks
*   **Path**: `Tweaks/Storage-Aggressive/`
*   **Purpose**: Sweeps system files and component stores for deeper debloating.

### Active Utility
*   `Deep Component Cleanup (Aggressive).bat`: A script that must be run as Administrator. It uses the Deployment Image Servicing and Management (DISM) tool to purge superseded system files, unused component packages, and legacy update backups from the `WinSXS` folder.
*   **Commands executed**:
    ```cmd
    Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
    ```
    > [!WARNING]
    > Running this aggressive component store cleanup removes old update uninstall files permanently. You will not be able to uninstall current updates once completed.

---

## 12. Troubleshooting Tweaks
*   **Path**: `Tweaks/Troubleshooting/`
*   **Purpose**: Restores system variables back to isolated baseline states.

### Tools
*   `Clean Boot Manager.ps1`: A PowerShell diagnostic utility that disables all non-Microsoft startup applications and services, creating an isolated boot profile. Extremely useful for identifying game-crashing software components or overlay conflicts.

---

## 13. WPF Dashboard Walkthrough
*   **Path**: `Start.bat` -> `Launch_Dashboard.ps1`
*   **Purpose**: The central menu interface.

The framework now features a stunning native PowerShell + WPF XAML graphical dashboard. Double-click `Start.bat` to launch it. The dashboard consists of multiple tabs:

1.  **Optimization Profiles**:
    *   **Max Performance Mode**: Targets the absolute lowest DPC latency and highest thread priorities for elite gamers.
    *   **Balanced Creator Mode**: Optimizes Windows Explorer and removes bloatware without disabling Windows Updates or breaking creative apps.
    *   **Enterprise Compliance Mode**: Reverts the OS into a highly secure, privacy-hardened state for corporate usage.
2.  **Observability Telemetry**: A real-time dashboard leveraging high-speed `.NET Diagnostics` to monitor DPC latency proxy speeds, Available RAM, Uptime, and Active Process Counts.
3.  **Rollback Engine**: Safely displays your JSON snapshot history, allowing you to instantly revert any registry/service modifications with a single click.
    *   Reducing visual effects quality parameters.
    *   Applying MMCSS gaming priority.
    *   Setting active game processes (like CS:GO, CS2, Fortnite, Minecraft, GTA V) to high performance CPU scheduling execution properties.
3.  **Create Restore Point**: Highly recommended first step. It runs PowerShell to enable system restores and establish a safe baseline bookmark named "Optimizer Script".
4.  **Delete Temporary Files**: Automatically cleans the user temp, system temp, and prefetch storage directories.
5.  **Disable Windows Defender**: Menu options to switch active Windows Defender, Security Health, and real-time monitoring services off.
6.  **Disable Windows Update**: Menu to pause and stop update schedulers and update self-healing dll dependencies.
7.  **About the Optimizer**: Credit listing and licensing summaries.

---

## 💡 Summary Recommendations by Use Case

### 🎮 Gaming Optimization
-   Create a restore point (Menu Option 3).
-   Run Option 1 (Apply Recommended Optimizations) to reduce MMCSS process delays and optimize service responsiveness.
-   Import `Tweaks/Recursos/CPU Power Plan/QuickCPU.pow` and active the profile.
-   Apply `Tweaks/Display/Enable Windowed Game Optimizations.reg`.
-   Verify sensor temperatures using diagnostics inside [**Hardware Monitoring**](HARDWARE.md).

### 💻 Legacy / Low-End Hardware (<8GB RAM)
-   Apply `Tweaks/Appearance/Disable Transparency.reg` to lighten graphics processor loads.
-   Keep Virtual RAM Compression **Enabled** (`Tweaks/Recursos/RAM Compression/Revert Changes.bat`) to prevent early HDD paging.
-   Run `Tweaks/Recursos/Mem Reduct RAM/memreduct.exe` to manage memory usage.
-   Apply services debloating via `Tweaks/Recursos/Services/Optimize Services.reg`.

### 🔒 Maximum System Privacy
-   Apply `Tweaks/Recursos/Telemetry/Disable Telemetry.reg` and `Tweaks/Privacy/Disable App Metadata Access.reg`.
-   Run `Tweaks/Background/Manage Background Apps.ps1` to stop closed applications from executing in the background.
-   Lock application permissions using the scripts in `Tweaks/Privacy/`.
-   Consult the [**Web Browsers Guide**](BROWSERS.md) to choose privacy-respecting navigation software.