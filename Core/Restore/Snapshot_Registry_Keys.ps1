# Windows Configuration & Optimization Framework
# Snapshot Registry Keys (Core/Restore/Snapshot_Registry_Keys.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Exit
}

$HelpersDir = Join-Path -Path $PSScriptRoot -ChildPath "..\Helpers"
Import-Module (Join-Path -Path $HelpersDir -ChildPath "Logging.psm1") -Force

$BackupDir = Join-Path -Path $PSScriptRoot -ChildPath "Backups"
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null }

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$SnapshotFolder = Join-Path -Path $BackupDir -ChildPath $Timestamp
New-Item -ItemType Directory -Force -Path $SnapshotFolder | Out-Null

$KeysToBackup = @{
    "Explorer" = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer"
    "Desktop" = "HKCU\Control Panel\Desktop"
    "SystemProfile" = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    "DWM" = "HKCU\Software\Microsoft\Windows\DWM"
    "Services" = "HKLM\SYSTEM\CurrentControlSet\Services"
}

Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Started Registry Snapshotting" -NewValue $SnapshotFolder

foreach ($Key in $KeysToBackup.GetEnumerator()) {
    $OutputFile = Join-Path -Path $SnapshotFolder -ChildPath "$($Key.Name).reg"
    $RegPath = $Key.Value
    
    # Run reg export silently
    $process = Start-Process -FilePath "reg.exe" -ArgumentList "export `"$RegPath`" `"$OutputFile`" /y" -Wait -PassThru -WindowStyle Hidden
    
    if ($process.ExitCode -eq 0) {
        Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Exported Registry Key" -NewValue $Key.Name
    } else {
        Write-FrameworkLog -ModuleName "RestoreEngine" -Action "Failed to export Registry Key" -NewValue $Key.Name -Level WARNING
    }
}

Write-Host "`n[SUCCESS] Registry snapshots saved to: $SnapshotFolder" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
