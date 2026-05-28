[CmdletBinding()]
param (
    [switch]$Force
)

# ==============================================================================
# SCRIPT: Manage Startup Apps
# TARGET SYSTEM: Windows 10 & Windows 11
# DESCRIPTION: Scans and displays all registry and folder-based startup items.
#              Provides a non-destructive disable feature by moving registry items
#              to backup keys (Run-Disabled) and shortcut files to parallel directories.
# SAFETY LEVEL: Safe & Fully Reversible
# ==============================================================================

$Host.UI.RawUI.WindowTitle = "Windows Startup Apps Manager"

# Registry Paths
$HKCU_Run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$HKCU_RunDisabled = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run-Disabled"
$HKLM_Run = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$HKLM_RunDisabled = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run-Disabled"
$HKLM_Wow_Run = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
$HKLM_Wow_RunDisabled = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run-Disabled"

# Folders
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

Ensure-Paths

function Clear-Console {
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "                       WINDOWS STARTUP APPS MANAGER                   " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-StartupItems {
    $items = @()
    $id = 1

    # 1. HKCU Run
    $props = Get-Item -Path $HKCU_Run | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
    foreach ($p in $props) {
        $val = (Get-ItemProperty -Path $HKCU_Run -Name $p).$p
        $items += [PSCustomObject]@{ Id = $id; Type = "Registry (User)"; Name = $p; Value = $val; Path = $HKCU_Run; DisabledPath = $HKCU_RunDisabled; IsDisabled = $false }
        $id++
    }

    # 2. HKLM Run
    $props = Get-Item -Path $HKLM_Run | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
    foreach ($p in $props) {
        $val = (Get-ItemProperty -Path $HKLM_Run -Name $p).$p
        $items += [PSCustomObject]@{ Id = $id; Type = "Registry (System)"; Name = $p; Value = $val; Path = $HKLM_Run; DisabledPath = $HKLM_RunDisabled; IsDisabled = $false }
        $id++
    }

    # 3. HKLM Wow6432Node Run
    $props = Get-Item -Path $HKLM_Wow_Run | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
    foreach ($p in $props) {
        $val = (Get-ItemProperty -Path $HKLM_Wow_Run -Name $p).$p
        $items += [PSCustomObject]@{ Id = $id; Type = "Registry (System-Wow64)"; Name = $p; Value = $val; Path = $HKLM_Wow_Run; DisabledPath = $HKLM_Wow_RunDisabled; IsDisabled = $false }
        $id++
    }

    # 4. User Startup Folder
    if (Test-Path $UserStartupDir) {
        $files = Get-ChildItem -Path $UserStartupDir -Filter "*.lnk"
        foreach ($f in $files) {
            $items += [PSCustomObject]@{ Id = $id; Type = "Folder (User)"; Name = $f.Name; Value = $f.FullName; Path = $UserStartupDir; DisabledPath = $UserStartupDisabledDir; IsDisabled = $false }
            $id++
        }
    }

    # 5. Common Startup Folder
    if (Test-Path $CommonStartupDir) {
        $files = Get-ChildItem -Path $CommonStartupDir -Filter "*.lnk"
        foreach ($f in $files) {
            $items += [PSCustomObject]@{ Id = $id; Type = "Folder (System)"; Name = $f.Name; Value = $f.FullName; Path = $CommonStartupDir; DisabledPath = $CommonStartupDisabledDir; IsDisabled = $false }
            $id++
        }
    }

    return $items
}

function Get-DisabledItems {
    $items = @()
    $id = 1

    # 1. HKCU Run Disabled
    $props = Get-Item -Path $HKCU_RunDisabled | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
    foreach ($p in $props) {
        $val = (Get-ItemProperty -Path $HKCU_RunDisabled -Name $p).$p
        $items += [PSCustomObject]@{ Id = $id; Type = "Registry (User)"; Name = $p; Value = $val; Path = $HKCU_RunDisabled; EnabledPath = $HKCU_Run; IsDisabled = $true }
        $id++
    }

    # 2. HKLM Run Disabled
    $props = Get-Item -Path $HKLM_RunDisabled | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
    foreach ($p in $props) {
        $val = (Get-ItemProperty -Path $HKLM_RunDisabled -Name $p).$p
        $items += [PSCustomObject]@{ Id = $id; Type = "Registry (System)"; Name = $p; Value = $val; Path = $HKLM_RunDisabled; EnabledPath = $HKLM_Run; IsDisabled = $true }
        $id++
    }

    # 3. HKLM Wow6432Node Run Disabled
    $props = Get-Item -Path $HKLM_Wow_RunDisabled | Select-Object -ExpandProperty Property -ErrorAction SilentlyContinue
    foreach ($p in $props) {
        $val = (Get-ItemProperty -Path $HKLM_Wow_RunDisabled -Name $p).$p
        $items += [PSCustomObject]@{ Id = $id; Type = "Registry (System-Wow64)"; Name = $p; Value = $val; Path = $HKLM_Wow_RunDisabled; EnabledPath = $HKLM_Wow_Run; IsDisabled = $true }
        $id++
    }

    # 4. User Startup Folder Disabled
    if (Test-Path $UserStartupDisabledDir) {
        $files = Get-ChildItem -Path $UserStartupDisabledDir -Filter "*.lnk"
        foreach ($f in $files) {
            $items += [PSCustomObject]@{ Id = $id; Type = "Folder (User)"; Name = $f.Name; Value = $f.FullName; Path = $UserStartupDisabledDir; EnabledPath = $UserStartupDir; IsDisabled = $true }
            $id++
        }
    }

    # 5. Common Startup Folder Disabled
    if (Test-Path $CommonStartupDisabledDir) {
        $files = Get-ChildItem -Path $CommonStartupDisabledDir -Filter "*.lnk"
        foreach ($f in $files) {
            $items += [PSCustomObject]@{ Id = $id; Type = "Folder (System)"; Name = $f.Name; Value = $f.FullName; Path = $CommonStartupDisabledDir; EnabledPath = $CommonStartupDir; IsDisabled = $true }
            $id++
        }
    }

    return $items
}

while ($true) {
    Clear-Console
    Write-Host "Choose an action:" -ForegroundColor White
    Write-Host "  1. List Active Startup Apps & Disable Items" -ForegroundColor Green
    Write-Host "  2. List Disabled Startup Apps & Re-enable Items" -ForegroundColor Yellow
    Write-Host "  3. Exit" -ForegroundColor Red
    Write-Host ""
    
    $op = Read-Host "Option (1-3)"

    if ($op -eq "1") {
        while ($true) {
            Clear-Console
            $actives = Get-StartupItems
            Write-Host "=== Active Startup Apps ===" -ForegroundColor Green
            Write-Host ""
            
            if ($actives.Count -eq 0) {
                Write-Host "No active startup applications found!" -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Press Enter to return to main menu..."
                break
            }

            foreach ($item in $actives) {
                Write-Host "  [$($item.Id)] $($item.Name)" -ForegroundColor White
                Write-Host "       Source: $($item.Type)" -ForegroundColor Gray
                Write-Host "       Command: $($item.Value)" -ForegroundColor Gray
                Write-Host ""
            }

            $select = Read-Host "Select number to DISABLE (or 'q' to go back)"
            if ($select -eq "q") { break }

            $match = $actives | Where-Object { $_.Id -eq $select }
            if ($match) {
                try {
                    if ($match.Type -like "Registry*") {
                        # Move Registry value to disabled key
                        Set-ItemProperty -Path $match.DisabledPath -Name $match.Name -Value $match.Value -Force | Out-Null
                        Remove-ItemProperty -Path $match.Path -Name $match.Name -Force | Out-Null
                    } else {
                        # Move shortcut file to disabled folder
                        $targetPath = Join-Path $match.DisabledPath $match.Name
                        Move-Item -Path $match.Value -Destination $targetPath -Force | Out-Null
                    }
                    Write-Host ""
                    Write-Host "[+] Disabled $($match.Name) successfully!" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                } catch {
                    Write-Host ""
                    Write-Host "[!] Error: Failed to disable $($match.Name). Make sure you run this script as Administrator if modifying System startup items." -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Gray
                    Read-Host "Press Enter to continue..."
                }
            } else {
                Write-Host "Invalid selection." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    elseif ($op -eq "2") {
        while ($true) {
            Clear-Console
            $disableds = Get-DisabledItems
            Write-Host "=== Disabled Startup Apps ===" -ForegroundColor Yellow
            Write-Host ""

            if ($disableds.Count -eq 0) {
                Write-Host "No disabled startup applications found!" -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Press Enter to return to main menu..."
                break
            }

            foreach ($item in $disableds) {
                Write-Host "  [$($item.Id)] $($item.Name)" -ForegroundColor White
                Write-Host "       Source: $($item.Type)" -ForegroundColor Gray
                Write-Host "       Command: $($item.Value)" -ForegroundColor Gray
                Write-Host ""
            }

            $select = Read-Host "Select number to RE-ENABLE (or 'q' to go back)"
            if ($select -eq "q") { break }

            $match = $disableds | Where-Object { $_.Id -eq $select }
            if ($match) {
                try {
                    if ($match.Type -like "Registry*") {
                        # Move Registry value back to enabled key
                        Set-ItemProperty -Path $match.EnabledPath -Name $match.Name -Value $match.Value -Force | Out-Null
                        Remove-ItemProperty -Path $match.Path -Name $match.Name -Force | Out-Null
                    } else {
                        # Move shortcut file back to startup folder
                        $targetPath = Join-Path $match.EnabledPath $match.Name
                        Move-Item -Path $match.Value -Destination $targetPath -Force | Out-Null
                    }
                    Write-Host ""
                    Write-Host "[+] Re-enabled $($match.Name) successfully!" -ForegroundColor Green
                    Start-Sleep -Seconds 1
                } catch {
                    Write-Host ""
                    Write-Host "[!] Error: Failed to re-enable $($match.Name). Make sure you run this script as Administrator if modifying System startup items." -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Gray
                    Read-Host "Press Enter to continue..."
                }
            } else {
                Write-Host "Invalid selection." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    elseif ($op -eq "3") {
        Write-Host "Exiting..." -ForegroundColor Cyan
        break
    }
}
