---
title: "OS Builder Framework"
description: "Complete guide on using WinAurexMaker.ps1 to build a zero-bloat Windows 11 ISO."
---

# 🏗️ OS Builder Framework

The WinAurex OS Builder is a powerful, native script-based framework designed to process an official Windows 11 ISO and compile a lightweight, telemetry-free, custom operating system image. It achieves this by directly injecting offline registry hives and surgically removing Provisioned AppxPackages.

## ⚙️ Overview & Architecture
At the core of the builder is `WinAurexMaker.ps1`. This script mounts the `install.wim` from a standard Windows ISO and performs offline servicing using Microsoft's native **DISM** (Deployment Image Servicing and Management) tools.
By editing the registry hives offline, the builder ensures that telemetry, sponsored apps, and restrictive hardware checks are completely neutralized *before* the operating system is even installed.

## 🛡️ Hardware Bypasses
The builder natively patches the WinPE (Windows Preinstallation Environment) setup files:
*   **TPM 2.0 & Secure Boot:** `LabConfig` registry keys are injected into `boot.wim` to bypass TPM and Secure Boot requirements natively during the setup phase.
*   **CPU & RAM Restrictions:** Removes the hard lock for older hardware (bypassing the 4GB RAM minimum and unsupported CPU blocks).
*   **Microsoft Account (MSA):** Edits the OOBE (Out-of-Box Experience) flow to allow and enforce Local Account creation without requiring internet connectivity.

## 🗑️ Aggressive Debloating
The script surgically removes bloatware from the mounted image:
*   **Removes Microsoft Edge & Edge WebView:** Completely purges Edge components before installation.
*   **Strips Copilot and AI:** Removes Copilot integrations and AI recall features.
*   **Eliminates Integrations:** Purges OneDrive, Microsoft Teams, and Xbox integrations natively.
*   **Purges 30+ Provisioned AppxPackages:** Removes Weather, News, Solitaire, GetHelp, Feedback Hub, and other unnecessary modern apps using DISM `/Remove-ProvisionedAppxPackage`.

## 🔒 Privacy & Telemetry
Offline registry injection guarantees privacy from the first boot:
*   **Disable Telemetry:** Injects `AllowTelemetry = 0` directly into the system hive.
*   **Turns off Sponsored Apps:** Disables Content Delivery Manager and third-party app installations.
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
    *   Apply the debloat lists and registry bypasses.
    *   Unmount and commit the changes.
4.  Finally, the script calls `oscdimg.exe` to package the modified files into a new, bootable ISO file (e.g., `WinAurex_NoWinSxS.iso`).
5.  Use a tool like Rufus to flash this custom ISO to a USB drive and install Windows as usual.

> [!CAUTION]
> Creating custom ISOs modifies core Windows files. Always test your generated ISO in a Virtual Machine (like VMware or VirtualBox) before deploying it to physical hardware to ensure stability.
