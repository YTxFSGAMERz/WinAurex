---
title: "Build a Custom Windows 11 ISO — Zero-Bloat OS Builder Framework"
description: "Step-by-step guide to building lightweight, telemetry-free Windows 11 ISOs with Recall removal, BitLocker prevention, and TPM bypass using WinAurex OS Builder."
---

The WinAurex OS Builder is a native script-based framework designed to process an official **Windows 11 ISO** and compile a lightweight, telemetry-free, custom operating system image. It achieves this by directly injecting offline registry hives and surgically removing Provisioned AppxPackages.

## ⚙️ Overview & Architecture
At the core of the builder is `WinAurexMaker.ps1`. This script mounts the `install.wim` from a standard Windows 11 ISO and performs offline servicing using Microsoft's native **DISM** (Deployment Image Servicing and Management) tools.
By editing the registry hives offline, the builder ensures that telemetry, sponsored apps, background AI runtimes, and restrictive hardware checks are completely neutralized *before* the operating system is even installed.

## 🛡️ Hardware Bypasses & BitLocker Prevention
The builder natively patches the WinPE (Windows Preinstallation Environment) setup files:
*   **TPM 2.0 & Secure Boot:** `LabConfig` registry keys are injected into `boot.wim` to bypass TPM and Secure Boot requirements natively during the setup phase.
*   **CPU & Instruction Set Checks:** Removes the hard lock for unsupported CPUs, bypassing SSE4.2 and CPU family restrictions.
*   **Prevent Silent BitLocker Encryption:** Injects `PreventDeviceEncryption = 1` into the system hive to stop setup from silently enabling BitLocker on internal SSDs, preserving maximum read/write performance.
*   **Microsoft Account (MSA):** Edits the OOBE flow to allow and enforce Local Account creation without requiring internet connectivity.

## 🗑️ Aggressive Debloating
The script surgically removes bloatware from the mounted image:
*   **Neutralizes Windows Recall & Copilot:** Purges Copilot runtime packages, Recall AI photographic snapshots, and AI daemons before installation.
*   **Removes Microsoft Edge & Edge WebView:** Completely purges Edge components before installation.
*   **Eliminates Integrations:** Purges OneDrive, Microsoft Teams, and Xbox background services natively.
*   **Purges 38+ Provisioned AppxPackages:** Removes Weather, News, Solitaire, GetHelp, Feedback Hub, DevHome, and other unnecessary modern apps using DISM `/Remove-ProvisionedAppxPackage`.

## 🔒 Privacy & Telemetry
Offline registry injection guarantees privacy from the first boot:
*   **Disable Telemetry:** Injects `AllowTelemetry = 0` and `DisableAIDataAnalysis = 1` directly into the system hive.
*   **Turns off Sponsored Apps:** Disables Content Delivery Manager and third-party app installations in the Start menu.
*   **Disables Advertising IDs:** Blocks Cloud Content optimization and targeted advertising IDs at the OS level.

## 🛠️ Step-by-Step Usage Guide

### Prerequisites
1.  Download an official Windows 11 ISO from Microsoft.
2.  Ensure you have `oscdimg.exe` (part of the Windows ADK) in the builder directory to compile the final ISO.

### Instructions
1.  Place your unmodified Windows 11 ISO in the root folder and name it appropriately.
2.  Right-click `WinAurexMaker.ps1` and select **Run with PowerShell** (ensure you have Administrator privileges).
3.  The script will automatically:
    *   Extract the ISO contents.
    *   Mount `boot.wim` and `install.wim`.
    *   Apply the debloat lists, BitLocker prevention, and registry bypasses.
    *   Unmount and commit the changes.
4.  Finally, the script calls `oscdimg.exe` to package the modified files into a new, bootable ISO file (e.g., `WinAurex_Clean.iso`).
5.  Use a tool like Rufus to flash this custom ISO to a USB drive and install Windows as usual.

:::danger
Creating custom ISOs modifies core Windows files. Always test your generated ISO in a Virtual Machine (like VMware or VirtualBox) before deploying it to physical hardware to ensure stability.
:::
