"""
WinAurex CLI Python Entry Point
Dispatches commands directly to Core/CLI/WinAurex.CLI.ps1 via PowerShell.
"""

import os
import sys
import subprocess


def find_cli_script():
    """Locate WinAurex.CLI.ps1 in package or development root."""
    # 1. Bundled package mode (wheel / site-packages)
    pkg_dir = os.path.dirname(os.path.abspath(__file__))
    candidate = os.path.join(pkg_dir, "Core", "CLI", "WinAurex.CLI.ps1")
    if os.path.isfile(candidate):
        return candidate

    # 2. Repo root / editable install mode
    repo_root = os.path.dirname(pkg_dir)
    candidate = os.path.join(repo_root, "Core", "CLI", "WinAurex.CLI.ps1")
    if os.path.isfile(candidate):
        return candidate

    return None


def main():
    cli_script = find_cli_script()
    if not cli_script:
        print("[WinAurex Error] Unable to find Core/CLI/WinAurex.CLI.ps1.", file=sys.stderr)
        print("Please verify your WinAurex installation.", file=sys.stderr)
        sys.exit(1)

    # Form the PowerShell invocation
    args = [
        "powershell.exe",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        cli_script,
    ] + sys.argv[1:]

    try:
        ret = subprocess.call(args)
        sys.exit(ret)
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as exc:
        print(f"[WinAurex Error] Subprocess execution failed: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
