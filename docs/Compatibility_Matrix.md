# Compatibility Matrix

The WinAurex framework is designed to be OS-aware. However, as Microsoft introduces and deprecates features across different builds of Windows 10 and Windows 11, certain tweaks may behave differently or become obsolete.

This matrix tracks the tested compatibility of major module packs across the most common Windows versions as of **Q2 2026**.

<div class="compat-grid">
  <div class="compat-card">
    <h3>WPF Dashboard UI</h3>
    <div class="os-tags">
      <span class="os-tag supported">Win 10 (22H2)</span>
      <span class="os-tag supported">Win 11 (23H2)</span>
      <span class="os-tag supported">Win 11 (24H2)</span>
      <span class="os-tag supported">Win 11 (25H2)</span>
    </div>
    <p class="notes">Requires .NET Framework 4.8+ (native on these builds) and PowerShell 5.1+.</p>
  </div>

  <div class="compat-card">
    <h3>Shell (Copilot/Widgets)</h3>
    <div class="os-tags">
      <span class="os-tag partial">Win 10 (22H2)</span>
      <span class="os-tag supported">Win 11 (23H2)</span>
      <span class="os-tag supported">Win 11 (24H2)</span>
      <span class="os-tag supported">Win 11 (25H2)</span>
    </div>
    <p class="notes">Win10 lacks Copilot & Widgets in the same implementation as Win11. Scripts will safely bypass missing keys.</p>
  </div>

  <div class="compat-card">
    <h3>Explorer Productivity</h3>
    <div class="os-tags">
      <span class="os-tag supported">Win 10 (22H2)</span>
      <span class="os-tag supported">Win 11 (23H2)</span>
      <span class="os-tag supported">Win 11 (24H2)</span>
      <span class="os-tag supported">Win 11 (25H2)</span>
    </div>
    <p class="notes">Win11 requires specific registry overrides to restore the Classic Context Menu.</p>
  </div>

  <div class="compat-card">
    <h3>Camera Privacy</h3>
    <div class="os-tags">
      <span class="os-tag supported">Win 10 (22H2)</span>
      <span class="os-tag supported">Win 11 (23H2)</span>
      <span class="os-tag partial">Win 11 (24H2)</span>
      <span class="os-tag partial">Win 11 (25H2)</span>
    </div>
    <p class="notes">Win11 24H2+ introduces Copilot+ Studio Effects which may override legacy app access controls.</p>
  </div>

  <div class="compat-card">
    <h3>Apps Debloat</h3>
    <div class="os-tags">
      <span class="os-tag partial">Win 10 (22H2)</span>
      <span class="os-tag supported">Win 11 (23H2)</span>
      <span class="os-tag supported">Win 11 (24H2)</span>
      <span class="os-tag supported">Win 11 (25H2)</span>
    </div>
    <p class="notes">Some sponsored apps (e.g., TikTok) are only provisioned out-of-the-box on Windows 11.</p>
  </div>

  <div class="compat-card">
    <h3>System Core Modules</h3>
    <div class="os-tags">
      <span class="os-tag supported">Win 10 (22H2)</span>
      <span class="os-tag supported">Win 11 (23H2)</span>
      <span class="os-tag supported">Win 11 (24H2)</span>
      <span class="os-tag supported">Win 11 (25H2)</span>
    </div>
    <p class="notes">Includes Visual Effects, Search, Power, Clipboard, Isolation, GPU HAGS, Tasks, Updates, and Telemetry.</p>
  </div>
</div>

### Legend
*   <span class="os-tag supported" style="display:inline-block; margin-bottom:5px;">Supported</span> Fully tested and functional.
*   <span class="os-tag partial" style="display:inline-block; margin-bottom:5px;">Partial</span> Script runs without errors, but the target feature may not exist, or newer OS features bypass the legacy block.
*   ❌ **Unsupported**: Script will fail or cause instability. (Currently, no core modules are unsupported).

### Core Engine Note
The **Core/Restore/** framework is fully functional across Windows PowerShell 5.1 and PowerShell 7+ on both Windows 10 and Windows 11.
