---
title: "Windows OS Compatibility Matrix — Supported Versions & Editions"
description: "Compatibility matrix for WinAurex across Windows 10 and 11 editions. Check which features work on Home, Pro, Enterprise, and LTSC."
---

# Compatibility Matrix

The WinAurex framework is designed to be OS-aware. However, as Microsoft introduces and deprecates features across different builds of Windows 10 and Windows 11, certain tweaks may behave differently or become obsolete.

This matrix tracks the tested compatibility of major module packs across the most common Windows versions as of **Q2 2026**.

<div class="matrix-table-container">
  <table class="matrix-table">
    <thead>
      <tr>
        <th>Module Pack</th>
        <th>Windows 10 (22H2)</th>
        <th>Windows 11 (23H2)</th>
        <th>Windows 11 (24H2)</th>
        <th>Windows 11 (25H2)</th>
        <th>Notes</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>WPF Dashboard UI</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Requires .NET Framework 4.8+ and PowerShell 5.1+.</td>
      </tr>
      <tr>
        <td><strong>Shell (Copilot/Widgets)</strong></td>
        <td><span class="status-badge partial">Partial</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Win10 lacks Copilot & Widgets in the same implementation as Win11.</td>
      </tr>
      <tr>
        <td><strong>Explorer Productivity</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Win11 requires overrides to restore Classic Context Menu.</td>
      </tr>
      <tr>
        <td><strong>Camera Privacy</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge partial">Partial</span></td>
        <td><span class="status-badge partial">Partial</span></td>
        <td>Win11 24H2+ Copilot+ Studio Effects may override access controls.</td>
      </tr>
      <tr>
        <td><strong>Apps Debloat</strong></td>
        <td><span class="status-badge partial">Partial</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Some sponsored apps (e.g., TikTok) are only provisioned on Win11.</td>
      </tr>
      <tr>
        <td><strong>System Core Modules</strong></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td><span class="status-badge supported">Supported</span></td>
        <td>Includes Visual Effects, Search, Power, Isolation, Tasks, Updates, etc.</td>
      </tr>
    </tbody>
  </table>
</div>

### Legend
*   <span class="status-badge supported" style="display:inline-block; margin-bottom:5px;">Supported</span> Fully tested and functional.
*   <span class="status-badge partial" style="display:inline-block; margin-bottom:5px;">Partial</span> Script runs without errors, but the target feature may not exist, or newer OS features bypass the legacy block.
*   ❌ **Unsupported**: Script will fail or cause instability. (Currently, no core modules are unsupported).

### Core Engine Note
The **Core/Restore/** framework is fully functional across Windows PowerShell 5.1 and PowerShell 7+ on both Windows 10 and Windows 11.

