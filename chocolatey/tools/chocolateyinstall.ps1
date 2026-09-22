$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "       Installing WinAurex CLI via Chocolatey    " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$launcher = Join-Path $toolsDir "winaurex.cmd"
if (Test-Path $launcher) {
    Write-Host "[WinAurex] Installed successfully to $toolsDir" -ForegroundColor Green
    Write-Host "[WinAurex] Command 'winaurex' is now ready in your terminal." -ForegroundColor Green
} else {
    Write-Error "[WinAurex Error] Launcher file $launcher missing!"
}
