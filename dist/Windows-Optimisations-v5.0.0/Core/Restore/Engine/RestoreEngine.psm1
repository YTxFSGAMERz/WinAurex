# Windows Configuration & Optimization Framework
# Restore Engine (Core/Restore/Engine/RestoreEngine.psm1)

function Restore-Transaction {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )
    
    $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
    $TransactionDir = Split-Path $ManifestPath -Parent
    
    Write-Host "`nRestoring Transaction $($Manifest.TransactionID)..." -ForegroundColor Yellow
    
    foreach ($Change in $Manifest.Changes) {
        switch ($Change.Type) {
            "Registry" {
                if ($Change.KeyExisted) {
                    if ($null -ne $Change.OldValue) {
                        # We have the exact previous value, restore it directly
                        Write-Host "Restoring Registry: $($Change.Path) -> $($Change.ValueName) = $($Change.OldValue)"
                        Set-ItemProperty -Path $Change.Path -Name $Change.ValueName -Value $Change.OldValue -Force -ErrorAction SilentlyContinue
                    } else {
                        # The value didn't exist before, so we delete the new value we created
                        Write-Host "Removing Registry Value created by tweak: $($Change.Path) -> $($Change.ValueName)"
                        Remove-ItemProperty -Path $Change.Path -Name $Change.ValueName -Force -ErrorAction SilentlyContinue
                    }
                } else {
                    # The entire key didn't exist before, we should delete it
                    Write-Host "Removing Registry Key created by tweak: $($Change.Path)"
                    Remove-Item -Path $Change.Path -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            "Service" {
                if ($null -ne $Change.OldStartType) {
                    Write-Host "Restoring Service: $($Change.Name) -> StartType = $($Change.OldStartType)"
                    Set-Service -Name $Change.Name -StartupType $Change.OldStartType -ErrorAction SilentlyContinue
                    if ($Change.OldStatus -eq "Running") {
                        Start-Service -Name $Change.Name -ErrorAction SilentlyContinue
                    } elseif ($Change.OldStatus -eq "Stopped") {
                        Stop-Service -Name $Change.Name -ErrorAction SilentlyContinue
                    }
                }
            }
            "Task" {
                if ($null -ne $Change.OldState) {
                    Write-Host "Restoring Task: $($Change.Path) -> State = $($Change.OldState)"
                    if ($Change.OldState -eq "Ready" -or $Change.OldState -eq "Running") {
                        Enable-ScheduledTask -TaskPath "\" -TaskName $Change.Path -ErrorAction SilentlyContinue
                    } elseif ($Change.OldState -eq "Disabled") {
                        Disable-ScheduledTask -TaskPath "\" -TaskName $Change.Path -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
    
    Write-Host "`n[SUCCESS] Transaction restored successfully!" -ForegroundColor Green
}

Export-ModuleMember -Function Restore-Transaction
