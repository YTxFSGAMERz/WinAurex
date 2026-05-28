[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Build & Package Release Script
# Run this script to generate a clean, distributable ZIP file for end users.

$Version = "5.0.0"
$RootPath = Join-Path $PSScriptRoot ".."
$DistDir = Join-Path $RootPath "dist"
$ReleaseName = "Windows-Optimisations-v$Version"
$ReleasePath = Join-Path $DistDir $ReleaseName
$ZipPath = Join-Path $DistDir "$ReleaseName.zip"

Write-Host "================================================="
Write-Host "   BUILDING RELEASE: v$Version" -ForegroundColor Cyan
Write-Host "================================================="

# 1. Clean previous builds
if (Test-Path $DistDir) {
    Remove-Item $DistDir -Recurse -Force
}
New-Item -ItemType Directory -Path $ReleasePath | Out-Null

# 2. Define Exclusion Rules (Don't package git history, user logs, or user backups)
$ExcludeList = @(
    ".git",
    ".gitignore",
    ".github",
    ".cache",
    ".netlify",
    ".antigravitycli",
    "venv",
    "dist",
    "docs",
    "site",
    "Build",
    "ReleaseNotes",
    "Logs\*",
    "Core\Restore\Backups\*",
    "Run_Integration_Tests.ps1",
    "*.md.bak",
    "temp_out.txt",
    "temp_err.txt",
    "test.ps1",
    "mkdocs.yml",
    "requirements.txt",
    "netlify.toml"
)

# 3. Copy Files to Staging Directory
Write-Host "Staging files to $ReleasePath..."
$CopyOptions = @{
    Path = "$RootPath\*"
    Destination = $ReleasePath
    Exclude = $ExcludeList
    Recurse = $true
    Force = $true
}

# The Exclude parameter in Copy-Item is notoriously finicky with recursive directories.
# We'll use robocopy for a much cleaner, more reliable exclusion copy.
$RoboArgs = @(
    $RootPath,
    $ReleasePath,
    "/E",
    "/XD", ".git", ".github", ".cache", ".netlify", ".antigravitycli", "venv", "dist", "docs", "site", "Build", "ReleaseNotes", "Logs", "Backups",
    "/XF", ".gitignore", "Run_Integration_Tests.ps1", "*.bak", "temp_out.txt", "temp_err.txt", "test.ps1", "mkdocs.yml", "requirements.txt", "netlify.toml",
    "/NJH", "/NJS", "/NDL", "/NC", "/NS"
)
& robocopy @RoboArgs | Out-Null

# Ensure empty directories exist for Logs and Backups in the release package!
New-Item -ItemType Directory -Path (Join-Path $ReleasePath "Logs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ReleasePath "Core\Restore\Backups") -Force | Out-Null

# 4. Create the ZIP Archive
Write-Host "Compressing to $ZipPath..." -ForegroundColor Yellow
Compress-Archive -Path "$ReleasePath\*" -DestinationPath $ZipPath -Force

# 5. Generate Checksum
$Hash = Get-FileHash -Path $ZipPath -Algorithm SHA256
$HashString = $Hash.Hash

$ChecksumFile = Join-Path $DistDir "$ReleaseName-SHA256.txt"
Set-Content -Path $ChecksumFile -Value $HashString

Write-Host "================================================="
Write-Host "   RELEASE BUILD SUCCESSFUL" -ForegroundColor Green
Write-Host "================================================="
Write-Host "ZIP Path: $ZipPath"
Write-Host "SHA-256:  $HashString"
Write-Host "Checksum saved to: $ChecksumFile"
