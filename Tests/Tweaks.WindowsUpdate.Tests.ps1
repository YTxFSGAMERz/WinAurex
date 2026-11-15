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

# 2. Strict Constraint Verification: ZERO DISM / SFC / ReAgentC in codebase
$forbiddenPatterns = @('dism\.exe', 'sfc\.exe', 'reagentc\.exe', 'Cleanup-Image', 'RestoreHealth', 'scannow')
foreach ($f in @($batPath, $psPath)) {
    $content = Get-Content $f -Raw
    foreach ($pat in $forbiddenPatterns) {
        if ($content -match $pat) {
            throw "Violation: Forbidden tool/command '$pat' found in $(Split-Path $f -Leaf)!"
        }
    }
}
Write-Host " [PASS] Zero DISM / SFC / ReAgentC commands present in scripts" -ForegroundColor Green

# 3. Test Catalog Engine Execution
Import-Module $catalogPath -Force
$res = Invoke-WinAurexItem -ItemPath $batPath
if (-not $res.Success -or $res.ExitCode -ne 0) {
    throw "Invoke-WinAurexItem failed on .bat: Success=$($res.Success), ExitCode=$($res.ExitCode)"
}
Write-Host " [PASS] Invoke-WinAurexItem returned Success: True and ExitCode: 0 on batch script" -ForegroundColor Green

# 4. Verify Services
$services = Get-Service -Name wuauserv, UsoSvc, BITS, cryptsvc -ErrorAction SilentlyContinue
foreach ($s in $services) {
    if ($s.Status -ne "Running") {
        throw "Service $($s.Name) is not Running (Current: $($s.Status))"
    }
    Write-Host " [PASS] Service $($s.Name) is Running (StartType: $($s.StartType))" -ForegroundColor Green
}

# 5. Verify Policies
$wuPolicy = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
if (Test-Path $wuPolicy) {
    $props = Get-ItemProperty -Path $wuPolicy
    if ($null -ne $props.DisableWindowsUpdateAccess) { throw "DisableWindowsUpdateAccess policy is still present" }
    if ($null -ne $props.WUServer) { throw "WUServer policy is still present" }
}
Write-Host " [PASS] Windows Update blocking policies are completely cleared" -ForegroundColor Green

# 6. Verify Settings Page Visibility
$exp = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (Test-Path $exp) {
    $val = (Get-ItemProperty -Path $exp -Name "SettingsPageVisibility" -ErrorAction SilentlyContinue).SettingsPageVisibility
    if ($val -and $val -like "*windowsupdate*") {
        throw "SettingsPageVisibility still hides windowsupdate: $val"
    }
}
Write-Host " [PASS] SettingsPageVisibility does not hide Windows Update page" -ForegroundColor Green

# 7. Verify Directory ACLs (SystemTemp & CbsTemp)
$sysTemp = "$env:SystemRoot\SystemTemp"
$sysTempAcl = (Get-Acl $sysTemp).AccessToString
if ($sysTempAcl -notmatch "TrustedInstaller" -and $sysTempAcl -notmatch "S-1-5-80-956008885") {
    throw "SystemTemp ACL missing TrustedInstaller permissions!"
}
Write-Host " [PASS] SystemTemp ACL contains TrustedInstaller permissions" -ForegroundColor Green

# 8. Verify CBS Package Registry Health (No stuck staging states with missing payload)
$cbsKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages"
$brokenStaged = 0
if (Test-Path $cbsKey) {
    Get-ChildItem -LiteralPath $cbsKey -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue
        if ($p.CurrentState -eq 32 -and ($p.InstallLocation -match 'SoftwareDistribution' -or -not (Test-Path -LiteralPath $p.InstallLocation -ErrorAction SilentlyContinue))) {
            $brokenStaged++
        }
    }
}
if ($brokenStaged -gt 0) {
    throw "Found $brokenStaged CBS packages stuck in CurrentState=32 with missing payload!"
}
Write-Host " [PASS] CBS Package Registry verified clean (0 stuck staging packages)" -ForegroundColor Green

Write-Host "`n[ALL TESTS PASSED] Windows Update Restoration & Hardening Verified." -ForegroundColor Green
