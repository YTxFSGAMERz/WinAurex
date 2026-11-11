<#
.SYNOPSIS
    WinAurex Curated Software Hub & Unattended Package Manager
.DESCRIPTION
    Integrates with Windows Package Manager (winget) to provide 1-click batch installation
    of curated essential browsers, gaming clients, developer environments, and utilities.
#>

$script:SoftwareCatalog = @(
    # BROWSERS
    @{ Id = "Brave.Brave"; Name = "Brave Browser"; Category = "Browsers"; Desc = "Privacy-centric browser with native ad & tracker blocker" },
    @{ Id = "Google.Chrome"; Name = "Google Chrome"; Category = "Browsers"; Desc = "Standard modern web browser" },
    @{ Id = "Mozilla.Firefox"; Name = "Mozilla Firefox"; Category = "Browsers"; Desc = "Open-source customizable web browser" },

    # GAMING & COMMUNICATION
    @{ Id = "Valve.Steam"; Name = "Steam"; Category = "Gaming"; Desc = "Digital distribution gaming platform" },
    @{ Id = "Discord.Discord"; Name = "Discord"; Category = "Gaming"; Desc = "Voice, video, and text communication platform" },
    @{ Id = "OBSProject.OBSStudio"; Name = "OBS Studio"; Category = "Gaming"; Desc = "Open-source video recording and live streaming suite" },
    @{ Id = "VideoLAN.VLC"; Name = "VLC Media Player"; Category = "Media"; Desc = "Universal multimedia player and framework" },
    @{ Id = "Spotify.Spotify"; Name = "Spotify"; Category = "Media"; Desc = "Digital music, podcast, and audio streaming service" },

    # DEVELOPER TOOLS
    @{ Id = "Microsoft.VisualStudioCode"; Name = "VS Code"; Category = "Development"; Desc = "Lightweight code editor and development workspace" },
    @{ Id = "Git.Git"; Name = "Git"; Category = "Development"; Desc = "Fast distributed version control system" },
    @{ Id = "Python.Python.3.12"; Name = "Python 3.12"; Category = "Development"; Desc = "Interpreted high-level programming language" },
    @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js (LTS)"; Category = "Development"; Desc = "JavaScript runtime built on Chrome's V8 engine" },

    # UTILITIES & POWER TOOLS
    @{ Id = "7zip.7zip"; Name = "7-Zip"; Category = "Utilities"; Desc = "High compression ratio file archiver" },
    @{ Id = "Notepad++.Notepad++"; Name = "Notepad++"; Category = "Utilities"; Desc = "Fast source code editor and notepad replacement" },
    @{ Id = "voidtools.Everything"; Name = "Everything Search"; Category = "Utilities"; Desc = "Instant filename search utility for Windows NTFS" },
    @{ Id = "Microsoft.PowerToys"; Name = "Windows PowerToys"; Category = "Utilities"; Desc = "System utilities for power users to tune Windows" }
)

function Get-WinAurexSoftwareCatalog {
    return $script:SoftwareCatalog
}

function Test-WingetAvailable {
    $wg = Get-Command "winget" -ErrorAction SilentlyContinue
    return ($null -ne $wg)
}

function Install-WinAurexPackages {
    param (
        [string[]]$PackageIds,
        [scriptblock]$OnProgress = $null
    )

    if (-not (Test-WingetAvailable)) {
        throw "Windows Package Manager (winget.exe) is not installed or not in PATH."
    }

    $total = $PackageIds.Count
    $index = 0
    $results = @()

    foreach ($pkgId in $PackageIds) {
        $index++
        $catalogItem = $script:SoftwareCatalog | Where-Object { $_.Id -eq $pkgId } | Select-Object -First 1
        $appName = if ($catalogItem) { $catalogItem.Name } else { $pkgId }

        Write-Host "`n[$index/$total] Installing $appName ($pkgId)..." -ForegroundColor Cyan
        if ($OnProgress) {
            & $OnProgress -Current $index -Total $total -PackageName $appName
        }

        $argsList = "install --id `"$pkgId`" -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
        
        $proc = Start-Process -FilePath "winget" -ArgumentList $argsList -NoNewWindow -Wait -PassThru
        $success = ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq -1978335189) # ExitCode -1978335189 means already installed
        
        if ($success) {
            Write-Host "  [+] $appName installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "  [-] Failed or non-zero exit code: $($proc.ExitCode)" -ForegroundColor Yellow
        }

        $results += [PSCustomObject]@{
            Id        = $pkgId
            Name      = $appName
            ExitCode  = $proc.ExitCode
            Success   = $success
        }
    }

    return $results
}

Export-ModuleMember -Function Get-WinAurexSoftwareCatalog, Test-WingetAvailable, Install-WinAurexPackages
