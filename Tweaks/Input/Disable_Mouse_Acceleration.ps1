[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Disable Mouse Acceleration (Tweaks/Input/Disable_Mouse_Acceleration.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

$MouseKey = "HKCU:\Control Panel\Mouse"
$curSpeed = (Get-ItemProperty -Path $MouseKey -Name "MouseSpeed" -ErrorAction SilentlyContinue).MouseSpeed
$curThresh1 = (Get-ItemProperty -Path $MouseKey -Name "MouseThreshold1" -ErrorAction SilentlyContinue).MouseThreshold1

if ($curSpeed -eq "0" -and $curThresh1 -eq "0") {
    Write-Host "  [-] Mouse Acceleration (Enhance Pointer Precision) is already disabled. 1:1 input active." -ForegroundColor DarkGray
    Exit 0
}

$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore\Input"
if (-not (Test-Path $SnapshotDir)) { New-Item -Path $SnapshotDir -ItemType Directory -Force | Out-Null }

Write-Host "================================================="
Write-Host "   DISABLE MOUSE ACCELERATION (E.P.P.)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Windows 'Enhance Pointer Precision' artificially scales"
Write-Host "mouse movement based on speed, which destroys muscle"
Write-Host "memory in competitive FPS games."
Write-Host "================================================="

$RegPath1 = "HKCU\Control Panel\Mouse"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "Mouse_Backup_BeforeDisable_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y | Out-Null

Write-Host "`nDisabling Enhance Pointer Precision..." -ForegroundColor Yellow
Set-ItemProperty -Path $MouseKey -Name "MouseSpeed" -Value "0" -Type String -Force
Set-ItemProperty -Path $MouseKey -Name "MouseThreshold1" -Value "0" -Type String -Force
Set-ItemProperty -Path $MouseKey -Name "MouseThreshold2" -Value "0" -Type String -Force

# Flatten mouse acceleration curves (MarkC 1-to-1 input curves)
$SmoothCurve = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x15,0x6e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x01,0x00,0x00,0x00,0x00,0x00,0x29,0xdc,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x00,0x00)
Set-ItemProperty -Path $MouseKey -Name "SmoothMouseXCurve" -Value $SmoothCurve -Type Binary -Force
Set-ItemProperty -Path $MouseKey -Name "SmoothMouseYCurve" -Value $SmoothCurve -Type Binary -Force

Write-Host "[SUCCESS] Mouse Acceleration is DISABLED. You now have 1:1 input." -ForegroundColor Green
Write-Host "You must LOG OUT or RESTART for the cursor curve to fully update." -ForegroundColor Yellow
