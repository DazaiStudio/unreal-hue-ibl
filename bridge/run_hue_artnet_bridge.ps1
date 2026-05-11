param(
    [switch]$SkipLaunch,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message"
}

function Assert-RequiredFiles {
    $requiredFiles = @(
        "hue_artnet_bridge.py",
        "setup_config.py",
        "requirements.txt",
        "config.example.json"
    )

    foreach ($file in $requiredFiles) {
        if (-not (Test-Path -LiteralPath $file)) {
            throw "Missing required file: $file. Run this launcher from a complete repo checkout."
        }
    }
}

function Test-PythonCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @()
    )

    try {
        $allArgs = @()
        $allArgs += $Arguments
        $allArgs += @("-c", "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)")

        & $FilePath @allArgs *> $null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function New-PythonCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments = @()
    )

    [PSCustomObject]@{
        FilePath = $FilePath
        Arguments = $Arguments
    }
}

function Find-Python {
    $candidates = @(
        (New-PythonCommand -FilePath "py" -Arguments @("-3")),
        (New-PythonCommand -FilePath "python"),
        (New-PythonCommand -FilePath "python3")
    )

    foreach ($candidate in $candidates) {
        $command = Get-Command $candidate.FilePath -ErrorAction SilentlyContinue
        if ($command -and (Test-PythonCommand -FilePath $command.Source -Arguments $candidate.Arguments)) {
            return (New-PythonCommand -FilePath $command.Source -Arguments $candidate.Arguments)
        }
    }

    $searchRoots = @()
    if ($env:LocalAppData) {
        $searchRoots += (Join-Path $env:LocalAppData "Programs\Python")
    }
    if ($env:ProgramFiles) {
        $searchRoots += $env:ProgramFiles
    }
    if (${env:ProgramFiles(x86)}) {
        $searchRoots += ${env:ProgramFiles(x86)}
    }

    foreach ($root in $searchRoots) {
        if (-not (Test-Path -LiteralPath $root)) {
            continue
        }

        $matches = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "Python*" } |
            ForEach-Object { Join-Path $_.FullName "python.exe" } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Sort-Object -Descending

        foreach ($match in $matches) {
            if (Test-PythonCommand -FilePath $match) {
                return (New-PythonCommand -FilePath $match)
            }
        }
    }

    return $null
}

function Install-PythonWithWinget {
    $winget = Get-Command "winget" -ErrorAction SilentlyContinue
    if (-not $winget) {
        return $false
    }

    foreach ($packageId in @("Python.Python.3.12", "Python.Python.3.13")) {
        Write-Step "Installing $packageId with winget"
        $process = Start-Process `
            -FilePath "winget" `
            -ArgumentList @(
                "install",
                "-e",
                "--id",
                $packageId,
                "--scope",
                "user",
                "--accept-package-agreements",
                "--accept-source-agreements"
            ) `
            -NoNewWindow `
            -Wait `
            -PassThru

        if ($process.ExitCode -eq 0) {
            return $true
        }
    }

    return $false
}

function Get-PythonInstallerUrl {
    Write-Step "Finding a Python installer from python.org"

    $downloadPage = "https://www.python.org/downloads/windows/"
    $response = Invoke-WebRequest -Uri $downloadPage -UseBasicParsing
    $pattern = '(https://www\.python\.org)?/ftp/python/3\.(12|13)\.\d+/python-3\.(12|13)\.\d+-amd64\.exe'
    $matches = [regex]::Matches($response.Content, $pattern)

    if ($matches.Count -eq 0) {
        throw "Could not find a Python 3.12/3.13 Windows installer on python.org."
    }

    $url = $matches[0].Value
    if ($url.StartsWith("/")) {
        $url = "https://www.python.org$url"
    }

    return $url
}

function Install-PythonFromPythonOrg {
    $url = Get-PythonInstallerUrl
    $installerPath = Join-Path $env:TEMP "python-hue-bridge-installer.exe"

    Write-Step "Downloading Python installer"
    Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing

    Write-Step "Installing Python for the current user"
    $process = Start-Process `
        -FilePath $installerPath `
        -ArgumentList @(
            "/quiet",
            "InstallAllUsers=0",
            "PrependPath=1",
            "Include_launcher=1",
            "Include_pip=1",
            "Include_test=0"
        ) `
        -Wait `
        -PassThru

    return $process.ExitCode -eq 0
}

function Ensure-Python {
    $python = Find-Python
    if ($python) {
        return $python
    }

    Write-Step "Python 3 was not found"
    Write-Host "Trying automatic Python installation."

    $installed = Install-PythonWithWinget
    $python = Find-Python
    if ($installed -and $python) {
        return $python
    }

    try {
        $installed = Install-PythonFromPythonOrg
        $python = Find-Python
        if ($installed -and $python) {
            return $python
        }
    } catch {
        Write-Host $_.Exception.Message
    }

    throw "Python could not be installed automatically. Install Python 3 manually from https://www.python.org/downloads/ and run this launcher again."
}

function Invoke-Python {
    param(
        [object]$Python,
        [string[]]$Arguments
    )

    $allArgs = @()
    $allArgs += $Python.Arguments
    $allArgs += $Arguments

    & $Python.FilePath @allArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Python command failed: $($Python.FilePath) $($allArgs -join ' ')"
    }
}

function Test-VenvPython {
    $venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
    if (-not (Test-Path -LiteralPath $venvPython)) {
        return $false
    }

    return (Test-PythonCommand -FilePath $venvPython)
}

function Ensure-Venv {
    param([object]$Python)

    $venvPath = Join-Path $PSScriptRoot ".venv"
    $venvPython = Join-Path $venvPath "Scripts\python.exe"

    if (Test-VenvPython) {
        return $venvPython
    }

    if (Test-Path -LiteralPath $venvPath) {
        $backupPath = Join-Path $PSScriptRoot (".venv.broken-" + (Get-Date -Format "yyyyMMddHHmmss"))
        Write-Step "Existing virtual environment is incomplete"
        Write-Host "Renaming it to $backupPath"
        Rename-Item -LiteralPath $venvPath -NewName (Split-Path -Leaf $backupPath)
    }

    Write-Step "Creating local Python virtual environment"
    Invoke-Python -Python $Python -Arguments @("-m", "venv", ".venv")

    if (-not (Test-VenvPython)) {
        throw "The virtual environment was created, but its Python executable did not pass validation."
    }

    return $venvPython
}

function Ensure-Dependencies {
    param([string]$VenvPython)

    Write-Step "Preparing pip"
    & $VenvPython -m ensurepip --upgrade
    if ($LASTEXITCODE -ne 0) {
        throw "ensurepip failed."
    }

    & $VenvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        throw "pip upgrade failed. Check internet access."
    }

    Write-Step "Installing Python dependencies"
    & $VenvPython -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        throw "Dependency install failed. Check internet access and requirements.txt."
    }
}

function Ensure-Config {
    param([string]$VenvPython)

    if (-not (Test-Path -LiteralPath "config.json")) {
        Write-Step "Creating bridge config"
        & $VenvPython setup_config.py
        if ($LASTEXITCODE -ne 0) {
            throw "Config setup failed."
        }
        return
    }

    & $VenvPython setup_config.py --check
    if ($LASTEXITCODE -ne 0) {
        Write-Step "Completing bridge config"
        & $VenvPython setup_config.py
        if ($LASTEXITCODE -ne 0) {
            throw "Config setup failed."
        }
    }
}

try {
    Assert-RequiredFiles

    if ($ValidateOnly) {
        $python = Find-Python
        if ($python) {
            Write-Host "Usable Python found: $($python.FilePath) $($python.Arguments -join ' ')"
        } else {
            Write-Host "No usable Python found. Automatic install path would be used."
        }

        $installerUrl = Get-PythonInstallerUrl
        Write-Host "Python.org installer fallback found: $installerUrl"
        exit 0
    }

    $python = Ensure-Python
    $venvPython = Ensure-Venv -Python $python
    Ensure-Dependencies -VenvPython $venvPython
    Ensure-Config -VenvPython $venvPython

    if (-not $SkipLaunch) {
        Write-Step "Starting Hue Art-Net bridge"
        & $venvPython -X utf8 hue_artnet_bridge.py --config config.json
        exit $LASTEXITCODE
    }

    Write-Step "Setup check complete"
    exit 0
} catch {
    Write-Host ""
    Write-Host "Setup failed:"
    Write-Host $_.Exception.Message
    exit 1
}
