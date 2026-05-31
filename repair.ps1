$xmlPath = 'c:\Users\Admin\Documents\GitHub\Windows-Optimisations\autounattend.xml'
$tweaksDir = 'c:\Users\Admin\Documents\GitHub\Windows-Optimisations\Tweaks'
$content = [System.IO.File]::ReadAllText($xmlPath)

# 1. Clean up previously injected files (we know they all start with <File path="C:\Windows\Setup\Scripts\Tweaks\)
$startIndex = $content.IndexOf('    <File path="C:\Windows\Setup\Scripts\Tweaks\')
if ($startIndex -gt 0) {
    $endIndex = $content.IndexOf('  </Extensions>')
    if ($endIndex -gt $startIndex) {
        $content = $content.Substring(0, $startIndex) + $content.Substring($endIndex)
    }
}

# 2. Generate the file tags again, but this time PROPERLY XML ESCAPE them AND filter extensions
$files = Get-ChildItem -Path $tweaksDir -File -Recurse
$excludedKeywords = @("Enable", "Restore", "Default", "Light", "Undo", "Revert")
$allowedExtensions = @(".ps1", ".bat", ".cmd", ".reg", ".txt")
$xmlBlock = New-Object System.Text.StringBuilder

foreach ($file in $files) {
    # Check extension
    if ($file.Extension -notin $allowedExtensions) {
        continue
    }

    $skip = $false
    foreach ($keyword in $excludedKeywords) {
        if ($file.Name -match $keyword) {
            $skip = $true
            break
        }
    }
    
    if (-not $skip) {
        $relativePath = $file.FullName.Substring($tweaksDir.Length + 1)
        $targetPath = "C:\Windows\Setup\Scripts\Tweaks\$relativePath"
        
        # Escape the file path for XML!
        $escapedPath = [System.Security.SecurityElement]::Escape($targetPath)
        
        # Read properly assuming UTF-8
        $fileContent = [System.IO.File]::ReadAllText($file.FullName)
        
        # XML Escape the content!
        if (-not [string]::IsNullOrEmpty($fileContent)) {
            # Ensure no null bytes sneak in even from text files
            $fileContent = $fileContent.Replace("`0", "")
            $escapedContent = [System.Security.SecurityElement]::Escape($fileContent)
        } else {
            $escapedContent = ""
        }
        
        [void]$xmlBlock.AppendLine("    <File path=`"$escapedPath`">")
        [void]$xmlBlock.AppendLine($escapedContent)
        [void]$xmlBlock.AppendLine("    </File>")
    }
}

# 3. Inject back into the XML
$newContent = $content.Replace("  </Extensions>", $xmlBlock.ToString() + "`r`n  </Extensions>")
[System.IO.File]::WriteAllText($xmlPath, $newContent)
Write-Output "autounattend.xml successfully updated!"
