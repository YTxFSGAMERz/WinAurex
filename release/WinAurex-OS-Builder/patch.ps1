if ($architecture -eq 'amd64') {
    $folderPaths = Get-ChildItem -Path "$mainOSDrive\scratchdir\Windows\WinSxS" -Filter "amd64_microsoft-edge-webview_31bf3856ad364e35*" -Directory | Select-Object -ExpandProperty FullName

    if ($folderPaths) {
        foreach ($folderPath in $folderPaths) {
            & 'takeown' '/f' $folderPath '/r' >null
            & icacls $folderPath  "/grant" "$($adminGroup.Value):(F)" '/T' '/C' >null
            Remove-Item -Path $folderPath -Recurse -Force >null
        }
    } else {
        Write-Host "Folder not found."
    }
} elseif ($architecture -eq 'arm64') {
    $folderPaths = Get-ChildItem -Path "$mainOSDrive\scratchdir\Windows\WinSxS" -Filter "arm64_microsoft-edge-webview_31bf3856ad364e35*" -Directory | Select-Object -ExpandProperty FullName >null

    if ($folderPaths) {
        foreach ($folderPath in $folderPaths) {
            & 'takeown' '/f' $folderPath '/r'>null
            & icacls $folderPath  "/grant" "$($adminGroup.Value):(F)" '/T' '/C' >null
            Remove-Item -Path $folderPath -Recurse -Force >null
        }
    } else {
        Write-Host "Folder not found."
    }
}

