# ==============================================================================
# SCRIPT: Manage Background Apps
# TARGET SYSTEM: Windows 10 & Windows 11
# DESCRIPTION: Manages Windows background applications behavior. 
#              Provides global disabling/enabling of background app activity
#              as well as granular control for individual Microsoft Store/UWP apps.
# SAFETY LEVEL: Safe & Fully Reversible
# ==============================================================================

$Host.UI.RawUI.WindowTitle = "Windows Background Apps Manager"

$GlobalReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
$ConsentReg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\backgroundTasks"

# Ensure global key exists
if (-not (Test-Path $GlobalReg)) {
    New-Item -Path $GlobalReg -Force | Out-Null
}
# Ensure consent key exists
if (-not (Test-Path $ConsentReg)) {
    New-Item -Path $ConsentReg -Force | Out-Null
}

function Clear-Console {
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "                      WINDOWS BACKGROUND APPS MANAGER                 " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Check-GlobalStatus {
    $val = Get-ItemProperty -Path $GlobalReg -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
    if ($val -and $val.GlobalUserDisabled -eq 1) {
        return "DISABLED (All background apps blocked)"
    } else {
        return "ENABLED (Background apps permitted globally)"
    }
}

while ($true) {
    Clear-Console
    $globalStatus = Check-GlobalStatus
    Write-Host "[*] Current Global Background Status: $globalStatus" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Choose an option:" -ForegroundColor White
    Write-Host "  1. Turn OFF Background Activity Globally (Recommended for max performance)" -ForegroundColor Green
    Write-Host "  2. Turn ON Background Activity Globally (Windows Default)" -ForegroundColor Gray
    Write-Host "  3. Manage Individual App Background Permissions" -ForegroundColor White
    Write-Host "  4. Exit" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Option (1-4)"

    switch ($choice) {
        "1" {
            try {
                Set-ItemProperty -Path $GlobalReg -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force | Out-Null
                Write-Host ""
                Write-Host "[+] All background applications have been disabled globally!" -ForegroundColor Green
                Write-Host "    Note: Individual settings will be overridden by this global block." -ForegroundColor Gray
            } catch {
                Write-Host "[!] Error: Failed to update global registry settings." -ForegroundColor Red
            }
            Start-Sleep -Seconds 2
        }
        
        "2" {
            try {
                # Set to 0 or remove
                Remove-ItemProperty -Path $GlobalReg -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
                Write-Host ""
                Write-Host "[+] Background applications re-enabled globally!" -ForegroundColor Green
                Write-Host "    Note: Individual app permissions will now be respected." -ForegroundColor Gray
            } catch {
                Write-Host "[!] Error: Failed to update global registry settings." -ForegroundColor Red
            }
            Start-Sleep -Seconds 2
        }

        "3" {
            while ($true) {
                Clear-Console
                Write-Host "Scanning installed Windows Store/UWP packages..." -ForegroundColor Gray
                
                # Fetch packages
                $packages = Get-AppxPackage -User ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) | 
                            Select-Object Name, PackageFamilyName -Unique | 
                            Sort-Object Name
                
                Write-Host "=== Individual App Background Permissions ===" -ForegroundColor Cyan
                Write-Host "    (Note: Denying background permissions keeps the app from running when closed)" -ForegroundColor Gray
                Write-Host ""

                $index = 1
                $appList = @()
                foreach ($pkg in $packages) {
                    # Skip system-critical packages if they are too basic
                    if ($pkg.Name -like "*Framework*" -or $pkg.Name -like "*Runtime*") { continue }

                    # Get current individual status from CapabilityAccessManager
                    $appRegPath = "$ConsentReg\$($pkg.PackageFamilyName)"
                    $status = "Allow (Default)"
                    if (Test-Path $appRegPath) {
                        $val = Get-ItemProperty -Path $appRegPath -Name "Value" -ErrorAction SilentlyContinue
                        if ($val) { $status = $val.Value }
                    }

                    $statusColor = "Green"
                    if ($status -eq "Deny") { $statusColor = "Red" }

                    Write-Host -NoNewline "  [$index] $($pkg.Name) " -ForegroundColor White
                    Write-Host -NoNewline "--> Current State: " -ForegroundColor Gray
                    Write-Host $status -ForegroundColor $statusColor
                    
                    $appList += [PSCustomObject]@{
                        Index = $index
                        Name = $pkg.Name
                        Family = $pkg.PackageFamilyName
                        Status = $status
                    }
                    $index++
                }

                Write-Host ""
                $select = Read-Host "Select app number to toggle Deny/Allow (or 'q' to go back)"
                if ($select -eq "q") { break }

                $match = $appList | Where-Object { $_.Index -eq $select }
                if ($match) {
                    $appRegPath = "$ConsentReg\$($match.Family)"
                    if (-not (Test-Path $appRegPath)) {
                        New-Item -Path $appRegPath -Force | Out-Null
                    }

                    $newVal = "Deny"
                    if ($match.Status -eq "Deny") {
                        $newVal = "Allow"
                    }

                    try {
                        Set-ItemProperty -Path $appRegPath -Name "Value" -Value $newVal -Type String -Force | Out-Null
                        Write-Host ""
                        Write-Host "[+] Successfully set $($match.Name) background permission to: $newVal" -ForegroundColor Green
                        Start-Sleep -Seconds 1
                    } catch {
                        Write-Host "[!] Error: Failed to modify app settings in registry." -ForegroundColor Red
                        Start-Sleep -Seconds 2
                    }
                } else {
                    Write-Host "Invalid selection." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        
        "4" {
            Write-Host "Exiting..." -ForegroundColor Cyan
            break
        }
    }
}
