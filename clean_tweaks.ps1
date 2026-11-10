# WinAurex Script Validator and Normalizer
# Ensures all PowerShell tweak scripts support non-interactive execution (-Force)
# and clean user-prompting without syntax breakage.

$files = Get-ChildItem -Path (Join-Path $PSScriptRoot "Tweaks") -Filter "*.ps1" -Recurse
$updated = 0

foreach ($file in $files) {
    $raw = Get-Content $file.FullName -Raw
    $newRaw = $raw

    if ($newRaw -match '(?m)^\$Confirm\s*=\s*.y.$') {
        $newRaw = $newRaw -replace '(?m)^\$Confirm\s*=\s*.y.$', "`$Confirm = if (`$Force -or [Console]::IsInputRedirected) { 'y' } else { Read-Host `"Press 'Y' to continue or any other key to abort`" }"
    }

    if ($newRaw -match '(?s)if \(-not \$Force\)\s*\{\s*if \(-not \$Force\)\s*\{\s*\}\s*\}') {
        $newRaw = $newRaw -replace '(?s)if \(-not \$Force\)\s*\{\s*if \(-not \$Force\)\s*\{\s*\}\s*\}', "if (-not `$Force -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {`n    `$null = Read-Host `"`nPress Enter to return...`"`n}"
    }

    if ($newRaw -ne $raw) {
        Set-Content -Path $file.FullName -Value $newRaw
        $updated++
        Write-Host "Normalized $($file.Name)" -ForegroundColor Cyan
    }
}

Write-Host "Validation complete. $updated scripts normalized." -ForegroundColor Green
