<#
.SYNOPSIS
    WinAurex Automated System Prerequisites Installer
.DESCRIPTION
    Detects and silently provisions all runtime dependencies required by the WinAurex ecosystem:
    - Microsoft Visual C++ 2015-2022 Redistributable (x64 and x86)
    - Microsoft Edge WebView2 Runtime
    - Python 3.12 (x64)
    - Node.js LTS (x64)
    - Refreshes Machine/User PATH and broadcasts environment updates
#>
[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$SkipPython,
    [switch]$SkipNode,
    [switch]$SkipVCRedist,
    [switch]$SkipWebView2
)

# Set TLS 1.2 and 1.3
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072 -bor 12288
$ProgressPreference = 'SilentlyContinue'

# Require Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Administrator privileges required to install system prerequisites. Please run as Administrator."
    Exit 1
}

$RepoRoot = $null
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    try {
        $parent = (Get-Item (Join-Path $PSScriptRoot "..\..") -ErrorAction SilentlyContinue)
        if ($parent) { $RepoRoot = $parent.FullName }
    } catch {}
}
if (-not $RepoRoot -or -not (Test-Path $RepoRoot)) {
    if (Test-Path "C:\WinAurex") {
        $RepoRoot = "C:\WinAurex"
    } else {
        $RepoRoot = (Get-Location).Path
    }
}

# Load CLI Progress & Streaming Module
$ProgressModule = Join-Path $RepoRoot "Core\Helpers\CliProgress.psm1"
if (Test-Path $ProgressModule) {
    Import-Module $ProgressModule -Force -DisableNameChecking
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex System Prerequisites & Runtime Provisioner          " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Auditing and provisioning core system dependencies for fresh Windows...`n" -ForegroundColor DarkGray

function Update-CurrentProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $env:Path = "$machinePath;$userPath"

    # Also broadcast WM_SETTINGCHANGE so other shells & Explorer pick up changes
    try {
        $Signature = @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(
    IntPtr hWnd,
    uint Msg,
    UIntPtr wParam,
    string lParam,
    uint fuFlags,
    uint uTimeout,
    out UIntPtr lpdwResult
);
'@
        $Type = Add-Type -MemberDefinition $Signature -Name "Win32SendMessage" -Namespace "WinAurexEnv" -PassThru -ErrorAction SilentlyContinue
        if ($Type) {
            $HWND_BROADCAST = [IntPtr]0xffff
            $WM_SETTINGCHANGE = 0x001A
            $SMTO_ABORTIFHUNG = 0x0002
            $result = [UIntPtr]::Zero
            [WinAurexEnv.Win32SendMessage]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", $SMTO_ABORTIFHUNG, 2000, [ref]$result) | Out-Null
        }
    } catch {}
}

function Add-DirectoryToSystemPath {
    param ([string]$Dir)
    if (-not (Test-Path $Dir)) { return }
    try {
        $machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
        if ($machinePath -notlike "*$Dir*") {
            [Environment]::SetEnvironmentVariable("Path", "$machinePath;$Dir", [EnvironmentVariableTarget]::Machine)
            Write-Host "    [+] Added to Machine PATH: $Dir" -ForegroundColor DarkGray
        }
        if ($env:Path -notlike "*$Dir*") {
            $env:Path = "$env:Path;$Dir"
        }
    } catch {}
}

function Download-And-Run {
    param (
        [string]$Url,
        [string]$FileName,
        [string]$Arguments,
        [string]$Description,
        [switch]$IsMsi
    )
    $dest = Join-Path $env:TEMP $FileName
    Write-Host "  [*] Downloading $Description..." -ForegroundColor Cyan
    
    $downloadOk = $false
    if (Get-Command Invoke-DownloadWithProgress -ErrorAction SilentlyContinue) {
        $downloadOk = Invoke-DownloadWithProgress -Url $Url -OutputFile $dest -Label "$Description download"
    } else {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing -TimeoutSec 180
            $downloadOk = (Test-Path $dest)
        } catch {
            Write-Warning "Failed downloading $($Description) from $Url : $_"
            return $false
        }
    }

    if (-not $downloadOk -or -not (Test-Path $dest)) {
        Write-Warning "Download failed for $Description"
        return $false
    }

    Write-Host "  [*] Installing $($Description) silently..." -ForegroundColor Cyan
    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        if ($IsMsi) {
            $pinfo.FileName = "msiexec.exe"
            $pinfo.Arguments = "/i `"$dest`" $Arguments"
        } else {
            $pinfo.FileName = $dest
            $pinfo.Arguments = $Arguments
        }
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($pinfo)
        $spinChars = @('|', '/', '-', '\')
        $sIdx = 0
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        while (-not $proc.HasExited) {
            $sChar = $spinChars[$sIdx % 4]
            $elapsed = [math]::Round($sw.Elapsed.TotalSeconds)
            Write-Host -NoNewline ("`r  [*] Installing $($Description) silently... [$sChar] (${elapsed}s)")
            Start-Sleep -Milliseconds 150
            $sIdx++
        }
        $sw.Stop()
        Write-Host ""

        $exitCode = $proc.ExitCode
        Remove-Item $dest -Force -ErrorAction SilentlyContinue
        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            Write-Host "  [+] $($Description) installed successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "$($Description) installer exited with code: $exitCode"
            return $false
        }
    } catch {
        Write-Warning "Failed executing installer for $($Description) : $_"
        Remove-Item $dest -Force -ErrorAction SilentlyContinue
        return $false
    }
}

# -------------------------------------------------------------------------
# 1. Visual C++ 2015-2022 Redistributables (x64 and x86)
# -------------------------------------------------------------------------
if (-not $SkipVCRedist) {
    Write-Host "[1/4] Checking Microsoft Visual C++ 2015-2022 Redistributables..." -ForegroundColor Cyan
    
    # Check x64
    $vc64Installed = $false
    try {
        $key64 = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" -ErrorAction SilentlyContinue
        if ($key64 -and $key64.Installed -eq 1) { $vc64Installed = $true }
    } catch {}

    if ($vc64Installed) {
        Write-Host "  [+] Visual C++ 2015-2022 (x64) is already installed." -ForegroundColor Green
    } else {
        Download-And-Run `
            -Url "https://aka.ms/vs/17/release/vc_redist.x64.exe" `
            -FileName "vc_redist.x64.exe" `
            -Arguments "/install /quiet /norestart" `
            -Description "Visual C++ 2015-2022 Redistributable (x64)"
    }

    # Check x86
    $vc86Installed = $false
    try {
        $key86 = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" -ErrorAction SilentlyContinue
        if (-not $key86) {
            $key86 = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" -ErrorAction SilentlyContinue
        }
        if ($key86 -and $key86.Installed -eq 1) { $vc86Installed = $true }
    } catch {}

    if ($vc86Installed) {
        Write-Host "  [+] Visual C++ 2015-2022 (x86) is already installed." -ForegroundColor Green
    } else {
        Download-And-Run `
            -Url "https://aka.ms/vs/17/release/vc_redist.x86.exe" `
            -FileName "vc_redist.x86.exe" `
            -Arguments "/install /quiet /norestart" `
            -Description "Visual C++ 2015-2022 Redistributable (x86)"
    }
} else {
    Write-Host "[1/4] Skipping Visual C++ Redistributable check." -ForegroundColor DarkGray
}

# -------------------------------------------------------------------------
# 2. Microsoft Edge WebView2 Runtime
# -------------------------------------------------------------------------
if (-not $SkipWebView2) {
    Write-Host "`n[2/4] Checking Microsoft Edge WebView2 Runtime..." -ForegroundColor Cyan
    $wvInstalled = $false
    $wvKeys = @(
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
        "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
        "HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
    )
    foreach ($k in $wvKeys) {
        try {
            $item = Get-ItemProperty $k -ErrorAction SilentlyContinue
            if ($item -and -not [string]::IsNullOrWhiteSpace($item.pv)) {
                $wvInstalled = $true
                $wvVersion = $item.pv
                break
            }
        } catch {}
    }

    if ($wvInstalled) {
        Write-Host "  [+] Microsoft Edge WebView2 Runtime is already installed ($wvVersion)." -ForegroundColor Green
    } else {
        # Check bundled installer in repo first
        $bundledWv = Join-Path $RepoRoot "Tools\Apps\WebView - IMPORTANT\MicrosoftEdgeWebview2Setup.exe"
        if (Test-Path $bundledWv) {
            Write-Host "  [*] Installing WebView2 from bundled package..." -ForegroundColor Cyan
            try {
                $proc = Start-Process -FilePath $bundledWv -ArgumentList "/silent /install" -Wait -PassThru
                if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                    Write-Host "  [+] WebView2 installed successfully from local bundle!" -ForegroundColor Green
                } else {
                    Write-Warning "Bundled WebView2 exited with code: $($proc.ExitCode)"
                }
            } catch {
                Write-Warning "Failed launching bundled WebView2 installer: $_"
            }
        } else {
            Download-And-Run `
                -Url "https://go.microsoft.com/fwlink/p/?LinkId=2124703" `
                -FileName "MicrosoftEdgeWebview2Setup.exe" `
                -Arguments "/silent /install" `
                -Description "Microsoft Edge WebView2 Evergreen Bootstrapper"
        }
    }
} else {
    Write-Host "`n[2/4] Skipping WebView2 check." -ForegroundColor DarkGray
}

# -------------------------------------------------------------------------
# 3. Python 3.12 (x64)
# -------------------------------------------------------------------------
if (-not $SkipPython) {
    Write-Host "`n[3/4] Checking Python Runtime..." -ForegroundColor Cyan
    $pyInstalled = $false
    $pyVersionStr = ""

    # Check if python or py is already on PATH
    $cmdPython = Get-Command "python" -ErrorAction SilentlyContinue
    $cmdPy = Get-Command "py" -ErrorAction SilentlyContinue
    if ($cmdPython) {
        try {
            $verOut = & $cmdPython.Source --version 2>&1
            if ($verOut -like "Python 3*") {
                $pyInstalled = $true
                $pyVersionStr = "$verOut ($($cmdPython.Source))"
            }
        } catch {}
    }
    if (-not $pyInstalled -and $cmdPy) {
        try {
            $verOut = & $cmdPy.Source -3 --version 2>&1
            if ($verOut -like "Python 3*") {
                $pyInstalled = $true
                $pyVersionStr = "$verOut (py launcher)"
            }
        } catch {}
    }

    # Check common registry & directory locations if not in current PATH
    if (-not $pyInstalled) {
        $commonPyDirs = @(
            "$env:ProgramFiles\Python312",
            "$env:ProgramFiles\Python311",
            "$env:ProgramFiles\Python310",
            "$env:SystemDrive\Python312",
            "$env:SystemDrive\Python311",
            "$env:SystemDrive\Python310",
            "$env:LOCALAPPDATA\Programs\Python\Python312",
            "$env:LOCALAPPDATA\Programs\Python\Python311"
        )
        foreach ($d in $commonPyDirs) {
            $exe = Join-Path $d "python.exe"
            if (Test-Path $exe) {
                $pyInstalled = $true
                $pyVersionStr = "Found at $exe"
                Add-DirectoryToSystemPath $d
                Add-DirectoryToSystemPath (Join-Path $d "Scripts")
                break
            }
        }
    }

    if ($pyInstalled) {
        Write-Host "  [+] Python is already installed: $pyVersionStr" -ForegroundColor Green
    } else {
        Write-Host "  [-] Python not found. Installing Python 3.12 (x64)..." -ForegroundColor Yellow
        $installedViaWinget = $false
        
        # Try winget if available
        if (Get-Command "winget" -ErrorAction SilentlyContinue) {
            try {
                Write-Host "  [*] Attempting silent installation via WinGet..." -ForegroundColor DarkGray
                $wingetProc = Start-Process winget -ArgumentList "install --id Python.Python.3.12 --exact --silent --accept-package-agreements --accept-source-agreements --scope machine" -Wait -PassThru
                if ($wingetProc.ExitCode -eq 0) {
                    $installedViaWinget = $true
                    Write-Host "  [+] Python 3.12 installed successfully via WinGet!" -ForegroundColor Green
                }
            } catch {}
        }

        # Direct download fallback
        if (-not $installedViaWinget) {
            $pyUrl = "https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
            $pyArgs = "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 SimpleInstall=1"
            Download-And-Run `
                -Url $pyUrl `
                -FileName "python-3.12.7-amd64.exe" `
                -Arguments $pyArgs `
                -Description "Python 3.12.7 Runtime"
        }

        # Resolve installed Python path and register to PATH
        Update-CurrentProcessPath
        $possiblePyDirs = @(
            "$env:ProgramFiles\Python312",
            "$env:SystemDrive\Python312",
            "$env:LOCALAPPDATA\Programs\Python\Python312"
        )
        foreach ($d in $possiblePyDirs) {
            if (Test-Path (Join-Path $d "python.exe")) {
                Add-DirectoryToSystemPath $d
                Add-DirectoryToSystemPath (Join-Path $d "Scripts")
                break
            }
        }
    }
} else {
    Write-Host "`n[3/4] Skipping Python check." -ForegroundColor DarkGray
}

# -------------------------------------------------------------------------
# 4. Node.js LTS (x64)
# -------------------------------------------------------------------------
if (-not $SkipNode) {
    Write-Host "`n[4/4] Checking Node.js Runtime..." -ForegroundColor Cyan
    $nodeInstalled = $false
    $nodeVersionStr = ""

    # Check if node is in current PATH
    $cmdNode = Get-Command "node" -ErrorAction SilentlyContinue
    if ($cmdNode) {
        try {
            $verOut = & $cmdNode.Source --version 2>&1
            if ($verOut -like "v*") {
                $nodeInstalled = $true
                $nodeVersionStr = "$verOut ($($cmdNode.Source))"
            }
        } catch {}
    }

    # Check common directory locations if not in current PATH
    if (-not $nodeInstalled) {
        $commonNodeDirs = @(
            "$env:ProgramFiles\nodejs",
            "${env:ProgramFiles(x86)}\nodejs"
        )
        foreach ($d in $commonNodeDirs) {
            $exe = Join-Path $d "node.exe"
            if (Test-Path $exe) {
                $nodeInstalled = $true
                $nodeVersionStr = "Found at $exe"
                Add-DirectoryToSystemPath $d
                break
            }
        }
    }

    if ($nodeInstalled) {
        Write-Host "  [+] Node.js is already installed: $nodeVersionStr" -ForegroundColor Green
    } else {
        Write-Host "  [-] Node.js not found. Installing Node.js LTS (x64)..." -ForegroundColor Yellow
        $installedViaWinget = $false
        
        # Try winget if available
        if (Get-Command "winget" -ErrorAction SilentlyContinue) {
            try {
                Write-Host "  [*] Attempting silent installation via WinGet..." -ForegroundColor DarkGray
                $wingetProc = Start-Process winget -ArgumentList "install --id OpenJS.NodeJS.LTS --exact --silent --accept-package-agreements --accept-source-agreements --scope machine" -Wait -PassThru
                if ($wingetProc.ExitCode -eq 0) {
                    $installedViaWinget = $true
                    Write-Host "  [+] Node.js LTS installed successfully via WinGet!" -ForegroundColor Green
                }
            } catch {}
        }

        # Direct MSI download fallback
        if (-not $installedViaWinget) {
            $nodeMsiUrl = "https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
            Download-And-Run `
                -Url $nodeMsiUrl `
                -FileName "node-lts-x64.msi" `
                -Arguments "/qn /norestart" `
                -Description "Node.js LTS (v20.18.0)" `
                -IsMsi
        }

        # Resolve installed Node path and register to PATH
        Update-CurrentProcessPath
        $nodeDir = "$env:ProgramFiles\nodejs"
        if (Test-Path (Join-Path $nodeDir "node.exe")) {
            Add-DirectoryToSystemPath $nodeDir
        }
    }
} else {
    Write-Host "`n[4/4] Skipping Node.js check." -ForegroundColor DarkGray
}

# Refresh environment once more to solidify PATH changes
Update-CurrentProcessPath

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] System prerequisites verification completed!               " -ForegroundColor Green
Write-Host "======================================================================`n" -ForegroundColor Cyan
