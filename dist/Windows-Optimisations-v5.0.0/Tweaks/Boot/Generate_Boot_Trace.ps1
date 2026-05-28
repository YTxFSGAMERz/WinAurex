# Windows Configuration & Optimization Framework
# Generate Boot Trace (Tweaks/Boot/Generate_Boot_Trace.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

Write-Host "================================================="
Write-Host "   ETW BOOT TRACE GENERATOR" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will configure the Windows Performance Recorder (WPR)"
Write-Host "to capture an Event Tracing for Windows (ETW) log during"
Write-Host "the next system boot. This is the most advanced way to"
Write-Host "diagnose slow boot times and hanging services."
Write-Host "================================================="
Write-Host "1. Arm the system for a Boot Trace (Requires Reboot)"
Write-Host "2. Cancel a pending Boot Trace"
Write-Host "3. Abort"
Write-Host "================================================="
$Choice = Read-Host "Select an option [1-3]"

if ($Choice -notmatch '^[1-2]$') {
    Write-Host "`nAborted by user."
    Exit
}

if (-not (Get-Command "wpr" -ErrorAction SilentlyContinue)) {
    Write-Host "`n[ERROR] Windows Performance Recorder (wpr.exe) is not available." -ForegroundColor Red
    Write-Host "It is usually included with Windows 10/11 natively."
    Exit
}

if ($Choice -eq '1') {
    Write-Host "`nArming WPR for next boot..." -ForegroundColor Yellow
    # Profiles: CPU, DiskIO, GeneralProfile
    $WprArgs = "-boottrace -addboot CPU -addboot DiskIO -filemode"
    Invoke-Expression "wpr $WprArgs"
    
    Write-Host "`n[SUCCESS] The system is armed." -ForegroundColor Green
    Write-Host "Please RESTART YOUR COMPUTER."
    Write-Host "After logging in, WPR will finish saving the trace file"
    Write-Host "to your Documents\WPR Files folder. You can analyze it"
    Write-Host "using Windows Performance Analyzer (WPA)." -ForegroundColor Cyan
} else {
    Write-Host "`nCancelling pending boot trace..." -ForegroundColor Yellow
    Invoke-Expression "wpr -cancel"
    Write-Host "`n[SUCCESS] Any pending boot trace has been cancelled." -ForegroundColor Green
}

Start-Sleep -Seconds 4
