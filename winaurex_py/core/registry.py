"""
Native Windows Registry Manipulation Module.
Interacts directly with Windows Registry using Python's winreg (C Win32 API),
avoiding PowerShell AMSI script inspection and execution policy restrictions.
"""

import winreg
from typing import Any, Tuple, Optional, Dict

ROOT_KEYS = {
    "HKCU": winreg.HKEY_CURRENT_USER,
    "HKEY_CURRENT_USER": winreg.HKEY_CURRENT_USER,
    "HKLM": winreg.HKEY_LOCAL_MACHINE,
    "HKEY_LOCAL_MACHINE": winreg.HKEY_LOCAL_MACHINE,
    "HKCR": winreg.HKEY_CLASSES_ROOT,
    "HKEY_CLASSES_ROOT": winreg.HKEY_CLASSES_ROOT,
    "HKU": winreg.HKEY_USERS,
    "HKEY_USERS": winreg.HKEY_USERS
}

def resolve_root(root: Any) -> int:
    """Converts string root identifier into winreg HKEY constant."""
    if isinstance(root, int):
        return root
    if isinstance(root, str):
        root_upper = root.upper().strip()
        if root_upper in ROOT_KEYS:
            return ROOT_KEYS[root_upper]
    raise ValueError(f"Invalid registry root key: {root}")

def get_reg_value(root: Any, subkey: str, value_name: str) -> Optional[Tuple[Any, int]]:
    """
    Reads a value from registry.
    Returns (value, type) tuple or None if does not exist.
    """
    h_root = resolve_root(root)
    try:
        with winreg.OpenKey(h_root, subkey, 0, winreg.KEY_READ) as key:
            val, reg_type = winreg.QueryValueEx(key, value_name)
            return val, reg_type
    except FileNotFoundError:
        return None
    except PermissionError:
        return None
    except Exception:
        return None

def set_reg_value(root: Any, subkey: str, value_name: str, value: Any, reg_type: Optional[int] = None) -> Dict[str, Any]:
    """
    Sets a registry value. Creates the subkey if it does not exist.
    Returns a dict with state before modification for rollback recording:
    {
        "existed": bool,
        "previous_value": Any,
        "previous_type": int or None,
        "success": bool,
        "error": str or None
    }
    """
    h_root = resolve_root(root)
    
    # Check prior state
    prev = get_reg_value(root, subkey, value_name)
    result = {
        "root": "HKLM" if h_root == winreg.HKEY_LOCAL_MACHINE else "HKCU",
        "subkey": subkey,
        "value_name": value_name,
        "existed": prev is not None,
        "previous_value": prev[0] if prev else None,
        "previous_type": prev[1] if prev else None,
        "success": False,
        "error": None
    }

    # Infer reg_type if not provided
    if reg_type is None:
        if isinstance(value, int):
            reg_type = winreg.REG_DWORD
        elif isinstance(value, str):
            reg_type = winreg.REG_SZ
        elif isinstance(value, bytes):
            reg_type = winreg.REG_BINARY
        elif isinstance(value, list):
            reg_type = winreg.REG_MULTI_SZ
        else:
            reg_type = winreg.REG_SZ

    try:
        with winreg.CreateKeyEx(h_root, subkey, 0, winreg.KEY_WRITE) as key:
            winreg.SetValueEx(key, value_name, 0, reg_type, value)
            result["success"] = True
    except PermissionError as pe:
        result["error"] = f"Access Denied (Requires Admin): {pe}"
    except Exception as e:
        result["error"] = str(e)

    return result

def delete_reg_value(root: Any, subkey: str, value_name: str) -> Dict[str, Any]:
    """
    Deletes a registry value.
    Returns state before deletion for rollback.
    """
    h_root = resolve_root(root)
    prev = get_reg_value(root, subkey, value_name)
    result = {
        "root": "HKLM" if h_root == winreg.HKEY_LOCAL_MACHINE else "HKCU",
        "subkey": subkey,
        "value_name": value_name,
        "existed": prev is not None,
        "previous_value": prev[0] if prev else None,
        "previous_type": prev[1] if prev else None,
        "success": False,
        "error": None
    }

    if not prev:
        result["success"] = True
        return result

    try:
        with winreg.OpenKey(h_root, subkey, 0, winreg.KEY_WRITE) as key:
            winreg.DeleteValue(key, value_name)
            result["success"] = True
    except FileNotFoundError:
        result["success"] = True
    except PermissionError as pe:
        result["error"] = f"Access Denied: {pe}"
    except Exception as e:
        result["error"] = str(e)

    return result
