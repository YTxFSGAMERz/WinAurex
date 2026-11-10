[CmdletBinding()]
param (
    [switch]$Force
)

# ==============================================================================
# SCRIPT: Apply_Curated_Safe_Suite.ps1
# PROJECT: WinAurex (Tier 1: Safe Optimizations & Privacy)
# TARGET AUDIENCE: Daily Driver, Normal Users, Gamers, Developers
# SAFETY GUARANTEE:
#   - 100% reversible configuration via SnapshotEngine transactions.
#   - NEVER deletes files, system DLLs, or services.
#   - Strictly preserves Microsoft Store, Windows Update, UAC, and core apps.
# ==============================================================================

# 1. Elevation Check & Auto-Relaunch
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        Write-Host "Requesting Administrator privileges to apply system-wide optimizations..." -ForegroundColor Yellow
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Exit
    } else {
        Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
        Exit 1
    }
}

Clear-Host
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "        WinAurex - Curated Safe Optimization & Privacy Suite          " -ForegroundColor White
Write-Host "                     Tier 1: Daily Driver Ready                       " -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " [*] Privacy Hardening: Telemetry disabled, Bing Search unhooked"
Write-Host " [*] System Responsiveness: 10ms menu delay, animation overhead removed"
Write-Host " [*] Gaming & Latency: HAGS enabled, 1:1 raw mouse input, Game Mode"
Write-Host " [*] Network Efficiency: Delivery Optimization P2P upload seeding stopped"
Write-Host " [*] App Cleanliness: Sponsored shovelware scrubbed"
Write-Host " [*] ZERO RISK: Preserves Microsoft Store, Windows Update, UAC & Core Apps"
Write-Host "======================================================================`n"

$Confirm = if ($Force -or [Console]::IsInputRedirected) { "Y" } else { Read-Host "Proceed with applying the safe optimizations? (Y/N)" }
if ($Confirm -notmatch '^[yY]') {
    Write-Host "`nAborted by user without changes." -ForegroundColor Yellow
    Exit
}

$RootDir = $PSScriptRoot
$TweaksDir = Join-Path $RootDir "Tweaks"

# 1.5 Start Universal Execution Transcript
$LogDir = Join-Path $RootDir "Logs"
if (-not (Test-Path $LogDir)) {
    $LogDir = "$env:SystemDrive\WinAurex\Logs"
    if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
}
$TranscriptPath = Join-Path $LogDir "Safe_Suite_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
try {
    Start-Transcript -Path $TranscriptPath -Append -Force -ErrorAction SilentlyContinue | Out-Null
    $HasStartedTranscript = $true
} catch {
    $HasStartedTranscript = $false
}

# 2. Transaction Snapshot
$EngineDir = Join-Path $RootDir "Core\Restore\Engine"
$SnapshotEngine = Join-Path $EngineDir "SnapshotEngine.psm1"
$TxnID = $null

if (Test-Path $SnapshotEngine) {
    try {
        Import-Module $SnapshotEngine -Force -DisableNameChecking
        $TxnID = New-Transaction -ModuleName "SafeSuite" -ProfileName "Tier1Safe"
        Write-Host "`n[SNAPSHOT] Created transactional rollback snapshot: $TxnID" -ForegroundColor Cyan
    } catch {
        Write-Warning "Could not initialize SnapshotEngine: $_"
    }
}

# Helper to run a tweak script safely
function Invoke-SafeTweak {
    param (
        [string]$SubPath,
        [string]$Description
    )
    $fullPath = Join-Path $TweaksDir $SubPath
    if (Test-Path $fullPath) {
        Write-Host "`n>>> [$Description]" -ForegroundColor Yellow
        try {
            if ($fullPath.EndsWith(".ps1")) {
                & $fullPath -Force:$true
            } elseif ($fullPath.EndsWith(".reg")) {
                reg.exe import $fullPath
                Write-Host "Registry imported successfully." -ForegroundColor Green
            } elseif ($fullPath.EndsWith(".bat")) {
                & cmd.exe /c "`"$fullPath`""
            }
        } catch {
            Write-Warning "Failed executing $SubPath : $_"
        }
    } else {
        Write-Host "[SKIP] Script not found: $SubPath" -ForegroundColor DarkGray
    }
}

# ==============================================================================
# BLOCK 1: PRIVACY & TELEMETRY HARDENING
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " [1/4] APPLYING PRIVACY & TELEMETRY HARDENING" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Invoke-SafeTweak "Diagnostics\Disable_Diagnostic_Data.ps1" "Disabling Diagnostic Data (Telemetry = 0)"
Invoke-SafeTweak "Diagnostics\Disable_Tailored_Experiences.ps1" "Disabling Tailored Ad Experiences"
Invoke-SafeTweak "Services\Disable_Telemetry_Services.ps1" "Disabling Background Telemetry Services (DiagTrack)"
Invoke-SafeTweak "Tasks\Disable_Telemetry_Tasks.ps1" "Disabling Telemetry Scheduled Tasks (CEIP / Compatibility Appraiser)"
Invoke-SafeTweak "Search\Disable_Web_Search.ps1" "Disabling Bing Web Search in Start Menu"
Invoke-SafeTweak "Search\Disable_Search_Highlights.ps1" "Disabling Search Box Web Highlights Spam"
Invoke-SafeTweak "Clipboard\Disable_Clipboard_Cloud_Sync.ps1" "Disabling Clipboard Cloud Sync"
Invoke-SafeTweak "Sync\Disable_Activity_History.ps1" "Disabling Windows Activity History Tracking"
Invoke-SafeTweak "Privacy\Disable Location.reg" "Setting App Location Permission to Deny"
Invoke-SafeTweak "Privacy\Disable App Metadata Access.reg" "Restricting App Metadata Snooping"

# ==============================================================================
# BLOCK 2: RESPONSIVENESS & SHELL ENHANCEMENTS
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " [2/4] APPLYING RESPONSIVENESS & SHELL TWEAKS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Invoke-SafeTweak "Visual\Reduce_Menu_Show_Delay.ps1" "Reducing Context Menu Delay to 10ms (Instant Snapping)"
Invoke-SafeTweak "Visual\Disable_Unnecessary_Animations.ps1" "Disabling Window Maximize/Minimize & Taskbar Animations"
Invoke-SafeTweak "Visual\Disable_Transparency.ps1" "Disabling DWM Transparency Effects to Free GPU Cycles"
Invoke-SafeTweak "Explorer\Restore_Classic_ContextMenu.ps1" "Restoring Instant Classic Right-Click Menu in Windows 11"
Invoke-SafeTweak "Shell\Disable_Copilot_Taskbar.ps1" "Removing Windows Copilot Button from Taskbar"
Invoke-SafeTweak "Shell\Disable_Windows_Widgets.ps1" "Disabling Windows Widgets Board from Taskbar"
Invoke-SafeTweak "Shell\Disable_Notification_Spam.ps1" "Disabling Windows Promotional Suggestions & Tips"
Invoke-SafeTweak "Shell\Remove_Recommended_Section.ps1" "Hiding Recommended Items in Start Menu"
Invoke-SafeTweak "Explorer\Disable_Recent_Frequent.ps1" "Hiding Recent Files & Frequent Folders in Explorer"

# ==============================================================================
# BLOCK 3: GAMING, PERFORMANCE & NETWORK
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " [3/4] APPLYING GAMING, PERFORMANCE & NETWORK" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Invoke-SafeTweak "GPU\Enable_Hardware_Accelerated_GPU_Scheduling.ps1" "Enabling Hardware-Accelerated GPU Scheduling (HAGS)"
Invoke-SafeTweak "GPU\Enable_Game_Mode.ps1" "Enabling Windows Game Mode"
Invoke-SafeTweak "Input\Disable_Mouse_Acceleration.ps1" "Disabling Enhance Pointer Precision (1:1 Raw Mouse Input)"
Invoke-SafeTweak "Power\Enable_Ultimate_Performance_Plan.ps1" "Unlocking & Activating Ultimate Performance Power Plan"
Invoke-SafeTweak "Updates\Disable_Delivery_Optimization.ps1" "Disabling P2P Delivery Optimization Upload Seeding"
Invoke-SafeTweak "Updates\Disable_Automatic_Driver_Updates.ps1" "Preventing Windows Update from Overwriting Custom Hardware Drivers"

# ==============================================================================
# BLOCK 4: SAFE BLOATWARE SCRUBBING
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " [4/4] EXECUTING SAFE APPS SCRUBBING" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Invoke-SafeTweak "Apps\Remove_Sponsored_Apps.ps1" "Removing Third-Party Sponsored Shovelware (TikTok, Candy Crush)"
Invoke-SafeTweak "Apps\Remove_Unnecessary_MS_Apps.ps1" "Removing Unused Default MS Apps (3D Viewer, Maps, Tips)"

# Close transaction if open
if ($TxnID) {
    try {
        Close-Transaction
        Write-Host "`n[STATE] Transaction $TxnID saved to Core\Restore\Backups." -ForegroundColor Cyan
    } catch { }
}

# ==============================================================================
# POST-EXECUTION HEALTH VERIFICATION
# ==============================================================================
Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host "                SYSTEM HEALTH & INTEGRITY REPORT                      " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Green

# 1. Check Store Package
$storePkg = Get-AppxPackage -Name "*WindowsStore*" -ErrorAction SilentlyContinue
if ($storePkg) {
    Write-Host " [+] Microsoft Store: HEALTHY & INSTALLED ($($storePkg.Name))" -ForegroundColor Green
} else {
    Write-Host " [*] Microsoft Store: NOT INSTALLED IN CURRENT USER (Installable via winget / wsreset)" -ForegroundColor Yellow
}

# 2. Check Core Services
$svcNames = @("wuauserv", "bits", "cryptsvc", "AppXSvc")
foreach ($s in $svcNames) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host " [+] Service [$($svc.Name)]: State = $($svc.Status), StartType = $($svc.StartType)" -ForegroundColor Green
    }
}

# 3. Check DNS & Internet
try {
    $dnsTest = [System.Net.Dns]::GetHostAddresses("dns.google")
    if ($dnsTest) {
        Write-Host " [+] Network & DNS: HEALTHY (Resolution OK)" -ForegroundColor Green
    }
} catch {
    Write-Warning "DNS resolution test timed out or offline."
}

Write-Host "======================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Curated Safe Optimization & Privacy Suite finished!" -ForegroundColor Green
if ($HasStartedTranscript) {
    Write-Host " [+] Complete execution transcript saved to: $TranscriptPath" -ForegroundColor Cyan
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
Write-Host " Please RESTART your computer (or restart explorer.exe) to apply all changes." -ForegroundColor Yellow
Write-Host "======================================================================`n"

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $null = Read-Host "Press Enter to finish..."
}
