[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Clean Framework Logs (Tools/System-Info/Clean_Framework_Logs.ps1)

$LogsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Logs"

Write-Host "================================================="
Write-Host "   FRAMEWORK LOG CLEANUP UTILITY" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will permanently delete all framework operation logs in:"
Write-Host "$LogsDir" -ForegroundColor DarkGray

if ($Force -or [Console]::IsInputRedirected) {
    $Confirm = 'y'
} else {
    Write-Host "Press 'Y' to confirm deletion or any other key to cancel..."
    $Confirm = Read-Host
}

if ($Confirm -notmatch '^[yY]') {
    Write-Host "`nOperation cancelled."
    Exit
}

if (Test-Path $LogsDir) {
    $LogFiles = Get-ChildItem -Path $LogsDir -Filter "*.log"
    $Count = $LogFiles.Count
    
    if ($Count -gt 0) {
        Remove-Item -Path "$LogsDir\*.log" -Force
        Write-Host "`n[SUCCESS] Deleted $Count log files." -ForegroundColor Green
    } else {
        Write-Host "`n[INFO] No log files found to delete." -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[INFO] Logs directory does not exist yet." -ForegroundColor Yellow
}

if (-not $Force -and -not [Console]::IsInputRedirected) {
    Read-Host "Press Enter to exit..."
}
