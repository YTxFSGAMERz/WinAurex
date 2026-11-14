# Tests/Tweaks.WindowsUpdate.Tests.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== RUNNING WINDOWS UPDATE RESTORATION TEST SUITE ===" -ForegroundColor Cyan

$root = Split-Path -Path $PSScriptRoot -Parent
$batPath = Join-Path $root "Tweaks\Updates\Enable Windows Update.bat"
$psPath = Join-Path $root "Tweaks\Updates\Enable_Windows_Update.ps1"
$catalogPath = Join-Path $root "Core\Helpers\CatalogEngine.psm1"

# 1. Existence
if (-not (Test-Path $batPath)) { throw "Missing $batPath" }
Write-Host " [PASS] Script exists: Enable Windows Update.bat" -ForegroundColor Green

if (-not (Test-Path $psPath)) { throw "Missing $psPath" }
Write-Host " [PASS] Script exists: Enable_Windows_Update.ps1" -ForegroundColor Green

# 2. Test Catalog Engine Execution
Import-Module $catalogPath -Force
$res = Invoke-WinAurexItem -ItemPath $batPath
if (-not $res.Success -or $res.ExitCode -ne 0) {
    throw "Invoke-WinAurexItem failed on .bat: Success=$($res.Success), ExitCode=$($res.ExitCode)"
}
Write-Host " [PASS] Invoke-WinAurexItem returned Success: True and ExitCode: 0 on batch script" -ForegroundColor Green

# 3. Verify Services
$services = Get-Service -Name wuauserv, UsoSvc, BITS -ErrorAction SilentlyContinue
foreach ($s in $services) {
    if ($s.Status -ne "Running") {
        throw "Service $($s.Name) is not Running (Current: $($s.Status))"
    }
    Write-Host " [PASS] Service $($s.Name) is Running (StartType: $($s.StartType))" -ForegroundColor Green
}

# 4. Verify Policies
$wuPolicy = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
if (Test-Path $wuPolicy) {
    $props = Get-ItemProperty -Path $wuPolicy
    if ($null -ne $props.DisableWindowsUpdateAccess) { throw "DisableWindowsUpdateAccess policy is still present" }
    if ($null -ne $props.WUServer) { throw "WUServer policy is still present" }
}
Write-Host " [PASS] Windows Update blocking policies are completely cleared" -ForegroundColor Green

# 5. Verify Settings Page Visibility
$exp = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (Test-Path $exp) {
    $val = (Get-ItemProperty -Path $exp -Name "SettingsPageVisibility" -ErrorAction SilentlyContinue).SettingsPageVisibility
    if ($val -and $val -like "*windowsupdate*") {
        throw "SettingsPageVisibility still hides windowsupdate: $val"
    }
}
Write-Host " [PASS] SettingsPageVisibility does not hide Windows Update page" -ForegroundColor Green

Write-Host "`n[ALL TESTS PASSED] Windows Update Restoration Verified." -ForegroundColor Green
