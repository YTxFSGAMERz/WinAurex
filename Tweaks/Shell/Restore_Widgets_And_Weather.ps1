<#
.SYNOPSIS
    WinAurex Restore Windows Widgets & Explorer Preferences
.DESCRIPTION
    Restores default Windows Widgets settings, Group Policies, Explorer taskbar visibility,
    and scheduled tasks.
#>
[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$RestartExplorer
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    Exit 1
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex Restore Windows Widgets Defaults                    " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. REMOVE RESTRICTIVE GROUP POLICIES
Write-Host "  [*] Restoring default Group Policies..." -ForegroundColor Cyan
$DshPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (Test-Path $DshPolicy) {
    Remove-ItemProperty -Path $DshPolicy -Name "AllowNewsAndInterests" -Force -ErrorAction SilentlyContinue
}

$FeedsPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
if (Test-Path $FeedsPolicy) {
    Remove-ItemProperty -Path $FeedsPolicy -Name "EnableFeeds" -Force -ErrorAction SilentlyContinue
}

# 2. RESTORE EXPLORER TASKBAR ICON
Write-Host "  [*] Enabling Widgets taskbar visibility..." -ForegroundColor Cyan
$UserAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (Test-Path $UserAdvanced) {
    Set-ItemProperty -Path $UserAdvanced -Name "TaskbarDa" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}

$UserFeeds = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
if (Test-Path $UserFeeds) {
    Set-ItemProperty -Path $UserFeeds -Name "ShellFeedsTaskbarViewMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

# 3. RE-ENABLE SCHEDULED TASKS
Write-Host "  [*] Re-enabling scheduled maintenance tasks..." -ForegroundColor Cyan
$tasksToEnable = @(
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
)
foreach ($task in $tasksToEnable) {
    try {
        Enable-ScheduledTask -TaskPath ($task | Split-Path -Parent) -TaskName ($task | Split-Path -Leaf) -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}

# 4. RESTART EXPLORER IF REQUESTED
if ($RestartExplorer) {
    Write-Host "  [*] Refreshing Windows Explorer shell..." -ForegroundColor Yellow
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 600
    if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
        Start-Process "explorer.exe"
    }
}

Write-Host "`n[SUCCESS] Windows Widgets preferences restored." -ForegroundColor Green
Write-Host "  Note: If WebExperience was uninstalled, you can reinstall it via Microsoft Store or winget install 'Windows Web Experience Pack'." -ForegroundColor DarkGray
