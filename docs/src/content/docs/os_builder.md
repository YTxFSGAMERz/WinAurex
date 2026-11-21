---
title: "Build a Custom Windows 11 ISO — 3-Tier OS Builder Framework"
description: "Step-by-step guide to building lightweight, telemetry-free Windows 11 ISOs across Stable, Performance & Gaming, and Core Ultra-Lite tiers with WinAurex OS Builder."
---

The WinAurex OS Builder is a native script-based framework designed to process an official **Windows 11 ISO** and compile a lightweight, telemetry-free, custom operating system image. It achieves this by directly injecting offline registry hives, surgically servicing Provisioned AppxPackages, and pre-staging a comprehensive post-install application suite.

---

## 📀 Official Pre-Built ISO Downloads

Pre-compiled, fully debloated, and verified ISO images are ready for direct download via Google Drive:

🔗 **[Browse the Official WinAurex ISOs Folder on Google Drive](https://drive.google.com/drive/folders/1ANWy6cB-PhQ5UTHWbES3MYS3NRSG5UV5)**

| Edition / Tier | File Size (Binary / Decimal) | Description | SHA-256 Checksum | Direct Download |
| :--- | :--- | :--- | :--- | :--- |
| **🟣 WinAurex Extreme (Core Ultra-Lite)** | `4.90 GiB` / `5.26 GB` | Pure TUI installer, extreme slop & Defender purge, minimal footprint for low-spec VMs & gaming rigs. | `b3431d529d1d9f3c4d1d4e187a0522cda0a45445141311fa71cc9384578ba929` | [📥 Download Extreme ISO](https://drive.google.com/file/d/1FQAMw9JdAHsuhpLlnFvSXBhfZ2Uh8cZP/view?usp=drivesdk) |
| **🟡 WinAurex Moderate (Performance & Gaming)** | `7.68 GiB` / `8.25 GB` | Debloated, telemetry stripped, Windows Update disabled, WinGet & hardware drivers 100% intact. | `b174a2eaa226bb86fc19bc76fb7b4aae091db273fb9d177bcd9e9663585340b2` | [📥 Download Moderate ISO](https://drive.google.com/file/d/1hl8GMYO5othK2nO_wOQEoFl4PCkCWSOs/view?usp=drivesdk) |
| **🟢 WinAurex Stable (Workstation Edition)** | `7.74 GiB` / `8.32 GB` | Enterprise stability, 100% working Windows Update, WinGet, Microsoft Store, and pristine driver stack. | `42811fd25bca09b0912e876146dc77e8bd45f4155d26cb5241e654094974fa9c` | [📥 Download Stable ISO](https://drive.google.com/file/d/1vtWpSpqIiThtuZ1V7Q64NwRApABFEPqe/view?usp=drivesdk) |

:::note
**Size Note**: Google Drive and Windows Explorer calculate storage in **Binary (GiB, base-1024)**, while decimal specifications use **GB (base-1000)**. The downloaded ISO files match the exact disk byte counts above.
:::

---

## ⚡ High-Speed Guided Direct-Deploy Engine (v2.0)

In v2.0, WinAurex replaces classic Microsoft `setup.exe` in WinPE with an interactive, **Archinstall-inspired TUI Direct-Deployment Engine** (`WinAurexDeploy.cmd`):

*   **Purged Legacy Setup Bloat:** All legacy Microsoft setup binaries (`setup.exe`, `setupplatform.*`, `winsetup.dll`, language directories) are removed from the media, reclaiming over 1 GB of ISO storage.
*   **Direct DISM Apply:** Applies `install.esd` directly to the target partition (`dism /apply-image`) in minutes, bypassing legacy wizard screens and auto-start delays.
*   **Guided Partition Manager:**
    *   **Zero Raw Commands:** Complete partition operations without typing `diskpart` commands.
    *   **Dual-Boot Ready:** Easily shrink existing partitions with a Megabyte prompt to allocate unallocated space for WinAurex alongside Linux or Windows.
    *   **Automated & Guided Options:** 1-click automatic disk wipe and UEFI/GPT creation, or guided manual partition creation (Primary NTFS, EFI 100MB FAT32 ESP, MSR 16MB), quick formatting, and volume assignment (`W:` OS, `S:` ESP).
    *   **Clean Terminal Display:** Screen-cleared (`cls`) interface on all sub-menus and actions, structured tabular storage overviews, and silent background command execution (`>nul 2>&1`).
*   **WinPE Native Tooling:** Chained `find /v /i` filters prevent shell errors on minimal WinPE images, supplemented by host `findstr.exe` injection into `boot.wim`.

---

## ⚙️ 3-Tier Architecture Comparison

Users can choose between three specialized build tiers:

| Tier / Edition | System Model | Windows Update | WinGet & Store | Drivers & Hardware | Target Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tier 1: Stable Workstation** | `WinAurex Stable Workstation Edition` | **100% Fully Functional** | **100% Fully Functional** | **100% Intact & Preserved** | Daily drivers, enterprise workstations, modern laptops |
| **Tier 2: Performance & Gaming** | `WinAurex Performance & Gaming Edition` | **Disabled** (Zero lag/reboots) | **100% Fully Functional** | **100% Intact & Preserved** | High-FPS gaming, competitive esports, power users |
| **Tier 3: Core Ultra-Lite** | `WinAurex Core Ultra-Lite Edition` | **Disabled / Stripped** | Minimal / Stripped | Minimal baseline | Low-spec hardware, VMs, extreme benchmarking |

---

## 🛡️ Hardware Bypasses & Driver Integrity
The builder natively patches the WinPE (Windows Preinstallation Environment) setup files:
*   **TPM 2.0 & Secure Boot:** `LabConfig` registry keys are injected into `boot.wim` to bypass TPM and Secure Boot requirements natively during the setup phase.
*   **CPU & Instruction Set Checks:** Removes the hard lock for unsupported CPUs, bypassing SSE4.2 and CPU family restrictions.
*   **Prevent Silent BitLocker Encryption:** Injects `PreventDeviceEncryption = 1` into the system hive to stop setup from silently enabling BitLocker on internal SSDs, preserving maximum read/write performance.
*   **Driver Integrity (Stable & Moderate):** The entire DriverStore, Plug and Play (`PlugPlay`), and Device Installation infrastructure remain 100% untouched. Wi-Fi, Ethernet, Bluetooth, GPU, and audio drivers operate out-of-the-box.
*   **Microsoft Account (MSA):** Edits the OOBE flow (`BypassNRO = 1`) to allow and enforce Local Account creation without requiring internet connectivity.

---

## 📦 Pre-Staged Post-Install Application Suite
Every compiled WinAurex ISO automatically places a `Post Install` folder on the Public Desktop and the root of the installation media:
*   **Browsers**: 1-click silent installers for Brave, Google Chrome, and Mozilla Firefox.
*   **Office Suites**: LibreOffice, ONLYOFFICE, and Microsoft 365 setup bootstrapper.
*   **Essential Utilities**: 7-Zip (offline installer included), Notepad++, VLC Media Player, Voidtools Everything search, and Rufus.
*   **WinAurex Hub**: Direct shortcuts to launch the WinAurex GUI Dashboard and full optimization engine.
*   **1-Click Master Setup**: `Install_All_Recommended.cmd` rapidly provisions a fresh machine with Brave, LibreOffice, 7-Zip, Notepad++, and VLC.
*   **SuperDebloat Ultimate**: Includes `SuperDebloat-Ultimate.cmd` for post-setup surgical cleanup.

---

## 🧪 VMware Automated Testing Harness

WinAurex OS Builder includes `Automate-VMwareTest.ps1` for non-interactive and visual VM verification:
*   Powers on virtual machines via `vmrun.exe`.
*   Captures live screenshot artifacts during deployment phases.
*   Validates installer execution, partition configuration, and desktop reachability automatically.

---

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
