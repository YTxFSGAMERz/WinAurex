# Windows Configuration & Optimization Framework
# Interactive Rollback Menu (Core/Restore/Rollback_Interactive.ps1)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit
}

$EngineDir = Join-Path -Path $PSScriptRoot -ChildPath "Engine"
Import-Module (Join-Path -Path $EngineDir -ChildPath "ValidationEngine.psm1") -Force
Import-Module (Join-Path -Path $EngineDir -ChildPath "RestoreEngine.psm1") -Force

$BackupsDir = Join-Path -Path $PSScriptRoot -ChildPath "Backups"

function Show-Menu {
    Clear-Host
    Write-Host "================================================="
    Write-Host "   TRANSACTIONAL ROLLBACK ENGINE" -ForegroundColor Cyan
    Write-Host "================================================="
    Write-Host "Manage and restore system state via snapshots."
    Write-Host "================================================="
    Write-Host "1. View All Transactions"
    Write-Host "2. Preview a Transaction Rollback"
    Write-Host "3. Rollback a Transaction"
    Write-Host "4. Exit"
    Write-Host "================================================="
}

function Get-Transactions {
    if (-not (Test-Path $BackupsDir)) { return @() }
    $Manifests = Get-ChildItem -Path $BackupsDir -Filter "manifest.json" -Recurse
    $Results = @()
    foreach ($M in $Manifests) {
        $Data = Get-Content $M.FullName | ConvertFrom-Json
        $Data | Add-Member -MemberType NoteProperty -Name "ManifestPath" -Value $M.FullName
        $Results += $Data
    }
    return $Results | Sort-Object Timestamp -Descending
}

while ($true) {
    Show-Menu
    $Choice = Read-Host "Select an option [1-4]"
    
    switch ($Choice) {
        '1' {
            Write-Host "`n--- Available Transactions ---" -ForegroundColor Yellow
            $Txns = Get-Transactions
            if ($Txns.Count -eq 0) { Write-Host "No transactions found." }
            else {
                $Txns | Select-Object TransactionID, Timestamp, Module, Profile | Format-Table -AutoSize
            }
            Read-Host "`nPress Enter to return to menu..."
        }
        '2' {
            $Txns = Get-Transactions
            if ($Txns.Count -eq 0) { Write-Host "`nNo transactions found." }
            else {
                $Txns | Select-Object TransactionID, Timestamp, Module, Profile | Format-Table -AutoSize
                $SelectedID = Read-Host "Enter the TransactionID to preview"
                $Target = $Txns | Where-Object { $_.TransactionID -eq $SelectedID }
                if ($Target) {
                    Preview-Manifest -ManifestPath $Target.ManifestPath
                } else {
                    Write-Host "`nTransactionID not found." -ForegroundColor Red
                }
            }
            Read-Host "`nPress Enter to return to menu..."
        }
        '3' {
            $Txns = Get-Transactions
            if ($Txns.Count -eq 0) { Write-Host "`nNo transactions found." }
            else {
                $Txns | Select-Object TransactionID, Timestamp, Module, Profile | Format-Table -AutoSize
                $SelectedID = Read-Host "Enter the TransactionID to restore"
                $Target = $Txns | Where-Object { $_.TransactionID -eq $SelectedID }
                if ($Target) {
                    $IsValid = Validate-Manifest -ManifestPath $Target.ManifestPath
                    if ($IsValid) {
                        $Confirm = Read-Host "Are you absolutely sure you want to restore this state? (Y/N)"
                        if ($Confirm -match '^[yY]') {
                            Restore-Transaction -ManifestPath $Target.ManifestPath
                        }
                    }
                } else {
                    Write-Host "`nTransactionID not found." -ForegroundColor Red
                }
            }
            Read-Host "`nPress Enter to return to menu..."
        }
        '4' {
            Exit
        }
    }
}
