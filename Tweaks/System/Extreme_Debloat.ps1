# ==========================================
# Extreme Debloat Script for WinAurex
# ==========================================
Write-Host "Running Extreme Debloat..."

# 1. Disable More Telemetry & Bloat Services
$servicesToDisable = @(
    "DiagTrack",       # Connected User Experiences and Telemetry
    "dmwappushservice",# WAP Push Message Routing Service
    "WSearch",         # Windows Search (extreme debloat often disables indexing)
    "MapsBroker",      # Downloaded Maps Manager
    "lfsvc",           # Geolocation Service
    "XblAuthManager",  # Xbox Live Auth Manager
    "XblGameSave",     # Xbox Live Game Save
    "XboxNetApiSvc",   # Xbox Live Networking Service
    "WaaSMedicSvc",    # Windows Update Medic Service
    "DusmSvc"          # Data Usage
)
foreach ($svc in $servicesToDisable) {
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# 2. Prevent OneDrive Setup
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f
reg.exe delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
Remove-Item -Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\System32\OneDriveSetup.exe" -Force -ErrorAction SilentlyContinue

# 3. Disable Automatic App Downloads (Candy Crush, etc)
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f

# 4. Remove Capabilities (Features on Demand)
$caps = @(
    "App.StepsRecorder~~~~0.0.1.0",
    "MathRecognizer~~~~0.0.1.0",
    "Microsoft.Windows.WordPad~~~~0.0.1.0",
    "Print.Fax.Scan~~~~0.0.1.0",
    "WMI-SNMP-Provider.Client~~~~0.0.1.0",
    "Browser.InternetExplorer~~~~0.0.11.0",
    "Media.WindowsMediaPlayer~~~~0.0.12.0",
    "Hello.Face.18967~~~~0.0.1.0"
)
foreach ($cap in $caps) {
    Remove-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue
}

# 5. Disable More Scheduled Tasks
$tasksToDisable = @(
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\AppID\SmartScreenSpecific",
    "\Microsoft\Windows\Location\Notifications",
    "\Microsoft\Windows\Maps\MapsToastTask",
    "\Microsoft\Windows\Maps\MapsUpdateTask"
)
foreach ($task in $tasksToDisable) {
    Disable-ScheduledTask -TaskPath (Split-Path $task) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue
}

# 6. Disable Windows Defender (Basic Registry Method)
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f

# 7. Disable System Intelligence, AI, and Copilot Features
# Disable Copilot
reg.exe add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
reg.exe add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f

# Disable Recall (Windows 11 24H2+)
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRecall /t REG_DWORD /d 1 /f
reg.exe add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRecall /t REG_DWORD /d 1 /f

# Disable SmartScreen for Edge and Windows
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f
reg.exe add "HKCU\SOFTWARE\Policies\Microsoft\MicrosoftEdge\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 0 /f

# Disable Windows Ink Workspace
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" /v AllowWindowsInkWorkspace /t REG_DWORD /d 0 /f

# Disable Typing Insights and Auto-Correction (AI typing features)
reg.exe add "HKCU\Software\Microsoft\Input\Settings" /v "MultilingualEnabled" /t REG_DWORD /d 0 /f
reg.exe add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f

# Disable Taskbar Web Search (Prevents Bing AI web results)
reg.exe add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f

Write-Host "Extreme Debloat Completed."
