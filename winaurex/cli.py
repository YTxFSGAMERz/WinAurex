"""
WinAurex CLI Python Entry Point
Dispatches commands directly to Core/CLI/WinAurex.CLI.ps1 via PowerShell,
or executes the native pure-Python engine when --python or -py is specified.
"""

import os
import sys
import subprocess


def find_cli_script():
    """Locate WinAurex.CLI.ps1 in package or development root."""
    pkg_dir = os.path.dirname(os.path.abspath(__file__))
    candidate = os.path.join(pkg_dir, "Core", "CLI", "WinAurex.CLI.ps1")
    if os.path.isfile(candidate):
        return candidate

    repo_root = os.path.dirname(pkg_dir)
    candidate = os.path.join(repo_root, "Core", "CLI", "WinAurex.CLI.ps1")
    if os.path.isfile(candidate):
        return candidate

    return None


def main():
    # Check if --python or -py flag is requested
    python_flags = {"--python", "-py"}
    args = sys.argv[1:]
    if any(flag in args for flag in python_flags):
        filtered_args = [a for a in args if a not in python_flags]
        sys.argv = [sys.argv[0]] + filtered_args
        
        # Import and run winaurex_py orchestrator
        try:
            from winaurex_py.main import main as py_main
            py_main()
            return
        except ImportError:
            # Fallback path resolution
            repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            if repo_root not in sys.path:
                sys.path.insert(0, repo_root)
            from winaurex_py.main import main as py_main
            py_main()
            return

    cli_script = find_cli_script()
    if not cli_script:
        # Fallback to pure python engine if PowerShell CLI script is missing
        print("[WinAurex Notice] Core/CLI/WinAurex.CLI.ps1 not found. Delegating to native Python engine...")
        from winaurex_py.main import main as py_main
        py_main()
        return

    # Form the PowerShell invocation
    ps_args = [
        "powershell.exe",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        cli_script,
    ] + args

    try:
        ret = subprocess.call(ps_args)
        sys.exit(ret)
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as exc:
        print(f"[WinAurex Error] Subprocess execution failed: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
