# Windows Configuration & Optimization Framework
# Validation Engine (Core/Restore/Engine/ValidationEngine.psm1)

function Validate-Manifest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )
    
    if (-not (Test-Path $ManifestPath)) {
        Write-Host "[ERROR] Manifest file not found at: $ManifestPath" -ForegroundColor Red
        return $false
    }
    
    $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
    $CurrentBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    Write-Host "`nValidating Transaction $($Manifest.TransactionID)..." -ForegroundColor Cyan
    $IsValid = $true
    
    if ($Manifest.OSBuild -ne $CurrentBuild) {
        Write-Host "[WARNING] OS Build Mismatch detected!" -ForegroundColor Yellow
        Write-Host "Transaction Build: $($Manifest.OSBuild)"
        Write-Host "Current OS Build:  $CurrentBuild"
        Write-Host "Some registry keys or services may be deprecated or behave differently."
        $WarningConfirmed = Read-Host "Are you sure you want to restore this across different OS builds? (Y/N)"
        if ($WarningConfirmed -notmatch '^[yY]') {
            Write-Host "Rollback aborted safely." -ForegroundColor Red
            return $false
        }
    }
    
    # Check if we have corrupt registry backups
    $TransactionDir = Split-Path $ManifestPath -Parent
    foreach ($Change in $Manifest.Changes) {
        if ($Change.Type -eq "Registry" -and $Change.KeyExisted) {
            $SafeName = ($Change.Path -replace '\\', '_') -replace ':', ''
            $RegBackupPath = Join-Path -Path $TransactionDir -ChildPath "Registry\$($SafeName)_$($Change.ValueName).reg"
            if (-not (Test-Path $RegBackupPath)) {
                Write-Host "[WARNING] Registry backup missing for $($Change.Path) -> $($Change.ValueName)" -ForegroundColor Yellow
                $IsValid = $false
            }
        }
    }
    
    if (-not $IsValid) {
        Write-Host "[ERROR] Manifest indicates registry keys were backed up, but .reg files are missing!" -ForegroundColor Red
        Write-Host "Rollback aborted safely to prevent partial state corruption." -ForegroundColor Red
        return $false
    }
    
    Write-Host "[OK] Validation passed. Safe to restore." -ForegroundColor Green
    return $true
}

function Preview-Manifest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )
    
    if (-not (Test-Path $ManifestPath)) { return }
    $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
    
    Write-Host "`n=== ROLLBACK PREVIEW ===" -ForegroundColor Cyan
    Write-Host "Transaction: $($Manifest.TransactionID)"
    Write-Host "Profile:     $($Manifest.Profile)"
    Write-Host "Timestamp:   $($Manifest.Timestamp)"
    
    $RegCount = 0
    $SvcCount = 0
    $TaskCount = 0
    
    foreach ($Change in $Manifest.Changes) {
        switch ($Change.Type) {
            "Registry" { $RegCount++ }
            "Service" { $SvcCount++ }
            "Task" { $TaskCount++ }
        }
    }
    
    Write-Host "`nRegistry Keys:  $RegCount changes"
    Write-Host "Services:       $SvcCount changes"
    Write-Host "Tasks:          $TaskCount changes"
    Write-Host "========================`n"
}

Export-ModuleMember -Function Validate-Manifest, Preview-Manifest
