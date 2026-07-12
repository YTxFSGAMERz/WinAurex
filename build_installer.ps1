$ErrorActionPreference = "Stop"

# Step 1: Ensure Inno Setup is installed
$isccPath = "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $isccPath)) {
    Write-Host "Inno Setup not found at $isccPath. Attempting to install via winget..."
    winget install -e --id JRSoftware.InnoSetup --silent --accept-source-agreements --accept-package-agreements
    if (-not (Test-Path $isccPath)) {
        Write-Error "Failed to install Inno Setup. Please install it manually from https://jrsoftware.org/isinfo.php"
        exit 1
    }
}

# Step 2: Build the .NET Application
Write-Host "Publishing WinAurex C# .NET Application..."
# Force unpackaged, self-contained, trimmed build for win-x64
dotnet publish "src\WinAurex.App\WinAurex.App.csproj" -c Release -r win-x64 --self-contained true -p:PublishTrimmed=false

if ($LASTEXITCODE -ne 0) {
    Write-Error "dotnet publish failed."
    exit 1
}

# WinUI 3 bug: .pri file for the app itself is often not copied to the publish dir for unpackaged apps
Copy-Item "src\WinAurex.App\bin\Release\net10.0-windows10.0.26100.0\win-x64\WinAurex.App.pri" "src\WinAurex.App\bin\Release\net10.0-windows10.0.26100.0\win-x64\publish\" -ErrorAction SilentlyContinue

# Step 3: Run Inno Setup Compiler
Write-Host "Compiling WinAurex-Setup.exe using Inno Setup..."
& $isccPath "installer\WinAurex.iss"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Inno Setup compilation failed."
    exit 1
}

Write-Host "Success! Installer generated at release\WinAurex-Setup.exe"
