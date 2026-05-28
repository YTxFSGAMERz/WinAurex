# Windows Configuration & Optimization Framework
# Clean Framework Logs (Tools/System-Info/Clean_Framework_Logs.ps1)

$LogsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Logs"

Write-Host "================================================="
Write-Host "   FRAMEWORK LOG CLEANUP UTILITY" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "This will permanently delete all framework operation logs in:"
Write-Host "$LogsDir" -ForegroundColor DarkGray
Write-Host "Press 'Y' to confirm deletion or any other key to cancel..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
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

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
