[CmdletBinding()]
param (
    [switch]$Force
)

# Windows Configuration & Optimization Framework
# Check TRIM Status (Tweaks/Storage-Advanced/Check_TRIM_Status.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-Host "================================================="
Write-Host "   SSD / NVME TRIM DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "TRIM is essential for maintaining SSD performance and lifespan."
Write-Host "This script will check if Windows is sending TRIM commands."
Write-Host "=================================================`n"

$TrimStatus = fsutil behavior query DisableDeleteNotify

# Parse NTFS status
if ($TrimStatus -match "NTFS DisableDeleteNotify = 0") {
    Write-Host "[NTFS] TRIM is ENABLED (Optimal)" -ForegroundColor Green
} elseif ($TrimStatus -match "NTFS DisableDeleteNotify = 1") {
    Write-Host "[NTFS] TRIM is DISABLED (Bad for SSDs)" -ForegroundColor Red
} else {
    Write-Host "[NTFS] TRIM status unknown" -ForegroundColor Yellow
}

# Parse ReFS status
if ($TrimStatus -match "ReFS DisableDeleteNotify = 0") {
    Write-Host "[ReFS] TRIM is ENABLED (Optimal)" -ForegroundColor Green
} elseif ($TrimStatus -match "ReFS DisableDeleteNotify = 1") {
    Write-Host "[ReFS] TRIM is DISABLED" -ForegroundColor Red
}

Write-Host "`nDo you want to force-enable TRIM for all file systems? (Y/N)"
if (-not $Force) { $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character } else { $Confirm = 'y' }

if ($Confirm -match 'y') {
    Write-Host "`nEnabling TRIM..." -ForegroundColor Yellow
    fsutil behavior set DisableDeleteNotify 0 | Out-Null
    Write-FrameworkLog -ModuleName "Storage" -Action "Enabled SSD TRIM"
    Write-Host "[SUCCESS] TRIM is now fully enabled." -ForegroundColor Green
} else {
    Write-Host "`nNo changes made."
}



$null = Read-Host "Press Enter to exit..."

