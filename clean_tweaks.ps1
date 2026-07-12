$files = Get-ChildItem -Path "c:\Users\Admin\Documents\GitHub\WinAurex\tweaks" -Filter "*.ps1" -Recurse
foreach ($file in $files) {
    $content = Get-Content $file.FullName
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

    if ($modified) {
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "Modified $($file.Name)"
    }
}
