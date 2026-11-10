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
    [switch]$SkipRestorePoint
)

$ApplyScript = Join-Path $PSScriptRoot "apply.ps1"
if (Test-Path $ApplyScript) {
    & $ApplyScript -Force:$Force -SkipRestorePoint:$SkipRestorePoint
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    & ([ScriptBlock]::Create((irm https://winaurex.tech/apply.ps1))) -Force:$Force -SkipRestorePoint:$SkipRestorePoint
}
