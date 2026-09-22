<#
.SYNOPSIS
    WinAurex-Cleaner.psm1 - Core Storage & PC Junk Cleaning Module for WinAurex
.DESCRIPTION
    High-performance storage analysis and forceful cleaning engine for Windows.
    Categorizes system junk, obsolete caches, crash dumps, AI indexes, and squirrel versions.
    Enforces strict zero-touch protection for user personal folders (Downloads, Photos, VMs, Git repos).
#>

function Get-FolderSizeFast {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0L }
    try {
        $out = cmd.exe /c "robocopy `"$Path`" `"$env:TEMP\winaurex_fake`" /L /E /BYTES /NFL /NDL /NJH /XJ /R:0 /W:0"
        $bytesLine = $out | Select-String -Pattern "Bytes :" | Select-Object -First 1
        if ($bytesLine -match "Bytes\s*:\s*(\d+)") {
            return [int64]$matches[1]
        }
    } catch { }
    return 0L
}

function Format-Bytes {
    param([int64]$Bytes)
    if ($Bytes -ge 1GB) {
        return "$([math]::Round($Bytes / 1GB, 2)) GB"
    } elseif ($Bytes -ge 1MB) {
        return "$([math]::Round($Bytes / 1MB, 2)) MB"
    } elseif ($Bytes -ge 1KB) {
        return "$([math]::Round($Bytes / 1KB, 2)) KB"
    }
    return "$Bytes B"
}

function Test-IsProtectedPath {
    param([string]$Path)
    $normalized = $Path.Trim().ToLowerInvariant()
    $protectedKeywords = @(
        "\downloads",
        "\pictures",
        "\photos",
        "\camera roll",
        "\saved pictures",
        "\virtual machines",
        "\desktop",
        "\documents\github"
    )
    foreach ($p in $protectedKeywords) {
        if ($normalized.Contains($p)) { return $true }
    }
    return $false
}

function Get-WinAurexJunkAnalysis {
    [CmdletBinding()]
    param()

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $userProfile = $env:USERPROFILE
    $localAppData = $env:LOCALAPPDATA
    $appData = $env:APPDATA

    # 1. System & User Temp
    $tempPaths = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\Logs\cbs",
        "C:\Windows\Logs\MoSetup",
        "C:\Windows\Panther"
    )
    $tempBytes = 0L
    foreach ($tp in $tempPaths) {
        if ((Test-Path $tp) -and -not (Test-IsProtectedPath $tp)) {
            $tempBytes += Get-FolderSizeFast $tp
        }
    }
    $results.Add([PSCustomObject]@{
        Id          = "SystemTemp"
        Category    = "System & User Temporary Files"
        SizeBytes   = $tempBytes
        SizeText    = Format-Bytes $tempBytes
        Safety      = "Zero Risk"
        Recommended = $true
        Description = "Temporary files created by Windows and apps ($env:TEMP, Windows\Temp, log files)."
    })

    # 2. Crash Dumps & Error Reports
    $dumpPaths = @(
        "$localAppData\CrashDumps",
        "$localAppData\Microsoft\Windows\WER\ReportArchive",
        "$localAppData\Microsoft\Windows\WER\ReportQueue",
        "C:\ProgramData\Microsoft\Windows\WER\ReportArchive"
    )
    $dumpBytes = 0L
    foreach ($dp in $dumpPaths) {
        if ((Test-Path $dp) -and -not (Test-IsProtectedPath $dp)) {
            $dumpBytes += Get-FolderSizeFast $dp
        }
    }
    $results.Add([PSCustomObject]@{
        Id          = "CrashDumps"
        Category    = "Application Crash Dumps (.dmp)"
        SizeBytes   = $dumpBytes
        SizeText    = Format-Bytes $dumpBytes
        Safety      = "Zero Risk"
        Recommended = $true
        Description = "Memory dumps generated when programs crash. Completely useless for normal daily use."
    })

    # 3. Stale Copilot & AI Code Search Indexes
    $copilotIndexDir = "$localAppData\copilot\tgrep-index"
    $copilotBytes = 0L
    if (Test-Path $copilotIndexDir) {
        Get-ChildItem -Path $copilotIndexDir -Directory | ForEach-Object {
            $retDir = Join-Path $_.FullName ".retired"
            if (Test-Path $retDir) { $copilotBytes += Get-FolderSizeFast $retDir }
            Get-ChildItem -Path $_.FullName -Filter "spill-*.tmp" -Directory | ForEach-Object {
                $copilotBytes += Get-FolderSizeFast $_.FullName
            }
        }
    }
    $results.Add([PSCustomObject]@{
        Id          = "AIIndexCaches"
        Category    = "Stale Copilot / AI Search Spill Dumps"
        SizeBytes   = $copilotBytes
        SizeText    = Format-Bytes $copilotBytes
        Safety      = "Zero Risk"
        Recommended = $true
        Description = "Old retired search index versions and crashed spillover tmp folders from Copilot CLI."
    })

    # 4. Orphan App Updaters & Update Downloads
    $updaterBytes = 0L
    $updaterPaths = @(
        "$localAppData\kimi-desktop-updater\pending",
        "$localAppData\Ollama\updates_v2"
    )
    if (Test-Path "$localAppData\kimi-desktop-updater\installer.exe") {
        $updaterBytes += (Get-Item "$localAppData\kimi-desktop-updater\installer.exe").Length
    }
    foreach ($up in $updaterPaths) {
        if (Test-Path $up) { $updaterBytes += Get-FolderSizeFast $up }
    }
    $results.Add([PSCustomObject]@{
        Id          = "AppUpdaters"
        Category    = "Orphan Application Updater Installers"
        SizeBytes   = $updaterBytes
        SizeText    = Format-Bytes $updaterBytes
        Safety      = "Zero Risk"
        Recommended = $true
        Description = "Downloaded update installers left behind by desktop apps (Kimi, Ollama, etc.)."
    })

    # 5. Obsolete Squirrel App Previous Builds
    $squirrelBytes = 0L
    $squirrelApps = @(
        @{ Path = "$localAppData\GitHubDesktop"; Prefix = "app-" },
        @{ Path = "$localAppData\Discord"; Prefix = "app-" },
        @{ Path = "$localAppData\AnthropicClaude"; Prefix = "app-" }
    )
    foreach ($sa in $squirrelApps) {
        if (Test-Path $sa.Path) {
            $appDirs = Get-ChildItem -Path $sa.Path -Directory -Filter "$($sa.Prefix)*" | Sort-Object Name -Descending
            if ($appDirs.Count -gt 1) {
                # Keep first (newest), count the rest as obsolete
                $appDirs | Select-Object -Skip 1 | ForEach-Object {
                    $squirrelBytes += Get-FolderSizeFast $_.FullName
                }
            }
            # Add downloaded .nupkg in packages folder
            $pkgDir = Join-Path $sa.Path "packages"
            if (Test-Path $pkgDir) { $squirrelBytes += Get-FolderSizeFast $pkgDir }
        }
    }
    $results.Add([PSCustomObject]@{
        Id          = "SquirrelVersions"
        Category    = "Obsolete Previous App Versions (Electron/Squirrel)"
        SizeBytes   = $squirrelBytes
        SizeText    = Format-Bytes $squirrelBytes
        Safety      = "Zero Risk"
        Recommended = $true
        Description = "Old versions kept on disk by auto-updating Electron apps (GitHub Desktop, Discord, Claude)."
    })

    # 6. Package Manager & Dev Caches
    $devBytes = 0L
    $devPaths = @(
        "$localAppData\npm-cache",
        "$localAppData\pnpm-cache",
        "$localAppData\pip\cache",
        "$localAppData\ms-playwright",
        "$userProfile\node_modules"
    )
    foreach ($dp in $devPaths) {
        if (Test-Path $dp) { $devBytes += Get-FolderSizeFast $dp }
    }
    $results.Add([PSCustomObject]@{
        Id          = "DevCaches"
        Category    = "Package Manager & Build Caches"
        SizeBytes   = $devBytes
        SizeText    = Format-Bytes $devBytes
        Safety      = "Low Risk"
        Recommended = $true
        Description = "npm, pnpm, pip, and Playwright browser caches. Can be re-downloaded anytime on demand."
    })

    # 7. Web Browser Caches (Non-Destructive)
    $browserBytes = 0L
    $browserPaths = @(
        "$localAppData\Microsoft\Edge\User Data\Default\Cache",
        "$localAppData\Microsoft\Edge\User Data\Default\Code Cache",
        "$localAppData\Google\Chrome\User Data\Default\Cache",
        "$localAppData\Google\Chrome\User Data\Default\Code Cache",
        "$localAppData\BraveSoftware\Brave-Browser\User Data\Default\Cache",
        "$localAppData\BraveSoftware\Brave-Browser\User Data\Default\Code Cache"
    )
    foreach ($bp in $browserPaths) {
        if (Test-Path $bp) { $browserBytes += Get-FolderSizeFast $bp }
    }
    $results.Add([PSCustomObject]@{
        Id          = "BrowserCaches"
        Category    = "Web Browser Code & Media Caches"
        SizeBytes   = $browserBytes
        SizeText    = Format-Bytes $browserBytes
        Safety      = "Low Risk"
        Recommended = $true
        Description = "Edge, Chrome, and Brave web cache files. Preserves passwords, cookies, history, and logins."
    })

    # 8. Leftover Root Installer Debris
    $looseBytes = 0L
    $rootFiles = @(
        "C:\install.exe",
        "C:\VC_RED.cab",
        "C:\VC_RED.MSI",
        "C:\globdata.ini",
        "C:\install.ini",
        "C:\vcredist.bmp",
        "C:\WinAurexTemp_Raw.vhd",
        "C:\WinAurexTemp_Extracted.efi",
        "C:\robocopy.log"
    )
    foreach ($rf in $rootFiles) {
        if (Test-Path $rf) { $looseBytes += (Get-Item $rf).Length }
    }
    Get-ChildItem -Path "C:\" -Filter "eula.*.txt" -ErrorAction SilentlyContinue | ForEach-Object { $looseBytes += $_.Length }
    Get-ChildItem -Path "C:\" -Filter "install.res.*.dll" -ErrorAction SilentlyContinue | ForEach-Object { $looseBytes += $_.Length }
    $results.Add([PSCustomObject]@{
        Id          = "LooseInstallers"
        Category    = "Loose Root Setup Debris & Broken Parts"
        SizeBytes   = $looseBytes
        SizeText    = Format-Bytes $looseBytes
        Safety      = "Zero Risk"
        Recommended = $true
        Description = "Accidental loose VC redist installer files in C:\ and incomplete download parts."
    })

    # 9. Windows Component Store (DISM)
    $results.Add([PSCustomObject]@{
        Id          = "ComponentStore"
        Category    = "Windows Component Store (WinSxS / DISM)"
        SizeBytes   = 3800000000L # Estimated ~3.8 GB
        SizeText    = "~3.8 GB (Estimated)"
        Safety      = "Official Microsoft Tool"
        Recommended = $false
        Description = "Deep purge of superseded Windows Update packages using official DISM (takes ~3 mins)."
    })

    return $results
}

function Invoke-WinAurexCleanup {
    [CmdletBinding()]
    param(
        [string[]]$Categories = @("SystemTemp", "CrashDumps", "AIIndexCaches", "AppUpdaters", "SquirrelVersions", "LooseInstallers", "BrowserCaches", "DevCaches"),
        [switch]$Force,
        [scriptblock]$OnProgress
    )

    $startDrive = Get-PSDrive C -ErrorAction SilentlyContinue
    $startFreeBytes = $startDrive.Free
    $localAppData = $env:LOCALAPPDATA
    $userProfile = $env:USERPROFILE

    $log = [System.Collections.Generic.List[string]]::new()

    function Report-Step($msg) {
        $log.Add($msg)
        if ($null -ne $OnProgress) { & $OnProgress $msg }
        else { Write-Host $msg -ForegroundColor Cyan }
    }

    # 1. System & User Temp
    if ("SystemTemp" -in $Categories) {
        Report-Step "[*] Cleaning User Temp ($env:TEMP)..."
        Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not (Test-IsProtectedPath $_.FullName)) {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Report-Step "[*] Cleaning Windows Temp (C:\Windows\Temp)..."
        Get-ChildItem -Path "C:\Windows\Temp" -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        Report-Step "[*] Cleaning CBS and system log files..."
        Remove-Item -Path "C:\Windows\Logs\cbs\*.log" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Logs\MoSetup\*.log" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Panther\*.log" -Force -ErrorAction SilentlyContinue
        Report-Step "[+] Temporary files purged."
    }

    # 2. Crash Dumps
    if ("CrashDumps" -in $Categories) {
        Report-Step "[*] Purging Application Crash Dumps..."
        $dumpDir = "$localAppData\CrashDumps"
        if (Test-Path $dumpDir) {
            Get-ChildItem -Path $dumpDir -Force -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Remove-Item -Path "$localAppData\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$localAppData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue
        Report-Step "[+] Crash dumps cleared."
    }

    # 3. AI & Search Indexes
    if ("AIIndexCaches" -in $Categories) {
        Report-Step "[*] Purging stale Copilot tgrep-index retired and spill temp files..."
        $copilotIndexDir = "$localAppData\copilot\tgrep-index"
        if (Test-Path $copilotIndexDir) {
            Get-ChildItem -Path $copilotIndexDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $retDir = Join-Path $_.FullName ".retired"
                if (Test-Path $retDir) { Remove-Item -Path $retDir -Recurse -Force -ErrorAction SilentlyContinue }
                Get-ChildItem -Path $_.FullName -Filter "spill-*.tmp" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
        Report-Step "[+] Stale AI search indexes cleared."
    }

    # 4. App Updaters
    if ("AppUpdaters" -in $Categories) {
        Report-Step "[*] Cleaning leftover desktop updater packages..."
        if (Test-Path "$localAppData\kimi-desktop-updater\pending") {
            Remove-Item -Path "$localAppData\kimi-desktop-updater\pending\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$localAppData\kimi-desktop-updater\installer.exe") {
            Remove-Item -Path "$localAppData\kimi-desktop-updater\installer.exe" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$localAppData\Ollama\updates_v2") {
            Remove-Item -Path "$localAppData\Ollama\updates_v2\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Report-Step "[+] Updater packages cleared."
    }

    # 5. Squirrel App Versions
    if ("SquirrelVersions" -in $Categories) {
        Report-Step "[*] Purging obsolete previous app versions..."
        $squirrelApps = @(
            @{ Path = "$localAppData\GitHubDesktop"; Prefix = "app-" },
            @{ Path = "$localAppData\Discord"; Prefix = "app-" },
            @{ Path = "$localAppData\AnthropicClaude"; Prefix = "app-" }
        )
        foreach ($sa in $squirrelApps) {
            if (Test-Path $sa.Path) {
                $appDirs = Get-ChildItem -Path $sa.Path -Directory -Filter "$($sa.Prefix)*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
                if ($appDirs.Count -gt 1) {
                    $appDirs | Select-Object -Skip 1 | ForEach-Object {
                        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                $pkgDir = Join-Path $sa.Path "packages"
                if (Test-Path $pkgDir) { Remove-Item -Path "$pkgDir\*" -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }
        Report-Step "[+] Obsolete app versions purged."
    }

    # 6. Dev Caches
    if ("DevCaches" -in $Categories) {
        Report-Step "[*] Cleaning package manager and build caches..."
        try { cmd.exe /c "npm cache clean --force" >nul 2>&1 } catch { }
        if (Test-Path "$localAppData\npm-cache") {
            Remove-Item -Path "$localAppData\npm-cache" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$localAppData\pnpm-cache") {
            Remove-Item -Path "$localAppData\pnpm-cache" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$localAppData\ms-playwright") {
            Remove-Item -Path "$localAppData\ms-playwright" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$userProfile\node_modules") {
            Remove-Item -Path "$userProfile\node_modules" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Report-Step "[+] Developer caches cleared."
    }

    # 7. Browser Caches
    if ("BrowserCaches" -in $Categories) {
        Report-Step "[*] Purging browser media & script caches (passwords & cookies preserved)..."
        $browserCaches = @(
            "$localAppData\Microsoft\Edge\User Data\Default\Cache",
            "$localAppData\Microsoft\Edge\User Data\Default\Code Cache",
            "$localAppData\Google\Chrome\User Data\Default\Cache",
            "$localAppData\Google\Chrome\User Data\Default\Code Cache",
            "$localAppData\BraveSoftware\Brave-Browser\User Data\Default\Cache",
            "$localAppData\BraveSoftware\Brave-Browser\User Data\Default\Code Cache"
        )
        foreach ($bc in $browserCaches) {
            if (Test-Path $bc) {
                Remove-Item -Path "$bc\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Report-Step "[+] Browser caches cleared."
    }

    # 8. Loose Installers & Debris
    if ("LooseInstallers" -in $Categories) {
        Report-Step "[*] Cleaning loose installer debris in C:\..."
        $rootFiles = @(
            "C:\install.exe",
            "C:\VC_RED.cab",
            "C:\VC_RED.MSI",
            "C:\globdata.ini",
            "C:\install.ini",
            "C:\vcredist.bmp",
            "C:\WinAurexTemp_Raw.vhd",
            "C:\WinAurexTemp_Extracted.efi",
            "C:\robocopy.log"
        )
        foreach ($rf in $rootFiles) {
            if (Test-Path $rf) { Remove-Item -Path $rf -Force -ErrorAction SilentlyContinue }
        }
        Get-ChildItem -Path "C:\" -Filter "eula.*.txt" -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
        }
        Get-ChildItem -Path "C:\" -Filter "install.res.*.dll" -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
        }
        Report-Step "[+] Loose installer debris cleared."
    }

    # 9. DISM Component Store
    if ("ComponentStore" -in $Categories) {
        Report-Step "[*] Executing DISM Component Store deep cleanup (this may take 2-5 minutes)..."
        cmd.exe /c "dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase" >nul 2>&1
        Report-Step "[+] Windows Component Store cleanup complete."
    }

    # Calculate freed storage
    $endDrive = Get-PSDrive C -ErrorAction SilentlyContinue
    $freedBytes = [math]::Max(0L, ($endDrive.Free - $startFreeBytes))

    Report-Step "=========================================="
    Report-Step "CLEANUP COMPLETE!"
    Report-Step "Storage Freed: $(Format-Bytes $freedBytes)"
    Report-Step "New Free Space: $(Format-Bytes $endDrive.Free)"
    Report-Step "=========================================="

    return [PSCustomObject]@{
        FreedBytes     = $freedBytes
        FreedText      = Format-Bytes $freedBytes
        StartFreeBytes = $startFreeBytes
        EndFreeBytes   = $endDrive.Free
        EndFreeText    = Format-Bytes $endDrive.Free
        Log            = $log
    }
}

Export-ModuleMember -Function Get-WinAurexJunkAnalysis, Invoke-WinAurexCleanup, Format-Bytes
