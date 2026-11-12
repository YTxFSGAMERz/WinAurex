<#
.SYNOPSIS
    WinAurex Dynamic Catalog & Execution Engine
.DESCRIPTION
    Dynamically discovers, indexes, categorizes, and executes all tweaks in Tweaks/
    and all diagnostic/tuning utilities in Tools/.
#>

function Get-WinAurexTweaksCatalog {
    param (
        [Parameter(Mandatory=$true)][string]$TweaksRoot
    )

    if (-not (Test-Path $TweaksRoot)) { return @() }

    $tweakFiles = Get-ChildItem -Path $TweaksRoot -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.Extension -in @(".ps1", ".reg", ".cmd", ".bat") }

    $catalog = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($file in $tweakFiles) {
        $category = $file.Directory.Name
        if ($category -eq "Tweaks") { $category = "General" }
        
        $rawName = $file.BaseName -replace '^(\d+[\.\-_])+', '' -replace '^[a-zA-Z]+_', ''
        $displayName = $file.BaseName -replace '_', ' '
        $type = $file.Extension.TrimStart('.').ToUpper()

        # Extract synopsis from PowerShell comments if present
        $synopsis = ""
        if ($file.Extension -eq ".ps1") {
            try {
                $head = Get-Content -Path $file.FullName -TotalCount 20 -ErrorAction SilentlyContinue
                for ($i = 0; $i -lt $head.Count; $i++) {
                    if ($head[$i] -match "\.SYNOPSIS") {
                        if (($i + 1) -lt $head.Count) {
                            $synopsis = $head[$i + 1].Trim().TrimStart('#').Trim()
                        }
                        break
                    }
                }
            } catch {}
        }

        if ([string]::IsNullOrWhiteSpace($synopsis)) {
            $synopsis = "$category optimization ($type format)"
        }

        $catalog.Add([PSCustomObject]@{
            Name        = $displayName
            Category    = $category
            Type        = $type
            Path        = $file.FullName
            FileName    = $file.Name
            Synopsis    = $synopsis
            DisplayText = "$displayName ($type)"
        })
    }

    return $catalog.ToArray()
}

function Get-WinAurexToolsCatalog {
    param (
        [Parameter(Mandatory=$true)][string]$ToolsRoot
    )

    if (-not (Test-Path $ToolsRoot)) { return @() }

    $toolFiles = Get-ChildItem -Path $ToolsRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @(".exe", ".ps1", ".cmd", ".bat") }

    $catalog = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($file in $toolFiles) {
        $category = $file.Directory.Name
        $type = $file.Extension.TrimStart('.').ToUpper()
        $displayName = $file.BaseName -replace '_', ' '

        $catalog.Add([PSCustomObject]@{
            Name        = $displayName
            Category    = $category
            Type        = $type
            Path        = $file.FullName
            FileName    = $file.Name
            DisplayText = "$displayName ($type)"
        })
    }

    return $catalog.ToArray()
}

function Invoke-WinAurexItem {
    param (
        [Parameter(Mandatory=$true)][string]$ItemPath,
        [string]$Arguments = ""
    )

    if (-not (Test-Path $ItemPath)) {
        Write-Warning "Target file not found: $ItemPath"
        return $false
    }

    $ext = [System.IO.Path]::GetExtension($ItemPath).ToLower()
    try {
        switch ($ext) {
            ".ps1" {
                $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$ItemPath`""
                if ($Arguments) { $argList += " $Arguments" }
                $proc = Start-Process powershell.exe -ArgumentList $argList -PassThru -Wait
                return ($proc.ExitCode -eq 0)
            }
            ".reg" {
                $proc = Start-Process "reg.exe" -ArgumentList "import `"$ItemPath`"" -PassThru -Wait -WindowStyle Hidden
                return ($proc.ExitCode -eq 0)
            }
            { $_ -in @(".cmd", ".bat") } {
                $argList = "/c `"$ItemPath`""
                if ($Arguments) { $argList += " $Arguments" }
                $proc = Start-Process "cmd.exe" -ArgumentList $argList -PassThru -Wait
                return ($proc.ExitCode -eq 0)
            }
            ".exe" {
                Start-Process -FilePath $ItemPath -ArgumentList $Arguments
                return $true
            }
            default {
                Invoke-Item $ItemPath
                return $true
            }
        }
    } catch {
        Write-Warning "Failed executing item ($ItemPath): $_"
        return $false
    }
}

Export-ModuleMember -Function Get-WinAurexTweaksCatalog, Get-WinAurexToolsCatalog, Invoke-WinAurexItem
