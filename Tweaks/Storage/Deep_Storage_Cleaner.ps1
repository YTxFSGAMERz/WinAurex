# ==============================================================================
# TWEAK: Deep Storage Cleaner
# CATEGORY: Storage
# DESCRIPTION: Analyzes system storage and purges temp files, crash dumps,
#              stale AI indexes, old squirrel app versions, dev caches, and browser caches.
# ==============================================================================

$RootPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$CleanerScript = Join-Path $RootPath "Tools\Cleaner\Invoke-PCCleaner.ps1"

if (Test-Path $CleanerScript) {
    & $CleanerScript
} else {
    Write-Warning "WinAurex Cleaner not found at $CleanerScript"
}
