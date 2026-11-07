@echo off
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

:: Check if user explicitly requested the Python engine
set "USE_PYTHON="
for %%A in (%*) do (
    if /i "%%A"=="--python" set "USE_PYTHON=1"
    if /i "%%A"=="-py" set "USE_PYTHON=1"
)

if defined USE_PYTHON (
    :: Collect arguments excluding --python / -py
    set "PY_ARGS="
    for %%A in (%*) do (
        if /i not "%%A"=="--python" if /i not "%%A"=="-py" (
            set "PY_ARGS=!PY_ARGS! %%A"
        )
    )
    where python >nul 2>&1
    if !errorlevel! equ 0 (
        python "%SCRIPT_DIR%winaurex_py\main.py" !PY_ARGS!
        exit /b !errorlevel!
    )
    where py >nul 2>&1
    if !errorlevel! equ 0 (
        py "%SCRIPT_DIR%winaurex_py\main.py" !PY_ARGS!
        exit /b !errorlevel!
    )
    echo [!] Python runtime not found in PATH. Please install Python 3.10+.
    exit /b 1
)

:: Otherwise invoke PowerShell CLI
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Core\CLI\WinAurex.CLI.ps1" %*
exit /b %ERRORLEVEL%
