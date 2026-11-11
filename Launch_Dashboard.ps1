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
$BtnEnableDefender   = Find-Control "BtnEnableDefender"
$BtnOpenThreatSettings = Find-Control "BtnOpenThreatSettings"
$TxtDefenderRealtimeStatus = Find-Control "TxtDefenderRealtimeStatus"
$TxtDefenderTamperStatus   = Find-Control "TxtDefenderTamperStatus"

# Footer UI Hooks
$BtnOpenLogsFolder = Find-Control "BtnOpenLogsFolder"

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
    
    $ActionLog = Join-Path $LogDir "${ActionName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $cmd = "& { Start-Transcript -Path `"$ActionLog`" -Append -Force; try { & `"$ScriptPath`" $Arguments } finally { Stop-Transcript } }"
    
    $proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -Wait -PassThru
    $exitCode = if ($proc) { $proc.ExitCode } else { 0 }
    
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
})

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
        $TxtProcessCount.Text = "$($procs.Count)"
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
    } catch { }

    # 4. DPC Latency Proxy (.NET Counter)
    try {
        if ($null -ne $DpcCounter) {
            $TxtDpcLatency.Text = "$([math]::Round($DpcCounter.NextValue()))"
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
            $result = Invoke-WinAurexCleanup -Categories $selected
            Update-DriveMetrics
            
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
$Window.ShowDialog() | Out-Null
