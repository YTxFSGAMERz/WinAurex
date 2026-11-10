# Windows Configuration & Optimization Framework
# Centralized Logging Module (Core/Helpers/Logging.psm1)

$Global:LogDirectory = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Logs"
$Global:LogDirectory = [System.IO.Path]::GetFullPath($Global:LogDirectory)

if (-not (Test-Path -Path $Global:LogDirectory)) {
    New-Item -ItemType Directory -Force -Path $Global:LogDirectory | Out-Null
}

function Start-WinAurexTranscript {
    <#
    .SYNOPSIS
    Starts an automated execution transcript in the WinAurex Logs directory.
    #>
    [CmdletBinding()]
    param (
        [string]$Prefix = "Execution",
        [string]$CustomLogDir = $null
    )

    $TargetLogDir = if (-not [string]::IsNullOrWhiteSpace($CustomLogDir)) { $CustomLogDir } else { $Global:LogDirectory }
    if (-not (Test-Path $TargetLogDir)) {
        New-Item -Path $TargetLogDir -ItemType Directory -Force | Out-Null
    }

    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $TranscriptPath = Join-Path $TargetLogDir "${Prefix}_${Timestamp}.log"

    try {
        Start-Transcript -Path $TranscriptPath -Append -Force | Out-Null
        $Global:CurrentWinAurexTranscript = $TranscriptPath
        return $TranscriptPath
    } catch {
        Write-Warning "Could not initialize transcript: $_"
        return $null
    }
}

function Stop-WinAurexTranscript {
    <#
    .SYNOPSIS
    Gracefully stops the active WinAurex execution transcript.
    #>
    [CmdletBinding()]
    param ()

    try {
        Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    if ($Global:CurrentWinAurexTranscript) {
        $path = $Global:CurrentWinAurexTranscript
        $Global:CurrentWinAurexTranscript = $null
        return $path
    }
    return $null
}

function Write-FrameworkLog {
    <#
    .SYNOPSIS
    Writes a standardized log entry to both the console and a daily module log file.
    .DESCRIPTION
    This function forms the backbone of the framework's observability layer.
    .EXAMPLE
    Write-FrameworkLog -ModuleName "Search" -Action "Disabled Bing Web Search" -OldValue "1" -NewValue "0"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory=$true)]
        [string]$Action,

        [string]$OldValue = "N/A",
        [string]$NewValue = "N/A",

        [ValidateSet("INFO", "WARNING", "ERROR", "CRITICAL")]
        [string]$Level = "INFO"
    )

    $DateString = Get-Date -Format "yyyy-MM-dd"
    $TimeString = Get-Date -Format "HH:mm:ss"
    $LogFile = Join-Path -Path $Global:LogDirectory -ChildPath "${DateString}_${ModuleName}.log"
    
    # Get friendly OS version build
    $OSBuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    $LogEntry = "[$TimeString] [$Level] [OS Build: $OSBuild] ACTION: $Action | OLD: $OldValue | NEW: $NewValue"
    
    # Write to console
    switch ($Level) {
        "INFO"     { Write-Host $LogEntry -ForegroundColor Cyan }
        "WARNING"  { Write-Host $LogEntry -ForegroundColor Yellow }
        "ERROR"    { Write-Host $LogEntry -ForegroundColor Red }
        "CRITICAL" { Write-Host $LogEntry -ForegroundColor Magenta }
    }
    
    # Write to file
    Add-Content -Path $LogFile -Value $LogEntry
}

Export-ModuleMember -Function Write-FrameworkLog, Start-WinAurexTranscript, Stop-WinAurexTranscript
