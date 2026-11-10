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
    [switch]$LaunchDashboard
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
Write-Host "  * Strips telemetry & bloatware while protecting Microsoft Store" -ForegroundColor Green
Write-Host "  * 10ms instant context menus, 1:1 raw mouse input, HAGS enabled" -ForegroundColor Green
Write-Host "  * Unlocks Ultimate Performance Plan & disables update seeding" -ForegroundColor Green
Write-Host "  * Injects WinAurex Performance Edition identity and GUI dashboard" -ForegroundColor Green
Write-Host "======================================================================`n"

# 3. Target Installation Directory (Persistent Local Storage)
$TargetDir = "$env:SystemDrive\WinAurex"
$ZipUrl = "https://github.com/YTxFSGAMERz/WinAurex/archive/refs/heads/master.zip"
$ZipFile = "$env:TEMP\winaurex_master.zip"

# If running locally from an existing repository clone on disk, use that directory
$LocalRepoRoot = $null
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and (Test-Path (Join-Path $PSScriptRoot "Apply_Curated_Safe_Suite.ps1"))) {
    $LocalRepoRoot = $PSScriptRoot
}

if (-not $LocalRepoRoot) {
    Write-Host "[1/4] Downloading latest WinAurex suite from GitHub..." -ForegroundColor Cyan
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
        
        $WorkingDir = $TargetDir
        Write-Host "[+] Download and extraction complete!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download WinAurex from GitHub: $_"
        Exit 1
    }
} else {
    Write-Host "[1/4] Running from local repository at: $LocalRepoRoot" -ForegroundColor Green
    $WorkingDir = $LocalRepoRoot
}

# 4. Create System Restore Point (Disaster Recovery Safeguard)
if (-not $SkipRestorePoint) {
    Write-Host "`n[2/4] Creating Windows System Restore Point ('Pre-WinAurex Conversion')..." -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive $env:SystemDrive -ErrorAction SilentlyContinue
        # Allow creating restore points on-demand without 24h frequency limit
        $srKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        if (-not (Test-Path $srKey)) { New-Item -Path $srKey -Force | Out-Null }
        Set-ItemProperty -Path $srKey -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Pre-WinAurex Conversion" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[+] System Restore point created successfully!" -ForegroundColor Green
    } catch {
        Write-Warning "System Restore checkpoint could not be created ($($_.Exception.Message)). Proceeding with transactional rollback engine."
    }
} else {
    Write-Host "`n[2/4] Skipping System Restore checkpoint as requested." -ForegroundColor DarkGray
}

# 5. Execute In-Place Conversion Engine
Write-Host "`n[3/4] Executing In-Place Conversion Engine..." -ForegroundColor Cyan
$ConversionScript = Join-Path $WorkingDir "Core\Conversion\Convert-ToWinAurex.ps1"

if (-not (Test-Path $ConversionScript)) {
    # Fallback to direct safe suite if conversion script not in downloaded archive
    $ConversionScript = Join-Path $WorkingDir "Apply_Curated_Safe_Suite.ps1"
}

if (Test-Path $ConversionScript) {
    & $ConversionScript -Force:$Force
} else {
    Write-Error "Could not find conversion script in $WorkingDir."
    Exit 1
}

# 6. Finalize System Integration
Write-Host "`n[4/4] Finalizing shortcuts and system integration..." -ForegroundColor Cyan
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
Write-Host "======================================================================`n"

if (-not $Force -and [Environment]::UserInteractive) {
    Write-Host "Press Enter to finish..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}
