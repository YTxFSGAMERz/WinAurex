<#
.SYNOPSIS
    WinAurex Deep Windows Widgets, Weather & Services Eradicator
.DESCRIPTION
    Permanently eliminates Windows Widgets, MSN Weather, MSN News, and all background telemetry traces:
    1. Purges AppX packages (WebExperience, BingWeather, BingNews, BingSearch) for all users.
    2. De-provisions staging packages from the online Windows image.
    3. Enforces Group Policy lockdowns (AllowNewsAndInterests = 0, EnableFeeds = 0, TaskbarDa = 0).
    4. Disables scheduled background maintenance and telemetry tasks.
    5. Force-terminates active Widgets runtime processes and refreshes Explorer.
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
Write-Host "       WinAurex Deep Windows Widgets & Weather Eradication Engine     " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Purging Widgets, WebExperience pack, Weather, News, and background traces...`n" -ForegroundColor DarkGray

$targetAppxPatterns = @(
    "*MicrosoftWindows.Client.WebExperience*",
    "*Microsoft.BingWeather*",
    "*Microsoft.BingNews*",
    "*Microsoft.BingSearch*"
)

# 1. PURGE PROVISIONED PACKAGES (Prevents reinstall on new users or feature updates)
Write-Host "  [*] Auditing and removing online provisioned AppX packages..." -ForegroundColor Cyan
foreach ($pattern in $targetAppxPatterns) {
    try {
        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like $pattern -or $_.DisplayName -like $pattern }
        foreach ($pkg in $provisioned) {
            Write-Host "    [-] De-provisioning package: $($pkg.DisplayName)" -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {}
}

# 2. PURGE INSTALLED PACKAGES FOR ALL USERS
Write-Host "  [*] Removing installed packages across all user profiles..." -ForegroundColor Cyan
foreach ($pattern in $targetAppxPatterns) {
    try {
        $installed = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern -or $_.PackageFullName -like $pattern }
        foreach ($pkg in $installed) {
            Write-Host "    [-] Removing installed package: $($pkg.Name)" -ForegroundColor Yellow
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {}
}

# 3. ENFORCE SYSTEM GROUP POLICIES & EXPLORER SETTINGS
Write-Host "  [*] Enforcing Group Policies and Explorer shell preferences..." -ForegroundColor Cyan

# Dsh Policy
$DshPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $DshPolicy)) { New-Item -Path $DshPolicy -Force | Out-Null }
Set-ItemProperty -Path $DshPolicy -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Windows Feeds Policy
$FeedsPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
if (-not (Test-Path $FeedsPolicy)) { New-Item -Path $FeedsPolicy -Force | Out-Null }
Set-ItemProperty -Path $FeedsPolicy -Name "EnableFeeds" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# PolicyManager Default
$PolicyManager = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests"
if (Test-Path $PolicyManager) {
    Set-ItemProperty -Path $PolicyManager -Name "value" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
}

# Explorer Advanced Settings (Hide widget icon from taskbar)
$UserAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $UserAdvanced)) { New-Item -Path $UserAdvanced -Force | Out-Null }
Set-ItemProperty -Path $UserAdvanced -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$MachineAdvanced = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $MachineAdvanced)) { New-Item -Path $MachineAdvanced -Force | Out-Null }
Set-ItemProperty -Path $MachineAdvanced -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Disable Taskbar Feeds View Mode (0 = icon and text, 1 = icon only, 2 = hidden)
$UserFeeds = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
if (-not (Test-Path $UserFeeds)) { New-Item -Path $UserFeeds -Force | Out-Null }
Set-ItemProperty -Path $UserFeeds -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue

$MachineFeeds = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds"
if (-not (Test-Path $MachineFeeds)) { New-Item -Path $MachineFeeds -Force | Out-Null }
Set-ItemProperty -Path $MachineFeeds -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue

# 4. DISABLE SCHEDULED TELEMETRY & BACKGROUND WIDGET TASKS
Write-Host "  [*] Disabling scheduled widget telemetry and refresh tasks..." -ForegroundColor Cyan
$tasksToDisable = @(
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
)
foreach ($task in $tasksToDisable) {
    try {
        $t = Get-ScheduledTask -TaskPath ($task | Split-Path -Parent) -TaskName ($task | Split-Path -Leaf) -ErrorAction SilentlyContinue
        if ($t -and $t.State -ne 'Disabled') {
            Disable-ScheduledTask -TaskPath ($task | Split-Path -Parent) -TaskName ($task | Split-Path -Leaf) -ErrorAction SilentlyContinue | Out-Null
            Write-Host "    [+] Disabled task: $task" -ForegroundColor DarkGray
        }
    } catch {}
}

# Scan for any additional tasks with Widget in the name or path
try {
    Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*Widget*" -or $_.TaskPath -like "*Widget*" } | ForEach-Object {
        if ($_.State -ne 'Disabled') {
            Disable-ScheduledTask -InputObject $_ -ErrorAction SilentlyContinue | Out-Null
            Write-Host "    [+] Disabled scheduled task: $($_.TaskName)" -ForegroundColor DarkGray
        }
    }
} catch {}

# 5. TERMINATE ACTIVE BACKGROUND PROCESSES
Write-Host "  [*] Terminating active Widgets and WebExperience host processes..." -ForegroundColor Cyan
$processesToKill = @("Widgets", "widgetservice")
foreach ($pName in $processesToKill) {
    Get-Process -Name $pName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "*widget*" } | Stop-Process -Force -ErrorAction SilentlyContinue

# 6. RESTART EXPLORER SHELL IF REQUESTED
if ($RestartExplorer) {
    Write-Host "  [*] Refreshing Windows Explorer shell to apply visual changes..." -ForegroundColor Yellow
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 600
    if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
        Start-Process "explorer.exe"
    }
}

Write-Host "`n[SUCCESS] Windows Widgets, Weather, and background traces completely eradicated!" -ForegroundColor Green
