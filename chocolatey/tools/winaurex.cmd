@echo off
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

set "USE_PYTHON="
for %%A in (%*) do (
    if /i "%%A"=="--python" set "USE_PYTHON=1"
    if /i "%%A"=="-py" set "USE_PYTHON=1"
)

if defined USE_PYTHON (
    set "PY_ARGS="
    for %%A in (%*) do (
        if /i not "%%A"=="--python" if /i not "%%A"=="-py" (
            set "PY_ARGS=!PY_ARGS! %%A"
        )
    )
    if exist "%SCRIPT_DIR%app\winaurex_py\main.py" (
        python "%SCRIPT_DIR%app\winaurex_py\main.py" !PY_ARGS!
        exit /b !errorlevel!
    ) else if exist "%SCRIPT_DIR%..\..\..\winaurex_py\main.py" (
        python "%SCRIPT_DIR%..\..\..\winaurex_py\main.py" !PY_ARGS!
        exit /b !errorlevel!
    )
)

if exist "%SCRIPT_DIR%app\Core\CLI\WinAurex.CLI.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%app\Core\CLI\WinAurex.CLI.ps1" %*
) else if exist "%SCRIPT_DIR%..\..\..\Core\CLI\WinAurex.CLI.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%..\..\..\Core\CLI\WinAurex.CLI.ps1" %*
) else (
    echo [WinAurex Error] Cannot find WinAurex.CLI.ps1
    exit /b 1
)
exit /b %ERRORLEVEL%
