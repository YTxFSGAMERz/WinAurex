[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$RiskAccepted
)

# ==============================================================================
# SCRIPT: Extreme Debloat (WinAurex Tier 3 - Critical / Heavy Tester)
# TARGET: Isolated Test Environments, Benchmarkers, Custom OS Builders
# SAFETY LEVEL: Critical (Requires explicit 'CONFIRM' or -RiskAccepted)
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

# 0. Safety Guardrail for Heavy Tester Tier
if (-not $RiskAccepted -and -not ($Force -and [Console]::IsInputRedirected)) {
    Write-Host "`n==========================================================" -ForegroundColor Red
    Write-Host "   [CRITICAL WARNING] TIER 3: HEAVY TESTER SCRIPT" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host "This script applies aggressive debloating and feature stripping." -ForegroundColor Yellow
    Write-Host "It is intended strictly for benchmarkers and test virtual machines." -ForegroundColor Yellow
    Write-Host "It will remove default capabilities and secondary scheduled tasks." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Red
    $Confirm = Read-Host "Type 'CONFIRM' (all caps) to proceed, or anything else to abort"
    if ($Confirm -cne 'CONFIRM') {
        Write-Host "`nAborted by user without changes." -ForegroundColor Green
        Exit
    }
}

Write-Host "`n[TIER 3] Executing Extreme Debloat..." -ForegroundColor Cyan

# 1. Disable Background Telemetry & Secondary Services
$servicesToDisable = @(
    "DiagTrack",       # Connected User Experiences and Telemetry
    "dmwappushservice",# WAP Push Message Routing Service
    "WSearch",         # Windows Search (indexing)
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
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f | Out-Null
reg.exe delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f 2>$null | Out-Null

# 3. Disable Automatic App Downloads (Candy Crush, etc)
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null

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
    Remove-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue | Out-Null
}

# 5. Disable Secondary Scheduled Tasks
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
    Disable-ScheduledTask -TaskPath (Split-Path $task) -TaskName (Split-Path $task -Leaf) -ErrorAction SilentlyContinue | Out-Null
}

# 6. Defender Telemetry & Cloud Reporting (Policy based - never delete services)
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 2 /f | Out-Null
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SpynetReporting" /t REG_DWORD /d 0 /f | Out-Null

# 7. Disable System Intelligence, AI, and Copilot Features
reg.exe add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRecall /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRecall /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" /v AllowWindowsInkWorkspace /t REG_DWORD /d 0 /f | Out-Null
reg.exe add "HKCU\Software\Microsoft\Input\Settings" /v "MultilingualEnabled" /t REG_DWORD /d 0 /f | Out-Null
reg.exe add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
reg.exe add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f | Out-Null

# 8. Shell UI Minimalist Adjustments
reg.exe add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableNotificationCenter /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v DisableNotificationCenter /t REG_DWORD /d 1 /f | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableEdgeDesktopShortcutCreation /t REG_DWORD /d 1 /f | Out-Null
Get-ScheduledTask -TaskName "*EdgeUpdate*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# 9. Guarded Microsoft Appx Purge (Strictly preserving Store, Terminal, Calculator, Photos, VCLibs)
Write-Host "Purging non-essential bloatware packages (protecting Store and Core runtimes)..." -ForegroundColor Cyan
$ProtectedAppxRegex = "DesktopAppInstaller|SecHealthUI|VCLibs|UI\.Xaml|Store|Native|WindowsTerminal|Calculator|Photos|Paint|ScreenSketch|Notepad|Appconnector|Services\.Store"

Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -match "Microsoft" -and $_.DisplayName -notmatch $ProtectedAppxRegex } | 
    ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }

Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match "Microsoft" -and $_.NonRemovable -eq $false -and $_.Name -notmatch $ProtectedAppxRegex } | 
    ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue | Out-Null }

Write-Host "`n[SUCCESS] Extreme Debloat script execution completed safely." -ForegroundColor Green
if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $null = Read-Host "`nPress Enter to return..."
}
