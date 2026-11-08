---
title: "Windows 11 26H2 Registry Tweaks Reference — Complete Key List"
description: "Comprehensive reference of Windows 11 26H2 registry keys for performance, Recall neutralization, BitLocker prevention, and gaming optimization."
---

This document provides total transparency into the exact registry keys and values modified by the **WinAurex Framework**. This is intended for power users, system administrators, and security auditors who want to know exactly what is happening under the hood across **Windows 11 26H2** (and Windows 10).

---

## 1. Shell, UI & AI Recommendations Cleanup
| Tweak | Registry Path | Value Name | Target Value |
| :--- | :--- | :--- | :--- |
| Disable Copilot | `HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot` | `TurnOffWindowsCopilot` | `1` |
| Disable Widgets | `HKLM:\SOFTWARE\Policies\Microsoft\Dsh` | `AllowNewsAndInterests` | `0` |
| Hide 26H2 Recommended AI | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer` | `HideRecommendedSection` | `1` |
| Disable Start Account Badges | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `Start_AccountNotifications` | `0` |
| Disable Toasts | `HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications` | `ToastEnabled` | `0` |

## 2. Explorer & Search
| Tweak | Registry Path | Value Name | Target Value |
| :--- | :--- | :--- | :--- |
| Show Hidden Files | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `Hidden` | `1` |
| Show Extensions | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `HideFileExt` | `0` |
| Launch to This PC | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `LaunchTo` | `1` |
| Compact View | `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `UseCompactMode` | `1` |
| Classic Context Menu | `HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32` | *(Default)* | *(Empty)* |
| Disable Web Search | `HKCU:\Software\Policies\Microsoft\Windows\Explorer` | `DisableSearchBoxSuggestions` | `1` |
| Disable Highlights | `HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings` | `IsDynamicSearchBoxEnabled` | `0` |

## 3. Privacy, 26H2 Recall & Telemetry
| Tweak | Registry Path | Value Name | Target Value |
| :--- | :--- | :--- | :--- |
| Disable 26H2 Windows Recall | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI` | `DisableAIDataAnalysis` | `1` |
| Disable Diagnostic Data | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection` | `AllowTelemetry` | `0` |
| Disable Tailored Exp. | `HKCU:\Software\Policies\Microsoft\Windows\CloudContent` | `DisableTailoredExperiencesWithDiagnosticData` | `1` |
| Disable Activity History | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System` | `PublishUserActivities` | `0` |
| Disable Clipboard Hist. | `HKCU:\Software\Microsoft\Clipboard` | `EnableClipboardHistory` | `0` |
| Disable Cloud Clipboard | `HKCU:\Software\Microsoft\Clipboard` | `EnableCloudClipboard` | `0` |
| Disable Camera (Lock) | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization` | `NoLockScreenCamera` | `1` |
| Disable Camera (Apps) | `HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam` | `Value` | `Deny` |

## 4. Hardware, SSD & 26H2 BitLocker Prevention
| Tweak | Registry Path | Value Name | Target Value |
| :--- | :--- | :--- | :--- |
| Prevent 26H2 Device Encryption | `HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker` | `PreventDeviceEncryption` | `1` |
| Disable Hibernation | `HKLM:\System\CurrentControlSet\Control\Power` | `HibernateEnabled` | `0` |
| Enable Game Mode | `HKCU:\Software\Microsoft\GameBar` | `AutoGameModeEnabled` | `1` |
| Enable HAGS | `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers` | `HwSchMode` | `2` |
| Disable Driver Updates | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` | `ExcludeWUDriversInQualityUpdate` | `1` |
| Disable Delivery Opt. | `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization` | `DODownloadMode` | `0` |

## 5. Setup & 26H2 Installation Bypasses (`LabConfig`)
| Tweak | Registry Path | Value Name | Target Value |
| :--- | :--- | :--- | :--- |
| Bypass TPM 2.0 | `HKLM:\SYSTEM\Setup\LabConfig` | `BypassTPMCheck` | `1` |
| Bypass Secure Boot | `HKLM:\SYSTEM\Setup\LabConfig` | `BypassSecureBootCheck` | `1` |
| Bypass CPU Requirements | `HKLM:\SYSTEM\Setup\LabConfig` | `BypassCPUCheck` | `1` |
| Bypass RAM Check | `HKLM:\SYSTEM\Setup\LabConfig` | `BypassRAMCheck` | `1` |
| Bypass Storage Check | `HKLM:\SYSTEM\Setup\LabConfig` | `BypassStorageCheck` | `1` |
| Bypass OOBE Network/MSA | `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE` | `BypassNRO` | `1` |

---
**Note:** Many other modifications in this framework are executed via `powercfg`, `schtasks`, `Get-Service`, and `Get-AppxPackage`, which do not rely directly on raw registry key injection. Those operations are documented within their respective `.ps1` scripts.
