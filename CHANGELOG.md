# Changelog

All notable changes to the **Windows Optimization Framework** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.1.0] - 2026-11-22

### Added
- **Official Pre-Built Windows 11 ISOs**: Released pre-compiled, debloated, and verified ISO images across all 3 tiers (Extreme, Moderate, Stable) hosted on Google Drive.
- **High-Speed Guided Direct-Deploy Engine (v2.0)**: Integrated `WinAurexDeploy.cmd` in WinPE, featuring an Archinstall-style text-based interface.
- **Guided Partition Manager**: Interactive storage manager with automated UEFI/GPT partitioning, guided partition creation (OS, EFI FAT32, MSR), partition shrinking for dual-boot, quick format, and volume assignment without raw commands.
- **Automated VMware Testing Harness**: Added `Automate-VMwareTest.ps1` to programmatically launch VMs, capture screen snapshots, and monitor end-to-end installation reaching the desktop.
- **Post-Install Utilities**: Added `SuperDebloat-Ultimate.cmd` and refreshed offline toolsets.

### Changed
- **Replaced Classic Microsoft Setup**: Eliminated legacy Windows `setup.exe` in WinPE, purging ~1.2 GB of setup bloat and using direct DISM apply (`dism /apply-image`) directly to the target partition.
- **WinPE Shell Hardening**: Switched diskpart output parsing from `findstr` to native chained `find /v /i` filters, avoiding WinPE missing binary aborts.
- **Sub-Menu Transitions**: Added screen clearing (`cls`) and centered banners across all installer configuration prompts and partition actions.
- **Documentation Overhaul**: Comprehensive updates across web documentation and repository READMEs with direct Google Drive download links and SHA-256 integrity checksums.

## [5.0.0] - 2026-05-28

### Added
- **GUI Dashboard**: PowerShell + WPF XAML dashboard featuring dark mode, cyber-style glowing elements, and Segoe Fluent icons.
- **Transactional Rollback Engine**: Full snapshot capability via `ValidationEngine.psm1` and `RestoreEngine.psm1`. Registry and Service states are captured to JSON manifests before any profile is applied.
- **Observability Tab**: Real-time native telemetry polling via .NET Diagnostics (DPC latency proxy, Boot Time, Uptime, Process Count) directly within the dashboard.
- **First-Run Onboarding**: Added `Start.bat` and `Initialize_Framework.ps1` to bootstrap the framework, create Desktop shortcuts, and offer System Restore point creation on initial launch.
- **Packaging Pipeline**: Added `Build_Release.ps1` to generate clean, reproducible ZIP artifacts for distribution.

### Changed
- Refactored codebase (91 files) to use `$PSScriptRoot` instead of `$MyInvocation.MyCommand.Definition` to support nested script execution within the Dashboard runspace.
- Renamed blocking setup scripts to `Interactive_*.ps1` to ensure automated test suites pass without stalling.

### Removed
- Removed legacy command-line-only orchestrator logic in favor of the unified UI Dashboard.
