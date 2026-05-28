# Windows Configuration & Optimization Framework
# Reset Network Stack (Tweaks/Network-Diagnostics/Reset_Network_Stack.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   RESET NETWORK STACK" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will completely reset the Windows TCP/IP stack,"
Write-Host "flush DNS, and reset Winsock. This is highly effective"
Write-Host "for fixing random lag spikes or connectivity drops."
Write-Host "WARNING: A reboot will be required after this completes."
Write-Host "Press 'Y' to confirm or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "Network" -Action "Aborted Network Stack Reset"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "Network" -Action "Initiating Full Network Stack Reset" -Level WARNING

Write-Host "`n[1/3] Flushing DNS Cache..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null

Write-Host "[2/3] Resetting Winsock Catalog..." -ForegroundColor Cyan
netsh winsock reset | Out-Null

Write-Host "[3/3] Resetting TCP/IP Stack..." -ForegroundColor Cyan
netsh int ip reset | Out-Null

Write-FrameworkLog -ModuleName "Network" -Action "Completed Network Stack Reset"

Write-Host "`n[SUCCESS] Network stack has been successfully reset." -ForegroundColor Green
Write-Host "Please RESTART YOUR COMPUTER to finish the process." -ForegroundColor Yellow
Start-Sleep -Seconds 2
