<#
.SYNOPSIS
    WinAurex Interactive CLI Progress & Streaming Download Engine
.DESCRIPTION
    Provides high-performance live visual progress bars, streaming buffer downloads,
    direct-to-disk zip extraction with file counters, and installer execution spinners.
#>

function Invoke-DownloadWithProgress {
    param (
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$OutputFile,
        [string]$Label = "Downloading"
    )

    $parentDir = Split-Path $OutputFile -Parent
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }

    $req = [System.Net.HttpWebRequest]::Create($Url)
    $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) WinAurex-Workstation"
    $req.Timeout = 90000
    
    $resp = $null
    $stream = $null
    $fileStream = $null

    try {
        $resp = $req.GetResponse()
        $totalBytes = $resp.ContentLength
        $stream = $resp.GetResponseStream()
        $fileStream = [System.IO.File]::Create($OutputFile)
        $buffer = New-Object byte[] 65536
        $bytesRead = 0
        $totalRead = 0
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastUpdate = [DateTime]::MinValue
        $barWidth = 26

        while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $bytesRead)
            $totalRead += $bytesRead

            $now = [DateTime]::UtcNow
            if (($now - $lastUpdate).TotalMilliseconds -ge 120 -or $totalRead -eq $totalBytes) {
                $lastUpdate = $now
                $elapsedSec = [math]::Max(0.001, $sw.Elapsed.TotalSeconds)
                $speedMBs = [math]::Round(($totalRead / 1MB) / $elapsedSec, 2)
                $curMB = [math]::Round($totalRead / 1MB, 2)

                if ($totalBytes -gt 0) {
                    $totMB = [math]::Round($totalBytes / 1MB, 2)
                    $pct = [math]::Min(100, [int](($totalRead / $totalBytes) * 100))
                    $filled = [int](($pct / 100) * $barWidth)
                    $empty = [math]::Max(0, $barWidth - $filled)
                    $pointer = if ($empty -gt 0) { ">" } else { "" }
                    $bar = ("=" * $filled) + $pointer + (" " * [math]::Max(0, $empty - 1))
                    $barStr = $bar.PadRight($barWidth).Substring(0, $barWidth)
                    Write-Host -NoNewline ("`r  [$barStr] {0,3}% ({1,5} MB / {2,5} MB) [{3,5} MB/s]" -f $pct, $curMB, $totMB, $speedMBs)
                } else {
                    $barStr = "=>".PadRight($barWidth)
                    Write-Host -NoNewline ("`r  [$barStr] {0,5} MB received [{1,5} MB/s]" -f $curMB, $speedMBs)
                }
            }
        }
        $sw.Stop()
        Write-Host ""
        $finalMB = [math]::Round($totalRead / 1MB, 2)
        $finalSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        Write-Host "  [+] $Label complete! ($finalMB MB in ${finalSec}s)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host ""
        Write-Warning "Download failed: $_"
        return $false
    } finally {
        if ($fileStream) { $fileStream.Dispose() }
        if ($stream) { $stream.Dispose() }
        if ($resp) { $resp.Dispose() }
    }
}

function Expand-ZipWithProgress {
    param (
        [Parameter(Mandatory=$true)][string]$ZipFile,
        [Parameter(Mandatory=$true)][string]$DestinationPath,
        [string]$Label = "Extraction"
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }

    $archive = $null
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipFile)
        $entries = $archive.Entries
        $totalEntries = $entries.Count
        if ($totalEntries -eq 0) { return }

        # Detect top-level root folder prefix (e.g. "WinAurex-master/")
        $firstEntry = $entries[0].FullName
        $topPrefix = ""
        if ($firstEntry -match "^([^/]+/)") {
            $topPrefix = $matches[1]
        }

        $barWidth = 26
        $currentIdx = 0
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastUpdate = [DateTime]::MinValue

        foreach ($entry in $entries) {
            $currentIdx++
            $relPath = $entry.FullName
            if ($topPrefix -and $relPath.StartsWith($topPrefix)) {
                $relPath = $relPath.Substring($topPrefix.Length)
            }
            if ([string]::IsNullOrWhiteSpace($relPath)) { continue }

            $targetFile = [System.IO.Path]::Combine($DestinationPath, $relPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))

            if ($entry.FullName.EndsWith('/')) {
                if (-not (Test-Path $targetFile)) {
                    [System.IO.Directory]::CreateDirectory($targetFile) | Out-Null
                }
            } else {
                $targetDir = [System.IO.Path]::GetDirectoryName($targetFile)
                if (-not (Test-Path $targetDir)) {
                    [System.IO.Directory]::CreateDirectory($targetDir) | Out-Null
                }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetFile, $true)
            }

            $now = [DateTime]::UtcNow
            if (($now - $lastUpdate).TotalMilliseconds -ge 100 -or $currentIdx -eq $totalEntries) {
                $lastUpdate = $now
                $pct = [int](($currentIdx / $totalEntries) * 100)
                $filled = [int](($pct / 100) * $barWidth)
                $empty = [math]::Max(0, $barWidth - $filled)
                $pointer = if ($empty -gt 0) { ">" } else { "" }
                $bar = ("=" * $filled) + $pointer + (" " * [math]::Max(0, $empty - 1))
                $barStr = $bar.PadRight($barWidth).Substring(0, $barWidth)
                Write-Host -NoNewline ("`r  [$barStr] {0,3}% ({1}/{2} files)" -f $pct, $currentIdx, $totalEntries)
            }
        }
        $sw.Stop()
        Write-Host ""
        $finalSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        Write-Host "  [+] $Label complete! ($totalEntries files extracted in ${finalSec}s)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host ""
        Write-Warning "Zip extraction error: $_"
        return $false
    } finally {
        if ($archive) { $archive.Dispose() }
    }
}

function Invoke-ProcessWithSpinner {
    param (
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string]$ArgumentList = "",
        [string]$Description = "Process",
        [int]$TimeoutSec = 300
    )

    Write-Host "  [*] Executing $Description silently..." -ForegroundColor Cyan
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $FilePath
    $pinfo.Arguments = $ArgumentList
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($pinfo)
    $spinChars = @('|', '/', '-', '\')
    $sIdx = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    while (-not $proc.HasExited) {
        if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) {
            try { $proc.Kill() } catch {}
            Write-Host ""
            Write-Warning "$Description timed out after ${TimeoutSec}s!"
            return -1
        }
        $sChar = $spinChars[$sIdx % 4]
        $elapsed = [math]::Round($sw.Elapsed.TotalSeconds)
        Write-Host -NoNewline ("`r  [*] Running $Description... [$sChar] (${elapsed}s)")
        Start-Sleep -Milliseconds 150
        $sIdx++
    }

    Write-Host ""
    $sw.Stop()
    $exitCode = $proc.ExitCode
    if ($exitCode -eq 0 -or $exitCode -eq 3010) {
        Write-Host "  [+] $Description finished successfully! (Exit: $exitCode)" -ForegroundColor Green
    } else {
        Write-Warning "  [-] $Description exited with code: $exitCode"
    }
    return $exitCode
}

Export-ModuleMember -Function Invoke-DownloadWithProgress, Expand-ZipWithProgress, Invoke-ProcessWithSpinner
