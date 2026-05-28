# Windows Configuration & Optimization Framework
# Snapshot Engine (Core/Restore/Engine/SnapshotEngine.psm1)

$Global:CurrentTransaction = $null
$Global:TransactionDir = $null

function New-Transaction {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory=$true)]
        [string]$ProfileName
    )
    
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $TransactionID = "TXN-$Timestamp-$(Get-Random -Minimum 1000 -Maximum 9999)"
    $OSBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    $BackupRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\Backups"
    $Global:TransactionDir = Join-Path -Path $BackupRoot -ChildPath "${Timestamp}_${ProfileName}"
    
    if (-not (Test-Path $Global:TransactionDir)) {
        New-Item -Path $Global:TransactionDir -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $Global:TransactionDir "Registry") -ItemType Directory -Force | Out-Null
    }
    
    $Global:CurrentTransaction = @{
        TransactionID = $TransactionID
        Module = $ModuleName
        Profile = $ProfileName
        Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        OSBuild = $OSBuild
        Changes = @()
    }
    
    Write-Host "[STATE] Started Transaction: $TransactionID" -ForegroundColor Cyan
    return $TransactionID
}

function Snapshot-RegistryKey {
    param (
        [Parameter(Mandatory=$true)]
        [string]$KeyPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueName,
        
        [Parameter(Mandatory=$false)]
        [string]$NewValue
    )
    
    if ($Global:CurrentTransaction -eq $null) {
        Write-Warning "No active transaction. Cannot snapshot registry key."
        return
    }
    
    $OldValue = $null
    $KeyExists = Test-Path $KeyPath
    if ($KeyExists) {
        $OldValue = (Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue).$ValueName
    }
    
    $Change = @{
        Type = "Registry"
        Path = $KeyPath
        ValueName = $ValueName
        OldValue = $OldValue
        NewValue = $NewValue
        KeyExisted = $KeyExists
    }
    
    $Global:CurrentTransaction.Changes += $Change
    
    # Also create a .reg backup of the entire key for deep safety, storing it in the transaction's Registry folder
    $SafeName = ($KeyPath -replace '\\', '_') -replace ':', ''
    $RegBackupPath = Join-Path -Path $Global:TransactionDir -ChildPath "Registry\$($SafeName)_$($ValueName).reg"
    & reg export $KeyPath $RegBackupPath /y 2>$null | Out-Null
}

function Snapshot-Service {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory=$false)]
        [string]$NewStartType,
        
        [Parameter(Mandatory=$false)]
        [string]$NewStatus
    )
    
    if ($Global:CurrentTransaction -eq $null) {
        Write-Warning "No active transaction. Cannot snapshot service."
        return
    }
    
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    $OldStartType = $null
    $OldStatus = $null
    
    if ($Service) {
        $OldStartType = $Service.StartType
        $OldStatus = $Service.Status
    }
    
    $Change = @{
        Type = "Service"
        Name = $ServiceName
        OldStartType = $OldStartType
        NewStartType = $NewStartType
        OldStatus = $OldStatus
        NewStatus = $NewStatus
    }
    
    $Global:CurrentTransaction.Changes += $Change
}

function Snapshot-Task {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TaskPath,
        
        [Parameter(Mandatory=$false)]
        [string]$NewState
    )
    
    if ($Global:CurrentTransaction -eq $null) {
        Write-Warning "No active transaction. Cannot snapshot task."
        return
    }
    
    $Task = Get-ScheduledTask -TaskPath "\" -TaskName $TaskPath -ErrorAction SilentlyContinue # Path lookup needs refinement based on input
    # Assuming TaskPath is just the name for now or full path
    $OldState = $null
    if ($Task) { $OldState = $Task.State }
    
    $Change = @{
        Type = "Task"
        Path = $TaskPath
        OldState = $OldState
        NewState = $NewState
    }
    
    $Global:CurrentTransaction.Changes += $Change
}

function Close-Transaction {
    if ($Global:CurrentTransaction -eq $null) { return }
    
    $ManifestPath = Join-Path -Path $Global:TransactionDir -ChildPath "manifest.json"
    $Global:CurrentTransaction | ConvertTo-Json -Depth 5 | Out-File -FilePath $ManifestPath -Encoding UTF8
    
    Write-Host "[STATE] Closed Transaction: $($Global:CurrentTransaction.TransactionID)" -ForegroundColor Cyan
    $Global:CurrentTransaction = $null
    $Global:TransactionDir = $null
}

Export-ModuleMember -Function New-Transaction, Snapshot-RegistryKey, Snapshot-Service, Snapshot-Task, Close-Transaction
