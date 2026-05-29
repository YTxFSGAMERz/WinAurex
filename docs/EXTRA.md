# 🛠️ Extra Utilities Guide

The `Extra/` directory contains a curated selection of lightweight, high-performance utilities, custom system configurators, and network tuning applications designed to optimize your workspace and reduce systemic latency.

---

## 🗃️ 1. File Archiving & Management

### 7-Zip (`7z2501-x64.exe` / `7z2501.exe`)
*   **Purpose**: Open-source, high-efficiency file archiver with a high compression ratio in the `.7z` format.
*   **Why Use**: Completely free of advertising and nag-screens. Consumes significantly less memory during compression/decompression compared to standard WinZIP.

### WinRAR (`winrar-x64-623.exe`)
*   **Purpose**: High-fidelity file archiver with native support for the `.rar` format. Excellent for extracting split archives.

### IObit Unlocker (`IObit Unlocker/`)
*   **Purpose**: Resolves issues where files or folders cannot be deleted because they are locked by background system services.
*   **How to Use**: Right-click the locked file, select **IObit Unlocker**, and click **Unlock & Delete** or **Unlock & Rename**.

### Everything (`Everything-1.4.1.1024.x86-Setup.exe`)
*   **Purpose**: Fast search utility that indexes your system's NTFS file structures in seconds. It provides near-instant search results as you type, consuming negligible background memory.

---

## ⚡ 2. Network & System Latency Tuning

### TCP Optimizer (`TCPOptimizer.exe`)
*   **Purpose**: A portable configurator designed to tune your TCP/IP parameters in the registry.
*   **Optimal Gaming Setup**:
    1. Right-click `TCPOptimizer.exe` and select **Run as administrator**.
    2. Drag the slider at the top to match your maximum internet connection speed.
    3. Select the **Optimal** radio button at the bottom.
    4. Click **Apply Changes**, check the backup box, and restart the PC to optimize MTU, TCP Window Auto-Tuning, and Nagle's Algorithm.

### MSI Utility V3 (`MSI Utility V3.exe`)
*   **Purpose**: Configures devices to use **Message Signaled-Based Interrupts (MSI)** instead of legacy Line-Based Interrupts (Pin-Based).

> [!IMPORTANT]
> **MSI Optimization Steps (Reduces Audio Crackling & GPU Latency)**:
> 1. Right-click `MSI Utility V3.exe` and select **Run as administrator**.
> 2. Locate your primary **Graphics Card (GPU)** in the hardware list.
> 3. Check the box in the **MSI** column for your GPU.
> 4. Change the **Interrupt Priority** column from "Undefined" or "Normal" to **High**.
> 5. Click **Apply** in the top right corner.
> 6. *Warning*: Do not set priority to High for non-essential components (like USB or network adapters) as this can lead to system instability.

---

## 🎨 3. System Customization

### Winaero Tweaker (`Winaero Tweaker.exe`)
*   **Purpose**: A comprehensive customization panel that allows you to safely toggle hidden Windows registry variables via a simple graphical interface.
*   **Key Optimizations**:
    *   Disable automatic driver updates via Windows Update.
    *   Disable lock screen ads, telemetry, and preloaded apps.
    *   Enable classic shell features and right-click menus on Windows 11.

---

## 🔍 4. System Monitoring & Diagnostics

### Process Explorer (`Process Explorer.exe`)
*   **Purpose**: An advanced Task Manager replacement by Sysinternals.
*   **Why Use**: Displays detailed process trees, lets you view active DLL handles, maps CPU thread usage inside individual tasks, and integrates with VirusTotal to check running processes for malware.

### ServiWin (`serviwin.exe`)
*   **Purpose**: Displays a clean, tabular list of all installed drivers and system services on your PC. It allows you to instantly stop, start, or change service startup configurations without navigating the Windows Services utility.

---

## ⚙️ 5. General Utilities

### RestartDWM (`RestartDWM.exe`)
*   **Purpose**: Safely and instantly restarts the Desktop Window Manager (DWM) process. 
*   **Why Use**: Restarting DWM is highly useful for fixing visual glitches, resetting Multiplane Overlay (MPO) states, and clearing VRAM buffers to fix input latency without needing to reboot the entire PC.
*   **[Download RestartDWM.exe](https://github.com/YTxFSGAMERz/Windows-Optimisations/raw/master/RestartDWM.exe){ .md-button }**

### Rufus (`rufus-3.22p.exe`)
*   **Purpose**: Highly reliable utility to format and create bootable USB installation media from ISO images (used for clean unattended OS installations).

### AnyDesk (`AnyDesk.exe`)
*   **Purpose**: Fast, lightweight remote desktop software used to obtain remote assistance or manage secondary PCs on your network.

### Custom Resolution Utility - CRU (`CRU.exe`)
*   **Purpose**: Bypasses EDID display limits to create custom desktop resolutions and refresh rates.

> [!TIP]
> **Using CRU to Overclock Monitors**:
> 1. Open `CRU.exe` as Administrator.
> 2. Select your active display from the dropdown menu at the top.
> 3. Click **Add...** under the *Detailed resolutions* box.
> 4. Keep settings on "Automatic" and increase the refresh rate incrementally (e.g., from 60Hz to 74Hz). Click OK.
> 5. Run the included `restart.exe` (or `restart64.exe`) inside the CRU folder to reset the graphics driver.
> 6. Right-click Desktop > Display Settings > Advanced Display and change your refresh rate to test stability.

### Lightshot (`Lightshot.exe`)
*   **Purpose**: Lightweight screenshot program. It overrides the `Print Screen` key to allow custom cropping, highlighting, and immediate cloud uploading.

### Steam (`SteamSetup.exe`)
*   **Purpose**: Installer for the Valve Steam gaming platform.

### Tetris GameBoy (`Tetris_GameBoy.exe`)
*   **Purpose**: A retro Tetris simulator. Great for checking system controller latency and responsiveness.
