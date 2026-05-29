# 💿 Unattended Windows Installation Guide

The `autounattend.xml` file located in the root of this repository is a highly optimized configuration script designed to automate the installation of **Windows 11 Pro** (and Windows 10 Pro) from scratch, creating a streamlined, high-performance, and debloated baseline immediately upon first boot.

[Download autounattend.xml](https://github.com/YTxFSGAMERz/Windows-Optimisations/raw/master/autounattend.xml){ .md-button .md-button--primary }

---

## ⚡ Core Automation Features

### 1. Hardware Restriction Bypasses
Windows 11 has strict installation blocks for older processors or systems without modern hardware modules. This configuration automatically bypasses these checks:
*   **TPM 2.0 Check**: Bypassed (Bypasses `TPMCheck`).
*   **Secure Boot Check**: Bypassed (Bypasses `SecureBootCheck`).
*   **RAM Capacity Check**: Bypassed (Allows installation on systems with less than 4GB of RAM).
*   **Storage Capacity Check**: Bypassed.

### 2. Automatic System Tweaks during Setup
The XML applies the following modifications directly into the registry during the OS installation process:
*   **Windows Defender**: Disabled system-wide via registry overrides.
*   **User Account Control (UAC)**: Adjusted to the lowest level to prevent intrusive authorization popups.
*   **SmartScreen & Core Isolation**: Disabled to reduce real-time virtualization overhead.
*   **System Restore**: Disabled to conserve disk space and write cycles.
*   **Fast Startup**: Disabled to prevent persistent hibernation-related write bottlenecks.

### 3. Desktop Experience & Custom Interface
*   **Classic Context Menu**: Re-enables the classic right-click context menu (Windows 10 style) on Windows 11 by default.
*   **Taskbar Alignment**: Left-aligned taskbar elements out-of-the-box.
*   **Taskbar Cleanups**: Bing search results, widgets, and task view buttons are hidden.
*   **Desktop Icons**: Restores classic system icons ("This PC", "Control Panel", "Network", "User Profile") directly to the desktop on first boot.

### 4. Deep System Debloating
The setup executes silent scripts to uninstall pre-loaded UWP applications, preventing them from consuming CPU and disk storage:
*   *Apps removed*: 3D Viewer, Weather, Solitaire Collection, Bing Search, Camera, Clipchamp, Alarms/Clock, Copilot, Cortana, Family Safety, Feedback Hub, Get Help, MSN News, Microsoft Photos, Power Automate, and various Xbox-related background integrations.

### 5. Automated Local Account Provisioning
*   **Account Name**: Creates a local offline user profile named `Admin`.
*   **Auto-Login**: Configured to log in automatically to the desktop without prompts.
*   **Password**: No password is set, and the password expiration policy is set to "Never Expire".

---

## 🛠️ Step-by-Step Installation Guide

To perform an automated, debloated installation using `autounattend.xml`, follow these steps:

### Phase 1: Prepare the Installation Media
1.  **Download Windows ISO**: Download the official Windows 11 (or Windows 10) ISO directly from Microsoft's website.
2.  **Launch Rufus**: Open the **Rufus** utility (`Extra/rufus-3.22p.exe`) in this repository.
3.  **Configure Rufus**:
    *   **Device**: Select your USB drive (minimum 8GB capacity).
    *   **Boot Selection**: Choose **Disk or ISO image** and click **SELECT** to load your downloaded Windows ISO.
    *   **Partition Scheme**: Select **GPT** (for UEFI systems) or **MBR** (for legacy BIOS systems).
    *   **Target System**: Select **UEFI (non CSM)**.
4.  **Create the Installer**: Click **START**. A popup will appear. Ensure the standard Rufus hardware bypass options are unchecked (since our `autounattend.xml` already handles these and custom debloating much more aggressively). Click **OK** and wait for Rufus to complete writing.

### Phase 2: Apply the Automation XML
1.  Navigate to the root directory of this repository and copy the `autounattend.xml` file.
2.  Open your written bootable USB drive in File Explorer.
3.  **Paste at Root**: Paste `autounattend.xml` directly into the **root** folder of your USB drive (alongside `setup.exe` and the `sources/` folder).
    *   *Do NOT place it in any subfolders.*

```
Your USB Drive (D:\ or E:\)
├── sources/
├── support/
├── efi/
├── autounattend.xml    <-- MUST BE PLACED HERE!
├── bootmgr
└── setup.exe
```

### Phase 3: Perform the Installation
1.  Insert the prepared USB drive into the target computer.
2.  Turn on the PC and access the **Boot Menu** (typically via `F12`, `F11`, `F8`, or `F2` depending on the motherboard).
3.  Select your USB drive to boot.
4.  **Hands-Off Setup**: Once the installer boots, it will read `autounattend.xml`. The partitioning, license agreement, edition selection, and account setup steps are automated. The computer will reboot several times and drop you directly onto a fully-configured, debloated desktop logged in as `Admin`.

---

## ⚠️ Essential Warning

> [!CAUTION]
> This unattended setup applies extremely aggressive modifications. It completely disables Windows Defender, SmartScreen, and System Restore, and debloats many Microsoft systems. 
> 
> *Do NOT use this XML on high-security enterprise workstations, database servers, or systems containing sensitive financial datasets without implementing alternative protection strategies.*
