# Contributing to WinAurex

Thank you for your interest in contributing to **WinAurex**! This framework aims to be the gold standard for safe, modular, and observable Windows configuration. We welcome contributions ranging from bug fixes and documentation improvements to entirely new configuration modules.

## Architecture Philosophy
Before proposing changes, please understand the core architecture introduced in **v5.0.0**:
1. **WPF Dashboard**: The user interface is a pure XAML/PowerShell dashboard. We do not use third-party compilation tools.
2. **Reversibility**: Every action must be reversible. Destructive tweaks that permanently break Windows components will not be accepted.
3. **Observability**: Blind registry tweaking is discouraged. We use native `.NET PerformanceCounters` and `Write-FrameworkLog` for telemetry.

## How to Contribute

### 1. Adding a New Script (Module)
If you are adding a new optimization module (a `.ps1` file):
- Place the file in the appropriate `Tweaks/` subfolder.
- The script **must** use `#Requires -RunAsAdministrator` if it requires elevation.
- The script **must** leverage `Core/Restore/Snapshot_Registry_Keys.ps1` if modifying complex registry keys.
- Write a clear `Write-Host` or `Write-FrameworkLog` output explaining what the script is doing.
- No obfuscation or compiled binaries allowed.

### 2. Updating the WPF Dashboard
If your script introduces a major feature that should be accessible via the GUI:
1. Open `GUI/Dashboard.xaml` and add the UI Element (e.g., a Button or CheckBox). Assign it an `x:Name`.
2. Open `Launch_Dashboard.ps1` and locate the matching Named Element Handle.
3. Wire the `.Add_Click({ ... })` event to invoke your script seamlessly.

### 3. Submitting a Pull Request
1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`.
3. Test your script on both Windows 10 and Windows 11 (if applicable).
4. Do not commit local backup files (`Core/Restore/Backups/`) or user logs (`Logs/`).
5. Ensure the documentation (`docs/` and `mkdocs.yml`) is updated if you added a major feature.
6. Push and open a PR!

## Code of Conduct
By participating in this project, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Local Development
To run the documentation site locally:
```bash
pip install -r requirements.txt
mkdocs serve
```
