<#
.SYNOPSIS
    WinAurex Universal In-Place PC Conversion Bootstrapper (Alias for apply.ps1)
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

$ApplyScript = Join-Path $PSScriptRoot "apply.ps1"
if (Test-Path $ApplyScript) {
    & $ApplyScript -Force:$Force -SkipRestorePoint:$SkipRestorePoint -LaunchDashboard:$LaunchDashboard
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    $content = try { irm https://www.winaurex.tech/apply.ps1 } catch { try { irm https://winaurex.tech/apply.ps1 } catch { irm https://raw.githubusercontent.com/YTxFSGAMERz/WinAurex/master/apply.ps1 } }
    & ([ScriptBlock]::Create($content)) -Force:$Force -SkipRestorePoint:$SkipRestorePoint -LaunchDashboard:$LaunchDashboard
}
