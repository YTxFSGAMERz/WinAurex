[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Enable Mouse Acceleration (Tweaks/Input/Enable_Mouse_Acceleration.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -ErrorAction SilentlyContinue
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore\Input"

if (-not (Test-Path $SnapshotDir)) { New-Item -Path $SnapshotDir -ItemType Directory -Force | Out-Null }

Write-Host "================================================="
Write-Host "   ENABLE MOUSE ACCELERATION (E.P.P.)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will restore Windows 'Enhance Pointer Precision'"
Write-Host "and default mouse acceleration curves."
Write-Host "================================================="

Write-FrameworkLog -ModuleName "Input" -Action "Backing up Mouse registry keys before enabling" -ErrorAction SilentlyContinue
$RegPath1 = "HKCU\Control Panel\Mouse"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "Mouse_Backup_BeforeEnable_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y | Out-Null

$MouseKey = "HKCU:\Control Panel\Mouse"

Write-Host "`nEnabling Enhance Pointer Precision..." -ForegroundColor Yellow
Set-ItemProperty -Path $MouseKey -Name "MouseSpeed" -Value "1" -Type String -Force
Set-ItemProperty -Path $MouseKey -Name "MouseThreshold1" -Value "6" -Type String -Force
Set-ItemProperty -Path $MouseKey -Name "MouseThreshold2" -Value "10" -Type String -Force

# Restore default Windows mouse curves by removing the flattened MarkC overrides
Remove-ItemProperty -Path $MouseKey -Name "SmoothMouseXCurve" -ErrorAction SilentlyContinue -Force
Remove-ItemProperty -Path $MouseKey -Name "SmoothMouseYCurve" -ErrorAction SilentlyContinue -Force

Write-FrameworkLog -ModuleName "Input" -Action "Enabled Mouse Acceleration (EPP)" -ErrorAction SilentlyContinue
Write-Host "[SUCCESS] Mouse Acceleration is ENABLED. Windows default acceleration restored." -ForegroundColor Green

Write-Host "You must LOG OUT or RESTART for the cursor curve to fully update." -ForegroundColor Yellow

