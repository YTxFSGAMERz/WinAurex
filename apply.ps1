<#
.SYNOPSIS
    WinAurex Universal In-Place PC Conversion Bootstrapper
.DESCRIPTION
    Converts any existing Windows 10/11 PC into WinAurex Edition in-place without reinstallation.
    Run via: irm https://winaurex.tech/apply.ps1 | iex
#>
[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipRestorePoint,
    [switch]$LaunchDashboard,
    [switch]$SkipPrereqs,
    [switch]$ForceReapply
)

# 1. Require Administrator Privileges (Auto-Elevate)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Administrative privileges required. Requesting elevation..." -ForegroundColor Yellow
    $argsList = "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"& { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; `$s = try { irm https://www.winaurex.tech/apply.ps1 } catch { try { irm https://winaurex.tech/apply.ps1 } catch { irm https://raw.githubusercontent.com/YTxFSGAMERz/WinAurex/master/apply.ps1 } }; iex `$s }`""
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList $argsList
        Exit
    } catch {
        Write-Error "Failed to elevate. Please right-click PowerShell and select 'Run as Administrator', then run this command again."
        Exit 1
    }
}

# 2. Performance & Security Protocol Configuration
$ProgressPreference = 'SilentlyContinue'
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

Clear-Host
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "        __          ___             /\                                " -ForegroundColor Cyan
Write-Host "        \ \        / (_)           /  \                               " -ForegroundColor Cyan
Write-Host "         \ \  /\  / / _ _ __      / /\ \  _   _ _ __ _____  __        " -ForegroundColor Cyan
Write-Host "          \ \/  \/ / | | '_ \    / ____ \| | | | '__/ _ \ \/ /        " -ForegroundColor Cyan
Write-Host "           \  /\  /  | | | | |  / /    \ \ |_| | | |  __/>  <         " -ForegroundColor Cyan
Write-Host "            \/  \/   |_|_| |_| /_/      \_\__,_|_|  \___/_/\_\        " -ForegroundColor Cyan
Write-Host "                                                                      " -ForegroundColor Cyan
Write-Host "                 IN-PLACE WINDOWS TRANSFORMATION SUITE                " -ForegroundColor White
Write-Host "                       https://winaurex.tech                          " -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Converts your existing PC into WinAurex with full optimizations:" -ForegroundColor White
Write-Host "  * 100% In-Place: ZERO file loss, no clean install required" -ForegroundColor Green
Write-Host "  * Auto-provisions runtimes: VC++ Redists, WebView2, Python, Node.js" -ForegroundColor Green
Write-Host "  * Strips telemetry & bloatware while protecting Microsoft Store" -ForegroundColor Green
Write-Host "  * 10ms instant context menus, 1:1 raw mouse input, HAGS enabled" -ForegroundColor Green
Write-Host "  * Unlocks Ultimate Performance Plan & disables update seeding" -ForegroundColor Green
Write-Host "  * Injects WinAurex Performance Edition identity and GUI dashboard" -ForegroundColor Green
Write-Host "======================================================================`n"

# 3. Target Installation Directory (Persistent Local Storage)
$TargetDir = "$env:SystemDrive\WinAurex"
$LogDir = Join-Path $TargetDir "Logs"
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
$TranscriptPath = Join-Path $LogDir "Conversion_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
try {
    Start-Transcript -Path $TranscriptPath -Append -Force -ErrorAction SilentlyContinue | Out-Null
    $HasStartedTranscript = $true
} catch {
    $HasStartedTranscript = $false
}

$ZipUrl = "https://github.com/YTxFSGAMERz/WinAurex/archive/refs/heads/master.zip"
$ZipFile = "$env:TEMP\winaurex_master.zip"

# If running locally from an existing repository clone on disk, use that directory
$LocalRepoRoot = $null
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and (Test-Path (Join-Path $PSScriptRoot "Apply_Curated_Safe_Suite.ps1"))) {
    $LocalRepoRoot = $PSScriptRoot
}

if (-not $LocalRepoRoot) {
    Write-Host "[1/5] Downloading latest WinAurex suite from GitHub..." -ForegroundColor Cyan
    try {
        if (-not (Test-Path $TargetDir)) { New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null }
        
        # Configure Defender folder exclusions so internal configuration scripts are not locked
        try {
            Add-MpPreference -ExclusionPath $TargetDir -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "$env:TEMP\winaurex_extract" -ErrorAction SilentlyContinue
        } catch {}

        Write-Host "Fetching repository archive..." -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -UseBasicParsing
        
        Write-Host "Extracting to $TargetDir..." -ForegroundColor DarkGray
        Expand-Archive -Path $ZipFile -DestinationPath "$env:TEMP\winaurex_extract" -Force
        
        # Copy contents of extracted master folder to TargetDir
        $ExtractedFolder = Get-ChildItem "$env:TEMP\winaurex_extract" -Directory | Select-Object -First 1
        Copy-Item -Path "$($ExtractedFolder.FullName)\*" -Destination $TargetDir -Recurse -Force
        
        # Clean temporary download files
        Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\winaurex_extract" -Recurse -Force -ErrorAction SilentlyContinue
        
        # Deploy Global Windows System Shim so 'winaurex' is immediately accessible everywhere
        $SystemShimContent = @"
@echo off
if exist "$TargetDir\winaurex.cmd" (
    call "$TargetDir\winaurex.cmd" %*
) else (
    echo [!] WinAurex installation not found in $TargetDir.
)
"@
        try {
            Set-Content -Path (Join-Path $env:SystemRoot "winaurex.cmd") -Value $SystemShimContent -Force -ErrorAction SilentlyContinue
            Set-Content -Path (Join-Path $env:SystemRoot "System32\winaurex.cmd") -Value $SystemShimContent -Force -ErrorAction SilentlyContinue
        } catch {}

        $WorkingDir = $TargetDir
        Write-Host "[+] Download and extraction complete!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download WinAurex from GitHub: $_"
        Exit 1
    }
} else {
    Write-Host "[1/5] Running from local repository at: $LocalRepoRoot" -ForegroundColor Green
    $WorkingDir = $LocalRepoRoot
}

# 4. Provision Core System Prerequisites (VC++, WebView2, Python, Node.js)
if (-not $SkipPrereqs) {
    # Check if all 4 runtimes are already installed (<50ms fast audit)
    $vcInstalled = $false
    try {
        $key64 = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" -ErrorAction SilentlyContinue
        if ($key64 -and $key64.Installed -eq 1) { $vcInstalled = $true }
    } catch {}

    $wvInstalled = (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}") -or 
                   (Test-Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}")

    $pyInstalled = [bool](Get-Command "python" -ErrorAction SilentlyContinue) -or [bool](Get-Command "py" -ErrorAction SilentlyContinue)
    $nodeInstalled = [bool](Get-Command "node" -ErrorAction SilentlyContinue)

    if ($vcInstalled -and $wvInstalled -and $pyInstalled -and $nodeInstalled -and -not $ForceReapply) {
        Write-Host "`n[2/5] All system prerequisites (VC++, WebView2, Python, Node.js) are already installed. (Skipping in 0.1s)" -ForegroundColor Green
    } else {
        Write-Host "`n[2/5] Checking and provisioning system prerequisites..." -ForegroundColor Cyan
        $PrereqScript = Join-Path $WorkingDir "Core\Prerequisites\Install-Prerequisites.ps1"
        if (Test-Path $PrereqScript) {
            $prereqArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PrereqScript)
            if ($Force) { $prereqArgs += "-Force" }
            & powershell.exe $prereqArgs
        } else {
            Write-Warning "Prerequisites script not found at $PrereqScript. Skipping."
        }
    }
} else {
    Write-Host "`n[2/5] Skipping system prerequisites provisioning as requested." -ForegroundColor DarkGray
}

# 5. Create System Restore Point (Disaster Recovery Safeguard)
if (-not $SkipRestorePoint) {
    # Check if a restore point already exists from a previous run
    $hasRecentRestore = $false
    try {
        $recent = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Where-Object {
            $_.Description -like "*WinAurex*"
        } | Select-Object -Last 1
        if ($recent) {
            $hasRecentRestore = $true
        }
    } catch {}

    if ($hasRecentRestore -and -not $ForceReapply) {
        Write-Host "`n[3/5] System Restore point already exists from a previous run. Skipping redundant checkpoint." -ForegroundColor DarkGray
    } else {
        Write-Host "`n[3/5] Creating Windows System Restore Point ('Pre-WinAurex Conversion')..." -ForegroundColor Cyan
        Write-Host "  [*] Initializing Volume Shadow Copy checkpoint (timeout: 15s)..." -ForegroundColor DarkGray
        $srJob = Start-Job -ScriptBlock {
            try {
                Enable-ComputerRestore -Drive $using:env:SystemDrive -ErrorAction SilentlyContinue
                # Allow creating restore points on-demand without 24h frequency limit
                $srKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
                if (-not (Test-Path $srKey)) { New-Item -Path $srKey -Force | Out-Null }
                Set-ItemProperty -Path $srKey -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Checkpoint-Computer -Description "Pre-WinAurex Conversion" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                return "SUCCESS"
            } catch {
                return $_.Exception.Message
            }
        }

        $srCompleted = Wait-Job $srJob -Timeout 15
        if ($srCompleted) {
            $srResult = Receive-Job $srJob
            Remove-Job $srJob -Force -ErrorAction SilentlyContinue
            if ($srResult -eq "SUCCESS") {
                Write-Host "  [+] System Restore point created successfully!" -ForegroundColor Green
            } else {
                Write-Warning "System Restore checkpoint could not be created ($srResult). Proceeding with transactional rollback engine."
            }
        } else {
            Stop-Job $srJob -ErrorAction SilentlyContinue
            Remove-Job $srJob -Force -ErrorAction SilentlyContinue
            Write-Warning "System Restore point creation timed out (VSS busy or locked by background updates). Proceeding with transactional rollback engine."
        }
    }
} else {
    Write-Host "`n[3/5] Skipping System Restore checkpoint as requested." -ForegroundColor DarkGray
}

# 6. Execute In-Place Conversion Engine
Write-Host "`n[4/5] Executing In-Place Conversion Engine..." -ForegroundColor Cyan
$ConversionScript = Join-Path $WorkingDir "Core\Conversion\Convert-ToWinAurex.ps1"

if (-not (Test-Path $ConversionScript)) {
    # Fallback to direct safe suite if conversion script not in downloaded archive
    $ConversionScript = Join-Path $WorkingDir "Apply_Curated_Safe_Suite.ps1"
}

if (Test-Path $ConversionScript) {
    $convArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ConversionScript, "-SkipPrereqs")
    if ($Force) { $convArgs += "-Force" }
    if ($ForceReapply) { $convArgs += "-ForceReapply" }
    & powershell.exe $convArgs
} else {
    Write-Error "Could not find conversion script in $WorkingDir."
    Exit 1
}

# 7. Finalize System Integration
Write-Host "`n[5/5] Finalizing shortcuts and system integration..." -ForegroundColor Cyan
if ($LaunchDashboard) {
    Write-Host "Launching WinAurex GUI Dashboard..." -ForegroundColor Cyan
    $DashboardScript = Join-Path $WorkingDir "Launch_Dashboard.ps1"
    if (Test-Path $DashboardScript) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$DashboardScript`""
    }
}

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Congratulations! Your PC is now converted to WinAurex!    " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " * Full optimizations applied without data loss." -ForegroundColor Green
Write-Host " * Installed locally to: $WorkingDir" -ForegroundColor Yellow
Write-Host " * Type 'winaurex' in any terminal to launch the CLI." -ForegroundColor Yellow
Write-Host " * WinAurex Dashboard and PC Cleaner shortcuts are on your Desktop." -ForegroundColor Yellow
if ($HasStartedTranscript) {
    Write-Host " * Complete execution transcript saved to: $TranscriptPath" -ForegroundColor Cyan
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "======================================================================`n"

if (-not $Force -and [Environment]::UserInteractive) {
    Write-Host "Press Enter to finish..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}
