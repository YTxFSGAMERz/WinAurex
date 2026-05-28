# Windows Configuration & Optimization Framework
# Test Latency To Game Servers (Tweaks/Network-Diagnostics/Test_Latency_To_Game_Servers.ps1)

Write-Host "================================================="
Write-Host "   NETWORK LATENCY DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "================================================="
Write-Host "Testing ICMP Ping latency to major cloud providers"
Write-Host "often used to host multiplayer game servers..."
Write-Host "=================================================`n"

$Endpoints = @{
    "Cloudflare (Global Routing)" = "1.1.1.1"
    "Google (Global Routing)" = "8.8.8.8"
    "AWS US East (N. Virginia)" = "dynamodb.us-east-1.amazonaws.com"
    "AWS EU West (Ireland)" = "dynamodb.eu-west-1.amazonaws.com"
    "AWS AP (Tokyo)" = "dynamodb.ap-northeast-1.amazonaws.com"
    "Azure US East" = "blob.core.windows.net"
}

foreach ($Key in $Endpoints.Keys) {
    Write-Host "Pinging $Key ($($Endpoints[$Key]))..."
    $Result = Test-Connection -ComputerName $Endpoints[$Key] -Count 4 -ErrorAction SilentlyContinue
    
    if ($Result) {
        $AvgLatency = ($Result | Measure-Object -Property ResponseTime -Average).Average
        $Color = "Green"
        if ($AvgLatency -gt 80) { $Color = "Yellow" }
        if ($AvgLatency -gt 150) { $Color = "Red" }
        
        Write-Host "-> Average Ping: $([math]::Round($AvgLatency)) ms`n" -ForegroundColor $Color
    } else {
        Write-Host "-> Request Timed Out (Host may block ICMP)`n" -ForegroundColor DarkGray
    }
}

Write-Host "================================================="
Write-Host "NOTE: If all servers show high ping (>100ms) or drop packets,"
Write-Host "try running 'Reset_Network_Stack.ps1' or check your router."
Write-Host "================================================="
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
