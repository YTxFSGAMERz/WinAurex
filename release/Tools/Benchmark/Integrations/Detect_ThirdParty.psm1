# Windows Configuration & Optimization Framework
# Detect Third-Party Integrations (Tools/Benchmark/Integrations/Detect_ThirdParty.psm1)

function Get-GeekbenchStatus {
    $Paths = @(
        "${Env:ProgramFiles}\Geekbench 6\geekbench6.exe",
        "${Env:ProgramFiles(x86)}\Geekbench 6\geekbench6.exe"
    )
    foreach ($P in $Paths) { if (Test-Path $P) { return $P } }
    return $null
}

function Get-CrystalDiskMarkStatus {
    $Paths = @(
        "${Env:ProgramFiles}\CrystalDiskMark\DiskMark64.exe",
        "${Env:ProgramFiles(x86)}\CrystalDiskMark\DiskMark64.exe"
    )
    foreach ($P in $Paths) { if (Test-Path $P) { return $P } }
    return $null
}

function Get-OCCTStatus {
    # OCCT is often portable, we check standard drop locations
    $Paths = @(
        "${Env:UserProfile}\Desktop\OCCT.exe",
        "${Env:UserProfile}\Downloads\OCCT.exe"
    )
    foreach ($P in $Paths) { if (Test-Path $P) { return $P } }
    return $null
}

function Invoke-ThirdPartyScan {
    Write-Host "`nScanning for supported Third-Party Benchmarks..." -ForegroundColor Cyan
    
    $GB = Get-GeekbenchStatus
    $CDM = Get-CrystalDiskMarkStatus
    $OCCT = Get-OCCTStatus
    
    if ($GB) { Write-Host "[DETECTED] Geekbench found at: $GB" -ForegroundColor Green }
    if ($CDM) { Write-Host "[DETECTED] CrystalDiskMark found at: $CDM" -ForegroundColor Green }
    if ($OCCT) { Write-Host "[DETECTED] OCCT found at: $OCCT" -ForegroundColor Green }
    
    if (-not $GB -and -not $CDM -and -not $OCCT) {
        Write-Host "No supported third-party benchmarks detected." -ForegroundColor Yellow
        Write-Host "The framework relies purely on native Windows telemetry."
        return
    }
    
    Write-Host "`nWould you like to run an integrated benchmark session using the detected tools? (Y/N)"
    $Choice = Read-Host
    if ($Choice -match '^[yY]') {
        if ($GB) {
            Write-Host "Launching Geekbench CLI..." -ForegroundColor Cyan
            Start-Process -FilePath $GB -ArgumentList "--no-upload" -Wait
        }
        if ($CDM) {
            Write-Host "Launching CrystalDiskMark..." -ForegroundColor Cyan
            Start-Process -FilePath $CDM
        }
    }
}

Export-ModuleMember -Function Get-GeekbenchStatus, Get-CrystalDiskMarkStatus, Get-OCCTStatus, Invoke-ThirdPartyScan
