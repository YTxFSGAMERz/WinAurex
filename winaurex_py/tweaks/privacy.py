"""
Privacy & Anti-Telemetry Tweaks for Windows.
Disables diagnostic tracking, advertising ID, activity history, and cloud tailored experiences.
"""

from typing import Dict, Any, List
from ..core.registry import set_reg_value, get_reg_value
from ..core.rollback import session_rollback

PRIVACY_POLICIES = [
    # Disable Windows Telemetry
    {
        "root": "HKLM",
        "subkey": r"SOFTWARE\Policies\Microsoft\Windows\DataCollection",
        "name": "AllowTelemetry",
        "value": 0,
        "desc": "Disable Diagnostic Telemetry Collection"
    },
    # Disable Advertising ID
    {
        "root": "HKCU",
        "subkey": r"Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo",
        "name": "Enabled",
        "value": 0,
        "desc": "Disable Personalized Advertising ID"
    },
    # Disable Activity Feed & User History Uploads
    {
        "root": "HKLM",
        "subkey": r"SOFTWARE\Policies\Microsoft\Windows\System",
        "name": "EnableActivityFeed",
        "value": 0,
        "desc": "Disable Timeline Activity Feed"
    },
    {
        "root": "HKLM",
        "subkey": r"SOFTWARE\Policies\Microsoft\Windows\System",
        "name": "PublishUserActivities",
        "value": 0,
        "desc": "Disable Publishing User Activities"
    },
    {
        "root": "HKLM",
        "subkey": r"SOFTWARE\Policies\Microsoft\Windows\System",
        "name": "UploadUserActivities",
        "value": 0,
        "desc": "Disable Cloud Activity Synchronization"
    },
    # Disable Tailored Experiences with Diagnostic Data
    {
        "root": "HKCU",
        "subkey": r"Software\Policies\Microsoft\Windows\CloudContent",
        "name": "DisableTailoredExperiencesWithDiagnosticData",
        "value": 1,
        "desc": "Disable Tailored Diagnostic Experiences"
    },
    # Disable Location Sensor tracking
    {
        "root": "HKLM",
        "subkey": r"SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors",
        "name": "DisableLocation",
        "value": 1,
        "desc": "Disable Background Location Tracking"
    }
]

def apply_privacy_shield() -> Dict[str, Any]:
    """Applies all privacy hardening policies and logs changes for rollback."""
    results = {
        "success_count": 0,
        "failed_count": 0,
        "details": []
    }

    for item in PRIVACY_POLICIES:
        res = set_reg_value(item["root"], item["subkey"], item["name"], item["value"])
        session_rollback.record_action(res)
        if res.get("success"):
            results["success_count"] += 1
            results["details"].append({"name": item["desc"], "status": "Applied"})
        else:
            results["failed_count"] += 1
            results["details"].append({"name": item["desc"], "status": f"Failed: {res.get('error')}"})

    return results

def get_privacy_status() -> Dict[str, Any]:
    """Checks whether privacy policies are currently active."""
    telemetry = get_reg_value("HKLM", r"SOFTWARE\Policies\Microsoft\Windows\DataCollection", "AllowTelemetry")
    ad_id = get_reg_value("HKCU", r"Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo", "Enabled")
    activity = get_reg_value("HKLM", r"SOFTWARE\Policies\Microsoft\Windows\System", "EnableActivityFeed")

    return {
        "telemetry_disabled": telemetry[0] == 0 if telemetry else False,
        "ad_id_disabled": ad_id[0] == 0 if ad_id else False,
        "activity_feed_disabled": activity[0] == 0 if activity else False
    }
