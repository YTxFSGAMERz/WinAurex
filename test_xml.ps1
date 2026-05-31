$xml = New-Object System.Xml.XmlDocument
try {
    $xml.Load('c:\Users\Admin\Documents\GitHub\Windows-Optimisations\autounattend.xml')
    Write-Host "XML is perfectly valid!"
} catch {
    Write-Host "XML is invalid:"
    Write-Host $_.Exception.Message
}
