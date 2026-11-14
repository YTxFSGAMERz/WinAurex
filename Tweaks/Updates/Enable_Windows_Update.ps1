[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Enable Windows Update (Tweaks/Updates/Enable_Windows_Update.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

Write-Host "================================================="
Write-Host "         ENABLE WINDOWS UPDATE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Restoring Windows Update services, policies, and tasks..." -ForegroundColor Gray

# 1. Restore any legacy renamed services
$binaries = @("WaaSMedicSvc", "wuaueng", "usosvc")
foreach ($bin in $binaries) {
    $bak = "$env:SystemRoot\System32\${bin}_BAK.dll"
    $target = "$env:SystemRoot\System32\${bin}.dll"
    if (Test-Path $bak) {
        Write-Host "Restoring $bak to $target..." -ForegroundColor Yellow
        takeown /f $bak >$null 2>&1
        icacls $bak /grant *S-1-1-0:F >$null 2>&1
        Rename-Item -Path $bak -NewName "${bin}.dll" -Force -ErrorAction SilentlyContinue
        icacls $target /setowner "NT SERVICE\TrustedInstaller" >$null 2>&1
        icacls $target /remove *S-1-1-0 >$null 2>&1
    }
}

# 2. Re-register UsoSvc if missing
$usoQuery = sc.exe query UsoSvc 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Re-registering Update Orchestrator Service (UsoSvc)..." -ForegroundColor Yellow
    sc.exe create UsoSvc binPath= "%SystemRoot%\system32\svchost.exe -k netsvcs -p" type= share start= auto depend= rpcss >$null 2>&1
}
$usoPath = "HKLM:\SYSTEM\CurrentControlSet\Services\UsoSvc"
if (-not (Test-Path $usoPath)) { New-Item -Path $usoPath -Force | Out-Null }
Set-ItemProperty -Path $usoPath -Name "DisplayName" -Value "@%systemroot%\system32\usosvc.dll,-101" -Type String -Force
Set-ItemProperty -Path $usoPath -Name "Description" -Value "@%systemroot%\system32\usosvc.dll,-102" -Type String -Force
Set-ItemProperty -Path $usoPath -Name "ImagePath" -Value "%SystemRoot%\system32\svchost.exe -k netsvcs -p" -Type ExpandString -Force
Set-ItemProperty -Path $usoPath -Name "ObjectName" -Value "LocalSystem" -Type String -Force
Set-ItemProperty -Path $usoPath -Name "ErrorControl" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $usoPath -Name "Start" -Value 2 -Type DWord -Force
Set-ItemProperty -Path $usoPath -Name "Type" -Value 32 -Type DWord -Force
Set-ItemProperty -Path $usoPath -Name "DependOnService" -Value @("rpcss") -Type MultiString -Force
Set-ItemProperty -Path $usoPath -Name "ServiceSidType" -Value 1 -Type DWord -Force

$usoParams = "$usoPath\Parameters"
if (-not (Test-Path $usoParams)) { New-Item -Path $usoParams -Force | Out-Null }
Set-ItemProperty -Path $usoParams -Name "ServiceDll" -Value "%SystemRoot%\system32\usosvc.dll" -Type ExpandString -Force
Set-ItemProperty -Path $usoParams -Name "ServiceDllUnloadOnStop" -Value 1 -Type DWord -Force

# 3. Re-register WaaSMedicSvc if missing
$waasQuery = sc.exe query WaaSMedicSvc 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Re-registering Windows Update Medic Service (WaaSMedicSvc)..." -ForegroundColor Yellow
    sc.exe create WaaSMedicSvc binPath= "%SystemRoot%\system32\svchost.exe -k wusvcs -p" type= share start= demand depend= rpcss >$null 2>&1
}
$waasPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
if (-not (Test-Path $waasPath)) { New-Item -Path $waasPath -Force | Out-Null }
Set-ItemProperty -Path $waasPath -Name "DisplayName" -Value "Windows Update Medic Service" -Type String -Force
Set-ItemProperty -Path $waasPath -Name "Description" -Value "Enables remediation and protection of Windows Update components." -Type String -Force
Set-ItemProperty -Path $waasPath -Name "ImagePath" -Value "%SystemRoot%\system32\svchost.exe -k wusvcs -p" -Type ExpandString -Force
Set-ItemProperty -Path $waasPath -Name "ObjectName" -Value "LocalSystem" -Type String -Force
Set-ItemProperty -Path $waasPath -Name "ErrorControl" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $waasPath -Name "Start" -Value 3 -Type DWord -Force
Set-ItemProperty -Path $waasPath -Name "Type" -Value 32 -Type DWord -Force
Set-ItemProperty -Path $waasPath -Name "DependOnService" -Value @("rpcss") -Type MultiString -Force
Set-ItemProperty -Path $waasPath -Name "ServiceSidType" -Value 1 -Type DWord -Force

$waasParams = "$waasPath\Parameters"
if (-not (Test-Path $waasParams)) { New-Item -Path $waasParams -Force | Out-Null }
Set-ItemProperty -Path $waasParams -Name "ServiceDll" -Value "%SystemRoot%\system32\WaaSMedicSvc.dll" -Type ExpandString -Force
Set-ItemProperty -Path $waasParams -Name "ServiceDllUnloadOnStop" -Value 1 -Type DWord -Force

# Ensure svchost groups
$svchostPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost"
Set-ItemProperty -Path $svchostPath -Name "wusvcs" -Value @("WaaSMedicSvc") -Type MultiString -Force

# 4. Remove Disabling Policies & WSUS Redirections
Write-Host "Removing blocking policies and WSUS redirects..." -ForegroundColor Gray
$wuPolicy = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
if (Test-Path $wuPolicy) {
    @("DisableWindowsUpdateAccess", "DoNotConnectToWindowsUpdateInternetLocations", "WUServer", "WUStatusServer", "UpdateServiceUrlAlternate") | ForEach-Object {
        Remove-ItemProperty -Path $wuPolicy -Name $_ -ErrorAction SilentlyContinue
    }
}
$auPolicy = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (Test-Path $auPolicy) {
    @("UseWUServer", "NoAutoUpdate", "AUOptions") | ForEach-Object {
        Remove-ItemProperty -Path $auPolicy -Name $_ -ErrorAction SilentlyContinue
    }
}
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "DisableOnline" -ErrorAction SilentlyContinue

# 5. Restore Settings Page Visibility
$exp = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (Test-Path $exp) {
    $val = (Get-ItemProperty -Path $exp -Name "SettingsPageVisibility" -ErrorAction SilentlyContinue).SettingsPageVisibility
    if ($val) {
        $newVal = ($val -replace ';?windowsupdate', '' -replace 'windowsupdate;?', '').Trim(';')
        if ($newVal -eq 'hide:' -or [string]::IsNullOrWhiteSpace($newVal) -or $newVal -eq 'hide') {
            Remove-ItemProperty -Path $exp -Name "SettingsPageVisibility" -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $exp -Name "SettingsPageVisibility" -Value $newVal -Force
        }
    }
}

# 6. Re-enable Services
Write-Host "Configuring and starting services..." -ForegroundColor Gray
Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
Set-Service -Name UsoSvc -StartupType Automatic -ErrorAction SilentlyContinue
Set-Service -Name WaaSMedicSvc -StartupType Manual -ErrorAction SilentlyContinue
Set-Service -Name BITS -StartupType Automatic -ErrorAction SilentlyContinue
Set-Service -Name dosvc -StartupType Manual -ErrorAction SilentlyContinue

Start-Service -Name BITS -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Start-Service -Name UsoSvc -ErrorAction SilentlyContinue

# 7. Re-enable Scheduled Tasks
Write-Host "Re-enabling scheduled update tasks..." -ForegroundColor Gray
$tasks = @(
    "\Microsoft\Windows\InstallService\ScanForUpdates",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
    "\Microsoft\Windows\UpdateOrchestrator\Report policies",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Work",
    "\Microsoft\Windows\WaaSMedic\PerformRemediation",
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
)
foreach ($t in $tasks) {
    schtasks.exe /change /tn $t /enable >$null 2>&1
}

Write-Host "`n[SUCCESS] Windows Update services, policies, and scheduled tasks restored successfully!" -ForegroundColor Green
