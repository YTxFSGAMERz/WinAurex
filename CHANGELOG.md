# Changelog

All notable changes to the **Windows Optimization Framework** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
