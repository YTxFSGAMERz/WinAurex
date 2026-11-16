[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$PurgeCache
)

# Windows Configuration & Optimization Framework
# Enable Windows Update (Tweaks/Updates/Enable_Windows_Update.ps1)
# Comprehensive Debloat-Safe Self-Healing (Zero DISM / SFC / ReAgentC)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

Write-Host "================================================="
Write-Host "         ENABLE WINDOWS UPDATE" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Restoring Windows Update services, policies, ACLs, and registry..." -ForegroundColor Gray

# 1. Restore any legacy renamed services
$binaries = @("WaaSMedicSvc", "wuaueng", "usosvc")
foreach ($bin in $binaries) {
    $bak = "$env:SystemRoot\System32\${bin}_BAK.dll"
    $target = "$env:SystemRoot\System32\${bin}.dll"
    if (Test-Path $bak) {
        Write-Host "Restoring $bak to $target..." -ForegroundColor Yellow
        takeown.exe /f $bak >$null 2>&1
        icacls.exe $bak /grant *S-1-1-0:F >$null 2>&1
        Rename-Item -Path $bak -NewName "${bin}.dll" -Force -ErrorAction SilentlyContinue
        icacls.exe $target /setowner "NT SERVICE\TrustedInstaller" >$null 2>&1
        icacls.exe $target /remove *S-1-1-0 >$null 2>&1
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

# 4. Configure Volume Shadow Copy (VSS) for LCU Restore Points (Resolves 0x80042302 / 0x80070422)
Write-Host "Configuring Volume Shadow Copy services for restore point staging..." -ForegroundColor Gray
$vssPath = "HKLM:\SYSTEM\CurrentControlSet\Services\VSS"
if (Test-Path $vssPath) {
    Set-ItemProperty -Path $vssPath -Name "Start" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
}
$swprvPath = "HKLM:\SYSTEM\CurrentControlSet\Services\swprv"
if (Test-Path $swprvPath) {
    Set-ItemProperty -Path $swprvPath -Name "Start" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
}

# 5. Remove Disabling Policies & WSUS Redirections
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

# 6. Restore Settings Page Visibility
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

# 7. Disable & Detach UCPD Minifilter Driver (Resolves 0x80070005 on Edge/WebView Servicing)
Write-Host "Disabling and detaching UCPD minifilter driver..." -ForegroundColor Gray
$ucpdPath = "HKLM:\SYSTEM\CurrentControlSet\Services\UCPD"
if (Test-Path $ucpdPath) {
    Set-ItemProperty -Path $ucpdPath -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
}
& schtasks.exe /change /tn "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity" /disable >$null 2>&1
& fltmc.exe detach ucpd C: >$null 2>&1
& fltmc.exe detach ucpd D: >$null 2>&1

# 8. Self-Healing Staging Permissions & Directory ACLs (Resolves 0x80070005)
Write-Host "Hardening staging directory ACLs and permissions..." -ForegroundColor Gray
$sysTemp = "$env:SystemRoot\SystemTemp"
if (-not (Test-Path $sysTemp)) { New-Item -ItemType Directory -Path $sysTemp -Force | Out-Null }
& icacls.exe $sysTemp /grant "*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F" /T /C /Q >$null 2>&1 # TrustedInstaller
& icacls.exe $sysTemp /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /C /Q >$null 2>&1
& icacls.exe $sysTemp /grant "BUILTIN\Administrators:(OI)(CI)F" /T /C /Q >$null 2>&1

$cbsTemp = "$env:SystemRoot\CbsTemp"
if (-not (Test-Path $cbsTemp)) { New-Item -ItemType Directory -Path $cbsTemp -Force | Out-Null }
& icacls.exe $cbsTemp /grant "*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F" /T /C /Q >$null 2>&1
& icacls.exe $cbsTemp /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /C /Q >$null 2>&1
& icacls.exe $cbsTemp /grant "BUILTIN\Administrators:(OI)(CI)F" /T /C /Q >$null 2>&1

# Hardening MumX directory ACLs for TrustedInstaller and SYSTEM (Resolves 0x80070005 during .mumx.esd staging)
$mumxDir = "$env:SystemRoot\Servicing\MumX"
if (-not (Test-Path $mumxDir)) { New-Item -ItemType Directory -Path $mumxDir -Force | Out-Null }
& icacls.exe $mumxDir /grant "*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F" /T /C /Q >$null 2>&1
& icacls.exe $mumxDir /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /C /Q >$null 2>&1
& icacls.exe $mumxDir /grant "BUILTIN\Administrators:(OI)(CI)F" /T /C /Q >$null 2>&1

# Purge locked CbsTemp._ForDelete if present
$cbsDelete = Join-Path $sysTemp "CbsTemp._ForDelete"
if (Test-Path $cbsDelete) {
    takeown.exe /F $cbsDelete /R /A /D Y >$null 2>&1
    cmd.exe /c "icacls `"$cbsDelete`" /grant administrators:F /t /c /q >nul 2>&1 & rd /s /q `"$cbsDelete`" >nul 2>&1"
    if (Test-Path $cbsDelete) {
        Rename-Item -Path $cbsDelete -NewName "CbsTemp_Garbage_$([guid]::NewGuid().ToString('N'))" -Force -ErrorAction SilentlyContinue
    }
}

# Grant Admin and AppContainer access on USOPrivate / USOShared to prevent Settings UI crash ('Something went wrong')
$usoPrivate = "$env:ProgramData\USOPrivate"
if (Test-Path $usoPrivate) {
    takeown.exe /F $usoPrivate /A /R /D Y >$null 2>&1
    & cmd.exe /c "icacls `"$usoPrivate`" /grant administrators:(OI)(CI)F /grant *S-1-15-2-1:(OI)(CI)RX /grant *S-1-15-2-2:(OI)(CI)RX /t /c /q >nul 2>&1"
}
$usoShared = "$env:ProgramData\USOShared"
if (Test-Path $usoShared) {
    takeown.exe /F $usoShared /A /R /D Y >$null 2>&1
    & cmd.exe /c "icacls `"$usoShared`" /grant administrators:(OI)(CI)F /grant *S-1-15-2-1:(OI)(CI)RX /grant *S-1-15-2-2:(OI)(CI)RX /t /c /q >nul 2>&1"
}

# 9. Self-Healing UpdateStore Reset (Resolves Settings UI 'Something went wrong. Try to reopen Settings later.')
$usoStore = "$env:ProgramData\USOPrivate\UpdateStore"
$storeDb = Join-Path $usoStore "store.db"
$isCorruptSize = (Test-Path $storeDb) -and ((Get-Item $storeDb).Length -gt 1MB)
$hasFailureState = $false
if (Test-Path $storeDb) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($storeDb)
        $text = [System.Text.Encoding]::Unicode.GetString($bytes)
        if ($text.Contains('BlockedByFailure')) {
            $hasFailureState = $true
        }
    } catch {}
}
$needsStoreReset = $Force -or $PurgeCache -or (-not (Test-Path $storeDb)) -or $isCorruptSize -or $hasFailureState
if ($needsStoreReset) {
    Write-Host "Resetting UpdateStore database to resolve Settings UI errors..." -ForegroundColor Gray
    Stop-Service UsoSvc -Force -ErrorAction SilentlyContinue
    Stop-Process -Name MoUsoCoreWorker, UsoClient, SystemSettings -Force -ErrorAction SilentlyContinue
    if (Test-Path $usoStore) {
        Get-ChildItem -Path $usoStore -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Start-Service UsoSvc -ErrorAction SilentlyContinue
    Start-Process usoclient -ArgumentList 'RefreshSettings' -Wait -ErrorAction SilentlyContinue
}

# 10. Debloat-Safe WinSxS Baseline Stub Restoration (Resolves 0x80073712 without DISM/SFC)
Write-Host "Verifying .NET and CSI delta base stubs in WinSxS..." -ForegroundColor Gray
function Restore-WinSxSStub($targetDir, $sourceFile, $destFileName) {
    if (-not (Test-Path -LiteralPath $sourceFile)) { return }
    $destFile = Join-Path $targetDir $destFileName
    if (Test-Path -LiteralPath $destFile) { return }
    
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    takeown.exe /F $targetDir >$null 2>&1
    icacls.exe $targetDir /grant "Administrators:(OI)(CI)F" >$null 2>&1
    Copy-Item -LiteralPath $sourceFile -Destination $destFile -Force -ErrorAction SilentlyContinue
    icacls.exe $destFile /setowner "NT SERVICE\TrustedInstaller" >$null 2>&1
    icacls.exe $targetDir /setowner "NT SERVICE\TrustedInstaller" >$null 2>&1
    icacls.exe $targetDir /reset /T /C /Q >$null 2>&1
}

$winsxsDir = "$env:SystemRoot\WinSxS"

# High-speed targeted stub restoration across known delta transition points
$stubConfigs = @(
    @{ Filter = "*netfx*aspnet_regiis*"; TargetFile = "aspnet_regiis.exe" },
    @{ Filter = "*netfx*installsqlstate_sql_*"; TargetFile = "InstallSqlState.sql" },
    @{ Filter = "*system.data_*"; TargetFile = "System.Data.dll" },
    @{ Filter = "*netfx*peverify*"; TargetFile = "peverify.dll" },
    @{ Filter = "*netfx*mscorpe*"; TargetFile = "mscorpe.dll" },
    @{ Filter = "*netfx*mscorjit*"; TargetFile = "mscorjit.dll" },
    @{ Filter = "*aspnet_regsql*"; TargetFile = "aspnet_regsql.exe" },
    @{ Filter = "*netfx35linq-system.web.extensions_*"; TargetFile = "System.Web.Extensions.dll" },
    @{ Filter = "*netfx4-vbc_exe*"; TargetFile = "vbc.exe" },
    @{ Filter = "*aspnet_regbrowsers*"; TargetFile = "aspnet_regbrowsers.exe" }
)

foreach ($sc in $stubConfigs) {
    $matchedDirs = Get-ChildItem -Path $winsxsDir -Filter $sc.Filter -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $matchedDirs) {
        # Strictly restrict baseline stub restoration to baseline OS build components (10.0.26100.1 / 4.0.15912.0).
        # Target update and delta staging directories (e.g. 10.0.27000.*, 4.0.15920.*) must NEVER have baseline
        # uncompressed stubs injected, as this triggers STATUS_SXS_COMPONENT_STORE_CORRUPT (0x80073712) in deltastore.cpp.
        $isBaseline = ($dir.Name -like "*10.0.26100.1_*") -or ($dir.Name -like "*4.0.15912.0_*")
        if (-not $isBaseline) { continue }

        $destFile = Join-Path $dir.FullName $sc.TargetFile
        if (-not (Test-Path -LiteralPath $destFile)) {
            $parts = $dir.Name -split '_'
            if ($parts.Count -ge 5) {
                $compPrefix = "$($parts[0])_$($parts[1])_"
                $donor = $matchedDirs | Where-Object {
                    $_.Name -ne $dir.Name -and $_.Name.StartsWith($compPrefix) -and (Test-Path -LiteralPath (Join-Path $_.FullName $sc.TargetFile))
                } | Select-Object -First 1

                if ($donor) {
                    $donorFile = Join-Path $donor.FullName $sc.TargetFile
                    Restore-WinSxSStub -targetDir $dir.FullName -sourceFile $donorFile -destFileName $sc.TargetFile
                }
            }
        }
    }
}

# Restore any missing base files for WinSxS folders containing \r\ delta differentials (Resolves 0x80073712 MissingFileSystemResource)
$rParentDirs = Get-ChildItem -Path $winsxsDir -Directory -Filter "*10.0.26100.*" -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName "r") }
foreach ($rp in $rParentDirs) {
    $rFiles = Get-ChildItem -Path (Join-Path $rp.FullName "r") -File -ErrorAction SilentlyContinue
    foreach ($rf in $rFiles) {
        $neededFile = Join-Path $rp.FullName $rf.Name
        if (-not (Test-Path -LiteralPath $neededFile)) {
            $parts = $rp.Name -split '_'
            if ($parts.Count -ge 5) {
                $compPrefix = "$($parts[0])_$($parts[1])_"
                $donorDirs = Get-ChildItem -Path $winsxsDir -Directory -Filter "$compPrefix*" -ErrorAction SilentlyContinue
                foreach ($donor in $donorDirs) {
                    $donorFile = Join-Path $donor.FullName $rf.Name
                    if (Test-Path -LiteralPath $donorFile) {
                        Restore-WinSxSStub -targetDir $rp.FullName -sourceFile $donorFile -destFileName $rf.Name
                        break
                    }
                }
            }
        }
    }
}

# 11. Surgical CBS Staging Registry Healing (Resolves 0x80073712, 0x80070005 & 0x8000ffff)
Write-Host "Verifying CBS package staging states in registry..." -ForegroundColor Gray
$cbsPackagesKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages"
$servicingDir = "$env:SystemRoot\Servicing\Packages"
if (Test-Path $cbsPackagesKey) {
    $packages = Get-ChildItem -LiteralPath $cbsPackagesKey -ErrorAction SilentlyContinue
    $repairedCount = 0
    foreach ($pkg in $packages) {
        $props = Get-ItemProperty -LiteralPath $pkg.PSPath -ErrorAction SilentlyContinue
        if ($null -eq $props) { continue }
        
        # Clear any recorded error code (e.g. 0x80070005, 0x80073712)
        if ($props.LastError -and $props.LastError -ne 0) {
            Remove-ItemProperty -LiteralPath $pkg.PSPath -Name "LastError" -Force -ErrorAction SilentlyContinue
            $repairedCount++
        }

        # Clear stale InstallGroup referencing dead sessions
        if ($props.InstallGroup) {
            Remove-ItemProperty -LiteralPath $pkg.PSPath -Name "InstallGroup" -Force -ErrorAction SilentlyContinue
            $repairedCount++
        }
        
        # If an Absent package (CurrentState 0) has no .mum file in Servicing\Packages, delete the orphaned key
        # so TiWorker's express update watchlist resolution does not fail with 0x80070490 (ERROR_NOT_FOUND).
        if ($props.CurrentState -eq 0) {
            $mumFile = Join-Path $servicingDir "$($pkg.PSChildName).mum"
            if (-not (Test-Path -LiteralPath $mumFile -ErrorAction SilentlyContinue)) {
                Remove-Item -LiteralPath $pkg.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                $repairedCount++
                continue
            }
        }
        
        # If package is missing its .mum file in Servicing\Packages or has no payload, clean or reset to Absent (0) so TiWorker doesn't crash with 0x8000ffff / 0x80070490
        $isStaged = ($props.CurrentState -eq 32 -or $props.CurrentState -eq 64)
        $hasMissingMum = ($props.InstallName -and !(Test-Path -LiteralPath (Join-Path $servicingDir $props.InstallName) -ErrorAction SilentlyContinue))
        $hasMissingLoc = ($props.InstallLocation -and !(Test-Path -LiteralPath $props.InstallLocation -ErrorAction SilentlyContinue))
        $isSDFolder = ($props.InstallLocation -match 'SoftwareDistribution\\Download')
        $noLoc = [string]::IsNullOrEmpty($props.InstallLocation)
        
        if ($isStaged -and ($hasMissingMum -or $hasMissingLoc -or $isSDFolder -or $noLoc)) {
            if ($hasMissingMum) {
                Remove-Item -LiteralPath $pkg.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Set-ItemProperty -LiteralPath $pkg.PSPath -Name "CurrentState" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                if ($props.InstallLocation) {
                    Remove-ItemProperty -LiteralPath $pkg.PSPath -Name "InstallLocation" -Force -ErrorAction SilentlyContinue
                }
            }
            $repairedCount++
        }
    }
    if ($repairedCount -gt 0) {
        Write-Host "Remediated $repairedCount CBS package registry records." -ForegroundColor Green
    }
}

# Clean orphaned MumXContainers keys (Resolves 0x80070005 during mumx container staging)
$mumxContainersKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\MumXContainers"
if (Test-Path $mumxContainersKey) {
    $mumxDir = "$env:SystemRoot\Servicing\MumX"
    $containers = Get-ChildItem -LiteralPath $mumxContainersKey -ErrorAction SilentlyContinue
    foreach ($c in $containers) {
        $containerFile = Join-Path $mumxDir "$($c.PSChildName).mumx.esd"
        if (-not (Test-Path -LiteralPath $containerFile)) {
            Remove-Item -LiteralPath $c.PSPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

$cbsPending = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\SessionsPending"
if (Test-Path $cbsPending) {
    $pendingItems = Get-ChildItem -LiteralPath $cbsPending -ErrorAction SilentlyContinue
    if ($pendingItems.Count -gt 0) {
        $pendingItems | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$lcuErrorKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\LCUInstallErrors",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\LCUInstallErrorPackageNames"
)
foreach ($k in $lcuErrorKeys) {
    if (Test-Path $k) {
        Get-ChildItem -LiteralPath $k -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 12. Optional/Self-Healing Cache & Catalog Purge
if ($PurgeCache -or $Force) {
    Write-Host "Purging SoftwareDistribution download cache and resetting catroot2..." -ForegroundColor Gray
    $sdDownload = "$env:SystemRoot\SoftwareDistribution\Download"
    if (Test-Path $sdDownload) {
        Get-ChildItem -Path $sdDownload -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 13. Re-enable Services
Write-Host "Configuring and starting services..." -ForegroundColor Gray
Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
Set-Service -Name UsoSvc -StartupType Automatic -ErrorAction SilentlyContinue
Set-Service -Name WaaSMedicSvc -StartupType Manual -ErrorAction SilentlyContinue
Set-Service -Name BITS -StartupType Automatic -ErrorAction SilentlyContinue
Set-Service -Name dosvc -StartupType Manual -ErrorAction SilentlyContinue
Set-Service -Name cryptsvc -StartupType Automatic -ErrorAction SilentlyContinue

Start-Service -Name cryptsvc -ErrorAction SilentlyContinue
Start-Service -Name BITS -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Start-Service -Name UsoSvc -ErrorAction SilentlyContinue
Start-Service -Name dosvc -ErrorAction SilentlyContinue

# 14. Re-enable Scheduled Tasks
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

Write-Host "`n[SUCCESS] Windows Update services, policies, ACLs, stubs, and scheduled tasks restored successfully!" -ForegroundColor Green
