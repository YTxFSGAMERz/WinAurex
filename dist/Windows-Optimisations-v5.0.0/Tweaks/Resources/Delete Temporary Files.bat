@echo off

:: BatchGotAdmin
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"="""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0" 

del /S /F /Q "%temp%"
del /S /F /Q "%WINDIR%\Temp\*.*"
del /S /F /Q "%WINDIR%\Prefetch\*.*"
del /S /F /Q "%WINDIR%\logs\cbs\*.log"
del /S /F /Q "%WINDIR%\Logs\MoSetup\*.log"
del /S /F /Q "%WINDIR%\Panther\*.log"
del /S /F /Q "%WINDIR%\inf\*.log"
del /S /F /Q "%WINDIR%\logs\*.log"
del /S /F /Q "%WINDIR%\SoftwareDistribution\*.log"
del /S /F /Q "%WINDIR%\Microsoft.NET\*.log"
del /S /F /Q "%SystemDrive%\Users\%USERNAME%\AppData\Local\Microsoft\Windows\WebCache\*.log"
del /S /F /Q "%SystemDrive%\Users\%USERNAME%\AppData\Local\Microsoft\Windows\SettingSync\*.log"
del /S /F /Q "%SystemDrive%\Users\%USERNAME%\AppData\Local\Microsoft\Windows\Explorer\ThumbCacheToDelete\*.tmp"
del /S /F /Q "%SystemDrive%\Users\%USERNAME%\AppData\Local\Microsoft\Terminal Server Client\Cache\*.bin"
net stop wuauserv
net stop UsoSvc
del /S /F /Q "%WINDIR%\SoftwareDistribution"
timeout /t 5 /nobreak
