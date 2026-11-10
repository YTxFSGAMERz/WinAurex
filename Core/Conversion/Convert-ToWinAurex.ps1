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

# 4. Register 'winaurex' in System PATH & Deploy Global Shim
Write-Host "`n[*] Registering WinAurex CLI in System Environment..." -ForegroundColor Cyan

# 4a. Deploy Global Windows System Shim (Instant access from ANY terminal)
$SystemShimContent = @"
@echo off
if exist "$RepoRoot\winaurex.cmd" (
    call "$RepoRoot\winaurex.cmd" %*
) else if exist "C:\WinAurex\winaurex.cmd" (
    call "C:\WinAurex\winaurex.cmd" %*
) else (
    echo [!] WinAurex installation not found.
)
"@

$ShimTargets = @(
    (Join-Path $env:SystemRoot "winaurex.cmd"),
    (Join-Path $env:SystemRoot "System32\winaurex.cmd")
)

foreach ($target in $ShimTargets) {
    try {
        Set-Content -Path $target -Value $SystemShimContent -Force -ErrorAction SilentlyContinue
        Write-Host " [+] Installed global CLI shim: $target" -ForegroundColor Green
    } catch {}
}

# 4b. Update Machine and User PATH
try {
    $MachinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if ($MachinePath -notlike "*$RepoRoot*") {
        [Environment]::SetEnvironmentVariable("Path", "$MachinePath;$RepoRoot", [EnvironmentVariableTarget]::Machine)
        Write-Host " [+] Added $RepoRoot to Machine PATH." -ForegroundColor Green
    }
    $UserPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($UserPath -notlike "*$RepoRoot*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$RepoRoot", [EnvironmentVariableTarget]::User)
        Write-Host " [+] Added $RepoRoot to User PATH." -ForegroundColor Green
    }
    $env:Path = "$env:Path;$RepoRoot"
} catch {
    Write-Warning "Could not update machine PATH environment variable: $_"
}

# 4c. Broadcast WM_SETTINGCHANGE to notify running shells & Explorer
try {
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern System.IntPtr SendMessageTimeout(
    System.IntPtr hWnd, uint Msg, System.UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out System.UIntPtr lpdwResult);
"@ -ErrorAction SilentlyContinue | Out-Null
    $result = [System.UIntPtr]::Zero
    [Win32.NativeMethods]::SendMessageTimeout([System.IntPtr]0xffff, 0x001A, [System.UIntPtr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
} catch {}

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
