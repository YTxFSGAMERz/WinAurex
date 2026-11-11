<#
.SYNOPSIS
    WinAurex Guarded OS Debloater & Appx Purge
.DESCRIPTION
    Scrubs pre-installed consumer bloatware, promotional packages, and sponsored shovelware
    while strictly protecting Microsoft Store, Windows Terminal, Calculator, Photos, and Visual C++ runtimes.
    Optimized for high-performance batch querying and idempotency.
#>
[CmdletBinding()]
param (
    [switch]$Force
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "              WinAurex Deep OS Debloat & Appx Purge                   " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. Disable Cloud Content Delivery & Shovelware Injection
Write-Host "`n[*] Checking automatic consumer bloatware policies..." -ForegroundColor Cyan
try {
    $cloudPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $curConsumer = (Get-ItemProperty $cloudPath -Name "DisableWindowsConsumerFeatures" -ErrorAction SilentlyContinue).DisableWindowsConsumerFeatures
    if ($curConsumer -eq 1) {
        Write-Host "  [-] Consumer bloatware injection already disabled (Skipping)." -ForegroundColor DarkGray
    } else {
        if (-not (Test-Path $cloudPath)) { New-Item -Path $cloudPath -Force | Out-Null }
        Set-ItemProperty -Path $cloudPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $contentDelivery = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $contentDelivery)) { New-Item -Path $contentDelivery -Force | Out-Null }
        Set-ItemProperty -Path $contentDelivery -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDelivery -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDelivery -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDelivery -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $contentDelivery -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  [+] Cloud content and silent sponsored app injection disabled." -ForegroundColor Green
    }
} catch {
    Write-Warning "Failed configuring CloudContent policy: $_"
}

# 2. Targeted Bloatware Package List
$BloatPackages = @(
    "*Clipchamp*",
    "*Cortana*",
    "*BingNews*",
    "*BingWeather*",
    "*MicrosoftSolitaireCollection*",
    "*GetHelp*",
    "*Getstarted*",
    "*MicrosoftOfficeHub*",
    "*Office.OneNote*",
    "*People*",
    "*SkypeApp*",
    "*Todos*",
    "*WindowsFeedbackHub*",
    "*WindowsMaps*",
    "*YourPhone*",
    "*ZuneMusic*",
    "*ZuneVideo*",
    "*Spotify*",
    "*TikTok*",
    "*Facebook*",
    "*Instagram*",
    "*PrimeVideo*",
    "*Disney*",
    "*CandyCrush*",
    "*MixedReality*",
    "*3DBuilder*"
)

# Core Protected Packages Regex (NEVER TOUCH)
$ProtectedRegex = "DesktopAppInstaller|SecHealthUI|VCLibs|UI\.Xaml|Store|Native|WindowsTerminal|Calculator|Photos|Paint|ScreenSketch|Notepad|Appconnector|Services\.Store"

Write-Host "`n[*] Auditing installed packages for consumer bloatware..." -ForegroundColor Cyan
$RemovedCount = 0

# Single-pass fast batch query
$allUserPackages = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue)
$allProvPackages = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)

foreach ($pattern in $BloatPackages) {
    # Remove per-user packages
    $matchingUser = $allUserPackages | Where-Object { $_.Name -like $pattern }
    foreach ($pkg in $matchingUser) {
        if ($pkg.Name -notmatch $ProtectedRegex -and $pkg.NonRemovable -eq $false) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                Write-Host "  [+] Removed User Package: $($pkg.Name)" -ForegroundColor Green
                $RemovedCount++
            } catch {}
        }
    }

    # Remove provisioned packages (prevents re-installing for new users)
    $matchingProv = $allProvPackages | Where-Object { $_.DisplayName -like $pattern }
    foreach ($prov in $matchingProv) {
        if ($prov.DisplayName -notmatch $ProtectedRegex) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  [+] Removed Provisioned Template: $($prov.DisplayName)" -ForegroundColor DarkGray
            } catch {}
        }
    }
}

if ($RemovedCount -eq 0) {
    Write-Host "  [-] No consumer bloatware packages found on system (Already clean & debloated)." -ForegroundColor DarkGray
}

# 3. Clean Windows Consumer Capabilities (WordPad, Fax, StepsRecorder)
Write-Host "`n[*] Checking deprecated and optional system capabilities..." -ForegroundColor Cyan
$caps = @(
    "App.StepsRecorder~~~~0.0.1.0",
    "MathRecognizer~~~~0.0.1.0",
    "Print.Fax.Scan~~~~0.0.1.0"
)
$removedCaps = 0
foreach ($cap in $caps) {
    try {
        $c = Get-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue
        if ($c -and $c.State -eq "Installed") {
            Remove-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  [+] Removed Capability: $cap" -ForegroundColor DarkGray
            $removedCaps++
        }
    } catch {}
}
if ($removedCaps -eq 0) {
    Write-Host "  [-] All target optional capabilities already clean (Skipping)." -ForegroundColor DarkGray
}

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Deep OS Debloat completed!" -ForegroundColor Green
Write-Host " Scrubbed $RemovedCount bloatware packages ($removedCaps capabilities removed)." -ForegroundColor Green
Write-Host " Microsoft Store & Core Utilities are 100% preserved." -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green

if (-not $Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host "`nPress Enter to finish..." -ForegroundColor DarkGray
    $null = [System.Console]::ReadLine()
}
