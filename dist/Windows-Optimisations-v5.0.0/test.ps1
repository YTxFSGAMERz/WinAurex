Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
$XamlPath = "C:\Users\Admin\Documents\GitHub\Windows-Optimisations\GUI\Dashboard.xaml"
try {
    [xml]$xmlWPF = Get-Content -Path $XamlPath
    $StringReader = New-Object System.IO.StringReader $xmlWPF.OuterXml
    $XmlReader = [System.Xml.XmlReader]::Create($StringReader)
    $Window = [Windows.Markup.XamlReader]::Load($XmlReader)
    Write-Host "Success!"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
