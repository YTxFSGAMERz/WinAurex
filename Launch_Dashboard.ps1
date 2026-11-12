[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Launch Dashboard (Launch_Dashboard.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

# Required Assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$RootPath = $PSScriptRoot
$XamlPath = Join-Path -Path $RootPath -ChildPath "GUI\Dashboard.xaml"

if (-not (Test-Path $XamlPath)) {
    Write-Host "[ERROR] Dashboard.xaml not found at $XamlPath" -ForegroundColor Red
    Exit
}

# Import Engine for Rollback Tab
$EngineDir = Join-Path -Path $RootPath -ChildPath "Core\Restore\Engine"
Import-Module (Join-Path -Path $EngineDir -ChildPath "ValidationEngine.psm1") -DisableNameChecking -Force
Import-Module (Join-Path -Path $EngineDir -ChildPath "RestoreEngine.psm1") -DisableNameChecking -Force
$BackupsDir = Join-Path -Path $RootPath -ChildPath "Core\Restore\Backups"

# Import PC Cleaner Engine
$CleanerModule = Join-Path -Path $RootPath -ChildPath "Tools\Cleaner\WinAurex-Cleaner.psm1"
if (Test-Path $CleanerModule) {
    Import-Module $CleanerModule -DisableNameChecking -Force
}

# Import Dynamic Catalog Engine for Tweaks & Tools
$CatalogModule = Join-Path -Path $RootPath -ChildPath "Core\Helpers\CatalogEngine.psm1"
if (Test-Path $CatalogModule) {
    Import-Module $CatalogModule -DisableNameChecking -Force
}

# Load XAML
[xml]$Global:xmlWPF = Get-Content -Path $XamlPath
$StringReader = New-Object System.IO.StringReader $Global:xmlWPF.OuterXml
$XmlReader = [System.Xml.XmlReader]::Create($StringReader)
$Window = [Windows.Markup.XamlReader]::Load($XmlReader)

# Helper function to find WPF controls by Name
function Find-Control {
    param([string]$Name)
    $Window.FindName($Name)
}

# Hook Controls
$BtnWinMinimize = Find-Control "BtnWinMinimize"
$BtnWinMaximize = Find-Control "BtnWinMaximize"
$BtnWinClose    = Find-Control "BtnWinClose"

# Sidebar Navigation Controls
$NavOverview      = Find-Control "NavOverview"
$NavAiOptimizer   = Find-Control "NavAiOptimizer"
$NavTweaks        = Find-Control "NavTweaks"
$NavToolsHub      = Find-Control "NavToolsHub"
$NavSoftwareHub   = Find-Control "NavSoftwareHub"
$NavObservability = Find-Control "NavObservability"
$NavPcCleaner     = Find-Control "NavPcCleaner"
$NavProfiles      = Find-Control "NavProfiles"
$NavRollback      = Find-Control "NavRollback"

# Content Views
$ViewOverview      = Find-Control "ViewOverview"
$ViewProfiles      = Find-Control "ViewProfiles"
$ViewAiOptimizer   = Find-Control "ViewAiOptimizer"
$ViewTweaks        = Find-Control "ViewTweaks"
$ViewToolsHub      = Find-Control "ViewToolsHub"
$ViewSoftwareHub   = Find-Control "ViewSoftwareHub"
$ViewObservability = Find-Control "ViewObservability"
$ViewPcCleaner     = Find-Control "ViewPcCleaner"
$ViewRollback      = Find-Control "ViewRollback"

# Overview HUD Controls
$BtnExecutiveBoost   = Find-Control "BtnExecutiveBoost"
$BtnNavToAi          = Find-Control "BtnNavToAi"
$TxtHudAiScore       = Find-Control "TxtHudAiScore"
$TxtHudAiState       = Find-Control "TxtHudAiState"
$TxtHudCpuName       = Find-Control "TxtHudCpuName"
$TxtHudCpuCores      = Find-Control "TxtHudCpuCores"
$TxtHudRamTotal      = Find-Control "TxtHudRamTotal"
$TxtHudRamUsed       = Find-Control "TxtHudRamUsed"
$TxtHudOsBuild       = Find-Control "TxtHudOsBuild"
$TxtHudPowerPlan     = Find-Control "TxtHudPowerPlan"
$TxtHudHealthGrade   = Find-Control "TxtHudHealthGrade"
$TxtHudHealthScore   = Find-Control "TxtHudHealthScore"
$TxtHudProcessCount  = Find-Control "TxtHudProcessCount"
$TxtHudThreadCount   = Find-Control "TxtHudThreadCount"
$TxtHudHandleCount   = Find-Control "TxtHudHandleCount"
$TxtHudLatencyStatus = Find-Control "TxtHudLatencyStatus"

# Sidebar Telemetry & Actions
$TxtSidebarRam       = Find-Control "TxtSidebarRam"
$ProgressSidebarRam  = Find-Control "ProgressSidebarRam"
$BtnSidebarFlushRam  = Find-Control "BtnSidebarFlushRam"

# Software Hub Extended Controls
$TxtSoftwareSearch   = Find-Control "TxtSoftwareSearch"
$BtnFilterBrowsers   = Find-Control "BtnFilterBrowsers"
$BtnFilterGaming     = Find-Control "BtnFilterGaming"
$BtnFilterDev        = Find-Control "BtnFilterDev"
$ProgressSoftware    = Find-Control "ProgressSoftware"

$BtnApplyMaxPerf = Find-Control "BtnApplyMaxPerf"
$BtnApplyBalanced = Find-Control "BtnApplyBalanced"
$BtnApplyEnterprise = Find-Control "BtnApplyEnterprise"
$BtnAnalyzeFrameTiming = Find-Control "BtnAnalyzeFrameTiming"
$BtnMeasureBootTime = Find-Control "BtnMeasureBootTime"
$BtnGenerateReport = Find-Control "BtnGenerateReport"
$BtnDetectThirdParty = Find-Control "BtnDetectThirdParty"
$ListTransactions = Find-Control "ListTransactions"
$BtnRefreshTransactions = Find-Control "BtnRefreshTransactions"
$TxtTransactionDetails = Find-Control "TxtTransactionDetails"
$BtnRollbackSelected = Find-Control "BtnRollbackSelected"
$TxtStatus = Find-Control "TxtStatus"

# Observability UI Hooks
$TxtDpcLatency = Find-Control "TxtDpcLatency"
$TxtMemAvailable = Find-Control "TxtMemAvailable"
$TxtUptime = Find-Control "TxtUptime"
$TxtProcessCount = Find-Control "TxtProcessCount"
$TxtThreadCount = Find-Control "TxtThreadCount"
$TxtHandleCount = Find-Control "TxtHandleCount"

# Tweaks & Debloat UI Hooks
$BtnOptimizeServices = Find-Control "BtnOptimizeServices"
$BtnDebloatOS        = Find-Control "BtnDebloatOS"
$BtnReduceThreads    = Find-Control "BtnReduceThreads"
$BtnDisableDefender  = Find-Control "BtnDisableDefender"
$BtnDisableDefenderPermanent = Find-Control "BtnDisableDefenderPermanent"
$BtnEnableDefender   = Find-Control "BtnEnableDefender"
$BtnOpenThreatSettings = Find-Control "BtnOpenThreatSettings"
$TxtDefenderRealtimeStatus = Find-Control "TxtDefenderRealtimeStatus"
$TxtDefenderTamperStatus   = Find-Control "TxtDefenderTamperStatus"
$TxtDefenderServicesStatus = Find-Control "TxtDefenderServicesStatus"

# Tweaks & Debloat Extended UI Hooks
$BtnModernizeExplorer   = Find-Control "BtnModernizeExplorer"
$BtnRestoreExplorer     = Find-Control "BtnRestoreExplorer"
$BtnDnsCloudflare       = Find-Control "BtnDnsCloudflare"
$BtnDnsGoogle           = Find-Control "BtnDnsGoogle"
$BtnDnsAdGuard          = Find-Control "BtnDnsAdGuard"
$BtnDnsDhcp             = Find-Control "BtnDnsDhcp"
$BtnDnsFlush            = Find-Control "BtnDnsFlush"
$BtnUnlockUltimatePlan  = Find-Control "BtnUnlockUltimatePlan"
$BtnReclaimHiberfil     = Find-Control "BtnReclaimHiberfil"
$BtnRunSsdTrim          = Find-Control "BtnRunSsdTrim"
$BtnOptimizeStartup     = Find-Control "BtnOptimizeStartup"
$BtnRestoreStartup      = Find-Control "BtnRestoreStartup"
$BtnApplyPrivacyShield  = Find-Control "BtnApplyPrivacyShield"
$BtnRestorePrivacy      = Find-Control "BtnRestorePrivacy"
$BtnKillShellClutter    = Find-Control "BtnKillShellClutter"
$BtnRestoreShellClutter = Find-Control "BtnRestoreShellClutter"
$BtnDeepRemoveWidgets   = Find-Control "BtnDeepRemoveWidgets"
$BtnRestoreWidgets      = Find-Control "BtnRestoreWidgets"

# Universal Tweaks Catalog UI Hooks
$TxtTweakSearch         = Find-Control "TxtTweakSearch"
$ComboTweakCategory     = Find-Control "ComboTweakCategory"
$ComboTweakType         = Find-Control "ComboTweakType"
$BtnClearTweakFilters   = Find-Control "BtnClearTweakFilters"
$ListAllTweaks          = Find-Control "ListAllTweaks"
$BtnInspectTweak        = Find-Control "BtnInspectTweak"
$BtnApplySelectedTweak  = Find-Control "BtnApplySelectedTweak"
$TxtTweakCount          = Find-Control "TxtTweakCount"
$TxtSelectedTweakStatus = Find-Control "TxtSelectedTweakStatus"

# Tools & Utilities Hub UI Hooks
$BtnToolCpuZ          = Find-Control "BtnToolCpuZ"
$BtnToolGpuZ          = Find-Control "BtnToolGpuZ"
$BtnToolHwMonitor     = Find-Control "BtnToolHwMonitor"
$BtnToolProcExp       = Find-Control "BtnToolProcExp"
$BtnToolMemReduct     = Find-Control "BtnToolMemReduct"
$BtnToolEverything    = Find-Control "BtnToolEverything"
$BtnToolTcpOpt        = Find-Control "BtnToolTcpOpt"
$BtnToolMsiUtil       = Find-Control "BtnToolMsiUtil"
$BtnToolCru           = Find-Control "BtnToolCru"
$BtnToolRufus         = Find-Control "BtnToolRufus"
$BtnTool7Zip          = Find-Control "BtnTool7Zip"
$BtnToolUnlocker      = Find-Control "BtnToolUnlocker"
$BtnToolRepairAudio   = Find-Control "BtnToolRepairAudio"
$BtnToolRepairNetwork = Find-Control "BtnToolRepairNetwork"
$BtnToolRepairUpdate  = Find-Control "BtnToolRepairUpdate"
$BtnToolRepairSfc     = Find-Control "BtnToolRepairSfc"
$BtnToolBenchmarkBoot = Find-Control "BtnToolBenchmarkBoot"
$BtnToolBenchmarkFrames = Find-Control "BtnToolBenchmarkFrames"
$BtnToolBenchmarkReport = Find-Control "BtnToolBenchmarkReport"
$BtnToolDetectThirdParty = Find-Control "BtnToolDetectThirdParty"
$BtnToolCleanLogs     = Find-Control "BtnToolCleanLogs"
$BtnToolHypervisor    = Find-Control "BtnToolHypervisor"

# Software Hub UI Hooks
$BtnSoftwareSelectAll   = Find-Control "BtnSoftwareSelectAll"
$BtnSoftwareClear       = Find-Control "BtnSoftwareClear"
$TxtSoftwareStatus      = Find-Control "TxtSoftwareStatus"
$BtnSoftwareInstall     = Find-Control "BtnSoftwareInstall"
$AppCheckboxes = @(
    (Find-Control "ChkAppBrave"),
    (Find-Control "ChkAppChrome"),
    (Find-Control "ChkAppFirefox"),
    (Find-Control "ChkAppSteam"),
    (Find-Control "ChkAppDiscord"),
    (Find-Control "ChkAppOBS"),
    (Find-Control "ChkAppVLC"),
    (Find-Control "ChkAppSpotify"),
    (Find-Control "ChkAppVSCode"),
    (Find-Control "ChkAppGit"),
    (Find-Control "ChkAppPython"),
    (Find-Control "ChkAppNode"),
    (Find-Control "ChkApp7Zip"),
    (Find-Control "ChkAppNotepad"),
    (Find-Control "ChkAppEverything"),
    (Find-Control "ChkAppPowerToys")
) | Where-Object { $null -ne $_ }

# AI Optimizer UI Hooks
$BtnAiScan              = Find-Control "BtnAiScan"
$BtnAiOptimize          = Find-Control "BtnAiOptimize"
$BtnAiFlushRam          = Find-Control "BtnAiFlushRam"
$BtnAiGamingShield      = Find-Control "BtnAiGamingShield"
$TxtAiScanStatus        = Find-Control "TxtAiScanStatus"
$TxtAiHealthScore       = Find-Control "TxtAiHealthScore"
$TxtAiServicesCount     = Find-Control "TxtAiServicesCount"
$TxtAiAppsCount         = Find-Control "TxtAiAppsCount"
$TxtAiTasksCount        = Find-Control "TxtAiTasksCount"
$TxtAiAnomaliesCount    = Find-Control "TxtAiAnomaliesCount"
$TxtAiProjectedImpact   = Find-Control "TxtAiProjectedImpact"
$TxtAiCandidateCount    = Find-Control "TxtAiCandidateCount"
$BtnAiFilterAll         = Find-Control "BtnAiFilterAll"
$BtnAiFilterSafe        = Find-Control "BtnAiFilterSafe"
$BtnAiFilterAnomalies   = Find-Control "BtnAiFilterAnomalies"
$ListAiFindings         = Find-Control "ListAiFindings"

# Load AI Engine
$AiModule = Join-Path $RootPath "Core\AI\WinAurex_AiEngine.psm1"
if (Test-Path $AiModule) {
    Import-Module $AiModule -Force -DisableNameChecking
}
$script:LastAiFindings = @()
$script:LastAnomalies = @()
$script:GamingShieldActive = $false

# Footer UI Hooks
$BtnOpenLogsFolder = Find-Control "BtnOpenLogsFolder"
$ProgressGlobal    = Find-Control "ProgressGlobal"
$TxtProgressDetail = Find-Control "TxtProgressDetail"

# Central Logging Engine Setup
$LogDir = "$env:SystemDrive\WinAurex\Logs"
if (-not (Test-Path $LogDir)) {
    $LogDir = Join-Path $RootPath "Logs"
    if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
}
$DashboardSessionLog = Join-Path $LogDir "Dashboard_Session_$(Get-Date -Format 'yyyyMMdd').log"

function Write-DashboardLog {
    param([string]$Message, [string]$Level = "INFO")
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$time] [$Level] $Message"
    Add-Content -Path $DashboardSessionLog -Value $line -ErrorAction SilentlyContinue
}

Write-DashboardLog "WinAurex GUI Dashboard session initialized by $([Environment]::UserName)"

# --- WINDOW CAPTION CONTROLS ---
if ($null -ne $BtnWinMinimize) {
    $BtnWinMinimize.Add_Click({
        $Window.WindowState = [System.Windows.WindowState]::Minimized
    })
}
if ($null -ne $BtnWinMaximize) {
    $BtnWinMaximize.Add_Click({
        if ($Window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $Window.WindowState = [System.Windows.WindowState]::Normal
        } else {
            $Window.WindowState = [System.Windows.WindowState]::Maximized
        }
    })
}
if ($null -ne $BtnWinClose) {
    $BtnWinClose.Add_Click({
        $Window.Close()
    })
}

# --- SIDEBAR VIEW SWITCHER ---
$script:DashboardViews = @{
    "Overview"      = $ViewOverview
    "Profiles"      = $ViewProfiles
    "AiOptimizer"   = $ViewAiOptimizer
    "Tweaks"        = $ViewTweaks
    "ToolsHub"      = $ViewToolsHub
    "SoftwareHub"   = $ViewSoftwareHub
    "Observability" = $ViewObservability
    "PcCleaner"     = $ViewPcCleaner
    "Rollback"      = $ViewRollback
}

function Show-DashboardView([string]$ViewName) {
    foreach ($key in $script:DashboardViews.Keys) {
        $viewObj = $script:DashboardViews[$key]
        if ($null -ne $viewObj) {
            if ($key -eq $ViewName) {
                $viewObj.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $viewObj.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
    }
}

if ($null -ne $NavOverview)      { $NavOverview.Add_Checked({ Show-DashboardView "Overview" }) }
if ($null -ne $NavProfiles)      { $NavProfiles.Add_Checked({ Show-DashboardView "Profiles" }) }
if ($null -ne $NavAiOptimizer)   { $NavAiOptimizer.Add_Checked({ Show-DashboardView "AiOptimizer" }) }
if ($null -ne $NavTweaks)        { $NavTweaks.Add_Checked({ Show-DashboardView "Tweaks" }) }
if ($null -ne $NavToolsHub)      { $NavToolsHub.Add_Checked({ Show-DashboardView "ToolsHub" }) }
if ($null -ne $NavSoftwareHub)   { $NavSoftwareHub.Add_Checked({ Show-DashboardView "SoftwareHub" }) }
if ($null -ne $NavObservability) { $NavObservability.Add_Checked({ Show-DashboardView "Observability" }) }
if ($null -ne $NavPcCleaner)     { $NavPcCleaner.Add_Checked({ Show-DashboardView "PcCleaner" }) }
if ($null -ne $NavRollback)      { $NavRollback.Add_Checked({ Show-DashboardView "Rollback" }) }

# --- HARDWARE SPECS & HUD INITIALIZATION ---
function Initialize-HardwareHUD {
    try {
        # CPU
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu -and $null -ne $TxtHudCpuName) {
            $TxtHudCpuName.Text = "$($cpu.Name.Trim())"
            $TxtHudCpuCores.Text = "$($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads"
        }

        # Memory
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object -First 1
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cs -and $null -ne $TxtHudRamTotal) {
            $totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            $TxtHudRamTotal.Text = "$totalGB GB Installed"
        }
        if ($os -and $null -ne $TxtHudRamUsed) {
            $totalKB = $os.TotalVisibleMemorySize
            $freeKB  = $os.FreePhysicalMemory
            $usedGB  = [math]::Round(($totalKB - $freeKB) / 1MB, 1)
            $pct     = [math]::Round((($totalKB - $freeKB) / $totalKB) * 100)
            $TxtHudRamUsed.Text = "Active: $usedGB GB ($pct%)"
            if ($null -ne $TxtSidebarRam) { $TxtSidebarRam.Text = "$usedGB / $([math]::Round($totalKB / 1MB, 1)) GB" }
            if ($null -ne $ProgressSidebarRam) { $ProgressSidebarRam.Value = $pct }
        }

        # OS Build
        if ($os -and $null -ne $TxtHudOsBuild) {
            $TxtHudOsBuild.Text = "$($os.Caption) ($($os.BuildNumber))"
        }

        # Active Power Scheme
        try {
            $scheme = powercfg /getactivescheme
            if ($scheme -match "\((.*?)\)") {
                $TxtHudPowerPlan.Text = "Plan: $($matches[1])"
            }
        } catch {}

        # AI Health Score
        if (Get-Command Get-WinAurexHealthScore -ErrorAction SilentlyContinue) {
            $health = Get-WinAurexHealthScore
            if ($null -ne $TxtHudHealthScore) { $TxtHudHealthScore.Text = "$($health.Score) / 100" }
            if ($null -ne $TxtHudHealthGrade) { $TxtHudHealthGrade.Text = "$($health.Grade)" }
            if ($null -ne $TxtAiHealthScore)  { $TxtAiHealthScore.Text = "$($health.Score)" }
            if ($null -ne $TxtHudAiScore)     { $TxtHudAiScore.Text = "$($health.Score)/100 (Grade $($health.Grade))" }
        }
    } catch {
        Write-DashboardLog "Hardware HUD initialization warning: $_" "WARN"
    }
}

# --- EXECUTIVE BOOST & SIDEBAR ACTION HANDLERS ---
if ($null -ne $BtnExecutiveBoost) {
    $BtnExecutiveBoost.Add_Click({
        Write-DashboardLog "User triggered ONE-CLICK EXTREME OPTIMIZE (Executive Boost)"
        Set-Status -Message "Executing One-Click Extreme Optimization..." -Color "#00ff41"

        # 1. AI dynamic system optimization
        $scriptPath = Join-Path $RootPath "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"
        Invoke-DashboardAction -ActionName "Executive_Boost" -ScriptPath $scriptPath -Arguments "-Auto -Force"

        # 2. Flush RAM working sets
        if (Get-Command Invoke-WinAurexRamFlush -ErrorAction SilentlyContinue) {
            $res = Invoke-WinAurexRamFlush
            Write-DashboardLog "Executive Boost RAM Flush: Reclaimed $($res.ReclaimedMB) MB"
        }

        # 3. Enable Gaming Latency Shield
        if (Get-Command Set-AiGamingShield -ErrorAction SilentlyContinue) {
            Set-AiGamingShield -Enable | Out-Null
            $script:GamingShieldActive = $true
            if ($null -ne $BtnAiGamingShield) {
                $BtnAiGamingShield.Content = "🎮 Gaming [ON]"
                $BtnAiGamingShield.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
            }
        }

        # 4. Flush DNS
        try { Clear-DnsClientCache } catch {}

        # Refresh UI
        Initialize-HardwareHUD
        Set-Status -Message "Executive Boost Complete! System tuned for maximum responsiveness." -Color "#00ff41"
    })
}

if ($null -ne $BtnNavToAi) {
    $BtnNavToAi.Add_Click({
        Write-DashboardLog "User clicked Open WinAurex AI Suite"
        Show-DashboardView "AiOptimizer"
        if ($null -ne $NavAiOptimizer) { $NavAiOptimizer.IsChecked = $true }
    })
}

if ($null -ne $BtnSidebarFlushRam) {
    $BtnSidebarFlushRam.Add_Click({
        if (Get-Command Invoke-WinAurexRamFlush -ErrorAction SilentlyContinue) {
            $res = Invoke-WinAurexRamFlush
            Set-Status -Message "RAM Flush: Reclaimed $($res.ReclaimedMB) MB across $($res.ProcessesTrimmed) processes!" -Color "#00ff41"
            Initialize-HardwareHUD
        }
    })
}

if ($null -ne $BtnSidebarViewLogs) {
    $BtnSidebarViewLogs.Add_Click({
        Start-Process explorer.exe $LogDir
    })
}

# --- SOFTWARE HUB SEARCH & CATEGORY FILTERS ---
if ($null -ne $TxtSoftwareSearch) {
    $TxtSoftwareSearch.Add_TextChanged({
        $query = $TxtSoftwareSearch.Text.Trim().ToLower()
        foreach ($chk in $AppCheckboxes) {
            if ([string]::IsNullOrWhiteSpace($query)) {
                $chk.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $name = "$($chk.Content) $($chk.Tag)".ToLower()
                $chk.Visibility = if ($name -match [regex]::Escape($query)) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
            }
        }
    })
}

if ($null -ne $BtnFilterBrowsers) {
    $BtnFilterBrowsers.Add_Click({
        foreach ($chk in $AppCheckboxes) {
            $chk.IsChecked = ($chk.Tag -in @("Brave.Brave", "Google.Chrome", "Mozilla.Firefox"))
        }
        if ($null -ne $TxtSoftwareStatus) { $TxtSoftwareStatus.Text = "Selected: Browsers" }
    })
}

if ($null -ne $BtnFilterGaming) {
    $BtnFilterGaming.Add_Click({
        foreach ($chk in $AppCheckboxes) {
            $chk.IsChecked = ($chk.Tag -in @("Valve.Steam", "Discord.Discord", "OBSProject.OBSStudio", "VideoLAN.VLC", "Spotify.Spotify"))
        }
        if ($null -ne $TxtSoftwareStatus) { $TxtSoftwareStatus.Text = "Selected: Gaming & Media" }
    })
}

if ($null -ne $BtnFilterDev) {
    $BtnFilterDev.Add_Click({
        foreach ($chk in $AppCheckboxes) {
            $chk.IsChecked = ($chk.Tag -in @("Microsoft.VisualStudioCode", "Git.Git", "Python.Python.3.12", "OpenJS.NodeJS.LTS", "7zip.7zip", "Notepad++.Notepad++", "voidtools.Everything", "Microsoft.PowerToys"))
        }
        if ($null -ne $TxtSoftwareStatus) { $TxtSoftwareStatus.Text = "Selected: Dev & Utilities" }
    })
}

# --- DEFENDER LIVE STATUS UI UPDATER ---
function Update-DefenderStatusUI {
    try {
        $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($null -ne $TxtDefenderRealtimeStatus) {
            if ($mp -and $mp.RealTimeProtectionEnabled) {
                $TxtDefenderRealtimeStatus.Text = "Active (Scanning)"
                $TxtDefenderRealtimeStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
            } else {
                $TxtDefenderRealtimeStatus.Text = "Disabled (Off)"
                $TxtDefenderRealtimeStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ff5722")
            }
        }
        if ($null -ne $TxtDefenderTamperStatus) {
            if ($mp -and $mp.IsTamperProtected) {
                $TxtDefenderTamperStatus.Text = "ON (Blocks changes)"
                $TxtDefenderTamperStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ff5722")
            } else {
                $TxtDefenderTamperStatus.Text = "OFF (Modifiable)"
                $TxtDefenderTamperStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00adb5")
            }
        }
        if ($null -ne $TxtDefenderServicesStatus) {
            $svcWinDefend = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" -Name "Start" -ErrorAction SilentlyContinue).Start
            $svcWdNisSvc  = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" -Name "Start" -ErrorAction SilentlyContinue).Start
            if ($svcWinDefend -eq 4 -and $svcWdNisSvc -eq 4) {
                $TxtDefenderServicesStatus.Text = "Disabled (Permanent)"
                $TxtDefenderServicesStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
            } else {
                $TxtDefenderServicesStatus.Text = "Active (Auto/Manual)"
                $TxtDefenderServicesStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ffb300")
            }
        }
    } catch {}
}

function DoEvents-WPF {
    try {
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [Action]{ $frame.Continue = $false }
        ) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    } catch {}
}

# --- UNIFIED DASHBOARD ACTION RUNNER & LOGGER ---
function Invoke-DashboardAction {
    param (
        [string]$ActionName,
        [string]$ScriptPath,
        [string]$Arguments = "-Force"
    )
    Write-DashboardLog "Starting Action: $ActionName (Target: $ScriptPath $Arguments)"
    Set-Status -Message "Executing $ActionName..." -Color "#ffb300"
    
    if ($null -ne $ProgressGlobal) {
        $ProgressGlobal.Visibility = "Visible"
        $ProgressGlobal.IsIndeterminate = $true
    }
    if ($null -ne $TxtProgressDetail) {
        $TxtProgressDetail.Visibility = "Visible"
        $TxtProgressDetail.Text = "Running $ActionName..."
    }
    DoEvents-WPF

    $ActionLog = Join-Path $LogDir "${ActionName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $cmd = "& { Start-Transcript -Path `"$ActionLog`" -Append -Force; try { & `"$ScriptPath`" $Arguments } finally { Stop-Transcript } }"
    
    $proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -PassThru
    
    # Non-blocking Dispatcher polling loop: UI remains responsive, window stays interactive
    $lastLogSize = 0
    while ($proc -and -not $proc.HasExited) {
        DoEvents-WPF
        Start-Sleep -Milliseconds 120
        
        # Read latest transcript lines to show live progress detail
        if (Test-Path $ActionLog) {
            try {
                $fileInfo = Get-Item $ActionLog -ErrorAction SilentlyContinue
                if ($fileInfo -and $fileInfo.Length -gt $lastLogSize) {
                    $lastLogSize = $fileInfo.Length
                    $tail = Get-Content -Path $ActionLog -Tail 1 -ErrorAction SilentlyContinue
                    if ($tail -and -not [string]::IsNullOrWhiteSpace($tail) -and -not ($tail -match "^(Transcript|[*=]+|$)")) {
                        $cleanTail = $tail.Trim()
                        if ($cleanTail.Length -gt 55) { $cleanTail = $cleanTail.Substring(0, 52) + "..." }
                        if ($null -ne $TxtProgressDetail) {
                            $TxtProgressDetail.Text = $cleanTail
                        }
                    }
                }
            } catch {}
        }
    }

    $exitCode = if ($proc) { $proc.ExitCode } else { 0 }

    if ($null -ne $ProgressGlobal) {
        $ProgressGlobal.IsIndeterminate = $false
        $ProgressGlobal.Visibility = "Collapsed"
    }
    if ($null -ne $TxtProgressDetail) {
        $TxtProgressDetail.Visibility = "Collapsed"
        $TxtProgressDetail.Text = ""
    }
    
    Write-DashboardLog "Completed Action: $ActionName (ExitCode: $exitCode, Log: $ActionLog)"
    Set-Status -Message "$ActionName complete! Log: $(Split-Path $ActionLog -Leaf)" -Color "#00adb5"
    Update-DefenderStatusUI
}

# PC Cleaner UI Hooks
$BtnAnalyzeStorage = Find-Control "BtnAnalyzeStorage"
$BtnCleanStorage = Find-Control "BtnCleanStorage"
$TxtDriveCapacity = Find-Control "TxtDriveCapacity"
$TxtDriveUsed = Find-Control "TxtDriveUsed"
$TxtDriveFree = Find-Control "TxtDriveFree"
$TxtReclaimableTotal = Find-Control "TxtReclaimableTotal"

$ChkSystemTemp = Find-Control "ChkSystemTemp"
$TxtSizeSystemTemp = Find-Control "TxtSizeSystemTemp"
$ChkCrashDumps = Find-Control "ChkCrashDumps"
$TxtSizeCrashDumps = Find-Control "TxtSizeCrashDumps"
$ChkAIIndex = Find-Control "ChkAIIndex"
$TxtSizeAIIndex = Find-Control "TxtSizeAIIndex"
$ChkAppUpdaters = Find-Control "ChkAppUpdaters"
$TxtSizeAppUpdaters = Find-Control "TxtSizeAppUpdaters"
$ChkSquirrel = Find-Control "ChkSquirrel"
$TxtSizeSquirrel = Find-Control "TxtSizeSquirrel"
$ChkBrowserCaches = Find-Control "ChkBrowserCaches"
$TxtSizeBrowserCaches = Find-Control "TxtSizeBrowserCaches"
$ChkDevCaches = Find-Control "ChkDevCaches"
$TxtSizeDevCaches = Find-Control "TxtSizeDevCaches"
$ChkLooseInstallers = Find-Control "ChkLooseInstallers"
$TxtSizeLooseInstallers = Find-Control "TxtSizeLooseInstallers"
$ChkComponentStore = Find-Control "ChkComponentStore"
$TxtSizeComponentStore = Find-Control "TxtSizeComponentStore"

# --- STATUS UPDATER ---
function Set-Status {
    param([string]$Message, [string]$Color = "#00adb5")
    $TxtStatus.Text = "Status: $Message"
    $TxtStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($Color)
    # Force UI update
    $Window.Dispatcher.Invoke([Action]{}, "Background")
}

# --- PROFILES TAB LOGIC ---
$BtnApplyMaxPerf.Add_Click({
    Invoke-DashboardAction -ActionName "Profile_MaxPerformance" -ScriptPath (Join-Path $RootPath "Profiles\Max_Performance_Profile.ps1")
})

$BtnApplyBalanced.Add_Click({
    Invoke-DashboardAction -ActionName "Profile_Balanced" -ScriptPath (Join-Path $RootPath "Profiles\Balanced_Creator_Profile.ps1")
})

$BtnApplyEnterprise.Add_Click({
    Invoke-DashboardAction -ActionName "Profile_Enterprise" -ScriptPath (Join-Path $RootPath "Profiles\Enterprise_Compliance_Profile.ps1")
})

# --- TWEAKS & DEBLOAT TAB LOGIC ---
$BtnOptimizeServices.Add_Click({
    Invoke-DashboardAction -ActionName "Optimize_Services" -ScriptPath (Join-Path $RootPath "Tweaks\Services\Optimize_Windows_Services.ps1") -Arguments "-Force"
})

$BtnDebloatOS.Add_Click({
    Invoke-DashboardAction -ActionName "Debloat_OS" -ScriptPath (Join-Path $RootPath "Tweaks\Apps\Deep_OS_Debloat.ps1") -Arguments "-Force"
})

$BtnReduceThreads.Add_Click({
    Invoke-DashboardAction -ActionName "Reduce_Threads" -ScriptPath (Join-Path $RootPath "Tweaks\Performance\Reduce_Processes_And_Threads.ps1") -Arguments "-Force"
})

$BtnDisableDefender.Add_Click({
    Invoke-DashboardAction -ActionName "Defender_Disable" -ScriptPath (Join-Path $RootPath "Tweaks\Security\Configure_Defender_Policy.ps1") -Arguments "-Disable -Force"
    Update-DefenderStatusUI
})

if ($null -ne $BtnDisableDefenderPermanent) {
    $BtnDisableDefenderPermanent.Add_Click({
        Invoke-DashboardAction -ActionName "Defender_PermanentDisable" -ScriptPath (Join-Path $RootPath "Tweaks\Security\Configure_Defender_Policy.ps1") -Arguments "-Disable -PermanentServices -Force"
        Update-DefenderStatusUI
    })
}

$BtnEnableDefender.Add_Click({
    Invoke-DashboardAction -ActionName "Defender_Enable" -ScriptPath (Join-Path $RootPath "Tweaks\Security\Configure_Defender_Policy.ps1") -Arguments "-Enable -Force"
})

if ($null -ne $BtnOpenThreatSettings) {
    $BtnOpenThreatSettings.Add_Click({
        Write-DashboardLog "User clicked Open Security Settings"
        Set-Status -Message "Opening Windows Security Threat Settings..." -Color "#ffb300"
        Start-Process "windowsdefender://threatsettings"
    })
}

if ($null -ne $BtnOpenLogsFolder) {
    $BtnOpenLogsFolder.Add_Click({
        Write-DashboardLog "User clicked View Logs (Opening $LogDir)"
        Start-Process explorer.exe $LogDir
    })
}

# --- EXTENDED TWEAKS EVENT HANDLERS ---
if ($null -ne $BtnModernizeExplorer) {
    $BtnModernizeExplorer.Add_Click({
        Invoke-DashboardAction -ActionName "Explorer_Modernize" -ScriptPath (Join-Path $RootPath "Tweaks\Explorer\Apply_Explorer_Modernizer.ps1") -Arguments "-Force"
    })
}
if ($null -ne $BtnRestoreExplorer) {
    $BtnRestoreExplorer.Add_Click({
        Invoke-DashboardAction -ActionName "Explorer_Restore" -ScriptPath (Join-Path $RootPath "Tweaks\Explorer\Apply_Explorer_Modernizer.ps1") -Arguments "-Revert -Force"
    })
}

if ($null -ne $BtnDnsCloudflare) {
    $BtnDnsCloudflare.Add_Click({
        Invoke-DashboardAction -ActionName "DNS_Cloudflare" -ScriptPath (Join-Path $RootPath "Tweaks\Network\Set_Dns_And_Network_Optimization.ps1") -Arguments "-Provider Cloudflare -Force"
    })
}
if ($null -ne $BtnDnsGoogle) {
    $BtnDnsGoogle.Add_Click({
        Invoke-DashboardAction -ActionName "DNS_Google" -ScriptPath (Join-Path $RootPath "Tweaks\Network\Set_Dns_And_Network_Optimization.ps1") -Arguments "-Provider Google -Force"
    })
}
if ($null -ne $BtnDnsAdGuard) {
    $BtnDnsAdGuard.Add_Click({
        Invoke-DashboardAction -ActionName "DNS_AdGuard" -ScriptPath (Join-Path $RootPath "Tweaks\Network\Set_Dns_And_Network_Optimization.ps1") -Arguments "-Provider AdGuard -Force"
    })
}
if ($null -ne $BtnDnsDhcp) {
    $BtnDnsDhcp.Add_Click({
        Invoke-DashboardAction -ActionName "DNS_Reset_DHCP" -ScriptPath (Join-Path $RootPath "Tweaks\Network\Set_Dns_And_Network_Optimization.ps1") -Arguments "-Provider DHCP -Force"
    })
}
if ($null -ne $BtnDnsFlush) {
    $BtnDnsFlush.Add_Click({
        Invoke-DashboardAction -ActionName "DNS_Flush_Cache" -ScriptPath (Join-Path $RootPath "Tweaks\Network\Set_Dns_And_Network_Optimization.ps1") -Arguments "-FlushOnly -Force"
    })
}

if ($null -ne $BtnUnlockUltimatePlan) {
    $BtnUnlockUltimatePlan.Add_Click({
        Invoke-DashboardAction -ActionName "Power_UltimatePlan" -ScriptPath (Join-Path $RootPath "Tweaks\Power\Manage_Hardware_Power_And_Storage.ps1") -Arguments "-Action UnlockUltimatePlan -Force"
    })
}
if ($null -ne $BtnReclaimHiberfil) {
    $BtnReclaimHiberfil.Add_Click({
        Invoke-DashboardAction -ActionName "Storage_HiberfilReclaim" -ScriptPath (Join-Path $RootPath "Tweaks\Power\Manage_Hardware_Power_And_Storage.ps1") -Arguments "-Action ReclaimHiberfil -Force"
    })
}
if ($null -ne $BtnRunSsdTrim) {
    $BtnRunSsdTrim.Add_Click({
        Invoke-DashboardAction -ActionName "Storage_SSD_TRIM" -ScriptPath (Join-Path $RootPath "Tweaks\Power\Manage_Hardware_Power_And_Storage.ps1") -Arguments "-Action RunSsdTrim -Force"
    })
}

if ($null -ne $BtnOptimizeStartup) {
    $BtnOptimizeStartup.Add_Click({
        Invoke-DashboardAction -ActionName "Startup_Optimize" -ScriptPath (Join-Path $RootPath "Tweaks\Startup\Optimize_Startup_Apps.ps1") -Arguments "-Force"
    })
}
if ($null -ne $BtnRestoreStartup) {
    $BtnRestoreStartup.Add_Click({
        Invoke-DashboardAction -ActionName "Startup_Restore" -ScriptPath (Join-Path $RootPath "Tweaks\Startup\Optimize_Startup_Apps.ps1") -Arguments "-RestoreAll -Force"
    })
}

if ($null -ne $BtnApplyPrivacyShield) {
    $BtnApplyPrivacyShield.Add_Click({
        Invoke-DashboardAction -ActionName "Privacy_Shield_Apply" -ScriptPath (Join-Path $RootPath "Tweaks\Privacy\Apply_Deep_Privacy_Shield.ps1") -Arguments "-Force"
    })
}
if ($null -ne $BtnRestorePrivacy) {
    $BtnRestorePrivacy.Add_Click({
        Invoke-DashboardAction -ActionName "Privacy_Shield_Restore" -ScriptPath (Join-Path $RootPath "Tweaks\Privacy\Restore_Privacy_Defaults.ps1") -Arguments "-Force"
    })
}

if ($null -ne $BtnKillShellClutter) {
    $BtnKillShellClutter.Add_Click({
        Invoke-DashboardAction -ActionName "Shell_KillWidgets" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Deep_Remove_Widgets_And_Weather.ps1") -Arguments "-Force -RestartExplorer"
        Invoke-DashboardAction -ActionName "Shell_KillSpotlight" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Disable_Desktop_Spotlight.ps1") -Arguments "-Force"
        Invoke-DashboardAction -ActionName "Shell_KillOneDriveNag" -ScriptPath (Join-Path $RootPath "Tweaks\Sync\Disable_OneDrive_Nag_And_Backup.ps1") -Arguments "-Force"
    })
}
if ($null -ne $BtnDeepRemoveWidgets) {
    $BtnDeepRemoveWidgets.Add_Click({
        Invoke-DashboardAction -ActionName "Shell_DeepRemoveWidgets" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Deep_Remove_Widgets_And_Weather.ps1") -Arguments "-Force -RestartExplorer"
        Invoke-DashboardAction -ActionName "Shell_KillSpotlight" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Disable_Desktop_Spotlight.ps1") -Arguments "-Force"
        Invoke-DashboardAction -ActionName "Shell_KillOneDriveNag" -ScriptPath (Join-Path $RootPath "Tweaks\Sync\Disable_OneDrive_Nag_And_Backup.ps1") -Arguments "-Force"
    })
}
if ($null -ne $BtnRestoreShellClutter) {
    $BtnRestoreShellClutter.Add_Click({
        Invoke-DashboardAction -ActionName "Shell_RestoreWidgets" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Restore_Widgets_And_Weather.ps1") -Arguments "-Force -RestartExplorer"
        Invoke-DashboardAction -ActionName "Shell_RestoreSpotlight" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Enable_Desktop_Spotlight.ps1") -Arguments "-Force"
        Invoke-DashboardAction -ActionName "Shell_RestoreOneDrive" -ScriptPath (Join-Path $RootPath "Tweaks\Sync\Enable_OneDrive_Nag_And_Backup.ps1") -Arguments "-Force"
    })
}
if ($null -ne $BtnRestoreWidgets) {
    $BtnRestoreWidgets.Add_Click({
        Invoke-DashboardAction -ActionName "Shell_RestoreWidgets" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Restore_Widgets_And_Weather.ps1") -Arguments "-Force -RestartExplorer"
        Invoke-DashboardAction -ActionName "Shell_RestoreSpotlight" -ScriptPath (Join-Path $RootPath "Tweaks\Shell\Enable_Desktop_Spotlight.ps1") -Arguments "-Force"
        Invoke-DashboardAction -ActionName "Shell_RestoreOneDrive" -ScriptPath (Join-Path $RootPath "Tweaks\Sync\Enable_OneDrive_Nag_And_Backup.ps1") -Arguments "-Force"
    })
}

# --- UNIVERSAL TWEAKS CATALOG LOGIC ---
$script:AllTweaksCatalog = @()
$script:IsCatalogUpdating = $false

function Initialize-TweaksCatalog {
    try {
        if (-not (Get-Command Get-WinAurexTweaksCatalog -ErrorAction SilentlyContinue)) {
            Write-DashboardLog "[WARN] Get-WinAurexTweaksCatalog command not available."
            return
        }

        $script:AllTweaksCatalog = Get-WinAurexTweaksCatalog -TweaksRoot (Join-Path $RootPath "Tweaks")
        Write-DashboardLog "Indexed $($script:AllTweaksCatalog.Count) tweaks across repository."

        $script:IsCatalogUpdating = $true

        # Populate Category Dropdown
        if ($null -ne $ComboTweakCategory) {
            $ComboTweakCategory.Items.Clear()
            $ComboTweakCategory.Items.Add("All Categories ($($script:AllTweaksCatalog.Count))") | Out-Null
            
            $cats = $script:AllTweaksCatalog | Group-Object Category | Sort-Object Name
            foreach ($cat in $cats) {
                $ComboTweakCategory.Items.Add("$($cat.Name) ($($cat.Count))") | Out-Null
            }
            $ComboTweakCategory.SelectedIndex = 0
        }

        # Populate Type Dropdown
        if ($null -ne $ComboTweakType) {
            $ComboTweakType.Items.Clear()
            $ComboTweakType.Items.Add("All Formats") | Out-Null
            $ComboTweakType.Items.Add("PS1 (PowerShell)") | Out-Null
            $ComboTweakType.Items.Add("REG (Registry)") | Out-Null
            $ComboTweakType.Items.Add("BAT (Batch)") | Out-Null
            $ComboTweakType.Items.Add("CMD (Command Script)") | Out-Null
            $ComboTweakType.SelectedIndex = 0
        }

        $script:IsCatalogUpdating = $false
        Update-TweaksCatalogFilter
    } catch {
        Write-DashboardLog "[ERROR] Failed to initialize Tweaks Catalog: $_"
        $script:IsCatalogUpdating = $false
    }
}

function Update-TweaksCatalogFilter {
    if ($script:IsCatalogUpdating -or -not $script:AllTweaksCatalog) { return }

    $query = if ($null -ne $TxtTweakSearch -and -not [string]::IsNullOrWhiteSpace($TxtTweakSearch.Text)) { 
        $TxtTweakSearch.Text.Trim().ToLower() 
    } else { "" }

    $selectedCategory = if ($null -ne $ComboTweakCategory -and $null -ne $ComboTweakCategory.SelectedItem) {
        $rawCat = $ComboTweakCategory.SelectedItem.ToString()
        if ($rawCat -match "^(.*?)\s*\(\d+\)$") { $matches[1] } else { $rawCat }
    } else { "All Categories" }

    $selectedType = if ($null -ne $ComboTweakType -and $null -ne $ComboTweakType.SelectedItem) {
        $rawType = $ComboTweakType.SelectedItem.ToString()
        if ($rawType -match "^([A-Za-z0-9]+)") { $matches[1].ToUpper() } else { "ALL" }
    } else { "ALL" }

    $filtered = $script:AllTweaksCatalog | Where-Object {
        $matchQuery = $true
        if ($query -ne "") {
            $matchQuery = ($_.Name.ToLower().Contains($query) -or 
                           $_.Category.ToLower().Contains($query) -or 
                           $_.Synopsis.ToLower().Contains($query) -or 
                           $_.FileName.ToLower().Contains($query))
        }

        $matchCat = $true
        if ($selectedCategory -ne "All Categories") {
            $matchCat = ($_.Category -eq $selectedCategory)
        }

        $matchType = $true
        if ($selectedType -ne "ALL" -and $selectedType -ne "ALL FORMATS") {
            $matchType = ($_.Type -eq $selectedType)
        }

        $matchQuery -and $matchCat -and $matchType
    }

    if ($null -ne $ListAllTweaks) {
        $ListAllTweaks.ItemsSource = $filtered
    }

    if ($null -ne $TxtTweakCount) {
        $TxtTweakCount.Text = "$($filtered.Count) of $($script:AllTweaksCatalog.Count) tweaks loaded"
    }

    # Reset preview status
    if ($null -ne $TxtSelectedTweakStatus) {
        $TxtSelectedTweakStatus.Text = "Select a tweak to inspect code or execute..."
    }
    if ($null -ne $BtnApplySelectedTweak) { $BtnApplySelectedTweak.IsEnabled = $false }
    if ($null -ne $BtnInspectTweak) { $BtnInspectTweak.IsEnabled = $false }
}

# Tweaks Catalog Event Listeners
if ($null -ne $TxtTweakSearch) {
    $TxtTweakSearch.Add_TextChanged({ Update-TweaksCatalogFilter })
}
if ($null -ne $ComboTweakCategory) {
    $ComboTweakCategory.Add_SelectionChanged({ Update-TweaksCatalogFilter })
}
if ($null -ne $ComboTweakType) {
    $ComboTweakType.Add_SelectionChanged({ Update-TweaksCatalogFilter })
}
if ($null -ne $BtnClearTweakFilters) {
    $BtnClearTweakFilters.Add_Click({
        $script:IsCatalogUpdating = $true
        if ($null -ne $TxtTweakSearch) { $TxtTweakSearch.Text = "" }
        if ($null -ne $ComboTweakCategory) { $ComboTweakCategory.SelectedIndex = 0 }
        if ($null -ne $ComboTweakType) { $ComboTweakType.SelectedIndex = 0 }
        $script:IsCatalogUpdating = $false
        Update-TweaksCatalogFilter
    })
}

if ($null -ne $ListAllTweaks) {
    $ListAllTweaks.Add_SelectionChanged({
        if ($null -ne $ListAllTweaks.SelectedItem) {
            $item = $ListAllTweaks.SelectedItem
            if ($null -ne $TxtSelectedTweakStatus) {
                $TxtSelectedTweakStatus.Text = "Ready: $($item.Name) ($($item.Type)) [Category: $($item.Category)]"
            }
            if ($null -ne $BtnApplySelectedTweak) { $BtnApplySelectedTweak.IsEnabled = $true }
            if ($null -ne $BtnInspectTweak) { $BtnInspectTweak.IsEnabled = $true }
        } else {
            if ($null -ne $TxtSelectedTweakStatus) {
                $TxtSelectedTweakStatus.Text = "Select a tweak to inspect code or execute..."
            }
            if ($null -ne $BtnApplySelectedTweak) { $BtnApplySelectedTweak.IsEnabled = $false }
            if ($null -ne $BtnInspectTweak) { $BtnInspectTweak.IsEnabled = $false }
        }
    })
}

if ($null -ne $BtnInspectTweak) {
    $BtnInspectTweak.Add_Click({
        if ($null -ne $ListAllTweaks.SelectedItem) {
            $item = $ListAllTweaks.SelectedItem
            if (Test-Path $item.Path) {
                Write-DashboardLog "User inspected tweak code: $($item.Path)"
                Start-Process notepad.exe -ArgumentList "`"$($item.Path)`""
                Set-Status -Message "Opened $($item.FileName) in Notepad" -Color "#00adb5"
            }
        }
    })
}

if ($null -ne $BtnApplySelectedTweak) {
    $BtnApplySelectedTweak.Add_Click({
        if ($null -ne $ListAllTweaks.SelectedItem) {
            $item = $ListAllTweaks.SelectedItem
            if (-not (Test-Path $item.Path)) {
                Set-Status -Message "Tweak file missing: $($item.FileName)" -Color "#ff5252"
                return
            }

            Write-DashboardLog "User triggered execution of catalog tweak: $($item.Name) ($($item.Path))"
            Set-Status -Message "Applying $($item.Name)..." -Color "#ffb300"
            if ($null -ne $TxtSelectedTweakStatus) {
                $TxtSelectedTweakStatus.Text = "Executing $($item.Name)..."
            }
            if ($null -ne $ProgressGlobal) {
                $ProgressGlobal.Visibility = "Visible"
                $ProgressGlobal.IsIndeterminate = $true
            }
            if ($null -ne $TxtProgressDetail) {
                $TxtProgressDetail.Visibility = "Visible"
                $TxtProgressDetail.Text = "Applying $($item.Name)..."
            }
            DoEvents-WPF

            try {
                if (Get-Command Invoke-WinAurexItem -ErrorAction SilentlyContinue) {
                    $res = Invoke-WinAurexItem -ItemPath $item.Path
                    if ($res.Success) {
                        Write-DashboardLog "Catalog tweak applied successfully: $($item.Name)"
                        Set-Status -Message "Applied: $($item.Name)" -Color "#00adb5"
                        if ($null -ne $TxtSelectedTweakStatus) {
                            $TxtSelectedTweakStatus.Text = "Success: $($item.Name) applied successfully (Exit: $($res.ExitCode))"
                        }
                    } else {
                        Write-DashboardLog "[WARN] Catalog tweak exited with code $($res.ExitCode): $($res.Error)"
                        Set-Status -Message "Completed $($item.Name) with code $($res.ExitCode)" -Color "#ffb300"
                        if ($null -ne $TxtSelectedTweakStatus) {
                            $TxtSelectedTweakStatus.Text = "Completed with warnings: $($item.Name) (Exit: $($res.ExitCode))"
                        }
                    }
                } else {
                    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($item.Path)`"" -Wait
                    Set-Status -Message "Applied: $($item.Name)" -Color "#00adb5"
                }
            } catch {
                Write-DashboardLog "[ERROR] Execution exception on $($item.Name): $_"
                Set-Status -Message "Failed to apply $($item.Name): $($_.Exception.Message)" -Color "#ff5252"
                if ($null -ne $TxtSelectedTweakStatus) {
                    $TxtSelectedTweakStatus.Text = "Error applying $($item.Name): $($_.Exception.Message)"
                }
            } finally {
                if ($null -ne $ProgressGlobal) {
                    $ProgressGlobal.IsIndeterminate = $false
                    $ProgressGlobal.Visibility = "Collapsed"
                }
                if ($null -ne $TxtProgressDetail) {
                    $TxtProgressDetail.Visibility = "Collapsed"
                    $TxtProgressDetail.Text = ""
                }
            }
        }
    })
}

# --- TOOLS & UTILITIES HUB LOGIC ---
function Launch-WinAurexTool {
    param (
        [Parameter(Mandatory=$true)][string]$ToolRelativePath,
        [Parameter(Mandatory=$true)][string]$DisplayName,
        [string]$Arguments = ""
    )

    $fullPath = Join-Path $RootPath $ToolRelativePath
    if (-not (Test-Path $fullPath)) {
        # Check if parent exists and find matching file
        $parent = Split-Path $fullPath -Parent
        $leafName = [System.IO.Path]::GetFileNameWithoutExtension($fullPath)
        if (Test-Path $parent) {
            $matched = Get-ChildItem -Path $parent -Filter "*$leafName*" -File | Select-Object -First 1
            if ($matched) {
                $fullPath = $matched.FullName
            }
        }
    }

    if (-not (Test-Path $fullPath)) {
        Write-DashboardLog "[ERROR] Tool not found: $ToolRelativePath (Resolved: $fullPath)"
        Set-Status -Message "Tool not found: $DisplayName" -Color "#ff5252"
        [System.Windows.MessageBox]::Show("Could not find tool file at:`n$fullPath", "Tool Missing", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Write-DashboardLog "Launching tool: $DisplayName ($fullPath $Arguments)"
    Set-Status -Message "Launching $DisplayName..." -Color "#ffb300"

    try {
        $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
        if ($ext -eq ".ps1") {
            $cmdArgs = if ([string]::IsNullOrWhiteSpace($Arguments)) { "-Force" } else { "$Arguments -Force" }
            Invoke-DashboardAction -ActionName ($DisplayName -replace '\s+', '_') -ScriptPath $fullPath -Arguments $cmdArgs
        } elseif ($ext -in @(".cmd", ".bat")) {
            $cmdArgs = if ([string]::IsNullOrWhiteSpace($Arguments)) { "/c `"$fullPath`"" } else { "/c `"$fullPath`" $Arguments" }
            Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -Verb RunAs -WindowStyle Normal
            Set-Status -Message "Launched $DisplayName in Command Prompt." -Color "#00adb5"
        } else {
            if ([string]::IsNullOrWhiteSpace($Arguments)) {
                Start-Process -FilePath $fullPath -Verb RunAs
            } else {
                Start-Process -FilePath $fullPath -ArgumentList $Arguments -Verb RunAs
            }
            Set-Status -Message "Launched $DisplayName successfully." -Color "#00adb5"
        }
    } catch {
        Write-DashboardLog "[ERROR] Failed to launch $($DisplayName) - $_"
        Set-Status -Message "Failed to launch $($DisplayName): $($_.Exception.Message)" -Color "#ff5252"
    }
}

# Hardware Diagnostics & Portable Utilities
if ($null -ne $BtnToolCpuZ)          { $BtnToolCpuZ.Add_Click({ Launch-WinAurexTool "Tools\Apps\Hardware\CPU-Z.exe" "CPU-Z" }) }
if ($null -ne $BtnToolGpuZ)          { $BtnToolGpuZ.Add_Click({ Launch-WinAurexTool "Tools\Apps\Hardware\GPU-Z.exe" "GPU-Z" }) }
if ($null -ne $BtnToolHwMonitor)     { $BtnToolHwMonitor.Add_Click({ Launch-WinAurexTool "Tools\Apps\Hardware\HW-Monitor.exe" "HW-Monitor" }) }
if ($null -ne $BtnToolProcExp)       { $BtnToolProcExp.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\Process Explorer.exe" "Process Explorer" }) }
if ($null -ne $BtnToolMemReduct)     { $BtnToolMemReduct.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\memreduct-3.4-setup.exe" "MemReduct" }) }
if ($null -ne $BtnToolEverything)    { $BtnToolEverything.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\Everything-1.4.1.1024.x86-Setup.exe" "Everything Search" }) }
if ($null -ne $BtnToolTcpOpt)        { $BtnToolTcpOpt.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\TCPOptimizer.exe" "TCP Optimizer" }) }
if ($null -ne $BtnToolMsiUtil)       { $BtnToolMsiUtil.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\MSI Utility V3.exe" "MSI Utility v3" }) }
if ($null -ne $BtnToolCru)           { $BtnToolCru.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\CRU.exe" "Custom Resolution Utility (CRU)" }) }
if ($null -ne $BtnToolRufus)         { $BtnToolRufus.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\rufus-3.22p.exe" "Rufus" }) }
if ($null -ne $BtnTool7Zip)          { $BtnTool7Zip.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\7z2501-x64.exe" "7-Zip Suite" }) }
if ($null -ne $BtnToolUnlocker)      { $BtnToolUnlocker.Add_Click({ Launch-WinAurexTool "Tools\Apps\Extra\IObit Unlocker\IObitUnlocker.exe" "IObit Unlocker" }) }

# Windows Subsystem Repair Station
if ($null -ne $BtnToolRepairAudio)   { $BtnToolRepairAudio.Add_Click({ Launch-WinAurexTool "Tools\Repair\Repair_Audio.ps1" "Repair Audio" }) }
if ($null -ne $BtnToolRepairNetwork) { $BtnToolRepairNetwork.Add_Click({ Launch-WinAurexTool "Tools\Repair\Repair_Network.ps1" "Reset Network" }) }
if ($null -ne $BtnToolRepairUpdate)  { $BtnToolRepairUpdate.Add_Click({ Launch-WinAurexTool "Tools\Repair\Repair_Windows_Update.ps1" "Repair Windows Update" }) }
if ($null -ne $BtnToolRepairSfc)     { $BtnToolRepairSfc.Add_Click({ Launch-WinAurexTool "Tools\Repair\Run_SFC_And_DISM.ps1" "Run SFC / DISM" }) }

# Kernel Benchmarks & Diagnostic Utilities
if ($null -ne $BtnToolBenchmarkBoot)     { $BtnToolBenchmarkBoot.Add_Click({ Launch-WinAurexTool "Tools\Benchmark\Native\Measure_Boot_Time.ps1" "Measure Boot Time" }) }
if ($null -ne $BtnToolBenchmarkFrames)   { $BtnToolBenchmarkFrames.Add_Click({ Launch-WinAurexTool "Tools\Benchmark\Native\Analyze_Frame_Timing.ps1" "Analyze Frame Timing" }) }
if ($null -ne $BtnToolBenchmarkReport)   { $BtnToolBenchmarkReport.Add_Click({ Launch-WinAurexTool "Tools\Benchmark\Native\Generate_System_Performance_Report.ps1" "Generate Performance Report" }) }
if ($null -ne $BtnToolDetectThirdParty)  { $BtnToolDetectThirdParty.Add_Click({ Launch-WinAurexTool "Tools\Testing\Test_WinAurex_Tier.ps1" "Detect Conflicting Utilities" }) }
if ($null -ne $BtnToolCleanLogs)         { $BtnToolCleanLogs.Add_Click({ Launch-WinAurexTool "Tools\System-Info\Clean_Framework_Logs.ps1" "Clean Framework Logs" }) }
if ($null -ne $BtnToolHypervisor)        { $BtnToolHypervisor.Add_Click({ Launch-WinAurexTool "Tools\Testing\Setup_Hypervisor.cmd" "Setup Hypervisor / VBS" }) }

# --- SOFTWARE HUB TAB LOGIC ---
if ($null -ne $BtnSoftwareSelectAll) {
    $BtnSoftwareSelectAll.Add_Click({
        foreach ($chk in $AppCheckboxes) { $chk.IsChecked = $true }
        if ($null -ne $TxtSoftwareStatus) { $TxtSoftwareStatus.Text = "All packages selected ($($AppCheckboxes.Count))" }
    })
}

if ($null -ne $BtnSoftwareClear) {
    $BtnSoftwareClear.Add_Click({
        foreach ($chk in $AppCheckboxes) { $chk.IsChecked = $false }
        if ($null -ne $TxtSoftwareStatus) { $TxtSoftwareStatus.Text = "Selection cleared (0 packages)" }
    })
}

if ($null -ne $BtnSoftwareInstall) {
    $BtnSoftwareInstall.Add_Click({
        $selected = $AppCheckboxes | Where-Object { $_.IsChecked }
        if ($null -eq $selected -or $selected.Count -eq 0) {
            if ($null -ne $TxtSoftwareStatus) {
                $TxtSoftwareStatus.Text = "Please select at least one package."
                $TxtSoftwareStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ff5722")
            }
            return
        }

        $packageIds = ($selected | ForEach-Object { $_.Tag }) -join ","
        Write-DashboardLog "User requested batch software installation: $packageIds"
        
        if ($null -ne $TxtSoftwareStatus) {
            $TxtSoftwareStatus.Text = "Installing $($selected.Count) packages via winget in background..."
            $TxtSoftwareStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ffb300")
        }

        $tempScript = Join-Path $env:TEMP "winaurex_batch_installer.ps1"
        $scriptContent = @'
[CmdletBinding()]
param([string]$Ids)
$ErrorActionPreference = 'Continue'
Write-Host '======================================================================' -ForegroundColor Cyan
Write-Host '         WinAurex Silent Batch Software Installer                     ' -ForegroundColor White
Write-Host '======================================================================' -ForegroundColor Cyan
$wg = Get-Command 'winget' -ErrorAction SilentlyContinue
if (-not $wg) {
    Write-Error 'Windows Package Manager (winget.exe) is not installed on this system.'
    Exit 1
}
$idList = $Ids -split ','
$total = $idList.Count
$idx = 0
foreach ($id in $idList) {
    $idx++
    Write-Host "`n[$idx/$total] Installing $id via winget..." -ForegroundColor Cyan
    $proc = Start-Process winget -ArgumentList "install --id `"$id`" -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) {
        Write-Host "  [+] $id installed successfully!" -ForegroundColor Green
    } else {
        Write-Warning "  [-] $id install exited with code: $($proc.ExitCode)"
    }
}
Write-Host "`n[SUCCESS] Batch software installation completed!" -ForegroundColor Cyan
'@
        Set-Content -Path $tempScript -Value $scriptContent -Force

        Invoke-DashboardAction -ActionName "Software_Batch_Install" -ScriptPath $tempScript -Arguments "-Ids `"$packageIds`""
        
        if ($null -ne $TxtSoftwareStatus) {
            $TxtSoftwareStatus.Text = "Installation finished! Check Logs for details."
            $TxtSoftwareStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
        }
    })
}

# --- AI OPTIMIZER TAB LOGIC ---
if ($null -ne $BtnAiScan) {
    $BtnAiScan.Add_Click({
        Write-DashboardLog "User clicked Run AI Diagnostic Scan"
        Set-Status -Message "AI Neural Engine: Interrogating services, apps, and tasks..." -Color "#ffb300"
        if ($null -ne $TxtAiScanStatus) {
            $TxtAiScanStatus.Text = "Status: Scanning live components through neural vectorizer..."
            $TxtAiScanStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ffb300")
        }

        if ($null -ne $ProgressGlobal) {
            $ProgressGlobal.Visibility = "Visible"
            $ProgressGlobal.IsIndeterminate = $true
        }
        if ($null -ne $TxtProgressDetail) {
            $TxtProgressDetail.Visibility = "Visible"
            $TxtProgressDetail.Text = "Scanning components..."
        }
        DoEvents-WPF

        $cb = {
            param([string]$msg, [int]$pct)
            if ($null -ne $TxtAiScanStatus) {
                $TxtAiScanStatus.Text = "Status: $msg"
            }
            if ($null -ne $TxtProgressDetail) {
                $TxtProgressDetail.Text = $msg
            }
            DoEvents-WPF
        }

        # Run Live Heuristic Scan with real-time UI progress updates
        $script:LastAiFindings = Invoke-WinAurexAiScan -ProgressCallback $cb

        if ($null -ne $ProgressGlobal) {
            $ProgressGlobal.IsIndeterminate = $false
            $ProgressGlobal.Visibility = "Collapsed"
        }
        if ($null -ne $TxtProgressDetail) {
            $TxtProgressDetail.Visibility = "Collapsed"
            $TxtProgressDetail.Text = ""
        }
        
        $svcs = $script:LastAiFindings | Where-Object { $_.TargetType -eq "Service" }
        $apps = $script:LastAiFindings | Where-Object { $_.TargetType -eq "AppX" }
        $tasks = $script:LastAiFindings | Where-Object { $_.TargetType -eq "ScheduledTask" }

        # Health Score Calculation
        $health = Get-WinAurexHealthScore
        if ($null -ne $TxtAiHealthScore) {
            $TxtAiHealthScore.Text = "$($health.Score)/100"
            $color = if ($health.Score -ge 90) { "#00ff41" } elseif ($health.Score -ge 75) { "#00adb5" } else { "#ffb300" }
            $TxtAiHealthScore.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($color)
        }

        # Process Anomalies
        $script:LastAnomalies = Get-ProcessAnomalies
        if ($null -ne $TxtAiAnomaliesCount) {
            $TxtAiAnomaliesCount.Text = "$($script:LastAnomalies.Count) Flagged"
        }

        if ($null -ne $TxtAiServicesCount) { $TxtAiServicesCount.Text = "$($svcs.Count)" }
        if ($null -ne $TxtAiAppsCount) { $TxtAiAppsCount.Text = "$($apps.Count)" }
        if ($null -ne $TxtAiTasksCount) { $TxtAiTasksCount.Text = "$($tasks.Count)" }
        if ($null -ne $TxtAiCandidateCount) { $TxtAiCandidateCount.Text = "($($script:LastAiFindings.Count) Candidates)" }
        if ($null -ne $TxtAiProjectedImpact) { 
            $TxtAiProjectedImpact.Text = "-$($svcs.Count) Procs | ~$([Math]::Round($apps.Count * 45))MB" 
        }

        if ($null -ne $ListAiFindings) {
            $ListAiFindings.ItemsSource = $script:LastAiFindings
        }

        if ($null -ne $BtnAiOptimize) {
            $BtnAiOptimize.IsEnabled = ($script:LastAiFindings.Count -gt 0)
        }

        if ($null -ne $TxtAiScanStatus) {
            $TxtAiScanStatus.Text = "Status: Scan Complete! Score: $($health.Score)/100 ($($health.Grade)). Found $($script:LastAiFindings.Count) optimization candidates."
            $TxtAiScanStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
        }
        Set-Status -Message "AI Scan Complete: Score $($health.Score)/100 ($($health.Grade)), $($script:LastAiFindings.Count) candidates identified." -Color "#00ff41"
    })
}

if ($null -ne $BtnAiFilterAll) {
    $BtnAiFilterAll.Add_Click({
        if ($null -ne $ListAiFindings -and $script:LastAiFindings) {
            $ListAiFindings.ItemsSource = $script:LastAiFindings
        }
    })
}

if ($null -ne $BtnAiFilterSafe) {
    $BtnAiFilterSafe.Add_Click({
        if ($null -ne $ListAiFindings -and $script:LastAiFindings) {
            $ListAiFindings.ItemsSource = ($script:LastAiFindings | Where-Object { $_.SafetyTier -eq "Tier 1 (Safe)" })
        }
    })
}

if ($null -ne $BtnAiFilterAnomalies) {
    $BtnAiFilterAnomalies.Add_Click({
        if ($null -ne $ListAiFindings) {
            if (-not $script:LastAnomalies -or $script:LastAnomalies.Count -eq 0) {
                $script:LastAnomalies = Get-ProcessAnomalies
            }
            # Transform anomaly objects to match GridView columns
            $displayAnomalies = $script:LastAnomalies | ForEach-Object {
                [PSCustomObject]@{
                    TargetType       = "Process"
                    Name             = $_.ProcessName
                    Category         = "Resource_Anomaly"
                    SafetyTier       = "Tier 2 (Recommended)"
                    Confidence       = "95.0%"
                    CurrentState     = "PID: $($_.PID)"
                    EstSavings       = "$($_.AnomalyReason) (~$($_.WorkingSetMB) MB)"
                }
            }
            $ListAiFindings.ItemsSource = $displayAnomalies
            Set-Status -Message "Showing $($displayAnomalies.Count) background process anomalies." -Color "#00adb5"
        }
    })
}

if ($null -ne $BtnAiFlushRam) {
    $BtnAiFlushRam.Add_Click({
        Write-DashboardLog "User clicked 1-Click Flush RAM"
        Set-Status -Message "Flushing idle process working sets into free standby memory..." -Color "#ffb300"
        $flush = Invoke-WinAurexRamFlush
        Write-DashboardLog "RAM Flush Complete: Reclaimed $($flush.ReclaimedMB) MB across $($flush.ProcessesTrimmed) processes."
        
        if ($null -ne $TxtAiScanStatus) {
            $TxtAiScanStatus.Text = "Status: Reclaimed $($flush.ReclaimedMB) MB active RAM! Total Free Memory: $($flush.FreeMemoryMB) MB."
            $TxtAiScanStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
        }
        Set-Status -Message "RAM Flushed: Reclaimed $($flush.ReclaimedMB) MB across $($flush.ProcessesTrimmed) processes." -Color "#00ff41"
    })
}

if ($null -ne $BtnAiGamingShield) {
    $BtnAiGamingShield.Add_Click({
        $script:GamingShieldActive = -not $script:GamingShieldActive
        if ($script:GamingShieldActive) {
            Write-DashboardLog "User enabled AI Gaming Latency Shield"
            $shield = Set-AiGamingShield -Enable
            $BtnAiGamingShield.Content = "🎮 Gaming [ON]"
            $BtnAiGamingShield.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
            if ($null -ne $TxtAiScanStatus) {
                $TxtAiScanStatus.Text = "Status: AI Gaming Latency Shield ACTIVE (Win32PrioritySeparation = 0x28, Throttling OFF)."
                $TxtAiScanStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
            }
            Set-Status -Message "Gaming Latency Shield ACTIVE (High foreground quantum enforced)." -Color "#00ff41"
        } else {
            Write-DashboardLog "User disabled AI Gaming Latency Shield"
            $shield = Set-AiGamingShield -Disable
            $BtnAiGamingShield.Content = "🎮 Gaming Shield"
            $BtnAiGamingShield.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ffffff")
            if ($null -ne $TxtAiScanStatus) {
                $TxtAiScanStatus.Text = "Status: Gaming Latency Shield disabled (Balanced priority restored)."
                $TxtAiScanStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#aaaaaa")
            }
            Set-Status -Message "Gaming Latency Shield deactivated (Standard scheduling)." -Color "#00adb5"
        }
    })
}

if ($null -ne $BtnAiOptimize) {
    $BtnAiOptimize.Add_Click({
        Write-DashboardLog "User clicked Execute AI Neural Optimization"
        $scriptPath = Join-Path $RootPath "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"
        Invoke-DashboardAction -ActionName "AI_Neural_Optimization" -ScriptPath $scriptPath -Arguments "-Auto -Force"
        
        if ($null -ne $TxtAiScanStatus) {
            $TxtAiScanStatus.Text = "Status: AI Optimization executed successfully! Memory trimmed and services disabled."
            $TxtAiScanStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
        }
    })
}

# --- OBSERVABILITY TAB LOGIC ---
$BtnAnalyzeFrameTiming.Add_Click({
    Set-Status -Message "Analyzing Frame Timing (15s)..." -Color "#ffb300"
    $Script = Join-Path $RootPath "Tools\Benchmark\Native\Analyze_Frame_Timing.ps1"
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$Script`""
    Set-Status -Message "Analysis Complete" -Color "#00adb5"
})

$BtnMeasureBootTime.Add_Click({
    $Script = Join-Path $RootPath "Tools\Benchmark\Native\Measure_Boot_Time.ps1"
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$Script`""
})

$BtnGenerateReport.Add_Click({
    Set-Status -Message "Generating System Report..." -Color "#ffb300"
    $Script = Join-Path $RootPath "Tools\Benchmark\Native\Generate_System_Performance_Report.ps1"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Script`"" -Wait
    Set-Status -Message "Report Generated in Tools\Benchmark\Reports" -Color "#00adb5"
})

$BtnDetectThirdParty.Add_Click({
    $Script = Join-Path $RootPath "Tools\Benchmark\Integrations\Detect_ThirdParty.psm1"
    # We create a temp script to import the module and call Invoke-ThirdPartyScan
    $TempCmd = "Import-Module `"$Script`" -Force; Invoke-ThirdPartyScan; Read-Host 'Press Enter to exit...'"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$TempCmd`""
})

# --- OBSERVABILITY LIVE POLLING (Optimized) ---
# Initialize compiled .NET counters outside the loop to prevent UI blocking
try {
    $MemCounter = New-Object System.Diagnostics.PerformanceCounter("Memory", "Available MBytes")
    $DpcCounter = New-Object System.Diagnostics.PerformanceCounter("Processor", "Interrupts/sec", "_Total")
} catch { }

$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromSeconds(2)
$Timer.Add_Tick({
    # 1. Available Memory (.NET Counter)
    try {
        if ($null -ne $MemCounter) {
            $TxtMemAvailable.Text = "$([math]::Round($MemCounter.NextValue())) MB"
        }
    } catch { }

    # 2. System Uptime (.NET Environment TickCount - extremely fast)
    try {
        $Uptime = [TimeSpan]::FromMilliseconds([Environment]::TickCount64)
        $TxtUptime.Text = "$($Uptime.Days)d $($Uptime.Hours)h $($Uptime.Minutes)m"
    } catch { }

    # 3. Process, Thread & Handle Metrics (.NET Diagnostics)
    try {
        $procs = [System.Diagnostics.Process]::GetProcesses()
        $procCount = $procs.Count
        if ($null -ne $TxtProcessCount) { $TxtProcessCount.Text = "$procCount" }
        if ($null -ne $TxtHudProcessCount) { $TxtHudProcessCount.Text = "$procCount" }
        
        $totalThreads = 0
        $totalHandles = 0
        foreach ($p in $procs) {
            try {
                $totalThreads += $p.Threads.Count
                $totalHandles += $p.HandleCount
            } catch {}
        }
        if ($null -ne $TxtThreadCount) { $TxtThreadCount.Text = "$totalThreads" }
        if ($null -ne $TxtHandleCount) { $TxtHandleCount.Text = "$totalHandles" }
        if ($null -ne $TxtHudThreadCount) { $TxtHudThreadCount.Text = "$totalThreads" }
        if ($null -ne $TxtHudHandleCount) { $TxtHudHandleCount.Text = "$totalHandles" }
    } catch { }

    # 4. DPC Latency Proxy (.NET Counter)
    try {
        if ($null -ne $DpcCounter) {
            $dpcVal = [math]::Round($DpcCounter.NextValue())
            if ($null -ne $TxtDpcLatency) { $TxtDpcLatency.Text = "$dpcVal" }
            if ($null -ne $TxtHudLatencyStatus) {
                if ($dpcVal -lt 300) {
                    $TxtHudLatencyStatus.Text = "Optimal ($dpcVal µs)"
                    $TxtHudLatencyStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00ff41")
                } elseif ($dpcVal -lt 800) {
                    $TxtHudLatencyStatus.Text = "Moderate ($dpcVal µs)"
                    $TxtHudLatencyStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ffb300")
                } else {
                    $TxtHudLatencyStatus.Text = "Spiking ($dpcVal µs)"
                    $TxtHudLatencyStatus.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#ff5722")
                }
            }
        }
    } catch { }

    # 5. Periodic Defender Live Status Refresh (every 6 seconds / 3 ticks)
    $script:defTick = ($script:defTick + 1) % 3
    if ($script:defTick -eq 0) {
        Update-DefenderStatusUI
    }
})
$Timer.Start()

# --- PC CLEANER TAB LOGIC ---
function Update-DriveMetrics {
    try {
        $cDrive = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($null -ne $cDrive) {
            $total = [math]::Round(($cDrive.Used + $cDrive.Free) / 1GB, 1)
            $used  = [math]::Round($cDrive.Used / 1GB, 1)
            $free  = [math]::Round($cDrive.Free / 1GB, 1)
            if ($null -ne $TxtDriveCapacity) { $TxtDriveCapacity.Text = "$total GB" }
            if ($null -ne $TxtDriveUsed) { $TxtDriveUsed.Text = "$used GB" }
            if ($null -ne $TxtDriveFree) { $TxtDriveFree.Text = "$free GB" }
        }
    } catch { }
}

$Global:LastCleanerAnalysis = $null

if ($null -ne $BtnAnalyzeStorage) {
    $BtnAnalyzeStorage.Add_Click({
        Set-Status -Message "Scanning storage tiers for junk..." -Color "#ffb300"
        if ($null -ne $ProgressGlobal) {
            $ProgressGlobal.Visibility = "Visible"
            $ProgressGlobal.IsIndeterminate = $true
        }
        if ($null -ne $TxtProgressDetail) {
            $TxtProgressDetail.Visibility = "Visible"
            $TxtProgressDetail.Text = "Analyzing disk tiers..."
        }
        DoEvents-WPF
        
        # Run analysis
        $analysis = Get-WinAurexJunkAnalysis
        $Global:LastCleanerAnalysis = $analysis
        
        $totalBytes = 0L
        foreach ($item in $analysis) {
            if ($item.Id -ne "ComponentStore") { $totalBytes += $item.SizeBytes }
            
            switch ($item.Id) {
                "SystemTemp"        { if ($null -ne $TxtSizeSystemTemp) { $TxtSizeSystemTemp.Text = $item.SizeText } }
                "CrashDumps"        { if ($null -ne $TxtSizeCrashDumps) { $TxtSizeCrashDumps.Text = $item.SizeText } }
                "AIIndexCaches"     { if ($null -ne $TxtSizeAIIndex) { $TxtSizeAIIndex.Text = $item.SizeText } }
                "AppUpdaters"       { if ($null -ne $TxtSizeAppUpdaters) { $TxtSizeAppUpdaters.Text = $item.SizeText } }
                "SquirrelVersions"  { if ($null -ne $TxtSizeSquirrel) { $TxtSizeSquirrel.Text = $item.SizeText } }
                "BrowserCaches"     { if ($null -ne $TxtSizeBrowserCaches) { $TxtSizeBrowserCaches.Text = $item.SizeText } }
                "DevCaches"         { if ($null -ne $TxtSizeDevCaches) { $TxtSizeDevCaches.Text = $item.SizeText } }
                "LooseInstallers"   { if ($null -ne $TxtSizeLooseInstallers) { $TxtSizeLooseInstallers.Text = $item.SizeText } }
                "ComponentStore"    { if ($null -ne $TxtSizeComponentStore) { $TxtSizeComponentStore.Text = $item.SizeText } }
            }
        }
        
        if ($null -ne $TxtReclaimableTotal) { $TxtReclaimableTotal.Text = Format-Bytes $totalBytes }
        if ($null -ne $BtnCleanStorage) { $BtnCleanStorage.IsEnabled = $true }

        if ($null -ne $ProgressGlobal) {
            $ProgressGlobal.IsIndeterminate = $false
            $ProgressGlobal.Visibility = "Collapsed"
        }
        if ($null -ne $TxtProgressDetail) {
            $TxtProgressDetail.Visibility = "Collapsed"
            $TxtProgressDetail.Text = ""
        }

        Set-Status -Message "Storage analysis complete! Review tiers and click PURGE SELECTED JUNK." -Color "#00ff41"
    })
}

if ($null -ne $BtnCleanStorage) {
    $BtnCleanStorage.Add_Click({
        $selected = @()
        if ($ChkSystemTemp.IsChecked) { $selected += "SystemTemp" }
        if ($ChkCrashDumps.IsChecked) { $selected += "CrashDumps" }
        if ($ChkAIIndex.IsChecked) { $selected += "AIIndexCaches" }
        if ($ChkAppUpdaters.IsChecked) { $selected += "AppUpdaters" }
        if ($ChkSquirrel.IsChecked) { $selected += "SquirrelVersions" }
        if ($ChkBrowserCaches.IsChecked) { $selected += "BrowserCaches" }
        if ($ChkDevCaches.IsChecked) { $selected += "DevCaches" }
        if ($ChkLooseInstallers.IsChecked) { $selected += "LooseInstallers" }
        if ($ChkComponentStore.IsChecked) { $selected += "ComponentStore" }
        
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please select at least one storage tier to clean.", "No Tiers Selected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }
        
        $confirm = [System.Windows.MessageBox]::Show(
            "Are you sure you want to forcefully purge $($selected.Count) selected storage tiers?`n`nProtected user folders (Downloads, Photos, Virtual Machines, and Git Repos) will NOT be touched.",
            "Confirm PC Storage Cleanup",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        
        if ($confirm -eq 'Yes') {
            Set-Status -Message "Purging selected junk..." -Color "#ff5722"
            if ($null -ne $ProgressGlobal) {
                $ProgressGlobal.Visibility = "Visible"
                $ProgressGlobal.IsIndeterminate = $true
            }
            if ($null -ne $TxtProgressDetail) {
                $TxtProgressDetail.Visibility = "Visible"
                $TxtProgressDetail.Text = "Purging selected storage tiers..."
            }
            DoEvents-WPF

            $result = Invoke-WinAurexCleanup -Categories $selected
            Update-DriveMetrics
            
            if ($null -ne $ProgressGlobal) {
                $ProgressGlobal.IsIndeterminate = $false
                $ProgressGlobal.Visibility = "Collapsed"
            }
            if ($null -ne $TxtProgressDetail) {
                $TxtProgressDetail.Visibility = "Collapsed"
                $TxtProgressDetail.Text = ""
            }

            [System.Windows.MessageBox]::Show(
                "Cleanup completed successfully!`n`nStorage Freed: $($result.FreedText)`nNew Free Space: $($result.EndFreeText)",
                "WinAurex PC Cleaner",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
            
            Set-Status -Message "Cleanup Complete! Freed $($result.FreedText)" -Color "#00adb5"
            if ($null -ne $TxtReclaimableTotal) { $TxtReclaimableTotal.Text = "Cleaned" }
            $BtnCleanStorage.IsEnabled = $false
        }
    })
}

# --- ROLLBACK TAB LOGIC ---
function Load-Transactions {
    $ListTransactions.Items.Clear()
    if (Test-Path $BackupsDir) {
        $Manifests = Get-ChildItem -Path $BackupsDir -Filter "manifest.json" -Recurse
        foreach ($M in $Manifests) {
            $Data = Get-Content $M.FullName | ConvertFrom-Json
            
            # Format the Date nicely
            $DateFormatted = "Unknown"
            if ($Data.Timestamp) {
                try {
                    $ParsedDate = [datetime]::ParseExact($Data.Timestamp, "yyyyMMdd_HHmmss", $null)
                    $DateFormatted = $ParsedDate.ToString("yyyy-MM-dd HH:mm:ss")
                } catch {
                    $DateFormatted = $Data.Timestamp
                }
            }

            $Item = [PSCustomObject]@{
                TransactionID = $Data.TransactionID
                Profile = $Data.Profile
                Date = $DateFormatted
                ManifestPath = $M.FullName
            }
            $ListTransactions.Items.Add($Item) | Out-Null
        }
    }
}

$BtnRefreshTransactions.Add_Click({ Load-Transactions })

$ListTransactions.Add_SelectionChanged({
    if ($ListTransactions.SelectedItem) {
        $Selected = $ListTransactions.SelectedItem
        $Manifest = Get-Content $Selected.ManifestPath | ConvertFrom-Json
        $TxtTransactionDetails.Text = "ID: $($Manifest.TransactionID)`nProfile: $($Manifest.Profile)`nTime: $($Manifest.Timestamp)`nOS Build: $($Manifest.OSBuild)`nChanges: $($Manifest.Changes.Count) total state changes captured."
        $BtnRollbackSelected.IsEnabled = $true
    } else {
        $TxtTransactionDetails.Text = "Select a transaction to preview changes..."
        $BtnRollbackSelected.IsEnabled = $false
    }
})

$BtnRollbackSelected.Add_Click({
    if ($ListTransactions.SelectedItem) {
        $Selected = $ListTransactions.SelectedItem
        $IsValid = Validate-Manifest -ManifestPath $Selected.ManifestPath
        if ($IsValid) {
            $Result = [System.Windows.MessageBox]::Show("Are you sure you want to rollback to this transaction state?", "Confirm Rollback", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($Result -eq 'Yes') {
                Set-Status -Message "Rolling back..." -Color "#ff5722"
                Restore-Transaction -ManifestPath $Selected.ManifestPath
                Set-Status -Message "Rollback Complete!" -Color "#00adb5"
            }
        } else {
            [System.Windows.MessageBox]::Show("Validation Failed! OS Build mismatch or missing registry backups.", "Rollback Aborted", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
})

# Initialize Window
Load-Transactions
Update-DriveMetrics
Update-DefenderStatusUI
Initialize-HardwareHUD
Initialize-TweaksCatalog
$Window.ShowDialog() | Out-Null
