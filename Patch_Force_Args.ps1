[CmdletBinding()]
param (
    [switch]$Force
)

$files = Get-ChildItem -Path "Tweaks", "Tools", "Core" -Recurse -Filter "*.ps1"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    $modified = $false
    
    # Check if param block needs to be added
    if (($content -match 'ReadKey') -and ($content -notmatch '\[switch\]\$Force')) {
        $content = "[CmdletBinding()]`r`nparam (`r`n    [switch]`$Force`r`n)`r`n`r`n" + $content
        $modified = $true
    }
    
    # Patch the "Press 'Y' to continue" block
    if ($content -match "(Write-Host `"Press 'Y' to continue.*`r`n[^\n]*ReadKey[^\n]*`r`n`r`nif \(`$Confirm -notmatch 'y'\) \{[\s\S]*?Exit`r`n\})") {
        $block = $matches[1]
        if ($content -notmatch "if \(-not `$Force\) \{\s*$([regex]::Escape($block))") {
            $newBlock = "if (-not `$Force) {`r`n    " + ($block -replace "`r`n", "`r`n    ") + "`r`n}"
            $content = $content.Replace($block, $newBlock)
            $modified = $true
        }
    }
    
    # Patch the "Press any key to exit" block
    if ($content -match "(Write-Host `"Press any key to exit\.\.\.`"`r`n[^\n]*ReadKey[^\n]*)") {
        $block2 = $matches[1]
        if ($content -notmatch "if \(-not `$Force\) \{\s*$([regex]::Escape($block2))") {
            $newBlock2 = "if (-not `$Force) {`r`n    " + ($block2 -replace "`r`n", "`r`n    ") + "`r`n}"
            $content = $content.Replace($block2, $newBlock2)
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content $file.FullName -Value $content
        Write-Host "Patched: $($file.Name)"
    }
}
