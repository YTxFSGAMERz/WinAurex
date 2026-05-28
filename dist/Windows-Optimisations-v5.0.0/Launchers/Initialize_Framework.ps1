# Windows Configuration & Optimization Framework
# First-Run Setup & Initialization

$RootPath = Join-Path $PSScriptRoot ".."
$ConfigPath = Join-Path $RootPath "Core\Config\FrameworkConfig.json"
$DashboardScript = Join-Path $RootPath "Launch_Dashboard.ps1"

Write-Host "Initializing Framework Environment..." -ForegroundColor Cyan

# 1. Load Configuration
if (-not (Test-Path $ConfigPath)) {
    Write-Warning "FrameworkConfig.json is missing! Creating default configuration."
    $DefaultConfig = @{
        IsInitialized = $false
        Version = "5.0.0"
        LoggingEnabled = $true
        LastRun = ""
    }
    $DefaultConfig | ConvertTo-Json | Out-File $ConfigPath -Encoding UTF8
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json

# 2. First-Run Logic
if ($Config.IsInitialized -eq $false) {
    Write-Host "`n============================================================"
    Write-Host "   WELCOME TO WINDOWS OPTIMIZATION FRAMEWORK v5.0!" -ForegroundColor Green
    Write-Host "============================================================"
    Write-Host "This appears to be your first time running the framework."
    
    # 2a. Ask to create a Desktop Shortcut
    $CreateShortcut = Read-Host "`nWould you like to create a Desktop Shortcut for easy access? (Y/N)"
    if ($CreateShortcut -match 'y') {
        $ShortcutScript = Join-Path $PSScriptRoot "Create_Shortcut.ps1"
        if (Test-Path $ShortcutScript) {
            & $ShortcutScript -Destination "Desktop" -TargetScript $DashboardScript
            Write-Host "Desktop shortcut created successfully." -ForegroundColor Green
        }
    }

    # 2b. Ask to create an initial System Restore Point
    $CreateRestore = Read-Host "`nWould you like to create a Windows System Restore Point now? [Recommended] (Y/N)"
    if ($CreateRestore -match 'y') {
        Write-Host "Creating Restore Point (This may take a minute)..." -ForegroundColor Yellow
        try {
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Pre-Optimization Snapshot" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-Host "System Restore Point created successfully!" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to create System Restore point. Ensure System Protection is enabled."
        }
    }

    # Mark as initialized
    $Config.IsInitialized = $true
}

# 3. Update Last Run
$Config.LastRun = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Config | ConvertTo-Json | Out-File $ConfigPath -Encoding UTF8

Write-Host "`nInitialization complete. Launching Dashboard..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# 4. Launch the Dashboard
if (Test-Path $DashboardScript) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DashboardScript`""
} else {
    Write-Error "Could not find Launch_Dashboard.ps1 at $DashboardScript"
    Read-Host "Press any key to exit..."
}
