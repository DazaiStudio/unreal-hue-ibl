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

call :find_python
if not defined PY_BOOTSTRAP_EXE (
    echo Python 3 was not found. Trying to install Python automatically with winget...
    call :install_python
    call :find_python
)

if not defined PY_BOOTSTRAP_EXE goto missing_python

if not exist ".venv\Scripts\python.exe" (
    echo Creating local Python virtual environment...
    "%PY_BOOTSTRAP_EXE%" %PY_BOOTSTRAP_ARGS% -m venv .venv
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

:find_python
set "PY_BOOTSTRAP_EXE="
set "PY_BOOTSTRAP_ARGS="

where py >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set "PY_BOOTSTRAP_EXE=py"
    set "PY_BOOTSTRAP_ARGS=-3"
    exit /b 0
)

where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    set "PY_BOOTSTRAP_EXE=python"
    exit /b 0
)

if exist "%LocalAppData%\Programs\Python\Python313\python.exe" (
    set "PY_BOOTSTRAP_EXE=%LocalAppData%\Programs\Python\Python313\python.exe"
    exit /b 0
)

if exist "%LocalAppData%\Programs\Python\Python312\python.exe" (
    set "PY_BOOTSTRAP_EXE=%LocalAppData%\Programs\Python\Python312\python.exe"
    exit /b 0
)

if exist "%LocalAppData%\Programs\Python\Python311\python.exe" (
    set "PY_BOOTSTRAP_EXE=%LocalAppData%\Programs\Python\Python311\python.exe"
    exit /b 0
)

exit /b 1

:install_python
where winget >nul 2>nul
if errorlevel 1 (
    echo winget was not found, so Python cannot be installed automatically.
    exit /b 1
)

echo Installing Python 3.12 for the current Windows user...
winget install -e --id Python.Python.3.12 --scope user --accept-package-agreements --accept-source-agreements
if not errorlevel 1 exit /b 0

echo Python 3.12 install failed. Trying Python 3.13...
winget install -e --id Python.Python.3.13 --scope user --accept-package-agreements --accept-source-agreements
exit /b %ERRORLEVEL%
