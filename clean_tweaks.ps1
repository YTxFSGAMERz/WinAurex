[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TweaksPath = (Join-Path $PSScriptRoot "tweaks")
)

$resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TweaksPath)
if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
    throw "Tweaks directory not found: $resolvedPath"
}

$files = Get-ChildItem -LiteralPath $resolvedPath -Filter "*.ps1" -Recurse -File
foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName
    $newContent = @()
    $modified = $false

    foreach ($line in $content) {
        $newLine = $line

        if ($newLine -match '\$Host\.UI\.RawUI\.ReadKey') {
            $newLine = "`$Confirm = 'y'"
            $modified = $true
        }

        if ($newLine -match 'Import-Module.*Logging\.psm1') {
            $newLine = "# " + $newLine
            $modified = $true
        }

        if ($newLine -match 'Write-FrameworkLog') {
            $newLine = "# " + $newLine
            $modified = $true
        }

        $newContent += $newLine
    }

    if ($modified -and $PSCmdlet.ShouldProcess($file.FullName, "Comment out interactive and logging calls")) {
        Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding UTF8
        Write-Host "Modified $($file.Name)"
    }
}
