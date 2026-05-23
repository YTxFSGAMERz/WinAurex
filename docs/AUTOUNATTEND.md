# Unattended Windows Installation Guide

The `autounattend.xml` file in this repository provides a highly optimized, automated installation for Windows 11 Pro.

## Key Features

### 1. Hardware Requirement Bypasses
- **TPM Check**: Bypassed
- **Secure Boot Check**: Bypassed
- **RAM Check**: Bypassed
- Allows installation on older or "unsupported" hardware.

### 2. System Optimizations during Setup
- **Windows Defender**: Automatically disabled via registry modification during the installation process.
- **UAC (User Account Control)**: Disabled for a less intrusive experience.
- **SmartScreen**: Disabled.
- **System Restore**: Disabled to save disk space and performance.
- **Fast Startup**: Disabled (often recommended for SSDs to prevent hibernation-related issues).
- **Core Isolation**: Disabled for better performance.

### 3. User Interface & Experience
- **Classic Context Menu**: Re-enables the classic right-click menu in Windows 11.
- **Taskbar Customization**:
  - Bing search results disabled.
  - Widgets disabled.
  - Left-aligned taskbar (classic style).
- **Desktop Icons**: Essential icons like "This PC", "Control Panel", and "Network" are enabled by default.
- **Start Menu**: Pre-configured to be cleaner, with many "bloat" apps removed.

### 4. Bloatware Removal
The installation automatically removes a wide range of pre-installed Windows applications, including:
- 3D Viewer, Bing Search, Calculator, Camera, Clipchamp, Clock.
- Copilot, Cortana, Family, Feedback Hub, Get Help.
- Microsoft News, Solitaire, People, Photos, Power Automate.
- Weather, Xbox-related apps (some), and more.

### 5. Account Configuration
- **User Account**: Creates a local account named "Admin".
- **Auto-Login**: Configured to log in automatically to the Admin account.
- **Password**: No password set by default (Unlimited expiration).

## How to Use

1. **Prepare Installation Media**: Create a bootable Windows 11 USB drive (using a tool like Rufus, included in `Extra/`).
2. **Add the XML**: Copy the `autounattend.xml` file to the root of your bootable USB drive.
3. **Boot from USB**: Start your computer from the USB drive.
4. **Automated Setup**: Windows Setup will read the file and automate the installation process according to the pre-defined settings.

## Important Note
This installation is highly customized for performance and privacy. It disables many security features by default. Ensure you understand the implications and have reviewed the [Antivirus Guide](ANTIVIRUS.md) guide for alternative security measures.
