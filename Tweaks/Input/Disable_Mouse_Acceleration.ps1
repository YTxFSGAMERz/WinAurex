# Windows Configuration & Optimization Framework
# Disable Mouse Acceleration (Tweaks/Input/Disable_Mouse_Acceleration.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force
$SnapshotDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Restore\Input"

if (-not (Test-Path $SnapshotDir)) { New-Item -Path $SnapshotDir -ItemType Directory -Force | Out-Null }

Write-Host "================================================="
Write-Host "   DISABLE MOUSE ACCELERATION (E.P.P.)" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Windows 'Enhance Pointer Precision' artificially scales"
Write-Host "mouse movement based on speed, which destroys muscle"
Write-Host "memory in competitive FPS games."
Write-Host "================================================="
Write-Host "1. Disable Mouse Acceleration (Recommended for Gamers)"
Write-Host "2. Enable Mouse Acceleration (Default Windows Behavior)"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-FrameworkLog -ModuleName "Input" -Action "Aborted Mouse Accel config"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Input" -Action "Backing up Mouse registry keys"
$RegPath1 = "HKCU\Control Panel\Mouse"
$BackupFile = Join-Path -Path $SnapshotDir -ChildPath "Mouse_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
& reg export $RegPath1 $BackupFile /y | Out-Null

$MouseKey = "HKCU:\Control Panel\Mouse"

if ($Choice -eq '1') {
    Write-Host "`nDisabling Enhance Pointer Precision..." -ForegroundColor Yellow
    Set-ItemProperty -Path $MouseKey -Name "MouseSpeed" -Value "0" -Type String -Force
    Set-ItemProperty -Path $MouseKey -Name "MouseThreshold1" -Value "0" -Type String -Force
    Set-ItemProperty -Path $MouseKey -Name "MouseThreshold2" -Value "0" -Type String -Force
    
    # Also ensure smooth mouse curves are flattened (the MarkC fix logic)
    $SmoothCurve = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x15,0x6e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x01,0x00,0x00,0x00,0x00,0x00,0x29,0xdc,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x28,0x00,0x00,0x00,0x00,0x00)
    Set-ItemProperty -Path $MouseKey -Name "SmoothMouseXCurve" -Value $SmoothCurve -Type Binary -Force
    Set-ItemProperty -Path $MouseKey -Name "SmoothMouseYCurve" -Value $SmoothCurve -Type Binary -Force

    Write-FrameworkLog -ModuleName "Input" -Action "Disabled Mouse Acceleration (EPP)"
    Write-Host "[SUCCESS] Mouse Acceleration is DISABLED. You now have 1:1 input." -ForegroundColor Green
} else {
    Write-Host "`nEnabling Enhance Pointer Precision..." -ForegroundColor Yellow
    Set-ItemProperty -Path $MouseKey -Name "MouseSpeed" -Value "1" -Type String -Force
    Set-ItemProperty -Path $MouseKey -Name "MouseThreshold1" -Value "6" -Type String -Force
    Set-ItemProperty -Path $MouseKey -Name "MouseThreshold2" -Value "10" -Type String -Force

    Write-FrameworkLog -ModuleName "Input" -Action "Enabled Mouse Acceleration (EPP)"
    Write-Host "[SUCCESS] Mouse Acceleration is ENABLED." -ForegroundColor Green
}

Write-Host "You must LOG OUT or RESTART for the cursor curve to fully update." -ForegroundColor Yellow


$null = Read-Host "Press Enter to exit..."
