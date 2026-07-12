$ErrorActionPreference = 'Stop'

$ps1Files = Get-ChildItem -Path . -Filter *.ps1 -Recurse | Where-Object { $_.FullName -notmatch '\\\.git\\' }

foreach ($file in $ps1Files) {
    $content = Get-Content $file.FullName -Raw
    $changed = $false
    
    # Fix 1: Wrap "Press any key to exit..." ReadKey in if (-not $Force) if not already
    # Match `if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }` exactly that is NOT already inside an if block
    # (Checking for simple not having 'if (-not $Force) {' before it is tricky with regex, 
    # but we can look for Write-Host "Press any key to exit..." followed by $null = ...)
    
    if ($content -match 'Write-Host "Press any key to exit\.\.\."\r?\n\s*\$null = \$Host\.UI\.RawUI\.ReadKey\("NoEcho,IncludeKeyDown"\)') {
        $content = $content -replace '(?s)Write-Host "Press any key to exit\.\.\."\r?\n\s*\$null = \$Host\.UI\.RawUI\.ReadKey\("NoEcho,IncludeKeyDown"\)', "if (-not `$Force) {`r`n    Write-Host `"Press any key to exit...`"`r`n    `$null = `$Host.UI.RawUI.ReadKey(`"NoEcho,IncludeKeyDown`")`r`n}"
        $changed = $true
    }

    # Fix 2: Sometimes it's just if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } without the Write-Host line right above, or different spacing
    # Let's just blindly wrap any `if (-not $Force) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }` that isn't already inside `if (-not $Force) { ... }` or `if ($Confirm -notmatch ...)`
    # This is safer to do via regex by checking if there's no `if (-not $Force)` in the whole script?
    # Actually, some scripts DO have `if (-not $Force)` around it. Let's just fix the ones that don't.
    if ($content -match '\$null = \$Host\.UI\.RawUI\.ReadKey\("NoEcho,IncludeKeyDown"\)' -and $content -notmatch 'if \(-not \$Force\) {\s*\$null = \$Host') {
        $content = $content -replace '(?s)\$null = \$Host\.UI\.RawUI\.ReadKey\("NoEcho,IncludeKeyDown"\)', "if (-not `$Force) { `$null = `$Host.UI.RawUI.ReadKey(`"NoEcho,IncludeKeyDown`") }"
        $changed = $true
    }
    
    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Patched $($file.FullName)"
    }
}
