"""
Appearance Tweaks for Windows.
Toggles Dark/Light mode and transparency effects natively using winreg.
"""

from typing import Dict, Any
from ..core.registry import set_reg_value, get_reg_value
from ..core.rollback import session_rollback

PERSONALIZE_KEY = r"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

def set_dark_mode(enabled: bool = True) -> Dict[str, Any]:
    """
    Sets Windows System and App themes to Dark (1 = Light, 0 = Dark).
    """
    val = 0 if enabled else 1
    # AppsUseLightTheme: 0 = Dark, 1 = Light
    r1 = set_reg_value("HKCU", PERSONALIZE_KEY, "AppsUseLightTheme", val)
    session_rollback.record_action(r1)

    # SystemUsesLightTheme: 0 = Dark, 1 = Light
    r2 = set_reg_value("HKCU", PERSONALIZE_KEY, "SystemUsesLightTheme", val)
    session_rollback.record_action(r2)

    return {
        "success": r1.get("success", False) and r2.get("success", False),
        "applied": "Dark Mode" if enabled else "Light Mode"
    }

def set_transparency(enabled: bool = True) -> Dict[str, Any]:
    """
    Enables or disables visual transparency effects.
    Disabling transparency reduces GPU/DWM load on lower-end systems.
    """
    val = 1 if enabled else 0
    res = set_reg_value("HKCU", PERSONALIZE_KEY, "EnableTransparency", val)
    session_rollback.record_action(res)
    return {
        "success": res.get("success", False),
        "applied": f"Transparency {'Enabled' if enabled else 'Disabled'}"
    }

def get_appearance_status() -> Dict[str, Any]:
    """Checks current appearance configuration."""
    apps_light = get_reg_value("HKCU", PERSONALIZE_KEY, "AppsUseLightTheme")
    sys_light = get_reg_value("HKCU", PERSONALIZE_KEY, "SystemUsesLightTheme")
    transp = get_reg_value("HKCU", PERSONALIZE_KEY, "EnableTransparency")

    return {
        "dark_mode": apps_light[0] == 0 if apps_light else False,
        "transparency": transp[0] == 1 if transp else True
    }
