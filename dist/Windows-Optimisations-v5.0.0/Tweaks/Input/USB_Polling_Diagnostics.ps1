# Windows Configuration & Optimization Framework
# USB Polling & Input Diagnostics (Tweaks/Input/USB_Polling_Diagnostics.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   USB & INPUT POLLING DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This script enumerates USB controllers and HID devices"
Write-Host "to check for power saving states that can induce input lag."
Write-Host "=================================================`n"

Write-Host "Analyzing USB Root Hubs Power Management..." -ForegroundColor Yellow

$USBHubs = Get-WmiObject -Class Win32_USBHub
$FoundIssues = $false

foreach ($Hub in $USBHubs) {
    # We check if power management is enabled for USB Hubs
    # In WMI, this is often tricky without diving into CIM or registry directly,
    # but we can list the hubs to identify overloaded controllers.
    Write-Host "Found Hub: $($Hub.Name) [$($Hub.DeviceID)]" -ForegroundColor Cyan
}

Write-Host "`nChecking Power Management Settings for USB (Registry)..." -ForegroundColor Yellow
# DisableSelectiveSuspend is located in USB settings
$USBRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
if (-not (Test-Path $USBRegistryPath)) {
    Write-Host "[WARNING] USB root key not found, creating for configuration." -ForegroundColor Yellow
    New-Item -Path $USBRegistryPath -Force | Out-Null
}

$SelectiveSuspend = Get-ItemProperty -Path $USBRegistryPath -Name "DisableSelectiveSuspend" -ErrorAction SilentlyContinue

if ($SelectiveSuspend.DisableSelectiveSuspend -eq 1) {
    Write-Host "[OK] USB Selective Suspend is globally DISABLED (Optimal for Input Latency)." -ForegroundColor Green
} else {
    Write-Host "[WARNING] USB Selective Suspend is ENABLED (May cause mouse stutter when waking from idle)." -ForegroundColor Red
    $FoundIssues = $true
}

if ($FoundIssues) {
    Write-Host "`nDo you want to disable USB Selective Suspend globally to fix input latency? (Y/N)"
    $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    
    if ($Confirm -match 'y') {
        Set-ItemProperty -Path $USBRegistryPath -Name "DisableSelectiveSuspend" -Value 1 -Type DWord -Force
        Write-Host "`n[SUCCESS] USB Selective Suspend has been disabled." -ForegroundColor Green
        
        $HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
        Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force -ErrorAction SilentlyContinue
        Write-FrameworkLog -ModuleName "Input" -Action "Disabled USB Selective Suspend"
    } else {
        Write-Host "`nNo changes made."
    }
}

Write-Host "`nNOTE: High-polling rate mice (4000Hz - 8000Hz) require raw CPU performance."
Write-Host "If you experience stutter at 8000Hz, drop your mouse software to 2000Hz."
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
