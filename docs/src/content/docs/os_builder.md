---
title: "Build a Custom Windows 11 ISO — 3-Tier OS Builder Framework"
description: "Step-by-step guide to building lightweight, telemetry-free Windows 11 ISOs across Stable, Performance & Gaming, and Core Ultra-Lite tiers with WinAurex OS Builder."
---

The WinAurex OS Builder is a native script-based framework designed to process an official **Windows 11 ISO** and compile a lightweight, telemetry-free, custom operating system image. It achieves this by directly injecting offline registry hives, surgically servicing Provisioned AppxPackages, and pre-staging a comprehensive post-install application suite.

## ⚙️ Overview & 3-Tier Architecture
At the core of the builder is `WinAurexMaker.ps1` and the unattended 1-click launcher `Build_WinAurex_ISO.cmd`. Users can choose between three specialized build tiers:

| Tier / Edition | System Model | Windows Update | WinGet & Store | Drivers & Hardware | Target Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Stable Workstation** | `WinAurex Stable Workstation Edition` | **100% Fully Functional** | **100% Fully Functional** | **100% Intact & Preserved** | Daily drivers, enterprise workstations, modern laptops |
| **Tier 2: Performance & Gaming** | `WinAurex Performance & Gaming Edition` | **Disabled** (Zero lag/reboots) | **100% Fully Functional** | **100% Intact & Preserved** | High-FPS gaming, competitive esports, power users |
| **Tier 3: Core Ultra-Lite** | `WinAurex Core Ultra-Lite Edition` | **Disabled / Stripped** | Minimal / Stripped | Minimal baseline | Low-spec hardware, VMs, extreme benchmarking |

## 🛡️ Hardware Bypasses & Driver Integrity
The builder natively patches the WinPE (Windows Preinstallation Environment) setup files:
*   **TPM 2.0 & Secure Boot:** `LabConfig` registry keys are injected into `boot.wim` to bypass TPM and Secure Boot requirements natively during the setup phase.
*   **CPU & Instruction Set Checks:** Removes the hard lock for unsupported CPUs, bypassing SSE4.2 and CPU family restrictions.
*   **Prevent Silent BitLocker Encryption:** Injects `PreventDeviceEncryption = 1` into the system hive to stop setup from silently enabling BitLocker on internal SSDs, preserving maximum read/write performance.
*   **Driver Integrity (Stable & Moderate):** The entire DriverStore, Plug and Play (`PlugPlay`), and Device Installation infrastructure remain 100% untouched. Wi-Fi, Ethernet, Bluetooth, GPU, and audio drivers operate out-of-the-box.
*   **Microsoft Account (MSA):** Edits the OOBE flow (`BypassNRO = 1`) to allow and enforce Local Account creation without requiring internet connectivity.

## 📦 Pre-Staged Post-Install Application Suite
Every compiled WinAurex ISO automatically places a `Post Install` folder on the Public Desktop and the root of the installation media:
*   **Browsers**: 1-click silent installers for Brave, Google Chrome, and Mozilla Firefox.
*   **Office Suites**: LibreOffice, ONLYOFFICE, and Microsoft 365 setup bootstrapper.
*   **Essential Utilities**: 7-Zip (offline installer included), Notepad++, VLC Media Player, Voidtools Everything search, and Rufus.
*   **WinAurex Hub**: Direct shortcuts to launch the WinAurex GUI Dashboard and full optimization engine.
*   **1-Click Master Setup**: `Install_All_Recommended.cmd` rapidly provisions a fresh machine with Brave, LibreOffice, 7-Zip, Notepad++, and VLC.

## 🛠️ Step-by-Step Usage Guide

### Method 1: 1-Click Interactive Batch Launcher (Recommended)
1. Place your Windows 11 ISO in your `Downloads` folder or inside the `WinAurex-OS-Builder` folder.
2. Right-click `Build_WinAurex_ISO.cmd` and select **Run as Administrator**.
3. Choose your desired profile (`1` for Stable, `2` for Performance & Gaming, `3` for Core Ultra-Lite).
4. The builder will automatically mount the image, apply the debloat profile, inject OEM branding, pre-stage the post-install suite, and compile the final bootable ISO.

### Method 2: PowerShell CLI Engine
```powershell
# Build Tier 1: Stable Workstation Edition
PS> .\WinAurexMaker.ps1 -Profile Stable -ISO E: -SCRATCH C:

# Build Tier 2: Performance & Gaming Edition
PS> .\WinAurexMaker.ps1 -Profile Moderate -ISO E: -SCRATCH C:

# Build Tier 3: Core Ultra-Lite Edition
PS> .\WinAurexMaker.ps1 -Profile Extreme -ISO E: -SCRATCH C:
```

:::tip
After installation, use Rufus (included in `Post Install\3-Tools\rufus-3.22p.exe`) to flash your generated `WinAurex.iso` to a USB drive with standard GPT/UEFI settings.
:::
