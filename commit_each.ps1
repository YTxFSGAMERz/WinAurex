$status = git status --porcelain
foreach ($line in $status) {
    if ($line -match '^\s*M\s+(.*)') {
        $file = $matches[1].Trim()
        
        # Remove quotes if git added them
        if ($file.StartsWith('"') -and $file.EndsWith('"')) {
            $file = $file.Substring(1, $file.Length - 2)
        }
        
        git add "`"$file`""
        git commit -m "fix: bypass trailing ReadKey pause in $file for seamless automation"
    }
}
