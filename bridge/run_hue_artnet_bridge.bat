@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%" || (
    echo Could not open the bridge script folder:
    echo %SCRIPT_DIR%
    pause
    exit /b 1
)

if not exist "hue_artnet_bridge.py" goto missing_files
if not exist "setup_config.py" goto missing_files
if not exist "requirements.txt" goto missing_files
if not exist "config.example.json" goto missing_files

set "PY_BOOTSTRAP="
where py >nul 2>nul
if %ERRORLEVEL% EQU 0 set "PY_BOOTSTRAP=py -3"

if not defined PY_BOOTSTRAP (
    where python >nul 2>nul
    if %ERRORLEVEL% EQU 0 set "PY_BOOTSTRAP=python"
)

if not defined PY_BOOTSTRAP goto missing_python

if not exist ".venv\Scripts\python.exe" (
    echo Creating local Python virtual environment...
    %PY_BOOTSTRAP% -m venv .venv
    if errorlevel 1 goto venv_failed
)

set "PYTHON_EXE=%CD%\.venv\Scripts\python.exe"

echo Installing Python dependencies...
"%PYTHON_EXE%" -m pip install -r requirements.txt
if errorlevel 1 goto install_failed

if not exist "config.json" (
    echo.
    echo config.json was not found. Starting first-time setup.
    "%PYTHON_EXE%" setup_config.py
    if errorlevel 1 goto setup_failed
)

"%PYTHON_EXE%" setup_config.py --check >nul 2>nul
if errorlevel 1 (
    echo.
    echo config.json still has missing or placeholder Hue values. Starting setup.
    "%PYTHON_EXE%" setup_config.py
    if errorlevel 1 goto setup_failed
)

"%PYTHON_EXE%" -X utf8 hue_artnet_bridge.py --config config.json
pause
exit /b %ERRORLEVEL%

:missing_files
echo This launcher must be run from the bridge folder in a complete repo checkout.
echo Current folder:
echo %CD%
pause
exit /b 1

:missing_python
echo Python 3 was not found.
echo Install Python 3 from https://www.python.org/downloads/
echo During install, enable "Add python.exe to PATH".
pause
exit /b 1

:venv_failed
echo Failed to create the local Python virtual environment.
pause
exit /b 1

:install_failed
echo Failed to install Python dependencies from requirements.txt.
pause
exit /b 1

:setup_failed
echo Failed to create bridge\config.json.
pause
exit /b 1
