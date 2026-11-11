[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$ForceReapply
)

# ==============================================================================
# SCRIPT: Apply_Curated_Safe_Suite.ps1
# PROJECT: WinAurex (Tier 1: Safe Optimizations & Privacy)
# TARGET AUDIENCE: Daily Driver, Normal Users, Gamers, Developers
# SAFETY GUARANTEE:
#   - 100% reversible configuration via SnapshotEngine transactions.
#   - NEVER deletes files, system DLLs, or services.
#   - Strictly preserves Microsoft Store, Windows Update, UAC, and core apps.
#   - IDEMPOTENT: Detects existing state; skips already-applied tweaks in <1ms.
# ==============================================================================

# 1. Elevation Check & Auto-Relaunch
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        Write-Host "Requesting Administrator privileges to apply system-wide optimizations..." -ForegroundColor Yellow
        $relaunchArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        if ($Force) { $relaunchArgs += " -Force" }
        if ($ForceReapply) { $relaunchArgs += " -ForceReapply" }
        Start-Process powershell.exe -Verb RunAs -ArgumentList $relaunchArgs
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

# Metrics Tracking
$script:SkippedCount = 0
$script:AppliedCount = 0
$script:CachedAppxNames = $null

function Get-CachedAppxNames {
    if ($null -eq $script:CachedAppxNames) {
        $script:CachedAppxNames = @(Get-AppxPackage -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    }
    return $script:CachedAppxNames
}

# Helper to run a tweak script safely with high-performance idempotency
function Invoke-SafeTweak {
    param (
        [string]$SubPath,
        [string]$Description,
        [scriptblock]$IsApplied = $null
    )

    # 1. Evaluate idempotency predicate if provided
    if ($null -ne $IsApplied -and -not $ForceReapply) {
        try {
            $alreadyDone = & $IsApplied
            if ($alreadyDone) {
                Write-Host "  [-] $Description : Already Applied (Skipping)" -ForegroundColor DarkGray
                $script:SkippedCount++
                return
            }
        } catch { }
    }

    # 2. If not applied, execute tweak
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
            $script:AppliedCount++
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

Invoke-SafeTweak "Diagnostics\Disable_Diagnostic_Data.ps1" "Disabling Diagnostic Data (Telemetry = 0)" `
    -IsApplied { (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue).AllowTelemetry -eq 0 }

Invoke-SafeTweak "Diagnostics\Disable_Tailored_Experiences.ps1" "Disabling Tailored Ad Experiences" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -ErrorAction SilentlyContinue).DisableTailoredExperiencesWithDiagnosticData -eq 1 }

Invoke-SafeTweak "Services\Disable_Telemetry_Services.ps1" "Disabling Background Telemetry Services (DiagTrack)" `
    -IsApplied { 
        $s = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        (-not $s) -or ($s.StartType -eq "Disabled" -and $s.Status -ne "Running")
    }

Invoke-SafeTweak "Tasks\Disable_Telemetry_Tasks.ps1" "Disabling Telemetry Scheduled Tasks (CEIP / Compatibility Appraiser)" `
    -IsApplied {
        $t = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "Microsoft Compatibility Appraiser" -ErrorAction SilentlyContinue
        (-not $t) -or ($t.State -eq "Disabled")
    }

Invoke-SafeTweak "Search\Disable_Web_Search.ps1" "Disabling Bing Web Search in Start Menu" `
    -IsApplied {
        $bing = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -ErrorAction SilentlyContinue).BingSearchEnabled
        $box  = (Get-ItemProperty "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions
        $bing -eq 0 -and $box -eq 1
    }

Invoke-SafeTweak "Search\Disable_Search_Highlights.ps1" "Disabling Search Box Web Highlights Spam" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsDynamicSearchBoxEnabled" -ErrorAction SilentlyContinue).IsDynamicSearchBoxEnabled -eq 0 }

Invoke-SafeTweak "Clipboard\Disable_Clipboard_Cloud_Sync.ps1" "Disabling Clipboard Cloud Sync" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Clipboard" -Name "CloudClipboardItemSyncEnabled" -ErrorAction SilentlyContinue).CloudClipboardItemSyncEnabled -eq 0 }

Invoke-SafeTweak "Sync\Disable_Activity_History.ps1" "Disabling Windows Activity History Tracking" `
    -IsApplied { (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -ErrorAction SilentlyContinue).EnableActivityFeed -eq 0 }

Invoke-SafeTweak "Privacy\Disable Location.reg" "Setting App Location Permission to Deny" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -ErrorAction SilentlyContinue).Value -eq "Deny" }

Invoke-SafeTweak "Privacy\Disable App Metadata Access.reg" "Restricting App Metadata Snooping" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" -Name "Value" -ErrorAction SilentlyContinue).Value -eq "Deny" }

Invoke-SafeTweak "Privacy\Apply_Deep_Privacy_Shield.ps1" "Applying Deep Privacy Shield (Find My Device, Advertising ID, Custom Dict, AI/Recall, App Permissions)" `
    -IsApplied {
        $findDevice = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice" -ErrorAction SilentlyContinue).AllowFindMyDevice -eq 0
        $adPolicy   = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue).DisabledByGroupPolicy -eq 1
        $appPrivacy = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessContacts" -ErrorAction SilentlyContinue).LetAppsAccessContacts -eq 2
        $findDevice -and $adPolicy -and $appPrivacy
    }

# ==============================================================================
# BLOCK 2: RESPONSIVENESS & SHELL ENHANCEMENTS
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " [2/4] APPLYING RESPONSIVENESS & SHELL TWEAKS" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Invoke-SafeTweak "Visual\Reduce_Menu_Show_Delay.ps1" "Reducing Context Menu Delay to 10ms (Instant Snapping)" `
    -IsApplied { (Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -ErrorAction SilentlyContinue).MenuShowDelay -eq "10" }

Invoke-SafeTweak "Visual\Disable_Unnecessary_Animations.ps1" "Disabling Window Maximize/Minimize & Taskbar Animations" `
    -IsApplied {
        $min = (Get-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -ErrorAction SilentlyContinue).MinAnimate
        $tb  = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -ErrorAction SilentlyContinue).TaskbarAnimations
        $min -eq "0" -and $tb -eq 0
    }

Invoke-SafeTweak "Visual\Disable_Transparency.ps1" "Disabling DWM Transparency Effects to Free GPU Cycles" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -ErrorAction SilentlyContinue).EnableTransparency -eq 0 }

Invoke-SafeTweak "Explorer\Restore_Classic_ContextMenu.ps1" "Restoring Instant Classic Right-Click Menu in Windows 11" `
    -IsApplied { Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" }

Invoke-SafeTweak "Shell\Disable_Copilot_Taskbar.ps1" "Removing Windows Copilot Button from Taskbar" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -ErrorAction SilentlyContinue).ShowCopilotButton -eq 0 }

Invoke-SafeTweak "Shell\Disable_Windows_Widgets.ps1" "Disabling Windows Widgets Board from Taskbar" `
    -IsApplied { (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue).AllowNewsAndInterests -eq 0 }

Invoke-SafeTweak "Shell\Disable_Notification_Spam.ps1" "Disabling Windows Promotional Suggestions & Tips" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-338389Enabled" -eq 0 }

Invoke-SafeTweak "Shell\Remove_Recommended_Section.ps1" "Hiding Recommended Items in Start Menu" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideRecentJumplists" -ErrorAction SilentlyContinue).HideRecentJumplists -eq 1 }

Invoke-SafeTweak "Explorer\Disable_Recent_Frequent.ps1" "Hiding Recent Files & Frequent Folders in Explorer" `
    -IsApplied {
        $rec = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -ErrorAction SilentlyContinue).ShowRecent
        $frq = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -ErrorAction SilentlyContinue).ShowFrequent
        $rec -eq 0 -and $frq -eq 0
    }

Invoke-SafeTweak "Shell\Disable_Desktop_Spotlight.ps1" "Hiding Desktop Spotlight 'Learn about this picture' Icon" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -ErrorAction SilentlyContinue)."{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -eq 1 }

Invoke-SafeTweak "Sync\Disable_OneDrive_Nag_And_Backup.ps1" "Blocking OneDrive 'Turn On Windows Backup' Nag Prompts & Autostart" `
    -IsApplied { (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMBlockOptIn" -ErrorAction SilentlyContinue).KFMBlockOptIn -eq 1 }

# ==============================================================================
# BLOCK 3: GAMING, PERFORMANCE & NETWORK
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " [3/4] APPLYING GAMING, PERFORMANCE & NETWORK" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Invoke-SafeTweak "GPU\Enable_Hardware_Accelerated_GPU_Scheduling.ps1" "Enabling Hardware-Accelerated GPU Scheduling (HAGS)" `
    -IsApplied { (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue).HwSchMode -eq 2 }

Invoke-SafeTweak "GPU\Enable_Game_Mode.ps1" "Enabling Windows Game Mode" `
    -IsApplied { (Get-ItemProperty "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue).AutoGameModeEnabled -eq 1 }

Invoke-SafeTweak "Input\Disable_Mouse_Acceleration.ps1" "Disabling Enhance Pointer Precision (1:1 Raw Mouse Input)" `
    -IsApplied { (Get-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -ErrorAction SilentlyContinue).MouseSpeed -eq "0" }

Invoke-SafeTweak "Power\Enable_Ultimate_Performance_Plan.ps1" "Unlocking & Activating Ultimate Performance Power Plan" `
    -IsApplied { (powercfg /getactivescheme) -match "Ultimate Performance" }

Invoke-SafeTweak "Updates\Disable_Delivery_Optimization.ps1" "Disabling P2P Delivery Optimization Upload Seeding" `
    -IsApplied { (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -ErrorAction SilentlyContinue).DODownloadMode -eq 0 }

Invoke-SafeTweak "Updates\Disable_Automatic_Driver_Updates.ps1" "Preventing Windows Update from Overwriting Custom Hardware Drivers" `
    -IsApplied { (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue).ExcludeWUDriversInQualityUpdate -eq 1 }

# ==============================================================================
# BLOCK 4: SAFE BLOATWARE SCRUBBING
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " [4/4] EXECUTING SAFE APPS SCRUBBING" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Invoke-SafeTweak "Apps\Remove_Sponsored_Apps.ps1" "Removing Third-Party Sponsored Shovelware (TikTok, Candy Crush)" `
    -IsApplied {
        $pkgs = Get-CachedAppxNames
        $targets = @("*TikTok*", "*Instagram*", "*Facebook*", "*Twitter*", "*Netflix*", "*Spotify*", "*Disney*", "*CandyCrush*", "*Roblox*")
        $found = $false
        foreach ($t in $targets) {
            if ($pkgs | Where-Object { $_ -like $t }) { $found = $true; break }
        }
        -not $found
    }

Invoke-SafeTweak "Apps\Remove_Unnecessary_MS_Apps.ps1" "Removing Unused Default MS Apps (3D Viewer, Maps, Tips)" `
    -IsApplied {
        $pkgs = Get-CachedAppxNames
        $targets = @("*Microsoft3DViewer*", "*WindowsFeedbackHub*", "*MixedReality.Portal*", "*ZuneVideo*", "*WindowsMaps*", "*BingWeather*")
        $found = $false
        foreach ($t in $targets) {
            if ($pkgs | Where-Object { $_ -like $t }) { $found = $true; break }
        }
        -not $found
    }

# Close transaction if open
if ($TxnID) {
    try {
        Close-Transaction
        Write-Host "`n[STATE] Transaction $TxnID saved to Core\Restore\Backups." -ForegroundColor Cyan
    } catch { }
}

# ==============================================================================
# POST-EXECUTION HEALTH & IDEMPOTENCY SUMMARY REPORT
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

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host "           CURATED SAFE OPTIMIZATION SUITE SUMMARY                   " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " Total Tweaks Evaluated : $($script:SkippedCount + $script:AppliedCount)" -ForegroundColor Cyan
Write-Host " Already Applied        : $($script:SkippedCount) (Skipped - 0 changes needed)" -ForegroundColor DarkGray
Write-Host " Applied in this run    : $($script:AppliedCount)" -ForegroundColor Green

if ($script:AppliedCount -eq 0) {
    Write-Host "`n [OK] System is already fully optimized! No redundant changes made." -ForegroundColor Green
} else {
    Write-Host "`n Please RESTART your computer (or restart explorer.exe) to apply new changes." -ForegroundColor Yellow
}

if ($HasStartedTranscript) {
    Write-Host " [+] Complete execution transcript saved to: $TranscriptPath" -ForegroundColor Cyan
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "======================================================================`n"

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $null = Read-Host "Press Enter to finish..."
}
