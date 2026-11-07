"""
Windows Debloat & Background Service Reducer.
Disables sponsored app suggestions, Start menu Bing integration,
and stops background telemetry services (DiagTrack, dmwappushservice).
"""

import subprocess
import winreg
from typing import Dict, Any, List
from ..core.registry import set_reg_value
from ..core.rollback import session_rollback

DEBLOAT_POLICIES = [
    # Disable Windows Consumer Features (Auto-install promo apps)
    {
        "root": "HKLM",
        "subkey": r"SOFTWARE\Policies\Microsoft\Windows\CloudContent",
        "name": "DisableWindowsConsumerFeatures",
        "value": 1,
        "type": winreg.REG_DWORD,
        "desc": "Disable Silent Sponsored App Installs"
    },
    # Disable Bing Search in Start Menu
    {
        "root": "HKCU",
        "subkey": r"Software\Policies\Microsoft\Windows\Explorer",
        "name": "DisableSearchBoxSuggestions",
        "value": 1,
        "type": winreg.REG_DWORD,
        "desc": "Disable Start Menu Bing Search Suggestions"
    },
    {
        "root": "HKCU",
        "subkey": r"Software\Microsoft\Windows\CurrentVersion\Search",
        "name": "BingSearchEnabled",
        "value": 0,
        "type": winreg.REG_DWORD,
        "desc": "Disable Bing Search Integration"
    },
    {
        "root": "HKCU",
        "subkey": r"Software\Microsoft\Windows\CurrentVersion\Search",
        "name": "CortanaConsent",
        "value": 0,
        "type": winreg.REG_DWORD,
        "desc": "Disable Cortana Assistant Integration"
    },
    # Disable Windows Tips & Recommendations
    {
        "root": "HKCU",
        "subkey": r"Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
        "name": "SoftLandingEnabled",
        "value": 0,
        "type": winreg.REG_DWORD,
        "desc": "Disable Windows Welcome Tips"
    },
    {
        "root": "HKCU",
        "subkey": r"Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager",
        "name": "SubscribedContent-338389Enabled",
        "value": 0,
        "type": winreg.REG_DWORD,
        "desc": "Disable Lockscreen Tips and Ads"
    }
]

def disable_telemetry_services() -> Dict[str, Any]:
    """Stops and disables Windows background telemetry services."""
    services = ["DiagTrack", "dmwappushservice"]
    results = {}

    for s in services:
        try:
            # Set service to disabled
            p1 = subprocess.run(["sc", "config", s, "start=", "disabled"], capture_output=True, text=True, timeout=10)
            # Stop the service if running
            p2 = subprocess.run(["sc", "stop", s], capture_output=True, text=True, timeout=10)
            results[s] = (p1.returncode == 0)
        except Exception:
            results[s] = False

    return {
        "success": any(results.values()),
        "services": results,
        "tweak": "Background Telemetry Services Disabled"
    }

def apply_all_debloat_tweaks() -> Dict[str, Any]:
    """Applies debloat registry rules and disables telemetry services."""
    results = []
    for item in DEBLOAT_POLICIES:
        res = set_reg_value(item["root"], item["subkey"], item["name"], item["value"], item["type"])
        session_rollback.record_action(res)
        results.append({"name": item["desc"], "success": res.get("success", False)})

    svc_res = disable_telemetry_services()
    results.append({"name": svc_res["tweak"], "success": svc_res["success"]})

    success_count = sum(1 for r in results if r["success"])
    return {
        "applied_count": success_count,
        "total": len(results),
        "details": results
    }
