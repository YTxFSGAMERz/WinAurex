# WinAurex Engineering & UI Guidelines

## 1. Web Bootstrapper Synchronization
- Whenever `apply.ps1` or `install.ps1` in the repository root is updated, the changes must immediately be synchronized to:
  - `docs/public/apply.ps1` and `docs/public/install.ps1` (Vercel CDN static root)
  - `site/apply.ps1` and `site/install.ps1` (Documentation mirror)
- Always verify remote HTTP headers and line counts after deployment to ensure CDN cache invalidation.

## 2. Comprehensive Debloat Standards
- Tweak and debloat scripts must eliminate all three layers of bloatware:
  1. **Package Layer**: Remove both active user packages (`Remove-AppxPackage -AllUsers`) and staging images (`Remove-AppxProvisionedPackage -Online`).
  2. **Policy Layer**: Enforce Group Policy and Explorer preferences in `HKLM` and `HKCU`.
  3. **Task & Process Layer**: Terminate runtime processes and disable scheduled background maintenance tasks.

## 3. Dashboard Navigation & Feature Discovery
- Flagship capabilities (WinAurex AI, PC Cleaner, Rollback Engine) must be accessible from the primary Overview HUD via dedicated Hero Action Cards.
- Navigation labels must use explicit product branding (e.g., `WinAurex AI` instead of ambiguous abbreviations).

## 4. Dynamic Catalog & Multi-Format Execution Architecture
- Expansive script and tool suites (such as `Tweaks/` and `Tools/`) must be dynamically indexed at runtime rather than hardcoding hundreds of static UI elements.
- The execution layer must provide unified support for:
  - PowerShell (`.ps1`) via bypass scope
  - Registry (`.reg`) via silent `reg.exe import`
  - Batch scripts (`.cmd`, `.bat`) via command processor
  - Standalone portable executables (`.exe`) launched safely in background threads
