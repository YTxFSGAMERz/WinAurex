$content = Get-Content 'Tweaks\Apply Optimizations.bat' -Raw
$content = $content -replace '(?m)^(sc config.*?) 2>nul$', '$1 | findstr /i "SUCCESS"'
$content = $content -replace '(?m)^(schtasks.*?) 2>nul$', '$1 | findstr /i "SUCCESS"'
$content = $content -replace '(?m)^(reg add.*?) 2>nul$', '$1 | findstr /i "successfully"'
Set-Content 'Tweaks\Apply Optimizations.bat' -Value $content -NoNewline
