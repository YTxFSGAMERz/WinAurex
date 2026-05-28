# Windows Configuration & Optimization Framework
# Export Current Settings (Core/Restore/Export_Current_Settings.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

$BackupDir = Join-Path -Path $PSScriptRoot -ChildPath "Backups"
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null }

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$SettingsFolder = Join-Path -Path $BackupDir -ChildPath "${Timestamp}_Settings"
New-Item -ItemType Directory -Force -Path $SettingsFolder | Out-Null

Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Started Settings Export" -NewValue $SettingsFolder

# 1. Export Services State
$ServicesFile = Join-Path -Path $SettingsFolder -ChildPath "Services_State.csv"
Get-Service | Select-Object Name, DisplayName, Status, StartType | Export-Csv -Path $ServicesFile -NoTypeInformation
Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Exported Services State"

# 2. Export Scheduled Tasks (Custom Tasks that are enabled)
$TasksFile = Join-Path -Path $SettingsFolder -ChildPath "Scheduled_Tasks.csv"
Get-ScheduledTask | Where-Object State -ne 'Disabled' | Select-Object TaskName, TaskPath, State | Export-Csv -Path $TasksFile -NoTypeInformation
Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Exported Scheduled Tasks"

# 3. Export Power Plan GUI output
$PowerFile = Join-Path -Path $SettingsFolder -ChildPath "Power_Plans.txt"
powercfg /list | Out-File -FilePath $PowerFile -Encoding UTF8
Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Exported Power Configuration"

Write-Host "`n[SUCCESS] Settings exported to: $SettingsFolder" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
