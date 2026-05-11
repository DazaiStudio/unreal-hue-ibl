@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%run_hue_artnet_bridge.ps1"

if not exist "%PS_SCRIPT%" (
    echo Missing run_hue_artnet_bridge.ps1.
    echo Make sure this file is inside a complete bridge folder.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "EXIT_CODE=%ERRORLEVEL%"

pause
exit /b %EXIT_CODE%
