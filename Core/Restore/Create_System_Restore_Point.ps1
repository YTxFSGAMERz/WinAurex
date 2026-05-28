# Windows Configuration & Optimization Framework
# Create System Restore Point (Core/Restore/Create_System_Restore_Point.ps1)

# Requires Run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

# Import Framework Logging
$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Initiating System Restore Point Creation"

try {
    # Check if system restore is enabled on OS drive
    $OSDrive = $env:SystemDrive + "\"
    Enable-ComputerRestore -Drive $OSDrive -ErrorAction SilentlyContinue

    $Description = "Windows-Optimisations Framework Baseline - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    
    Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Successfully created restore point: $Description"
    Write-Host "`n[SUCCESS] Baseline snapshot created perfectly. It is now safe to apply optimizations." -ForegroundColor Green
}
catch {
    Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Failed to create restore point" -NewValue $_.Exception.Message -Level ERROR
    Write-Host "`n[ERROR] Failed to create restore point. Ensure System Protection is enabled in Windows." -ForegroundColor Red
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
