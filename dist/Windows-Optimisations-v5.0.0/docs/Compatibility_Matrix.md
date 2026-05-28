# Compatibility Matrix

The Windows-Optimisations framework is designed to be OS-aware. However, as Microsoft introduces and deprecates features across different builds of Windows 10 and Windows 11, certain tweaks may behave differently or become obsolete.

This matrix tracks the tested compatibility of major module packs across the most common Windows versions as of **Q2 2026**.

| Module Pack | Windows 10 (22H2) | Windows 11 (23H2) | Windows 11 (24H2) | Notes |
| :--- | :---: | :---: | :---: | :--- |
| **Shell (Copilot/Widgets)** | ⚠️ Partial | ✅ Supported | ✅ Supported | Win10 lacks Copilot & Widgets in the same implementation as Win11. Scripts will safely bypass missing keys. |
| **Explorer Productivity** | ✅ Supported | ✅ Supported | ✅ Supported | Win11 requires specific registry overrides to restore the Classic Context Menu. |
| **Visual Effects** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Search & Indexing** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Power & Thermal** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Clipboard Privacy** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Sync Isolation** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Camera Privacy** | ✅ Supported | ✅ Supported | ⚠️ Partial | Win11 24H2 introduces Copilot+ Studio Effects which may override legacy app access controls. |
| **GPU & Hardware** | ✅ Supported | ✅ Supported | ✅ Supported | HAGS (Hardware Accelerated GPU Scheduling) is recommended for both. |
| **Scheduled Tasks** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Background Services** | ✅ Supported | ✅ Supported | ✅ Supported | `DiagTrack` exists across all versions. |
| **Updates Control** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Diagnostics (Telemetry)** | ✅ Supported | ✅ Supported | ✅ Supported | |
| **Apps Debloat** | ⚠️ Partial | ✅ Supported | ✅ Supported | Some sponsored apps (e.g., TikTok) are only provisioned out-of-the-box on Windows 11. |

### Legend
*   ✅ **Supported**: Fully tested and functional.
*   ⚠️ **Partial**: Script will run without errors, but the target feature may not exist on this OS, or newer OS features may slightly bypass the legacy block.
*   ❌ **Unsupported**: Script will fail or cause instability. (Currently, no core modules are unsupported).

### Core Engine Note
The **Core/Restore/** framework is fully functional across Windows PowerShell 5.1 and PowerShell 7+ on both Windows 10 and Windows 11.
