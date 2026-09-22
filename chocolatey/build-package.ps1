<#
.SYNOPSIS
    Automated Chocolatey Package Builder for WinAurex
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$AppTarget = Join-Path $ScriptDir "tools\app"

Write-Host ">>> Preparing WinAurex Chocolatey Payload..." -ForegroundColor Cyan

if (Test-Path $AppTarget) {
    Remove-Item -Path $AppTarget -Recurse -Force
}
New-Item -ItemType Directory -Path $AppTarget -Force | Out-Null

$DirsToCopy = @("Core", "Tweaks", "Profiles", "Tools", "GUI")
foreach ($dir in $DirsToCopy) {
    $src = Join-Path $RepoRoot $dir
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $AppTarget $dir) -Recurse -Force
    }
}

$FilesToCopy = @("winaurex.cmd", "PC_Cleaner.bat", "Start.bat", "Launch_Dashboard.ps1")
foreach ($file in $FilesToCopy) {
    $src = Join-Path $RepoRoot $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $AppTarget $file) -Force
    }
}

Write-Host ">>> Building Chocolatey Package..." -ForegroundColor Cyan
$NuspecPath = Join-Path $ScriptDir "winaurex.nuspec"
choco pack $NuspecPath --outputdirectory $ScriptDir

Write-Host "[SUCCESS] Chocolatey package generated in $ScriptDir" -ForegroundColor Green
