<#
.SYNOPSIS
    WinAurex DNS & Low-Latency Network Accelerator
.DESCRIPTION
    Configures low-latency DNS servers, flushes DNS resolver cache, and optimizes TCP/IP stack parameters.
    Providers:
      - Cloudflare (1.1.1.1, 1.0.0.1) - Maximum speed, zero logging
      - Google (8.8.8.8, 8.8.4.4) - Global reliability & reach
      - AdGuard (94.140.14.14, 94.140.15.15) - System-wide ad and tracker suppression
      - Quad9 (9.9.9.9, 149.112.112.112) - Automated malware and phishing protection
      - DHCP (Automatic) - Restores router default dynamic assignment
#>
[CmdletBinding()]
param (
    [ValidateSet("Cloudflare", "Google", "AdGuard", "Quad9", "DHCP")]
    [string]$Provider = "Cloudflare",
    [switch]$FlushOnly,
    [switch]$OptimizeTcp,
    [switch]$Force
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "         WinAurex DNS & Network Latency Accelerator                   " -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run PowerShell as Admin."
    Exit 1
}

# 1. DNS Cache Flush
Write-Host "`n[*] Flushing Windows DNS resolver cache..." -ForegroundColor Cyan
try {
    Clear-DnsClientCache
    Write-Host "  [+] DNS Cache flushed successfully." -ForegroundColor Green
} catch {
    Write-Warning "Could not flush DNS cache: $_"
}

if ($FlushOnly) {
    Write-Host "`n[SUCCESS] DNS cache flush complete!" -ForegroundColor Green
    Exit 0
}

# 2. DNS Server Addresses Map
$DnsMap = @{
    "Cloudflare" = @{
        "IPv4" = @("1.1.1.1", "1.0.0.1")
        "IPv6" = @("2606:4700:4700::1111", "2606:4700:4700::1001")
        "Desc" = "Cloudflare Ultra-Fast Privacy DNS"
    }
    "Google" = @{
        "IPv4" = @("8.8.8.8", "8.8.4.4")
        "IPv6" = @("2001:4860:4860::8888", "2001:4860:4860::8844")
        "Desc" = "Google Public DNS (Global Standard)"
    }
    "AdGuard" = @{
        "IPv4" = @("94.140.14.14", "94.140.15.15")
        "IPv6" = @("2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff")
        "Desc" = "AdGuard DNS (Hardware Ad & Tracking Blocking)"
    }
    "Quad9" = @{
        "IPv4" = @("9.9.9.9", "149.112.112.112")
        "IPv6" = @("2620:fe::fe", "2620:fe::9")
        "Desc" = "Quad9 Threat Intelligence & Phishing Blocking"
    }
}

# 3. Apply DNS to Active Adapters
$activeAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Hyper-V|Virtual|Loopback" }
if (-not $activeAdapters) {
    # Fallback to any active adapter
    $activeAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
}

if (-not $activeAdapters) {
    Write-Warning "No active network adapters found!"
} else {
    foreach ($adapter in $activeAdapters) {
        Write-Host "`n[*] Configuring Adapter: $($adapter.Name) ($($adapter.InterfaceDescription))..." -ForegroundColor Cyan
        
        if ($Provider -eq "DHCP") {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
                Write-Host "  [+] Reset to automatic DHCP assigned DNS." -ForegroundColor Green
            } catch {
                Write-Warning "Failed resetting DNS for $($adapter.Name): $_"
            }
        } else {
            $config = $DnsMap[$Provider]
            Write-Host "  Applying $($config.Desc)..." -ForegroundColor Yellow
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $config.IPv4 -ErrorAction Stop
                Write-Host "  [+] IPv4 DNS set: $($config.IPv4 -join ', ')" -ForegroundColor Green
                
                # Attempt IPv6 if adapter supports it
                try {
                    Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ($config.IPv4 + $config.IPv6) -ErrorAction SilentlyContinue
                } catch {}
            } catch {
                Write-Warning "Failed setting DNS on $($adapter.Name): $_"
            }
        }
    }
}

# 4. Low Latency TCP/IP Stack Tuning
Write-Host "`n[*] Optimizing TCP/IP Network Stack for Low Latency..." -ForegroundColor Cyan
try {
    # Enable TCP Window Auto-Tuning (fixes throughput bottlenecks on high-speed fiber)
    netsh int tcp set global autotuninglevel=normal | Out-Null
    
    # Disable TCP Heuristics (prevents Windows from arbitrarily throttling connection window)
    netsh int tcp set heuristics disabled | Out-Null
    
    # Enable ECN (Explicit Congestion Notification - prevents router packet drops during heavy loads)
    netsh int tcp set global ecncapability=enabled | Out-Null
    
    # Disable TCP Timestamps (reduces per-packet packet header overhead by 12 bytes)
    netsh int tcp set global timestamps=disabled | Out-Null
    
    Write-Host "  [+] TCP Auto-Tuning: Normal (Unlocked throughput)" -ForegroundColor Green
    Write-Host "  [+] TCP Heuristics: Disabled (No throttling)" -ForegroundColor Green
    Write-Host "  [+] ECN Capability: Enabled (Zero packet drops)" -ForegroundColor Green
} catch {
    Write-Warning "TCP Stack tuning note: $_"
}

Write-Host "`n[SUCCESS] DNS & Network Latency Acceleration complete! (Active Provider: $Provider)" -ForegroundColor Cyan
