# ./scripts/powershell.ps1
<#
.SYNOPSIS
    Installs Docker Desktop, WSL2, and runs a Redis container on Windows.

.DESCRIPTION
    This script checks for administrator privileges, installs WSL2 if not already installed,
    downloads and installs Docker Desktop, waits for Docker to start, and then pulls and runs
    a Redis container.

.NOTES
    Author: Jonathan Agustin
    Version: 1.0
    Requires: PowerShell 5.1 or higher, Windows 10 or higher
#>

# Check if running as administrator
function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Enable WSL2
function Enable-WSL2 {
    # Check if WSL is installed
    $wslInstalled = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled"

    if (-not $wslInstalled) {
        # Enable WSL
        Write-Host "Enabling WSL..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart

        # Enable Virtual Machine Platform
        Write-Host "Enabling Virtual Machine Platform..."
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

        # Download and install WSL2 update
        Write-Host "Downloading WSL2 update..."
        Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"

        Write-Host "Installing WSL2 update..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i wsl_update_x64.msi /quiet /norestart" -Wait

        # Set WSL2 as default
        Write-Host "Setting WSL2 as default..."
        wsl --set-default-version 2

        Write-Host "WSL2 is now enabled. Please restart your computer to complete the setup."
        exit
    }

    # Check if WSL2 is the default version
    $wslDefaultVersion = (wsl --get-default-version) -as [int]

    if ($wslDefaultVersion -ne 2) {
        Write-Host "WSL2 is not the default version. Setting WSL2 as default..."
        wsl --set-default-version 2
    }
}

# Install Docker Desktop
function Install-DockerDesktop {
    # Download Docker Desktop installer
    Write-Host "Downloading Docker Desktop installer..."
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile "DockerDesktopInstaller.exe"

    # Download checksum file
    Write-Host "Downloading checksum file..."
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/checksums.txt" -OutFile "checksums.txt"

    # Verify checksum
    Write-Host "Verifying checksum..."
    $checksumFileContent = Get-Content -Path "checksums.txt"
    $expectedChecksum = ($checksumFileContent -split '\s+')[0]
    $actualChecksum = (Get-FileHash -Path "DockerDesktopInstaller.exe" -Algorithm SHA256).Hash.ToLower()

    if ($expectedChecksum -ne $actualChecksum) {
        Write-Host "Checksum verification failed. Please try downloading the installer again."
        exit
    }

    # Install Docker Desktop silently
    Write-Host "Installing Docker Desktop..."
    Start-Process -FilePath ".\DockerDesktopInstaller.exe" -ArgumentList "/S" -Wait

    # Wait for Docker to start
    Write-Host "Waiting for Docker to start..."
    Start-Sleep -Seconds 60

    # Enable Docker CLI in PowerShell
    Write-Host "Enabling Docker CLI in PowerShell..."
    $env:Path += ";$env:ProgramFiles\Docker\Docker\resources\bin"
}

# Pull and run Redis container
function Invoke-RedisContainer {
    # Pull Redis image
    Write-Host "Pulling Redis image..."
    docker pull redis:latest

    # Run Redis container
    Write-Host "Running Redis container..."
    docker run --name redis -d -p 6379:6379 redis:latest

    Write-Host "Redis container is running."
}

# Main script execution
if (-not (Test-IsAdmin)) {
    Write-Host "This script must be run with administrator privileges."
    exit
}

Enable-WSL2
Install-DockerDesktop
Invoke-RedisContainer