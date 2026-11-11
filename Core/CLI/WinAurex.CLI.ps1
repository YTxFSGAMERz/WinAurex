<#
.SYNOPSIS
    WinAurex Unified CLI Engine
.DESCRIPTION
    Provides a comprehensive, unified command-line interface for the WinAurex framework.
    Dispatches to optimization, cleanup, profiling, repair, benchmark, and diagnostic modules.
.EXAMPLE
    winaurex status
    winaurex optimize --recommended
    winaurex clean --force
    winaurex profile max-performance --force
    winaurex repair sfc --force
    winaurex bench health --force
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$SubTarget,

    [switch]$Force,
    [switch]$Help,
    [switch]$Version,
    [switch]$Recommended,
    [switch]$All,
    [switch]$Aggressive,
    [switch]$Deep,
    [switch]$NoElevate
)

$VERSION_NUMBER = "1.2.0"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Show-Version {
    Write-Host "WinAurex CLI v$VERSION_NUMBER - Advanced Windows Optimization Suite" -ForegroundColor Cyan
    Write-Host "Repository: https://github.com/YTxFSGAMERz/WinAurex" -ForegroundColor DarkGray
}

function Show-Help {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "                   WINAUREX UNIFIED COMMAND-LINE INTERFACE                " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "Version: $VERSION_NUMBER" -ForegroundColor Gray
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  winaurex [command] [options]"
    Write-Host ""
    Write-Host "COMMANDS:" -ForegroundColor Yellow
    Write-Host "  status                    Display live system hardware & diagnostic report"
    Write-Host "  optimize                  Run batch & registry performance optimizations"
    Write-Host "                            Flags: --recommended (default), --all, --force"
    Write-Host "  clean                     Purge temp files, caches, and Windows Update downloads"
    Write-Host "                            Flags: --aggressive, --deep, --force"
    Write-Host "  profile <name>            Apply a system tuning profile"
    Write-Host "                            Profiles: max-performance, balanced, enterprise"
    Write-Host "  repair <target>           Run system integrity & hardware stack repairs"
    Write-Host "                            Targets: sfc, dism, network, audio, update"
    Write-Host "  bench <type>              Run native performance observability benchmarks"
    Write-Host "                            Types: boot, timing, health"
    Write-Host "  rollback                  Revert settings to previous snapshot or defaults"
    Write-Host "                            Subtargets: last, defaults"
    Write-Host "  prereqs | deps            Check & provision runtimes (VC++, WebView2, Python, Node.js)"
    Write-Host "  debloat                   Deep OS debloat & consumer appx package purge"
    Write-Host "  services                  Permanently disable 15+ useless background services"
    Write-Host "  reduce-threads            Reduce active processes, threads, and kernel handles"
    Write-Host "  defender <action>         Manage Defender policy (actions: disable, enable, status)"
    Write-Host "  update                    Check for & apply latest WinAurex updates from GitHub"
    Write-Host "  dashboard | gui           Launch the Graphical WPF Dashboard"
    Write-Host "  menu                      Launch interactive CLI menu dashboard"
    Write-Host ""
    Write-Host "GLOBAL FLAGS:" -ForegroundColor Yellow
    Write-Host "  -Force, -f                Bypass confirmation prompts (Automated / CI Mode)"
    Write-Host "  -Help, -h                 Show this help overview"
    Write-Host "  -Version, -v              Display current WinAurex CLI version"
    Write-Host "  -NoElevate                Do not auto-request UAC Administrator elevation"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  winaurex status"
    Write-Host "  winaurex optimize -Force"
    Write-Host "  winaurex clean --aggressive -Force"
    Write-Host "  winaurex profile max-performance -Force"
    Write-Host "  winaurex repair sfc -Force"
    Write-Host "  winaurex bench health -Force"
    Write-Host "==========================================================================" -ForegroundColor Cyan
}

# Check version or help flags
if ($Version -or $Command -in @("-v", "--version", "version")) {
    Show-Version
    exit 0
}

if ($Help -or $Command -in @("-h", "--help", "help", "/?")) {
    Show-Help
    exit 0
}

# Check Admin Rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Commands that do not require Admin privileges
$readOnlyCommands = @("status", "version", "--version", "-v", "help", "--help", "-h")

if (-not $isAdmin -and ($Command -notin $readOnlyCommands) -and -not $NoElevate) {
    Write-Host "[*] Administrator privileges required. Requesting UAC elevation..." -ForegroundColor Yellow
    $allArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    if ($Command) { $allArgs += $Command }
    if ($SubTarget) { $allArgs += $SubTarget }
    if ($Force) { $allArgs += "-Force" }
    if ($Recommended) { $allArgs += "-Recommended" }
    if ($All) { $allArgs += "-All" }
    if ($Aggressive) { $allArgs += "-Aggressive" }
    if ($Deep) { $allArgs += "-Deep" }

    $proc = Start-Process powershell -ArgumentList $allArgs -Verb RunAs -Wait -PassThru
    exit $proc.ExitCode
}

# Helper to run script cleanly
function Invoke-WinAurexScript {
    param([string]$RelativePath, [string[]]$ScriptArgs = @())
    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $fullPath)) {
        Write-Host "[ERROR] Script not found: $fullPath" -ForegroundColor Red
        return 1
    }
    
    if ($fullPath.EndsWith(".bat") -or $fullPath.EndsWith(".cmd")) {
        $cmdLine = "`"$fullPath`" " + ($ScriptArgs -join " ")
        & cmd.exe /c $cmdLine
        return
    } else {
        $pArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$fullPath`"") + $ScriptArgs
        & powershell.exe $pArgs
        return
    }
}

function Show-InteractiveMenu {
    while ($true) {
        try {
            if (-not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected) {
                Clear-Host
            }
        } catch {}

        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "                     WINAUREX INTERACTIVE CLI CONSOLE                     " -ForegroundColor Cyan
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "  1. System Diagnostic Status Report" -ForegroundColor White
        Write-Host "  2. Apply Recommended System Optimizations" -ForegroundColor Green
        Write-Host "  3. Quick Storage & Temp Files Cleanup" -ForegroundColor Yellow
        Write-Host "  4. Deep Component Storage Cleanup (Aggressive)" -ForegroundColor Yellow
        Write-Host "  5. Apply Max Performance Profile (Esports / Audio / Gaming)" -ForegroundColor Cyan
        Write-Host "  6. Apply Balanced Creator Profile (Power Users / Devs)" -ForegroundColor Cyan
        Write-Host "  7. System File Checker & DISM Repair" -ForegroundColor White
        Write-Host "  8. Network Stack Repair (DNS / Winsock / IP)" -ForegroundColor White
        Write-Host "  9. Audio Services Restart & Latency Fix" -ForegroundColor White
        Write-Host " 10. Generate System Performance HTML Report" -ForegroundColor Magenta
        Write-Host " 11. Launch Graphical Dashboard (WPF)" -ForegroundColor Magenta
        Write-Host " 12. Rollback Registry to Last Snapshot" -ForegroundColor Red
        Write-Host " 13. Check & Apply Latest WinAurex Updates (GitHub)" -ForegroundColor Green
        Write-Host "  0. Exit" -ForegroundColor DarkGray
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host ""

        $choice = Read-Host "Select an option [0-13]"

        switch ($choice) {
            "1"  { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot "Tools\System-Info\Generate_System_Report.ps1"); Read-Host "`nPress Enter to continue..." }
            "2"  { Invoke-WinAurexScript -RelativePath "Tweaks\Apply Optimizations.bat" -ScriptArgs @(":recommended"); Read-Host "`nPress Enter to continue..." }
            "3"  { Invoke-WinAurexScript -RelativePath "Tweaks\Resources\Delete Temporary Files.bat"; Read-Host "`nPress Enter to continue..." }
            "4"  { Invoke-WinAurexScript -RelativePath "Tweaks\Storage-Aggressive\Deep Component Cleanup (Aggressive).bat" -ScriptArgs @("/force"); Read-Host "`nPress Enter to continue..." }
            "5"  { Invoke-WinAurexScript -RelativePath "Profiles\Max_Performance_Profile.ps1"; Read-Host "`nPress Enter to continue..." }
            "6"  { Invoke-WinAurexScript -RelativePath "Profiles\Balanced_Creator_Profile.ps1"; Read-Host "`nPress Enter to continue..." }
            "7"  { Invoke-WinAurexScript -RelativePath "Tools\Repair\Run_SFC_And_DISM.ps1"; Read-Host "`nPress Enter to continue..." }
            "8"  { Invoke-WinAurexScript -RelativePath "Tools\Repair\Repair_Network.ps1"; Read-Host "`nPress Enter to continue..." }
            "9"  { Invoke-WinAurexScript -RelativePath "Tools\Repair\Repair_Audio.ps1"; Read-Host "`nPress Enter to continue..." }
            "10" { Invoke-WinAurexScript -RelativePath "Tools\Benchmark\Native\Generate_System_Performance_Report.ps1"; Read-Host "`nPress Enter to continue..." }
            "11" { Invoke-WinAurexScript -RelativePath "Launch_Dashboard.ps1" }
            "12" { Invoke-WinAurexScript -RelativePath "Core\Restore\Rollback_Last_Changes.ps1"; Read-Host "`nPress Enter to continue..." }
            "13" {
                Write-Host "`n[*] Fetching and applying latest WinAurex updates..." -ForegroundColor Cyan
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; irm https://www.winaurex.tech/apply.ps1 | iex"
                Read-Host "`nPress Enter to continue..."
            }
            "0"  { Write-Host "Exiting WinAurex CLI." -ForegroundColor Cyan; break }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# Route Commands
switch ($Command.ToLowerInvariant()) {
    "status" {
        $reportScript = Join-Path $RepoRoot "Tools\System-Info\Generate_System_Report.ps1"
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $reportScript -Force
    }

    "optimize" {
        Write-Host "[*] Executing WinAurex System Optimizations..." -ForegroundColor Cyan
        $batFile = "Tweaks\Apply Optimizations.bat"
        $target = if ($All) { ":all" } else { ":recommended" }
        Invoke-WinAurexScript -RelativePath $batFile -ScriptArgs @($target)
    }

    "clean" {
        Write-Host "[*] Cleaning temporary files & caches..." -ForegroundColor Cyan
        $tempBat = "Tweaks\Resources\Delete Temporary Files.bat"
        Invoke-WinAurexScript -RelativePath $tempBat

        if ($Aggressive -or $Deep) {
            Write-Host "[*] Executing Deep Component Cleanup (Aggressive)..." -ForegroundColor Yellow
            $deepBat = "Tweaks\Storage-Aggressive\Deep Component Cleanup (Aggressive).bat"
            Invoke-WinAurexScript -RelativePath $deepBat -ScriptArgs @("/force")
        }
        Write-Host "[SUCCESS] Cleanup operations complete!" -ForegroundColor Green
    }

    "profile" {
        $pName = ($SubTarget -replace "_", "-").ToLowerInvariant()
        switch -Regex ($pName) {
            "^(max|perf|max-performance)$" {
                Write-Host "[*] Applying Max Performance Profile..." -ForegroundColor Cyan
                $f = if ($Force) { @("-Force") } else { @() }
                Invoke-WinAurexScript -RelativePath "Profiles\Max_Performance_Profile.ps1" -ScriptArgs $f
            }
            "^(bal|balanced|creator)$" {
                Write-Host "[*] Applying Balanced Creator Profile..." -ForegroundColor Cyan
                $f = if ($Force) { @("-Force") } else { @() }
                Invoke-WinAurexScript -RelativePath "Profiles\Balanced_Creator_Profile.ps1" -ScriptArgs $f
            }
            "^(ent|enterprise|compliance)$" {
                Write-Host "[*] Applying Enterprise Compliance Profile..." -ForegroundColor Cyan
                $f = if ($Force) { @("-Force") } else { @() }
                Invoke-WinAurexScript -RelativePath "Profiles\Enterprise_Compliance_Profile.ps1" -ScriptArgs $f
            }
            default {
                Write-Host "[!] Unknown profile '$SubTarget'. Available: max-performance, balanced, enterprise" -ForegroundColor Red
                exit 1
            }
        }
    }

    "repair" {
        $rName = $SubTarget.ToLowerInvariant()
        $f = if ($Force) { @("-Force") } else { @() }
        switch -Regex ($rName) {
            "^(sfc|dism|sys)$" {
                Invoke-WinAurexScript -RelativePath "Tools\Repair\Run_SFC_And_DISM.ps1" -ScriptArgs $f
            }
            "^(net|network|dns|ip)$" {
                Invoke-WinAurexScript -RelativePath "Tools\Repair\Repair_Network.ps1" -ScriptArgs $f
            }
            "^(audio|sound)$" {
                Invoke-WinAurexScript -RelativePath "Tools\Repair\Repair_Audio.ps1" -ScriptArgs $f
            }
            "^(wu|update|updates)$" {
                Invoke-WinAurexScript -RelativePath "Tools\Repair\Repair_Windows_Update.ps1" -ScriptArgs $f
            }
            default {
                Write-Host "[!] Unknown repair target '$SubTarget'. Available: sfc, network, audio, update" -ForegroundColor Red
                exit 1
            }
        }
    }

    "bench" {
        $bName = $SubTarget.ToLowerInvariant()
        $f = if ($Force) { @("-Force") } else { @() }
        switch -Regex ($bName) {
            "^(boot|boottime)$" {
                Invoke-WinAurexScript -RelativePath "Tools\Benchmark\Native\Measure_Boot_Time.ps1" -ScriptArgs $f
            }
            "^(timing|frametime|frame)$" {
                Invoke-WinAurexScript -RelativePath "Tools\Benchmark\Native\Analyze_Frame_Timing.ps1" -ScriptArgs $f
            }
            "^(health|report|all)$" {
                Invoke-WinAurexScript -RelativePath "Tools\Benchmark\Native\Generate_System_Performance_Report.ps1" -ScriptArgs $f
            }
            default {
                Write-Host "[!] Unknown benchmark '$SubTarget'. Available: boot, timing, health" -ForegroundColor Red
                exit 1
            }
        }
    }

    "rollback" {
        $rbTarget = $SubTarget.ToLowerInvariant()
        $f = if ($Force) { @("-Force") } else { @() }
        if ($rbTarget -eq "defaults") {
            Invoke-WinAurexScript -RelativePath "Core\Restore\Restore_All_Defaults.ps1" -ScriptArgs $f
        } else {
            Invoke-WinAurexScript -RelativePath "Core\Restore\Rollback_Last_Changes.ps1" -ScriptArgs $f
        }
    }

    "gui" {
        Write-Host "[*] Launching WinAurex Graphical Dashboard..." -ForegroundColor Cyan
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Launch_Dashboard.ps1" -ScriptArgs $f
    }
    "dashboard" {
        Write-Host "[*] Launching WinAurex Graphical Dashboard..." -ForegroundColor Cyan
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Launch_Dashboard.ps1" -ScriptArgs $f
    }

    "prereqs" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Core\Prerequisites\Install-Prerequisites.ps1" -ScriptArgs $f
    }
    "requirements" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Core\Prerequisites\Install-Prerequisites.ps1" -ScriptArgs $f
    }
    "deps" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Core\Prerequisites\Install-Prerequisites.ps1" -ScriptArgs $f
    }
    "install-deps" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Core\Prerequisites\Install-Prerequisites.ps1" -ScriptArgs $f
    }

    "services" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Tweaks\Services\Optimize_Windows_Services.ps1" -ScriptArgs $f
    }

    "debloat" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Tweaks\Apps\Deep_OS_Debloat.ps1" -ScriptArgs $f
    }

    "reduce-threads" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Tweaks\Performance\Reduce_Processes_And_Threads.ps1" -ScriptArgs $f
    }
    "reduce-processes" {
        $f = if ($Force) { @("-Force") } else { @() }
        Invoke-WinAurexScript -RelativePath "Tweaks\Performance\Reduce_Processes_And_Threads.ps1" -ScriptArgs $f
    }

    "defender" {
        $act = $SubTarget.ToLowerInvariant()
        $argsList = @()
        if ($act -in @("disable", "off", "stop")) {
            $argsList += "-Disable"
        } elseif ($act -in @("enable", "on", "start", "restore")) {
            $argsList += "-Enable"
        } elseif ($act -in @("status", "check")) {
            $argsList += "-Status"
        } else {
            $argsList += "-Disable"
        }
        if ($Force) { $argsList += "-Force" }
        Invoke-WinAurexScript -RelativePath "Tweaks\Security\Configure_Defender_Policy.ps1" -ScriptArgs $argsList
    }

    "update" {
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "                    WINAUREX IN-PLACE SELF-UPDATE                        " -ForegroundColor Cyan
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "[*] Fetching and applying latest WinAurex updates from GitHub..." -ForegroundColor Cyan
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
            $bootstrap = try { irm https://www.winaurex.tech/apply.ps1 } catch { irm https://raw.githubusercontent.com/YTxFSGAMERz/WinAurex/master/apply.ps1 }
            & ([ScriptBlock]::Create($bootstrap)) -Force
        } catch {
            Write-Error "Failed to update WinAurex: $_"
            exit 1
        }
    }

    "menu" {
        Show-InteractiveMenu
    }

    "" {
        Show-InteractiveMenu
    }

    default {
        Write-Host "[!] Unknown command: '$Command'" -ForegroundColor Red
        Write-Host "Run 'winaurex --help' to see all available commands." -ForegroundColor Yellow
        exit 1
    }
}

