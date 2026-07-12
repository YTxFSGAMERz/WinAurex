# Windows Configuration & Optimization Framework
# Create Desktop / Start Menu Shortcut

param(
    [switch]$Force,

    [ValidateSet("Desktop", "StartMenu")]
    [string]$Destination = "Desktop",

    [Parameter(Mandatory=$true)]
    [string]$TargetScript
)

$WshShell = New-Object -ComObject WScript.Shell

if ($Destination -eq "Desktop") {
    $ShortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Windows Optimization Dashboard.lnk"
} else {
    $StartMenuPath = Join-Path ([Environment]::GetFolderPath("Programs")) "Windows Optimization Framework"
    if (-not (Test-Path $StartMenuPath)) { New-Item -ItemType Directory -Path $StartMenuPath | Out-Null }
    $ShortcutPath = Join-Path $StartMenuPath "Windows Optimization Dashboard.lnk"
}

# We want the shortcut to launch PowerShell, bypassing execution policy, running hidden, and pointing to our Dashboard script.
$PowerShellPath = (Get-Command powershell.exe).Source
$Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$TargetScript`""

$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $PowerShellPath
$Shortcut.Arguments = $Arguments
$Shortcut.WorkingDirectory = (Split-Path $TargetScript -Parent)
$Shortcut.IconLocation = "$PowerShellPath,0"
$Shortcut.Description = "Launch the Windows Optimization Framework Dashboard"

# Save the shortcut
$Shortcut.Save()

# Configure the shortcut to "Run as Administrator" natively by flipping byte 21
# This ensures a native UAC prompt happens when the user double clicks the shortcut!
try {
    $Bytes = [System.IO.File]::ReadAllBytes($ShortcutPath)
    $Bytes[21] = $Bytes[21] -bor 0x20
    [System.IO.File]::WriteAllBytes($ShortcutPath, $Bytes)
} catch {
    Write-Warning "Could not flag shortcut for elevation. The dashboard will request it automatically."
}
