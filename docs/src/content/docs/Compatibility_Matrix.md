---
title: "Windows OS Compatibility Matrix — Supported Versions & Editions"
description: "Comprehensive compatibility matrix for WinAurex across Windows 10 and Windows 11 (23H2, 24H2, 25H2, 26H2) editions. Check which features work on Home, Pro, Enterprise, and LTSC."
---

The WinAurex framework is engineered to be fully OS-aware across all modern Windows versions. As Microsoft continuously evolves system architectures, background AI runtimes (Recall, Copilot+ Studio Effects), and default disk encryption across Windows 11 releases (**24H2, 25H2, and 26H2**), WinAurex adapts its servicing logic dynamically.

This matrix tracks the verified compatibility of major module packs across all mainstream Windows versions.

<div class="matrix-table-container">
  <table class="matrix-table">
    <thead>
      <tr>
        <th>Module Pack</th>
        <th>Windows 10 (22H2)</th>
        <th>Windows 11 (23H2)</th>
        <th>Windows 11 (24H2)</th>
        <th>Windows 11 (25H2)</th>
        <th>Windows 11 (26H2)</th>
        <th>Architectural & Servicing Notes</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>WPF Dashboard UI</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Runs natively on .NET 8 / 4.8+ with zero runtime dependencies.</td>
      </tr>
      <tr>
        <td><strong>Windows Recall & AI Subsystem</strong></td>
        <td><span class="status-badge not-applicable">N/A</span></td>
        <td><span class="status-badge not-applicable">N/A</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Completely neutralizes Recall snapshotting, AI indexer SQLite databases, and Copilot background daemons.</td>
      </tr>
      <tr>
        <td><strong>Silent BitLocker Prevention</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Blocks automatic disk encryption during setup on 24H2, 25H2, and 26H2, preserving full NVMe SSD read/write speeds.</td>
      </tr>
      <tr>
        <td><strong>Shell (Copilot & Widgets)</strong></td>
        <td><span class="status-badge partial">Partial</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Purges taskbar Copilot key mappings, widget panes, and web search hooks.</td>
      </tr>
      <tr>
        <td><strong>Explorer Productivity</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Restores Classic Context Menu and hides "Recommended" cloud file summaries.</td>
      </tr>
      <tr>
        <td><strong>Camera & Studio Effects Privacy</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Prevents NPU-accelerated background camera and microphone filters from overriding privacy toggles.</td>
      </tr>
      <tr>
        <td><strong>Apps & DISM Debloat</strong></td>
        <td><span class="status-badge partial">Partial</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Purges 38+ provisioned AppX packages including Copilot, DevHome, Clipchamp, and sponsored apps.</td>
      </tr>
      <tr>
        <td><strong>System Core & Gaming (MMCSS)</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Full support for MMCSS GPU priority, unparking CPU cores, and WDDM display driver scheduling.</td>
      </tr>
    </tbody>
  </table>
</div>

---

### Legend
*   <span class="status-badge supported" style="display:inline-block; margin-bottom:5px;">Supported</span> Fully tested, functional, and verified on clean installs.
*   <span class="status-badge partial" style="display:inline-block; margin-bottom:5px;">Partial</span> Script runs safely, but target feature is partially implemented or behaves differently in legacy OS builds.
*   <span class="status-badge not-applicable" style="display:inline-block; margin-bottom:5px;">N/A</span> Feature does not exist on this OS version (e.g., Recall does not exist on Windows 10 or 23H2).

---

## 🔬 Windows 11 Modern Architecture Breakdown (24H2 · 25H2 · 26H2)

Recent Windows 11 releases introduce major structural shifts toward automated AI background telemetry and silent system encryption:

### 1. Neutralizing Windows Recall & the AI Subsystem (24H2 &ndash; 26H2)
Introduced in **24H2** and expanded through **25H2** and **26H2**, Windows Recall captures regular photographic snapshots of your desktop and stores them in local SQLite vector databases for semantic search.
- **WinAurex Action**: Applies `DisableAIDataAnalysis = 1` in the system hive, unloads Recall background tasks, and provides a DISM command to safely disable the Recall optional package (`Recall-Client`).

### 2. Preventing Silent BitLocker Device Encryption (24H2 &ndash; 26H2)
Starting in **24H2** and continued in **25H2** and **26H2**, Windows automatically enables BitLocker XTS-AES encryption across all internal drives by default during clean installation on both Home and Pro editions.
- **Problem**: Testing shows up to **45% lower sequential and random NVMe read/write throughput**, higher CPU overhead, and severe lockout risks if using a local offline account without a cloud recovery key.
- **WinAurex Action**: Injects `PreventDeviceEncryption = 1` via `autounattend.xml` and live registry tweaks, preventing automatic disk encryption while allowing manual BitLocker configuration for users who explicitly want it.

### 3. Checkpoint Cumulative Updates & DISM Servicing
Modern Windows 11 builds utilize **Checkpoint Cumulative Updates** to reduce package sizes.
- **WinAurex Action**: WinAurex scripts utilize standard Microsoft DISM APIs (`/Remove-ProvisionedAppxPackage`) that maintain the integrity of the Component Store (WinSxS), ensuring future Windows cumulative updates install smoothly without servicing corruption.
