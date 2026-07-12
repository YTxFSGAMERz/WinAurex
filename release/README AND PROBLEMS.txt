In this document, I will show you what you need for your computer to work correctly
with this system and get the maximum benefits possible.

=== First Step | Install Drivers ===

Drivers are necessary for your components to work correctly and give the best performance.
They are used for the computer to communicate with the PC efficiently.

To install the drivers, you need an internet connection. If your device currently doesn't have it
or is not working correctly, I recommend using a cell phone to get internet.
To do this, you need to connect the phone to the PC and activate the "Internet Connection to PC" method if it supports it
(If you need it, you can search for information on the internet for your device)

After having an internet connection, you can use the "Drivers" folder that is in this folder. There are utilities
that will help you install the best drivers for your computer. My recommendation is that you use "Driver Booster"
and "Driver Identifier" for the best results.

Mainly, I recommend installing the video driver to get higher screen resolution and prevent games from having issues.

=== Second Step | Install Browsers ===

Browsers are the programs you use to search the internet, mainly recognized as "Google". The Store is a modern
Windows application used to install apps more easily and exclusively.

To get browsers, you can use the "Browsers" folder where some of the most recognized worldwide are located.
It's very easy to install, just double-click any of them and it will install automatically.

=== Last Step | Extra Recommendations ===

Mainly, we would like to recommend that you don't use antivirus. It may sound strange, but nowadays they are not worth as much as they were years ago,
due to the emergence of online websites like VirusTotal to analyze files without needing any downloaded antivirus, or tria.ge that
analyzes the executable from the root to see its behavior. It's your decision whether to use it or not.

=== Directory Overview ===

This Windows Optimisation v5.0.0 package is organized into several folders, each with a clear purpose. Below is a simple, user‑friendly overview of what you will find.

Activators
  Contains tools for activating Windows.
  - Windows Activators/AAct_x64.exe: A popular activation utility.
  - Windows Activators/MassGrave.cmd: A script for activating various Windows versions.

Antivirus
  Antivirus installers and a help file.
  - HELP.txt: General help/readme for the antivirus tools.
  - Kaspersky.exe: Kaspersky Internet Security installer.
  - MBSetup.exe: Malwarebytes setup.
  - eset_internet_security_live_installer.exe: ESET Internet Security installer.

Browsers
  Installers for common web browsers.
  - BraveBrowserSetup-BRV010.exe: Brave browser.
  - ChromeSetup.exe: Google Chrome.
  - Firefox Installer.exe: Mozilla Firefox.
  - Internet Explorer 11.bat: Script to enable/install IE11 if needed.
  - OperaGXSetup.exe: Opera GX browser.
  - OperaSetup.exe: Opera browser.
  - RECOMMENDATIONS.txt: Advice on which browsers to choose.

Build
  Build and release scripts.
  - Build_Release.ps1: PowerShell script to create a release build.

Core
  Core system optimization and restore components.
  - Config/FrameworkConfig.json: Configuration for the optimization framework.
  - Helpers/Logging.psm1: PowerShell logging helper.
  - Restore/: Tools for creating and managing system restore points.
    - Create_System_Restore_Point.ps1: Creates a manual restore point.
    - Engine/: Contains RestoreEngine.psm1, SnapshotEngine.psm1, ValidationEngine.psm1.
    - Export_Current_Settings.ps1: Exports current Windows settings.
    - Restore_All_Defaults.ps1: Resets Windows to default settings.
    - Rollback_Interactive.ps1: Interactive rollback of changes.
    - Rollback_Last_Changes.ps1: Rolls back the last applied changes.
    - Snapshot_Registry_Keys.ps1: Backs up registry keys.

Drivers
  Driver installation utilities.
  - 3DP Chip.exe: Detects and downloads drivers.
  - Driver Booster.exe: Driver Booster installer.
  - RECOMMENDATION.txt: Tips on driver installation order.
  - driveridentifier_setup.exe: Driver Identifier installer.

Extra
  A collection of useful extra tools.
  - 7z2501-x64.exe, 7z2501.exe: 7‑Zip archiver (64‑bit and 32‑bit).
  - AnyDesk.exe: Remote desktop software.
  - CRU.exe: Custom Resolution Utility for monitor tweaks.
  - Everything-1.4.1.1024.x86-Setup.exe: Everything search engine installer.
  - IObit Unlocker/: Suite to unlock locked files (includes DLL, EXE, SYS, extension DLL).
  - Interrupt Affinity Policy Tool.exe: Sets CPU interrupt affinity.
  - Lightshot.exe: Screenshot tool.
  - MSI Utility V3.exe: MSI motherboard utilities.
  - Process Explorer.exe: Advanced process monitoring (Sysinternals).
  - SteamSetup.exe: Steam gaming platform installer.
  - TCPOptimizer.exe: TCP/IP optimizer for internet speed.
  - Tetris_GameBoy.exe: Simple Tetris game (for fun/testing).
  - Winaero Tweaker.exe: Advanced Windows customization tool.
  - memreduct-3.4-setup.exe: Memory reducer installer.
  - rufus-3.22p.exe: Bootable USB creator.
  - serviwin.exe: Service and driver viewer.
  - uwd.exe: Unknown Windows Device utility.
  - winrar-x64-623.exe: WinRAR archiver.

GUI
  Graphical user interface components.
  - Dashboard.xaml: Main dashboard UI definition (for a WPF application).

Hardware
  Hardware monitoring and information tools.
  - CPU-Z.exe: CPU information and benchmarking.
  - GPU-Z.exe: GPU information and monitoring.
  - HW-Monitor.exe: Monitors temperatures, fans, voltages.

Launchers
  Scripts to create shortcuts and initialize the framework.
  - Create_Shortcut.ps1: Creates desktop or start menu shortcuts.
  - Initialize_Framework.ps1: Initializes the optimization framework on first run.

Profiles
  PowerShell profiles for different optimization presets.
  - Balanced_Creator_Profile.ps1: Balanced settings for content creators.
  - Enterprise_Compliance_Profile.ps1: Settings compliant with enterprise policies.
  - Max_Performance_Profile.ps1: Maximum performance settings (may affect battery life).

Tools
  Various utility scripts grouped by purpose.
  - Apps/Install_Essential_Apps_WinGet.ps1: Installs essential apps via Windows Package Manager (winget).
  - Benchmark/: Performance measurement tools.
    - Integrations/Detect_ThirdParty.psm1: Detects third‑party benchmarking integrations.
    - Native/: Native PowerShell benchmark scripts.
      - Analyze_Frame_Timing.ps1: Analyzes frame timing (gaming performance).
      - Generate_System_Performance_Report.ps1: Generates a full system performance report.
      - Measure_Boot_Time.ps1: Measures Windows boot time.
  - Repair/: Troubleshooting and repair scripts.
    - Repair_Audio.ps1: Fixes common audio issues.
    - Repair_Network.ps1: Resets network adapters and settings.
    - Repair_Windows_Update.ps1: Repairs Windows Update components.
    - Run_SFC_And_DISM.ps1: Runs System File Checker and DISM to repair system files.
  - System-Info/: System information gathering tools.
    - Clean_Framework_Logs.ps1: Clears logs generated by this framework.
    - Generate_System_Report.ps1: Creates a detailed HTML/system report.

Tweaks
  Registry files, scripts, and resources to apply Windows optimizations, organized by category.
  Each subfolder contains .reg files, .ps1 PowerShell scripts, .bat batch files, and .txt guides.
  Examples of categories:
    - Appearance: Theme and UI tweaks (dark/light theme, Cortana, Action Center, transparency).
    - Apps: Scripts to remove bloatware and unnecessary Microsoft apps.
    - Audio: Audio enhancement controls and exclusive mode manager.
    - Background: Manage background apps to save resources.
    - Boot: Optimize startup and detect slow startup applications.
    - Browser: Edge performance tweaks via registry.
    - Camera: Privacy scripts to disable camera access.
    - Clipboard: Privacy tweaks for clipboard history and cloud sync.
    - Developer: Enable Developer Mode, WSL, long paths; install PowerShell 7 and Windows Terminal.
    - Diagnostics: Disable diagnostic data and tailored experiences.
    - Display: HDR settings, windowed game optimizations, GPU preference management.
    - Drivers: Analyze DPC latency, backup installed drivers, block automatic driver replacement.
    - Explorer: File Explorer productivity tweaks, compact view, classic context menu.
    - GPU: Gaming GPU profile, enable Game Mode, hardware‑accelerated GPU scheduling.
    - Gaming: Enable/disable Game Mode registry toggles.
    - Input: Mouse acceleration tweaks, USB polling diagnostics.
    - Network‑Diagnostics: Reset network stack, test latency to game servers.
    - Network: Bandwidth caps, peer‑to‑peer update toggles.
    - Power: Power plans for desktop/laptop, disable hibernation, USB selective suspend, ultimate performance plan.
    - Privacy: Registry toggles to disable/enable camera, microphone, location, notifications, app metadata.
    - Profiles: Master profiles for Gaming, Privacy, Workstation (apply multiple tweaks at once).
    - Recursos: Miscellaneous resources (CPU mitigations, power plans, priority, memory reduction, SSD optimization, RAM compression, services, telemetry).
    - Resources: Duplicate of some Recursos items for convenience (power plans, RAM compression, temporary file cleanup).
    - Search: Privacy tweaks for Windows Search (disable history, highlights, web search, rebuild index).
    - Security: SmartScreen configuration, firewall profile manager, memory integrity manager.
    - Services: Clean services profile, disable telemetry services.
    - Shell: Minimal shell, disable Copilot/taskbar spam, notifications, widgets, recommended section.
    - Startup: Manage startup applications.
    - Storage‑Advanced: SSD health analysis, TRIM status, pagefile optimization.
    - Storage‑Aggressive: Deep component cleanup (aggressive mode).
    - Storage: Storage Sense enable/disable toggles.
    - Sync: Privacy tweaks for activity history and Windows Settings sync, OneDrive uninstaller.
    - Tasks: Clean tasks profile, disable telemetry tasks.
    - Troubleshooting: Interactive clean boot manager.
    - Updates: Update control profile, disable automatic driver updates, disable delivery optimization.
    - Visual: Aesthetic and performance visual tweaks (transparency, animations, menu show delay).

WebView - IMPORTANT
  Information about the WebView component used in the dashboard.
  - DATA AND PURPOSE.txt: Explains what data is collected and the purpose of the WebView.

Windows Update
  Scripts to control the Windows Update service.
  - Disable Windows Update.bat: Disables Windows Update (use with caution).
  - Enable Windows Update.bat: Re‑enables Windows Update.
  - RECOMMENDATIONS.txt: Advice on when to disable/enable updates.

Root Files
  - Launch_Dashboard.ps1: Main script to launch the optimization dashboard GUI.
  - Start.bat: Batch file to start the optimization process (may call Launch_Dashboard.ps1).
  - Patch_Batch.ps1, Patch_Everything.ps1, Patch_Force_Args.ps1, Patch_Pauses.ps1: Various patching and optimization scripts.
  - RestartDWM.exe: Utility to restart Desktop Window Manager (fixes graphical glitches).
  - autounattend.xml: Windows unattended installation answer sheet (for automated Windows setup).
  - README AND PROBLEMS.txt: This file you are reading.

=== How to Use ===

1. Run Start.bat or execute Launch_Dashboard.ps1 to open the main dashboard.
2. From the dashboard you can apply tweaks, install drivers/browsers, run benchmarks, or create system restore points.
3. For specific tasks, go to the relevant folder and run the appropriate .ps1, .bat, or .reg file.
4. Always create a system restore point (via Core\Restore\Create_System_Restore_Point.ps1) before applying major changes.
5. Check individual .txt files in each folder for detailed instructions and recommendations.

=== Notes ===

- Some scripts require administrative privileges. Right‑click and choose "Run as administrator" when prompted.
- Antivirus tools are provided but not required; the author suggests relying on online scanners such as VirusTotal.
- The WebView component may collect anonymous usage data; see WebView - IMPORTANT/DATA AND PURPOSE.txt for details.