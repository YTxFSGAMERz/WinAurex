@echo off
setlocal EnableDelayedExpansion
title WinAurex Python Engine

:: Set working directory to script location
cd /d "%~dp0"

:: -----------------------------------------------------------
:: Check for Administrative Privileges & Auto-Elevate
:: -----------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WinAurex] Requesting Administrator Privileges via Windows UAC...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\" %*\"' -Verb RunAs" 2>nul
    if %errorlevel% equ 0 (
        exit /b 0
    )
    :: Fallback to VBScript elevation if PowerShell is restricted
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\winaurex_elevate.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c """"%~f0"""" %*", "", "runas", 1 >> "%temp%\winaurex_elevate.vbs"
    cscript //nologo "%temp%\winaurex_elevate.vbs" >nul 2>&1
    del "%temp%\winaurex_elevate.vbs" 2>nul
    exit /b 0
)

:: -----------------------------------------------------------
:: Detect Python Runtime
:: -----------------------------------------------------------
set "PYTHON_EXE="

where python >nul 2>&1
if %errorlevel% equ 0 (
    set "PYTHON_EXE=python"
) else (
    where py >nul 2>&1
    if %errorlevel% equ 0 (
        set "PYTHON_EXE=py"
    )
)

if not defined PYTHON_EXE (
    if exist "C:\Python313\python.exe" (
        set "PYTHON_EXE=C:\Python313\python.exe"
    ) else if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" (
        set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    ) else if exist "%ProgramFiles%\Python313\python.exe" (
        set "PYTHON_EXE=%ProgramFiles%\Python313\python.exe"
    ) else if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
        set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    )
)

if not defined PYTHON_EXE (
    echo.
    echo ==========================================================================
    echo [!] Python 3.10+ was not found on this system.
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add python.exe to PATH" during installation.
    echo ==========================================================================
    echo.
    pause
    exit /b 1
)

:: -----------------------------------------------------------
:: Launch WinAurex Python Engine
:: -----------------------------------------------------------
"%PYTHON_EXE%" "%~dp0winaurex_py\main.py" %*
if %errorlevel% neq 0 (
    echo.
    echo [!] WinAurex finished with exit code %errorlevel%.
    pause
)
