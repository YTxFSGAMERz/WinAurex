"""
Elevation and UAC helper for WinAurex Python Engine.
Checks and handles administrator privileges natively via ctypes without PowerShell.
"""

import sys
import os
import ctypes
import time
from .colors import c_cyan, c_green, c_yellow, c_red, c_gray, print_info, print_success, print_warning, print_error

def is_admin() -> bool:
    """Returns True if the current process is running with administrative privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False

def get_main_script() -> str:
    """Locates the absolute path to winaurex_py/main.py."""
    core_dir = os.path.dirname(os.path.abspath(__file__))
    main_py = os.path.abspath(os.path.join(core_dir, "..", "main.py"))
    return main_py

def get_project_root() -> str:
    """Returns the project repository root directory."""
    core_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(core_dir, "..", ".."))

def elevate_and_exit(pause_on_cancel: bool = True) -> bool:
    """
    Relaunches winaurex_py with elevated administrative permissions via Windows UAC prompt.
    Terminates the non-elevated process if elevation is accepted.
    Returns False if cancelled or denied.
    """
    if is_admin():
        return True

    main_script = get_main_script()
    project_root = get_project_root()

    # Forward any arguments excluding elevation/python wrapper flags
    raw_args = sys.argv[1:] if len(sys.argv) > 1 else []
    forward_args = [arg for arg in raw_args if arg not in ("--elevate", "-e", "--python", "-py")]

    # Build command line parameters for python.exe
    # Format: "C:\path\to\winaurex_py\main.py" <forward_args>
    params = f'"{main_script}"'
    if forward_args:
        params += " " + " ".join([f'"{arg}"' for arg in forward_args])

    print_info("Requesting Administrator privileges via Windows UAC prompt...")

    try:
        # ShellExecuteW: hwnd, operation ("runas"), file, parameters, directory, show_cmd (1=SW_SHOWNORMAL)
        ret = ctypes.windll.shell32.ShellExecuteW(
            None,
            "runas",
            sys.executable,
            params.strip(),
            project_root,
            1
        )
        # ShellExecute returns an HINSTANCE > 32 on success
        if ret > 32:
            print_success("Elevation granted! A new elevated Administrator console has opened.")
            print(c_gray("  Closing non-elevated session in 1 second..."))
            time.sleep(1.2)
            sys.exit(0)
        else:
            # Code 5 = ERROR_ACCESS_DENIED (user clicked 'No' on UAC prompt)
            print_warning("Elevation was cancelled or declined by user.")
            return False
    except Exception as e:
        print_error(f"Elevation request encountered an error: {e}")
        return False

def require_admin(prompt_if_not: bool = True) -> bool:
    """
    Ensures administrator privileges. If not admin and prompt_if_not is True,
    prompts user to elevate.
    """
    if is_admin():
        return True
    if prompt_if_not:
        return elevate_and_exit()
    return False
