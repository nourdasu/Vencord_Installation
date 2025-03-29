# PowerShell script to install Git, Node.js, and Vencord from source with custom plugins

# Function to check if running as administrator
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure script runs with admin privileges (needed for some installations)
if (-not (Test-Admin)) {
    Write-Host "This script requires administrative privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

# Install Git if not present
Write-Host "Checking for Git..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing Git..." -ForegroundColor Yellow
    try {
        # Download and install Git using winget (Windows Package Manager)
        winget install --id Git.Git -e --silent
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Host "Git installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Git: $_"
        Write-Host "Please install Git manually from https://git-scm.com/downloads and rerun the script"
        exit 1
    }
}

# Install Node.js if not present
Write-Host "Checking for Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js not found. Installing Node.js..." -ForegroundColor Yellow
    try {
        # Download and install Node.js LTS using winget
        winget install --id OpenJS.NodeJS.LTS -e --silent
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Host "Node.js installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Node.js: $_"
        Write-Host "Please install Node.js manually from https://nodejs.org/ and rerun the script"
        exit 1
    }
}

# Check if pnpm is installed
Write-Host "Checking for pnpm..." -ForegroundColor Yellow
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "pnpm not found. Installing pnpm..." -ForegroundColor Yellow
    npm install -g pnpm
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install pnpm"
        exit 1
    }
}

# Set installation directory
$installDir = "$env:USERPROFILE\Vencord"
if (Test-Path $installDir) {
    Write-Host "Existing Vencord directory found. Removing it..." -ForegroundColor Yellow
    Remove-Item -Path $installDir -Recurse -Force
}

# Clone Vencord repository
Write-Host "Cloning Vencord repository..." -ForegroundColor Green
git clone https://github.com/Vendicated/Vencord.git $installDir
Set-Location $installDir

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Green
pnpm install

# Build Vencord
Write-Host "Building Vencord..." -ForegroundColor Green
pnpm build

# Function to install custom plugins
function Install-VencordPlugin {
    param (
        [Parameter(Mandatory=$true)]
        [string]$PluginUrl
    )
    
    # Create plugins directory if it doesn't exist
    $pluginsDir = "$installDir\src\plugins"
    if (-not (Test-Path $pluginsDir)) {
        New-Item -Path $pluginsDir -ItemType Directory | Out-Null
    }

    # Extract filename from URL
    $fileName = [System.IO.Path]::GetFileName($PluginUrl)
    $pluginPath = Join-Path $pluginsDir $fileName

    # Download plugin
    Write-Host "Downloading plugin from $PluginUrl..." -ForegroundColor Green
    Invoke-WebRequest -Uri $PluginUrl -OutFile $pluginPath

    Write-Host "Plugin installed successfully: $fileName" -ForegroundColor Green
}

# Example usage of installing custom plugins (uncomment and modify URLs as needed)
# Install-VencordPlugin -PluginUrl "https://example.com/custom-plugin.ts"

# Install Vencord
Write-Host "Installing Vencord..." -ForegroundColor Green
pnpm inject

Write-Host "Vencord installation completed!" -ForegroundColor Cyan
Write-Host "To install custom plugins, use the Install-VencordPlugin function with a plugin URL" -ForegroundColor Cyan
Write-Host "Example: Install-VencordPlugin -PluginUrl 'https://example.com/plugin.ts'" -ForegroundColor Cyan