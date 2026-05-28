# 🔌 Driver Management Guide

Device drivers are the translation layer between your operating system and physical hardware components. Installing correct, optimized drivers is critical to achieve high stability, prevent Blue Screen of Death (BSOD) crashes, and unlock maximum graphics performance.

---

## 🎯 Post-Installation Driver Update Priorities

After a clean Windows installation (e.g., using our `autounattend.xml`), update your drivers in this exact sequence to ensure system stability:

```
[1. Motherboard Chipset] ──> [2. Graphics Card (GPU)] ──> [3. Network (LAN/WiFi)] ──> [4. NVMe/SATA Storage] ──> [5. Sound/Audio]
```

### 1. Motherboard Chipset Drivers (Priority 1 - Critical)
*   *Why*: Governs bus communications between the CPU, RAM, and PCI Express slots.
*   *Downloads Needed*: Intel Chipset Device Software / Management Engine (ME) or AMD Ryzen Chipset Drivers.
*   *Impact*: Stabilizes CPU voltages, unlocks correct power scheduling, and ensures USB ports operate at full speeds.

### 2. Graphics Card Drivers (Priority 1 - Critical)
*   *Why*: Crucial for gaming, 3D rendering, and hardware video acceleration.
*   *Downloads Needed*: 
    *   **NVIDIA GeForce**: Geforce Game Ready Drivers (from nvidia.com).
    *   **AMD Radeon**: Software Adrenalin Edition (from amd.com).
    *   **Intel Arc**: Arc Graphics Drivers (from intel.com).
*   *Impact*: Restores high-resolution output, enables custom display refresh rates, and updates API support (DirectX 12, Vulkan).

### 3. Network Adapters (Priority 1 - Critical)
*   *Why*: Stabilizes ping, resolves packet loss, and increases download speeds.
*   *Downloads Needed*: Realtek LAN/WiFi, Intel Ethernet (e.g., I225-V/I226-V), or Killer Network drivers.

### 4. Storage Controllers (Priority 2 - Important)
*   *Why*: Improves file access speeds and NVMe temperatures.
*   *Downloads Needed*: Standard NVMe storage controller drivers (e.g., Samsung NVMe Driver).

### 5. Sound & Audio (Priority 2 - Important)
*   *Why*: Enables high-fidelity audio output and mic inputs.
*   *Downloads Needed*: Realtek High Definition Audio Drivers.

---

## 🛠️ Integrated Driver Utilities

The `Drivers/` directory contains tools to assist with automatic scanning, identification, and update processes:

### 1. Driver Booster
*   **File**: `Driver Booster.exe` (by IObit)
*   **How it Works**: Scans your hardware IDs against a massive cloud database of WHQL-certified drivers.
*   **Best For**: Speed. Allows one-click detection and automatic background installation of all missing motherboard, USB, and legacy drivers.

### 2. 3DP Chip
*   **File**: `3DP Chip.exe`
*   **How it Works**: A lightweight, portable diagnostic tool that instantly detects your specific motherboard, CPU, GPU, Network Card, and Sound Card.
*   **Best For**: post-install setups. It provides direct, clean links to official, stripped-down hardware drivers without bundling bloated software.

### 3. Driver Identifier
*   **File**: `driveridentifier_setup.exe`
*   **How it Works**: Scans the system, generates a local HTML report of all hardware components with their corresponding VEN (Vendor) and DEV (Device) strings, and links to verified driver packages.
*   **Best For**: Finding extremely rare or legacy drivers for "Unknown Devices" in Device Manager.

---

## 🔒 Safe Update Practices

Applying driver updates can sometimes cause system stability regressions. Follow these safety protocols:

### Step 1: Create a System Restore Point (Mandatory)
Before altering any drivers, establish a system-wide fallback:
1. Open the Start menu, search for **Create a restore point**, and select it.
2. Under System Protection, select your primary System Drive (typically `C:`) and click **Configure**. Ensure system protection is **Turned On** and allocate at least 2% disk space.
3. Click **Create...**, name it `Pre-Driver Update`, and click OK.

### Step 2: Clean Install Graphics Drivers using DDU
When upgrading graphics cards or resolving display stutters, performing a standard over-the-top installer update can leave corrupted cache residues. Perform a clean install instead:
1. Download **Display Driver Uninstaller (DDU)** (an external open-source utility).
2. Download your latest NVIDIA/AMD driver installer.
3. **Disconnect from the Internet**: This is crucial to prevent Windows Update from automatically downloading generic display drivers.
4. Reboot Windows into **Safe Mode**:
    * Hold `Shift` while clicking **Restart** in the Start Menu.
    * Navigate to **Troubleshoot > Advanced Options > Startup Settings > Restart**.
    * Press `4` or `F4` to enable Safe Mode.
5. Open DDU, select your Device Type (**GPU**), select your vendor (**NVIDIA** or **AMD**), and click **Clean and restart**.
6. Once Windows boots back to the desktop, run your downloaded graphics installer, select "Custom/Advanced Installation", and check "Perform a Clean Installation" if available.
7. Reconnect the internet.

---

## 🔍 Post-Installation Verification

Confirm your drivers are working correctly:
1.  **Check Device Manager**:
    *   Press `Win + X` and select **Device Manager**.
    *   Ensure there are **no yellow exclamation marks** or categories labeled "Unknown Device".
    *   If you see "Microsoft Basic Display Adapter", your graphics drivers are not active.
2.  **Verify High Refresh Rate**:
    *   Navigate to **Settings > System > Display > Advanced Display**.
    *   Confirm your monitor is set to its maximum supported refresh rate (e.g., 144Hz, 240Hz) rather than the default 60Hz.