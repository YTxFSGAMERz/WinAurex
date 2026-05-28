# Windows Configuration & Optimization Framework
# Rollback Last Changes (Core/Restore/Rollback_Last_Changes.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

$BackupDir = Join-Path -Path $PSScriptRoot -ChildPath "Backups"
if (-not (Test-Path $BackupDir)) { 
    Write-Host "[ERROR] No Backups directory found. Cannot rollback." -ForegroundColor Red
    Exit 
}

$LatestSnapshot = Get-ChildItem -Path $BackupDir -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1

if (-not $LatestSnapshot) {
    Write-Host "[ERROR] No registry snapshots found in Backups directory." -ForegroundColor Red
    Exit
}

Write-Host "================================================="
Write-Host "   WARNING: ROLLBACK REGISTRY CHANGES" -ForegroundColor Yellow
Write-Host "================================================="
Write-Host "Found snapshot: $($LatestSnapshot.Name)"
Write-Host "This will merge all .reg files from this snapshot back into the registry."
Write-Host "Press 'Y' to continue or any other key to abort..."
$Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

if ($Confirm -notmatch 'y') {
    Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Aborted Registry Rollback"
    Write-Host "`nAborted by user."
    Exit
}

Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Initiated Registry Rollback" -OldValue "Current" -NewValue $LatestSnapshot.Name -Level WARNING

$RegFiles = Get-ChildItem -Path $LatestSnapshot.FullName -Filter "*.reg"
foreach ($File in $RegFiles) {
    $process = Start-Process -FilePath "reg.exe" -ArgumentList "import `"$($File.FullName)`"" -Wait -PassThru -WindowStyle Hidden
    if ($process.ExitCode -eq 0) {
        Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Restored Registry Key" -NewValue $File.Name
    } else {
        Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Failed to restore Registry Key" -NewValue $File.Name -Level ERROR
    }
}

Write-Host "`n[SUCCESS] Rollback completed from snapshot: $($LatestSnapshot.Name)" -ForegroundColor Green
Write-Host "A restart is required to fully apply changes." -ForegroundColor Yellow
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
