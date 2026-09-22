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
Import-Module (Join-Path -Path $EngineDir -ChildPath "ValidationEngine.psm1") -Force
Import-Module (Join-Path -Path $EngineDir -ChildPath "RestoreEngine.psm1") -Force
$BackupsDir = Join-Path -Path $RootPath -ChildPath "Core\Restore\Backups"

# Import PC Cleaner Engine
$CleanerModule = Join-Path -Path $RootPath -ChildPath "Tools\Cleaner\WinAurex-Cleaner.psm1"
if (Test-Path $CleanerModule) {
    Import-Module $CleanerModule -Force
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
    Set-Status -Message "Applying Max Performance Profile..." -Color "#ffb300"
    $Script = Join-Path $RootPath "Profiles\Max_Performance_Profile.ps1"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Script`"" -Wait
    Set-Status -Message "Max Performance Applied!" -Color "#00adb5"
})

$BtnApplyBalanced.Add_Click({
    Set-Status -Message "Applying Balanced Creator Profile..." -Color "#ffb300"
    $Script = Join-Path $RootPath "Profiles\Balanced_Creator_Profile.ps1"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Script`"" -Wait
    Set-Status -Message "Balanced Creator Applied!" -Color "#00adb5"
})

$BtnApplyEnterprise.Add_Click({
    Set-Status -Message "Applying Enterprise Compliance Profile..." -Color "#ffb300"
    $Script = Join-Path $RootPath "Profiles\Enterprise_Compliance_Profile.ps1"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$Script`"" -Wait
    Set-Status -Message "Enterprise Compliance Applied!" -Color "#00adb5"
})

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

    # 3. Process Count (.NET Diagnostics - fast array count)
    try {
        $TxtProcessCount.Text = "$([System.Diagnostics.Process]::GetProcesses().Count)"
    } catch { }

    # 4. DPC Latency Proxy (.NET Counter)
    try {
        if ($null -ne $DpcCounter) {
            $TxtDpcLatency.Text = "$([math]::Round($DpcCounter.NextValue()))"
        }
    } catch { }
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
$Window.ShowDialog() | Out-Null
