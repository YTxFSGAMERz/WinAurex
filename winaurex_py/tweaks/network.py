"""
Network & Low-Latency TCP/IP Optimization Tweaks.
Disables multimedia network throttling, sets 100% system responsiveness for real-time traffic,
and provides native DNS and network stack flushing.
"""

import winreg
import subprocess
from typing import Dict, Any
from ..core.registry import set_reg_value, get_reg_value
from ..core.rollback import session_rollback

MULTIMEDIA_KEY = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"

def optimize_network_throttling() -> Dict[str, Any]:
    """
    Disables network packet throttling during non-multimedia tasks (0xFFFFFFFF = disabled).
    Reduces packet latency and network jitter.
    """
    res = set_reg_value("HKLM", MULTIMEDIA_KEY, "NetworkThrottlingIndex", 0xFFFFFFFF, winreg.REG_DWORD)
    session_rollback.record_action(res)
    return {"success": res.get("success", False), "tweak": "Network Packet Throttling Disabled"}

def optimize_system_responsiveness() -> Dict[str, Any]:
    """
    Sets SystemResponsiveness to 0 (default is 20%).
    Ensures 100% of CPU time is prioritized for foreground applications and games.
    """
    res = set_reg_value("HKLM", MULTIMEDIA_KEY, "SystemResponsiveness", 0, winreg.REG_DWORD)
    session_rollback.record_action(res)
    return {"success": res.get("success", False), "tweak": "System Responsiveness Priority Set to 100%"}

def flush_dns() -> Dict[str, Any]:
    """Clears and resets the contents of the DNS client resolver cache."""
    try:
        proc = subprocess.run(["ipconfig", "/flushdns"], capture_output=True, text=True, timeout=10)
        return {
            "success": proc.returncode == 0,
            "output": proc.stdout.strip(),
            "tweak": "DNS Resolver Cache Flushed"
        }
    except Exception as e:
        return {"success": False, "error": str(e), "tweak": "DNS Cache Flush Failed"}

def reset_network_stack() -> Dict[str, Any]:
    """Resets Winsock catalog and TCP/IP stack to clean defaults."""
    results = []
    try:
        r1 = subprocess.run(["netsh", "winsock", "reset"], capture_output=True, text=True, timeout=10)
        r2 = subprocess.run(["netsh", "int", "ip", "reset"], capture_output=True, text=True, timeout=10)
        return {
            "success": r1.returncode == 0 and r2.returncode == 0,
            "tweak": "Winsock Catalog & TCP/IP Stack Reset"
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

def apply_all_network_tweaks() -> Dict[str, Any]:
    """Applies network performance registry optimizations and flushes DNS."""
    r1 = optimize_network_throttling()
    r2 = optimize_system_responsiveness()
    r3 = flush_dns()
    return {
        "applied_count": sum(1 for r in [r1, r2, r3] if r.get("success")),
        "details": [r1, r2, r3]
    }
