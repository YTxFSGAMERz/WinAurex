# Windows Configuration & Optimization Framework
# Enable Ultimate Performance Plan (Tweaks/Power/Enable_Ultimate_Performance_Plan.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Core\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "Power" -Action "Initiating Ultimate Performance Plan Deployment"

# 1. Unlock Ultimate Performance Plan
$DuplicateOutput = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
$Success = ($LASTEXITCODE -eq 0)

if ($Success -and $DuplicateOutput -match "([a-fA-F0-9\-]{36})") {
    $PlanGUID = $matches[1]
    
    # 2. Set as Active
    powercfg /setactive $PlanGUID
    
    Write-FrameworkLog -ModuleName "Power" -Action "Enabled and Activated Ultimate Performance Plan" -OldValue "Unknown" -NewValue $PlanGUID
    Write-Host "`n[SUCCESS] Ultimate Performance Plan unlocked and set as active!" -ForegroundColor Green
    Write-Host "This ensures zero CPU throttling and maximum hardware responsiveness." -ForegroundColor Yellow
} else {
    Write-FrameworkLog -ModuleName "Power" -Action "Failed to unlock Ultimate Performance Plan" -Level ERROR
    Write-Host "`n[ERROR] Failed to duplicate the Ultimate Performance scheme." -ForegroundColor Red
}



$null = Read-Host "Press Enter to exit..."
