$ErrorActionPreference = 'Stop'

$ps1Files = Get-ChildItem -Path . -Filter *.ps1 -Recurse | Where-Object { $_.FullName -notmatch '\\\.git\\' }

foreach ($file in $ps1Files) {
    $content = Get-Content $file.FullName -Raw
    $changed = $false

    # Add [CmdletBinding()] param([switch]$Force) if not exists
    if ($content -match 'ReadKey' -or $content -match 'Join-Path') {
        if ($content -notmatch '\[switch\]\$Force') {
            if ($content -match '(?m)^param\s*\(') {
                $content = $content -replace '(?m)^(param\s*\()', "`$1`n    [switch]`$Force,`n"
                $changed = $true
            } else {
                $content = "[CmdletBinding()]`nparam (`n    [switch]`$Force`n)`n`n" + $content
                $changed = $true
            }
        }
    }

    # Inject -Force:$Force to all Join-Path script invocations
    if ($content -match '&\s*\(Join-Path') {
        # Match lines like: & (Join-Path -Path $ScriptDir -ChildPath "Configure_Developer_View.ps1")
        # And ensure they don't already end with -Force or -Force:$Force
        $newContent = [regex]::Replace($content, '(?m)^(\s*&\s*\(Join-Path[^\)]+\))(?!.*-Force).*$', '$1 -Force:$Force')
        if ($newContent -ne $content) {
            $content = $newContent
            $changed = $true
        }
    }
    
    # Bypass "Press 'Y' to continue" prompts
    # Look for: $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    # and if ($Confirm -notmatch 'y') { ... Exit }
    $pattern = '(?s)(\$Confirm\s*=\s*\$Host\.UI\.RawUI\.ReadKey[^:]+::GetCurrent\(\)\)\s*if\s*\(\$Confirm\s*-notmatch\s*''y''\)\s*\{\s*[^}]+Exit\s*\})'
    # Wait, regex is complex. Let's just do a simpler replace for the prompt blocks.
    
    # Alternatively, find:
    # $Confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    # if ($Confirm -notmatch 'y')
    # and replace with:
    # if (-not $Force) { $Confirm = ... } else { $Confirm = 'y' }
    if ($content -match '\$Confirm = \$Host\.UI\.RawUI\.ReadKey') {
        if ($content -notmatch 'if \(-not \$Force\) \{ \$Confirm') {
            $content = $content -replace '(?s)(\$Confirm = \$Host\.UI\.RawUI\.ReadKey\([^)]+\)\.Character)', "if (-not `$Force) { `$1 } else { `$Confirm = 'y' }"
            $changed = $true
        }
    }

    if ($changed) {
        Write-Host "Updating $($file.Name)..."
        Set-Content $file.FullName -Value $content -NoNewline
    }
}
