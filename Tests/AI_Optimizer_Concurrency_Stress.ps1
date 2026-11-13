$OptimizerScript = Join-Path (Split-Path $PSScriptRoot -Parent) "Tweaks\Services\AI_Dynamic_System_Optimizer.ps1"

Write-Host "Spawning 2 concurrent processes of AI_Dynamic_System_Optimizer.ps1..."
$pinfo1 = New-Object System.Diagnostics.ProcessStartInfo
$pinfo1.FileName = "powershell.exe"
$pinfo1.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -ScanOnly -Force"
$pinfo1.RedirectStandardOutput = $true
$pinfo1.RedirectStandardError = $true
$pinfo1.UseShellExecute = $false
$pinfo1.CreateNoWindow = $true

$pinfo2 = New-Object System.Diagnostics.ProcessStartInfo
$pinfo2.FileName = "powershell.exe"
$pinfo2.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$OptimizerScript`" -ScanOnly -Force"
$pinfo2.RedirectStandardOutput = $true
$pinfo2.RedirectStandardError = $true
$pinfo2.UseShellExecute = $false
$pinfo2.CreateNoWindow = $true

$p1 = [System.Diagnostics.Process]::Start($pinfo1)
$p2 = [System.Diagnostics.Process]::Start($pinfo2)

$out1 = $p1.StandardOutput.ReadToEnd()
$err1 = $p1.StandardError.ReadToEnd()
$p1.WaitForExit()

$out2 = $p2.StandardOutput.ReadToEnd()
$err2 = $p2.StandardError.ReadToEnd()
$p2.WaitForExit()

Write-Host "Process 1 ExitCode: $($p1.ExitCode), Stderr: '$err1'"
Write-Host "Process 2 ExitCode: $($p2.ExitCode), Stderr: '$err2'"

if ($p1.ExitCode -eq 0 -and $p2.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($err1) -and [string]::IsNullOrWhiteSpace($err2)) {
    Write-Host "CONCURRENCY_TEST_PASSED"
} else {
    Write-Host "CONCURRENCY_TEST_FAILED"
}
