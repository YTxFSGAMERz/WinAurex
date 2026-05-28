$ScriptsToTest = Get-ChildItem -Path ".\Tweaks", ".\Profiles", ".\Tools" -Recurse -Filter "*.ps1" | Where-Object {
    $_.Name -notmatch "Interactive" -and 
    $_.Name -notmatch "Dashboard" -and
    $_.Name -notmatch "Test_Latency" -and
    $_.Name -notmatch "Analyze_DPC" -and
    $_.Name -notmatch "Generate_System_Performance_Report"
}

$LogFile = "integration_test_results.log"
$ErrorLog = "integration_test_errors.log"

Clear-Content $LogFile -ErrorAction SilentlyContinue
Clear-Content $ErrorLog -ErrorAction SilentlyContinue

$Total = $ScriptsToTest.Count
$Passed = 0
$Failed = 0

Write-Host "Starting integration tests on $Total scripts..." -ForegroundColor Cyan

foreach ($Script in $ScriptsToTest) {
    Write-Host "Testing: $($Script.Name)..." -NoNewline
    
    $Args = "/c powershell -NoProfile -ExecutionPolicy Bypass -File `"$($Script.FullName)`" -Force"
    $process = Start-Process cmd -ArgumentList $Args -NoNewWindow -Wait -PassThru -RedirectStandardOutput "temp_out.txt" -RedirectStandardError "temp_err.txt"
    
    $StdOut = Get-Content "temp_out.txt" -Raw -ErrorAction SilentlyContinue
    $StdErr = Get-Content "temp_err.txt" -Raw -ErrorAction SilentlyContinue
    
    $FailedThisScript = $false
    
    if ($process.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($StdErr) -eq $false) {
        if ($StdErr -match "unapproved verbs") {
            $StdErr = $StdErr -replace 'WARNING: The names of.*?Get-Verb\.', '' -replace '(?s)\s+', ' '
        }
        
        if ([string]::IsNullOrWhiteSpace($StdErr) -eq $false -or $process.ExitCode -ne 0) {
            $FailedThisScript = $true
            $Failed++
            Write-Host " FAILED" -ForegroundColor Red
            
            Add-Content -Path $ErrorLog -Value "================================================="
            Add-Content -Path $ErrorLog -Value "SCRIPT: $($Script.FullName)"
            Add-Content -Path $ErrorLog -Value "EXIT CODE: $($process.ExitCode)"
            Add-Content -Path $ErrorLog -Value "STDERR: $StdErr"
            Add-Content -Path $ErrorLog -Value "STDOUT: $StdOut"
            Add-Content -Path $ErrorLog -Value "================================================="
        }
    }
    
    if (-not $FailedThisScript) {
        $Passed++
        Write-Host " PASSED" -ForegroundColor Green
    }
}

Remove-Item "temp_out.txt", "temp_err.txt" -ErrorAction SilentlyContinue

Write-Host "`nTest Run Completed!" -ForegroundColor Cyan
Write-Host "Passed: $Passed" -ForegroundColor Green
Write-Host "Failed: $Failed" -ForegroundColor Red

if ($Failed -gt 0) {
    Write-Host "Check $ErrorLog for details." -ForegroundColor Yellow
}
