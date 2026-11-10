<#
.SYNOPSIS
    WinAurex In-Place PC Conversion Engine
.DESCRIPTION
    Converts an existing Windows 10/11 system to WinAurex Edition in-place:
    - Injects WinAurex OEM branding into Windows System Properties.
    - Applies Tier 1 Safe Optimization & Privacy hardening.
    - Registers 'winaurex' command globally in System PATH.
    - Creates Desktop and Start Menu shortcuts.
#>
[CmdletBinding()]
param (
    [switch]$Force
)

# 1. Require Administrator Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "WinAurex In-Place Conversion requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

$RepoRoot = (Get-Item (Join-Path $PSScriptRoot "..\..")).FullName
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "             WinAurex In-Place PC Conversion Engine                   " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

# 2. Inject WinAurex OEM Branding into Windows System Information
Write-Host "`n[*] Applying WinAurex OEM Branding to System Properties..." -ForegroundColor Cyan
$OEMKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
if (-not (Test-Path $OEMKey)) { New-Item -Path $OEMKey -Force | Out-Null }

Set-ItemProperty -Path $OEMKey -Name "Manufacturer" -Value "WinAurex" -Type String -Force
Set-ItemProperty -Path $OEMKey -Name "Model" -Value "WinAurex Performance Edition" -Type String -Force
Set-ItemProperty -Path $OEMKey -Name "SupportURL" -Value "https://winaurex.tech" -Type String -Force
Set-ItemProperty -Path $OEMKey -Name "SupportHours" -Value "24/7 Community Support" -Type String -Force
Set-ItemProperty -Path $OEMKey -Name "SupportPhone" -Value "Telegram: @FFShaikh69" -Type String -Force

Write-Host " [+] OEM Information updated: System Model set to 'WinAurex Performance Edition'." -ForegroundColor Green

# 3. Execute Curated Safe Suite (Tier 1 Optimizations)
Write-Host "`n[*] Executing Curated Safe Optimizations & Privacy Hardening..." -ForegroundColor Cyan
$SafeSuite = Join-Path $RepoRoot "Apply_Curated_Safe_Suite.ps1"

if (Test-Path $SafeSuite) {
    & $SafeSuite -Force:$Force
} else {
    Write-Warning "Apply_Curated_Safe_Suite.ps1 not found in $RepoRoot. Skipping automated tweak execution."
}

# 4. Register 'winaurex' in System PATH
Write-Host "`n[*] Registering WinAurex CLI in System Environment PATH..." -ForegroundColor Cyan
$BinDir = Join-Path $RepoRoot "bin"
if (-not (Test-Path $BinDir)) {
    # If installed in ProgramData
    $BinDir = $RepoRoot
}

try {
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if ($CurrentPath -notlike "*$RepoRoot*" -and $CurrentPath -notlike "*$BinDir*") {
        $NewPath = "$CurrentPath;$RepoRoot"
        [Environment]::SetEnvironmentVariable("Path", $NewPath, [EnvironmentVariableTarget]::Machine)
        Write-Host " [+] Added $RepoRoot to System PATH. 'winaurex' CLI is now globally accessible!" -ForegroundColor Green
    } else {
        Write-Host " [+] WinAurex is already registered in System PATH." -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not update machine PATH environment variable: $_"
}

# 5. Create Desktop & Start Menu Shortcuts
Write-Host "`n[*] Creating Desktop & Start Menu Shortcuts..." -ForegroundColor Cyan
$WScriptShell = New-Object -ComObject WScript.Shell

$DashboardScript = Join-Path $RepoRoot "Launch_Dashboard.ps1"
$CleanerScript = Join-Path $RepoRoot "PC_Cleaner.bat"

# Desktop Shortcuts
$DesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
if (-not (Test-Path $DesktopPath)) { $DesktopPath = [Environment]::GetFolderPath("Desktop") }

# Shortcut 1: WinAurex Dashboard
$DashShortcutPath = Join-Path $DesktopPath "WinAurex Dashboard.lnk"
$DashShortcut = $WScriptShell.CreateShortcut($DashShortcutPath)
$DashShortcut.TargetPath = "powershell.exe"
$DashShortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$DashboardScript`""
$DashShortcut.WorkingDirectory = $RepoRoot
$DashShortcut.Description = "WinAurex Performance & Optimization Dashboard"
$DashShortcut.Save()

# Shortcut 2: WinAurex PC Cleaner
if (Test-Path $CleanerScript) {
    $CleanShortcutPath = Join-Path $DesktopPath "WinAurex PC Cleaner.lnk"
    $CleanShortcut = $WScriptShell.CreateShortcut($CleanShortcutPath)
    $CleanShortcut.TargetPath = "cmd.exe"
    $CleanShortcut.Arguments = "/c `"$CleanerScript`""
    $CleanShortcut.WorkingDirectory = $RepoRoot
    $CleanShortcut.Description = "WinAurex Safe Junk & Storage Cleaner"
    $CleanShortcut.Save()
}

Write-Host " [+] Created 'WinAurex Dashboard' and 'WinAurex PC Cleaner' on Desktop!" -ForegroundColor Green

# Start Menu Programs Shortcut
$StartMenuPath = [Environment]::GetFolderPath("CommonPrograms")
if (Test-Path $StartMenuPath) {
    $WinAurexMenuDir = Join-Path $StartMenuPath "WinAurex"
    if (-not (Test-Path $WinAurexMenuDir)) { New-Item -Path $WinAurexMenuDir -ItemType Directory -Force | Out-Null }
    
    $MenuShortcut = $WScriptShell.CreateShortcut((Join-Path $WinAurexMenuDir "WinAurex Dashboard.lnk"))
    $MenuShortcut.TargetPath = "powershell.exe"
    $MenuShortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$DashboardScript`""
    $MenuShortcut.WorkingDirectory = $RepoRoot
    $MenuShortcut.Save()
}

Write-Host "`n[SUCCESS] In-Place PC Conversion to WinAurex complete!" -ForegroundColor Green
