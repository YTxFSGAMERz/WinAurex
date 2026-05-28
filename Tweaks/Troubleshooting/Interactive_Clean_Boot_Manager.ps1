[CmdletBinding()]
param (
    [switch]$Force
)

# ==============================================================================
# SCRIPT: Clean Boot & Troubleshooting Manager
# TARGET SYSTEM: Windows 10 & Windows 11
# DESCRIPTION: Diagnoses and isolates background app and service conflicts.
#              Saves the original state of all running third-party (non-Microsoft)
#              services and startup apps to a JSON file (boot_profile.json),
#              then safely disables them for troubleshooting.
#              A simple restore function returns the system to its exact original state.
# SAFETY LEVEL: Advanced, Fully Reversible and Safe
# ==============================================================================

$Host.UI.RawUI.WindowTitle = "Windows Clean Boot Manager"

$ProfileFile = Join-Path $PSScriptRoot "boot_profile.json"

# Startup Registry & Folders Paths (For Startup App backup)
$HKCU_Run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$HKCU_RunDisabled = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run-Disabled"
$HKLM_Run = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$HKLM_RunDisabled = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run-Disabled"
$HKLM_Wow_Run = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
$HKLM_Wow_RunDisabled = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run-Disabled"
$UserStartupDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$UserStartupDisabledDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup-Disabled"
$CommonStartupDir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
$CommonStartupDisabledDir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup-Disabled"

# Ensure backup paths exist
function Ensure-Paths {
    if (-not (Test-Path $HKCU_RunDisabled)) { New-Item -Path $HKCU_RunDisabled -Force | Out-Null }
    if (-not (Test-Path $HKLM_RunDisabled)) { New-Item -Path $HKLM_RunDisabled -Force | Out-Null }
    if (-not (Test-Path $HKLM_Wow_RunDisabled)) { New-Item -Path $HKLM_Wow_RunDisabled -Force | Out-Null }
    if (-not (Test-Path $UserStartupDisabledDir)) { New-Item -Path $UserStartupDisabledDir -ItemType Directory -Force | Out-Null }
    if (-not (Test-Path $CommonStartupDisabledDir)) { New-Item -Path $CommonStartupDisabledDir -ItemType Directory -Force | Out-Null }
}

function Clear-Console {
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "                    WINDOWS CLEAN BOOT & TROUBLESHOOT MANAGER         " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Check Admin Rights
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Clear-Console
    Write-Host "[!] ERROR: This script must be run as an Administrator." -ForegroundColor Red
    Write-Host "    Right-click your PowerShell window and select 'Run as Administrator'." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit
}

while ($true) {
    Clear-Console
    $hasBackup = Test-Path $ProfileFile
    
    if ($hasBackup) {
        Write-Host "[!] SYSTEM STATUS: Currently in a Clean Boot / Troubleshoot state." -ForegroundColor Yellow
        Write-Host "    Original system boot configuration is saved in: boot_profile.json" -ForegroundColor Gray
    } else {
        Write-Host "[*] SYSTEM STATUS: Normal Boot (All third-party items active)" -ForegroundColor Green
    }
    Write-Host ""

    Write-Host "Choose an option:" -ForegroundColor White
    Write-Host "  1. Apply Clean Boot (Saves states, disables 3rd-party services & startup apps)" -ForegroundColor Green
    Write-Host "  2. Restore Normal Boot (Re-enables all services & startup apps to original state)" -ForegroundColor Yellow
    Write-Host "  3. Exit" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Option (1-3)"

    switch ($choice) {
        "1" {
            if ($hasBackup) {
                Write-Host ""
                Write-Host "[!] Already in a clean boot state! Please restore normal boot first." -ForegroundColor Red
                Start-Sleep -Seconds 2
                continue
            }

            Ensure-Paths
            Clear-Console
            Write-Host "Starting Clean Boot analysis..." -ForegroundColor Cyan
            Write-Host ""

            # 1. Fetch Third-Party Services
            Write-Host "[*] Identifying third-party services..." -ForegroundColor Gray
            $services = Get-CimInstance Win32_Service | Where-Object { 
                $_.PathName -notlike "*Windows*" -and 
                $_.PathName -notlike "*Microsoft*" -and 
                $_.StartMode -ne "Disabled" 
            }

            Write-Host "    Found $($services.Count) active third-party services." -ForegroundColor Gray

            # 2. Fetch Active Startup Apps
            Write-Host "[*] Identifying active startup items..." -ForegroundColor Gray
            $startupApps = @()
            
            # HKCU Run
            $props = Get-Item -Path $HKCU_Run | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
            foreach ($p in $props) {
                $val = (Get-ItemProperty -Path $HKCU_Run -Name $p).$p
                $startupApps += @{ Name = $p; Value = $val; Source = "HKCU_Run" }
            }
            # HKLM Run
            $props = Get-Item -Path $HKLM_Run | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
            foreach ($p in $props) {
                $val = (Get-ItemProperty -Path $HKLM_Run -Name $p).$p
                $startupApps += @{ Name = $p; Value = $val; Source = "HKLM_Run" }
            }
            # HKLM Wow
            $props = Get-Item -Path $HKLM_Wow_Run | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
            foreach ($p in $props) {
                $val = (Get-ItemProperty -Path $HKLM_Wow_Run -Name $p).$p
                $startupApps += @{ Name = $p; Value = $val; Source = "HKLM_Wow_Run" }
            }
            # Folders
            if (Test-Path $UserStartupDir) {
                Get-ChildItem -Path $UserStartupDir -Filter "*.lnk" | ForEach-Object {
                    $startupApps += @{ Name = $_.Name; Value = $_.FullName; Source = "UserStartupFolder" }
                }
            }
            if (Test-Path $CommonStartupDir) {
                Get-ChildItem -Path $CommonStartupDir -Filter "*.lnk" | ForEach-Object {
                    $startupApps += @{ Name = $_.Name; Value = $_.FullName; Source = "CommonStartupFolder" }
                }
            }

            Write-Host "    Found $($startupApps.Count) active startup items." -ForegroundColor Gray
            Write-Host ""

            $confirm = Read-Host "Proceed with disabling these items for troubleshooting? (y/n)"
            if ($confirm -ne "y") { continue }

            # Prepare Backup Payload
            $backupData = @{
                Services = @()
                StartupApps = $startupApps
            }

            foreach ($srv in $services) {
                $backupData.Services += @{
                    Name = $srv.Name
                    DisplayName = $srv.DisplayName
                    StartMode = $srv.StartMode
                }
            }

            # Write Backup File
            try {
                $backupData | ConvertTo-Json -Depth 5 | Out-File -FilePath $ProfileFile -Force
                Write-Host ""
                Write-Host "[+] Original system boot profile successfully backed up to boot_profile.json!" -ForegroundColor Green
            } catch {
                Write-Host "[!] Error writing boot backup profile. Aborting Clean Boot." -ForegroundColor Red
                Start-Sleep -Seconds 3
                continue
            }

            # 3. Apply Clean Boot (Disable Items)
            Write-Host ""
            Write-Host "[*] Disabling third-party services..." -ForegroundColor Yellow
            foreach ($srv in $services) {
                try {
                    Set-Service -Name $srv.Name -StartupType Disabled -ErrorAction Stop
                    Stop-Service -Name $srv.Name -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Host "    [!] Could not disable service: $($srv.Name)" -ForegroundColor DarkGray
                }
            }

            Write-Host "[*] Disabling startup applications..." -ForegroundColor Yellow
            foreach ($app in $startupApps) {
                try {
                    switch ($app.Source) {
                        "HKCU_Run" {
                            Set-ItemProperty -Path $HKCU_RunDisabled -Name $app.Name -Value $app.Value -Force | Out-Null
                            Remove-ItemProperty -Path $HKCU_Run -Name $app.Name -Force | Out-Null
                        }
                        "HKLM_Run" {
                            Set-ItemProperty -Path $HKLM_RunDisabled -Name $app.Name -Value $app.Value -Force | Out-Null
                            Remove-ItemProperty -Path $HKLM_Run -Name $app.Name -Force | Out-Null
                        }
                        "HKLM_Wow_Run" {
                            Set-ItemProperty -Path $HKLM_Wow_RunDisabled -Name $app.Name -Value $app.Value -Force | Out-Null
                            Remove-ItemProperty -Path $HKLM_Wow_Run -Name $app.Name -Force | Out-Null
                        }
                        "UserStartupFolder" {
                            Move-Item -Path $app.Value -Destination (Join-Path $UserStartupDisabledDir $app.Name) -Force | Out-Null
                        }
                        "CommonStartupFolder" {
                            Move-Item -Path $app.Value -Destination (Join-Path $CommonStartupDisabledDir $app.Name) -Force | Out-Null
                        }
                    }
                } catch {
                    Write-Host "    [!] Could not disable startup app: $($app.Name)" -ForegroundColor DarkGray
                }
            }

            Write-Host ""
            Write-Host "======================================================================" -ForegroundColor Green
            Write-Host "                    CLEAN BOOT CONFIGURATION APPLIED                  " -ForegroundColor Green
            Write-Host "======================================================================" -ForegroundColor Green
            Write-Host " [!] Success! Third-party services and startup apps have been disabled." -ForegroundColor Green
            Write-Host " [!] IMPORTANT: Please RESTART your computer now to isolate issues." -ForegroundColor Yellow
            Write-Host " ======================================================================" -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter to return to main menu..."
        }

        "2" {
            if (-not $hasBackup) {
                Write-Host ""
                Write-Host "[!] No backup file found. Your system is already in Normal Boot state." -ForegroundColor Red
                Start-Sleep -Seconds 2
                continue
            }

            Clear-Console
            Write-Host "Restoring Normal Boot configuration..." -ForegroundColor Cyan
            Write-Host ""

            # Load Backup File
            try {
                $backupData = Get-Content -Raw -Path $ProfileFile | ConvertFrom-Json
            } catch {
                Write-Host "[!] Error loading boot_profile.json. Backup file might be corrupt." -ForegroundColor Red
                Read-Host "Press Enter to return..."
                continue
            }

            # 1. Restore Services
            Write-Host "[*] Restoring original third-party services states..." -ForegroundColor Yellow
            foreach ($srv in $backupData.Services) {
                # Map StartMode to ServiceStartMode parameter string
                # Win32 StartMode values: Boot, System, Auto, Manual, Disabled
                # Set-Service StartupType values: Automatic, Manual, Disabled, Boot, System
                $mode = $srv.StartMode
                if ($mode -eq "Auto") { $mode = "Automatic" }
                
                try {
                    Set-Service -Name $srv.Name -StartupType $mode -ErrorAction Stop
                } catch {
                    Write-Host "    [!] Could not restore service: $($srv.Name) to $mode" -ForegroundColor DarkGray
                }
            }

            # 2. Restore Startup Apps
            Write-Host "[*] Restoring startup applications..." -ForegroundColor Yellow
            foreach ($app in $backupData.StartupApps) {
                try {
                    switch ($app.Source) {
                        "HKCU_Run" {
                            Set-ItemProperty -Path $HKCU_Run -Name $app.Name -Value $app.Value -Force | Out-Null
                            Remove-ItemProperty -Path $HKCU_RunDisabled -Name $app.Name -Force | Out-Null
                        }
                        "HKLM_Run" {
                            Set-ItemProperty -Path $HKLM_Run -Name $app.Name -Value $app.Value -Force | Out-Null
                            Remove-ItemProperty -Path $HKLM_RunDisabled -Name $app.Name -Force | Out-Null
                        }
                        "HKLM_Wow_Run" {
                            Set-ItemProperty -Path $HKLM_Wow_Run -Name $app.Name -Value $app.Value -Force | Out-Null
                            Remove-ItemProperty -Path $HKLM_Wow_RunDisabled -Name $app.Name -Force | Out-Null
                        }
                        "UserStartupFolder" {
                            $src = Join-Path $UserStartupDisabledDir $app.Name
                            Move-Item -Path $src -Destination (Join-Path $UserStartupDir $app.Name) -Force | Out-Null
                        }
                        "CommonStartupFolder" {
                            $src = Join-Path $CommonStartupDisabledDir $app.Name
                            Move-Item -Path $src -Destination (Join-Path $CommonStartupDir $app.Name) -Force | Out-Null
                        }
                    }
                } catch {
                    Write-Host "    [!] Could not restore startup app: $($app.Name)" -ForegroundColor DarkGray
                }
            }

            # Delete Backup File
            Remove-Item -Path $ProfileFile -Force | Out-Null

            Write-Host ""
            Write-Host "======================================================================" -ForegroundColor Green
            Write-Host "                    NORMAL BOOT CONFIGURATION RESTORED                 " -ForegroundColor Green
            Write-Host "======================================================================" -ForegroundColor Green
            Write-Host " [+] Success! Your services and startup apps have been restored." -ForegroundColor Green
            Write-Host " [+] Please RESTART your computer to complete the normal boot restoration." -ForegroundColor Yellow
            Write-Host " ======================================================================" -ForegroundColor Green
            Write-Host ""
            Read-Host "Press Enter to return to main menu..."
        }

        "3" {
            Write-Host "Exiting..." -ForegroundColor Cyan
            break
        }
    }
}
