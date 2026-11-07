"""
Windows Power Plan & Performance Profile Management.
Enables and activates the Windows Ultimate Performance power scheme,
preventing CPU frequency downclocking and core parking during intensive tasks.
"""

import subprocess
import re
from typing import Dict, Any, Optional

def get_active_power_scheme() -> Dict[str, Any]:
    """Queries current active Windows power plan."""
    try:
        proc = subprocess.run(["powercfg", "/getactivescheme"], capture_output=True, text=True, timeout=10)
        out = proc.stdout.strip()
        # Example output: Power Scheme GUID: 381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced)
        match = re.search(r"GUID:\s*([a-f0-9\-]+)\s*\((.*?)\)", out, re.IGNORECASE)
        if match:
            return {"guid": match.group(1), "name": match.group(2)}
        return {"guid": "", "name": out}
    except Exception:
        return {"guid": "", "name": "Unknown"}

def enable_ultimate_performance() -> Dict[str, Any]:
    """
    Unlocks and activates the Ultimate Performance power plan.
    Fallback to High Performance if Ultimate Performance is unavailable on hardware.
    """
    # Ultimate Performance Template GUID: e9a42b02-d5df-448d-aa00-03f14749eb61
    # High Performance Template GUID: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    try:
        # Duplicate scheme
        proc = subprocess.run(
            ["powercfg", "-duplicatescheme", "e9a42b02-d5df-448d-aa00-03f14749eb61"],
            capture_output=True,
            text=True,
            timeout=10
        )
        match = re.search(r"([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})", proc.stdout, re.IGNORECASE)
        new_guid = match.group(1) if match else None

        if not new_guid:
            # Fallback to High Performance
            proc = subprocess.run(
                ["powercfg", "-duplicatescheme", "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"],
                capture_output=True,
                text=True,
                timeout=10
            )
            match = re.search(r"([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})", proc.stdout, re.IGNORECASE)
            new_guid = match.group(1) if match else None

        if new_guid:
            # Set active
            subprocess.run(["powercfg", "/setactive", new_guid], capture_output=True, timeout=10)
            active = get_active_power_scheme()
            return {
                "success": True,
                "guid": new_guid,
                "scheme": active.get("name", "Ultimate Performance"),
                "tweak": f"Active Plan Set to: {active.get('name')}"
            }
        else:
            return {
                "success": False,
                "error": "Could not unlock power scheme",
                "tweak": "Power Scheme Activation Failed"
            }
    except Exception as e:
        return {"success": False, "error": str(e)}

def disable_sleep_timeouts(ac_only: bool = True) -> Dict[str, Any]:
    """Sets sleep timeout to 0 (never sleep when plugged in)."""
    try:
        subprocess.run(["powercfg", "/change", "standby-timeout-ac", "0"], capture_output=True, timeout=10)
        return {"success": True, "tweak": "System Standby Timeout (AC) set to Never"}
    except Exception as e:
        return {"success": False, "error": str(e)}
