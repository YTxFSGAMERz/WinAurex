[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Repair Network (Tools/Repair/Repair_Network.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   NETWORK REPAIR TOOL" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will flush DNS, reset Winsock, release/renew IP,"
Write-Host "and reset the TCP/IP stack to fix 'No Internet' issues."
Write-Host "WARNING: You will briefly lose connection."
Write-Host "Press 'Y' to begin or any other key to abort..."
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Repair" -Action "Aborted Network Repair"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Repair" -Action "Started Network Repair"

Write-Host "`n[1/4] Flushing DNS Cache..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null

Write-Host "[2/4] Releasing and Renewing IP Address..." -ForegroundColor Yellow
ipconfig /release | Out-Null
ipconfig /renew | Out-Null

Write-Host "[3/4] Resetting Winsock Catalog..." -ForegroundColor Yellow
netsh winsock reset | Out-Null

Write-Host "[4/4] Resetting TCP/IP Stack..." -ForegroundColor Yellow
netsh int ip reset | Out-Null

Write-FrameworkLog -ModuleName "Repair" -Action "Completed Network Repair"

Write-Host "`n================================================="
Write-Host "[SUCCESS] Network stack has been repaired." -ForegroundColor Green
Write-Host "Please REBOOT YOUR COMPUTER to complete the Winsock reset."
if (-not $Force) {
    if (-not $Force) {
    Write-Host "Press any key to exit..."
    if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
}
}

