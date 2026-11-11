[CmdletBinding()]
param (
    [switch]$Force
)

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
    Write-Host "Creating System Restore point (timeout: 20s)..." -ForegroundColor Cyan
    $OSDrive = $env:SystemDrive + "\"
    $Description = "WinAurex Framework Baseline - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    $srJob = Start-Job -ScriptBlock {
        param($drive, $desc)
        try {
            Enable-ComputerRestore -Drive $drive -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            return "SUCCESS"
        } catch {
            return $_.Exception.Message
        }
    } -ArgumentList $OSDrive, $Description

    $completed = Wait-Job $srJob -Timeout 20
    if ($completed) {
        $result = Receive-Job $srJob
        Remove-Job $srJob -Force -ErrorAction SilentlyContinue
        if ($result -eq "SUCCESS") {
            Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Successfully created restore point: $Description"
            Write-Host "`n[SUCCESS] Baseline snapshot created perfectly. It is now safe to apply optimizations." -ForegroundColor Green
        } else {
            Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Failed to create restore point" -NewValue $result -Level ERROR
            Write-Host "`n[ERROR] Failed to create restore point: $result" -ForegroundColor Red
        }
    } else {
        Stop-Job $srJob -Force -ErrorAction SilentlyContinue
        Remove-Job $srJob -Force -ErrorAction SilentlyContinue
        Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Restore point creation timed out" -Level WARN
        Write-Host "`n[WARNING] Restore point creation timed out (VSS busy or locked). Transactional rollback engine remains active." -ForegroundColor Yellow
    }
}
catch {
    Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Failed to create restore point" -NewValue $_.Exception.Message -Level ERROR
    Write-Host "`n[ERROR] Failed to create restore point. Ensure System Protection is enabled in Windows." -ForegroundColor Red
}

if (-not $Force -and -not [Console]::IsInputRedirected) {
    Read-Host "Press Enter to exit..."
}
