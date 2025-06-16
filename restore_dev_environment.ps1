# ===================================================================
# AZURE AI DEVELOPMENT ENVIRONMENT RESTORATION SCRIPT
# Phase 3: Azure Environment Restoration and Validation
# ===================================================================

param(
    [switch]$Force,
    [switch]$SkipBackup,
    [switch]$Detailed,
    [string]$LogPath = ".\dev_restoration_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Initialize logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
}

# Configuration
$DevConfig = @{
    VirtualEnvPath = ".\azure-ai-envsource"
    VirtualEnvBackup = ".\azure-ai-envsource-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    MCPServerPath = ".\azure-ai-mcp-server"
    PythonVersion = "3.12"
    RequiredPackages = @(
        "openai==1.58.1",
        "azure-identity==1.19.0",
        "azure-ai-projects==1.0.0b5",
        "azure-core==1.32.0",
        "azure-keyvault-secrets==4.8.0",
        "azure-mgmt-cognitiveservices==13.5.0",
        "azure-mgmt-resource==23.1.1",
        "requests==2.32.3",
        "python-dotenv==1.0.1",
        "pydantic==2.10.3",
        "typing-extensions==4.12.2"
    )
    GitConfig = @{
        UserName = ""
        UserEmail = ""
    }
}

Write-Log "=== AZURE AI DEVELOPMENT ENVIRONMENT RESTORATION STARTED ===" "INFO"
Write-Log "Log file: $LogPath" "INFO"

# Restoration Results
$RestoreResults = @{
    BackupCreated = $false
    VirtualEnvRestored = $false
    PackagesInstalled = $false
    AzureCLIConfigured = $false
    GitConfigured = $false
    EnvironmentVariables = $false
    MCPServerRestored = $false
    IntegrityValidated = $false
}

# ===================================================================
# BACKUP EXISTING ENVIRONMENT
# ===================================================================

if (-not $SkipBackup) {
    Write-Log "Creating backup of existing environment..." "INFO"
    
    if (Test-Path $DevConfig.VirtualEnvPath) {
        try {
            Write-Log "Backing up virtual environment to: $($DevConfig.VirtualEnvBackup)" "INFO"
            Copy-Item -Path $DevConfig.VirtualEnvPath -Destination $DevConfig.VirtualEnvBackup -Recurse -Force
            Write-Log "Backup created successfully" "SUCCESS"
            $RestoreResults.BackupCreated = $true
        } catch {
            Write-Log "Failed to create backup: $($_.Exception.Message)" "ERROR"
            if (-not $Force) {
                Write-Log "Use -Force to continue without backup" "ERROR"
                exit 1
            }
        }
    } else {
        Write-Log "No existing virtual environment found to backup" "INFO"
        $RestoreResults.BackupCreated = $true
    }
}

# ===================================================================
# VALIDATE SYSTEM PREREQUISITES
# ===================================================================

Write-Log "Validating system prerequisites..." "INFO"

# Check Python installation
try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -like "*Python $($DevConfig.PythonVersion)*") {
        Write-Log "Compatible Python version found: $pythonVersion" "SUCCESS"
    } else {
        Write-Log "Python version mismatch. Expected: $($DevConfig.PythonVersion), Found: $pythonVersion" "WARN"
        Write-Log "Continuing with available Python version..." "INFO"
    }
} catch {
    Write-Log "Python not found in PATH. Please install Python $($DevConfig.PythonVersion)" "ERROR"
    exit 1
}

# Check pip availability
try {
    $pipVersion = python -m pip --version 2>&1
    Write-Log "pip is available: $pipVersion" "SUCCESS"
} catch {
    Write-Log "pip not available. Installing pip..." "WARN"
    try {
        python -m ensurepip --upgrade
        Write-Log "pip installation completed" "SUCCESS"
    } catch {
        Write-Log "Failed to install pip: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# ===================================================================
# VIRTUAL ENVIRONMENT RESTORATION
# ===================================================================

Write-Log "Restoring Python virtual environment..." "INFO"

# Remove existing environment if Force is specified
if ($Force -and (Test-Path $DevConfig.VirtualEnvPath)) {
    Write-Log "Force flag specified. Removing existing virtual environment..." "WARN"
    try {
        Remove-Item -Path $DevConfig.VirtualEnvPath -Recurse -Force
        Write-Log "Existing virtual environment removed" "SUCCESS"
    } catch {
        Write-Log "Failed to remove existing environment: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Create new virtual environment
if (-not (Test-Path $DevConfig.VirtualEnvPath)) {
    Write-Log "Creating new virtual environment..." "INFO"
    try {
        python -m venv $DevConfig.VirtualEnvPath
        Write-Log "Virtual environment created successfully" "SUCCESS"
        $RestoreResults.VirtualEnvRestored = $true
    } catch {
        Write-Log "Failed to create virtual environment: $($_.Exception.Message)" "ERROR"
        exit 1
    }
} else {
    Write-Log "Virtual environment already exists" "INFO"
    $RestoreResults.VirtualEnvRestored = $true
}

# Verify virtual environment structure
$venvPython = Join-Path $DevConfig.VirtualEnvPath "Scripts\python.exe"
$venvPip = Join-Path $DevConfig.VirtualEnvPath "Scripts\pip.exe"

if ((Test-Path $venvPython) -and (Test-Path $venvPip)) {
    Write-Log "Virtual environment structure validated" "SUCCESS"
} else {
    Write-Log "Virtual environment structure is incomplete" "ERROR"
    exit 1
}

# ===================================================================
# PACKAGE INSTALLATION AND RESTORATION
# ===================================================================

Write-Log "Installing Azure AI packages..." "INFO"

# Upgrade pip first
try {
    Write-Log "Upgrading pip..." "INFO"
    & $venvPython -m pip install --upgrade pip
    Write-Log "pip upgraded successfully" "SUCCESS"
} catch {
    Write-Log "Failed to upgrade pip: $($_.Exception.Message)" "WARN"
}

# Install required packages
$failedPackages = @()
$installedPackages = @()

foreach ($package in $DevConfig.RequiredPackages) {
    Write-Log "Installing package: $package" "INFO"
    try {
        $installOutput = & $venvPython -m pip install $package 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Successfully installed: $package" "SUCCESS"
            $installedPackages += $package
        } else {
            Write-Log "Failed to install $package`: $installOutput" "ERROR"
            $failedPackages += $package
        }
    } catch {
        Write-Log "Error installing $package`: $($_.Exception.Message)" "ERROR"
        $failedPackages += $package
    }
}

# Package installation summary
if ($failedPackages.Count -eq 0) {
    Write-Log "All packages installed successfully" "SUCCESS"
    $RestoreResults.PackagesInstalled = $true
} else {
    Write-Log "Failed to install $($failedPackages.Count) packages: $($failedPackages -join ', ')" "ERROR"
    Write-Log "Successfully installed $($installedPackages.Count) packages" "INFO"
}

# Generate requirements.txt for future use
try {
    Write-Log "Generating requirements.txt..." "INFO"
    $requirements = & $venvPython -m pip freeze
    $requirements | Out-File -FilePath "requirements.txt" -Encoding UTF8
    Write-Log "requirements.txt generated successfully" "SUCCESS"
} catch {
    Write-Log "Failed to generate requirements.txt: $($_.Exception.Message)" "WARN"
}

# ===================================================================
# AZURE CLI CONFIGURATION RESTORATION
# ===================================================================

Write-Log "Validating Azure CLI configuration..." "INFO"

try {
    $azVersion = az --version 2>$null
    if ($azVersion) {
        Write-Log "Azure CLI is available" "SUCCESS"
        
        # Check current authentication
        $accountInfo = az account show --output json 2>$null | ConvertFrom-Json
        if ($accountInfo) {
            Write-Log "Azure CLI is authenticated as: $($accountInfo.user.name)" "SUCCESS"
            $RestoreResults.AzureCLIConfigured = $true
        } else {
            Write-Log "Azure CLI requires authentication. Please run 'az login'" "WARN"
        }
        
        # Install Azure CLI extensions if needed
        $requiredExtensions = @("ml", "cognitiveservices")
        foreach ($extension in $requiredExtensions) {
            try {
                $extensionList = az extension list --output json 2>$null | ConvertFrom-Json
                $isInstalled = $extensionList | Where-Object { $_.name -eq $extension }
                
                if (-not $isInstalled) {
                    Write-Log "Installing Azure CLI extension: $extension" "INFO"
                    az extension add --name $extension
                    Write-Log "Extension '$extension' installed successfully" "SUCCESS"
                } else {
                    Write-Log "Extension '$extension' is already installed" "SUCCESS"
                }
            } catch {
                Write-Log "Failed to install extension '$extension': $($_.Exception.Message)" "WARN"
            }
        }
    } else {
        Write-Log "Azure CLI not found. Please install from https://docs.microsoft.com/cli/azure/install-azure-cli" "ERROR"
    }
} catch {
    Write-Log "Error validating Azure CLI: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# GIT CONFIGURATION RESTORATION
# ===================================================================

Write-Log "Validating Git configuration..." "INFO"

try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Log "Git is available: $gitVersion" "SUCCESS"
        
        # Check Git configuration
        $gitUserName = git config user.name 2>$null
        $gitUserEmail = git config user.email 2>$null
        
        if ($gitUserName -and $gitUserEmail) {
            Write-Log "Git is configured with user: $gitUserName <$gitUserEmail>" "SUCCESS"
            $RestoreResults.GitConfigured = $true
        } else {
            Write-Log "Git user configuration is incomplete" "WARN"
            Write-Log "Please run: git config --global user.name 'Your Name'" "INFO"
            Write-Log "Please run: git config --global user.email 'your.email@example.com'" "INFO"
        }
        
        # Validate repository integrity
        if (Test-Path ".git") {
            Write-Log "Git repository detected in current directory" "INFO"
            try {
                $gitStatus = git status --porcelain 2>$null
                Write-Log "Git repository status validated" "SUCCESS"
                
                # Check for any uncommitted changes
                if ($gitStatus) {
                    Write-Log "Uncommitted changes detected:" "WARN"
                    $gitStatus | ForEach-Object { Write-Log "  $_" "INFO" }
                } else {
                    Write-Log "Working directory is clean" "SUCCESS"
                }
            } catch {
                Write-Log "Git repository may be corrupted: $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-Log "No Git repository found in current directory" "INFO"
        }
    } else {
        Write-Log "Git not found. Please install Git from https://git-scm.com/" "WARN"
    }
} catch {
    Write-Log "Error validating Git: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# ENVIRONMENT VARIABLES RESTORATION
# ===================================================================

Write-Log "Setting up environment variables..." "INFO"

# Create .env file template
$envTemplate = @"
# Azure Configuration
AZURE_SUBSCRIPTION_ID=831ed202-1c08-4b14-91eb-19ee3e5b3c78
AZURE_RESOURCE_GROUP=guardr
AZURE_OPENAI_ENDPOINT=https://eastus.api.cognitive.microsoft.com/
AZURE_OPENAI_API_KEY=your_api_key_here
AZURE_ML_WORKSPACE_NAME=midnight

# Development Configuration
PYTHON_PATH=$($DevConfig.VirtualEnvPath)\Scripts\python.exe
VIRTUAL_ENV=$($DevConfig.VirtualEnvPath)

# Project Configuration
PROJECT_ENDPOINT=https://your-project.eastus.inference.ai.azure.com
"@

try {
    if (-not (Test-Path ".env") -or $Force) {
        $envTemplate | Out-File -FilePath ".env" -Encoding UTF8
        Write-Log ".env file created/updated" "SUCCESS"
        $RestoreResults.EnvironmentVariables = $true
    } else {
        Write-Log ".env file already exists (use -Force to overwrite)" "INFO"
        $RestoreResults.EnvironmentVariables = $true
    }
} catch {
    Write-Log "Failed to create .env file: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# MCP SERVER RESTORATION
# ===================================================================

Write-Log "Restoring MCP server configuration..." "INFO"

if (Test-Path $DevConfig.MCPServerPath) {
    Write-Log "MCP server directory found" "SUCCESS"
    
    # Check Node.js availability
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Log "Node.js is available: $nodeVersion" "SUCCESS"
            
            # Install MCP server dependencies
            Push-Location $DevConfig.MCPServerPath
            try {
                Write-Log "Installing MCP server dependencies..." "INFO"
                $npmInstall = npm install 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "MCP server dependencies installed successfully" "SUCCESS"
                    $RestoreResults.MCPServerRestored = $true
                } else {
                    Write-Log "Failed to install MCP server dependencies: $npmInstall" "ERROR"
                }
                
                # Verify TypeScript compilation if needed
                if (Test-Path "index.ts") {
                    try {
                        $tscCheck = npx tsc --noEmit index.ts 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Log "MCP server TypeScript validation passed" "SUCCESS"
                        } else {
                            Write-Log "MCP server TypeScript validation failed: $tscCheck" "WARN"
                        }
                    } catch {
                        Write-Log "TypeScript compiler not available" "INFO"
                    }
                }
            } catch {
                Write-Log "Error setting up MCP server: $($_.Exception.Message)" "ERROR"
            } finally {
                Pop-Location
            }
        } else {
            Write-Log "Node.js not found. Please install Node.js from https://nodejs.org/" "WARN"
        }
    } catch {
        Write-Log "Error checking Node.js: $($_.Exception.Message)" "ERROR"
    }
} else {
    Write-Log "MCP server directory not found: $($DevConfig.MCPServerPath)" "WARN"
}

# ===================================================================
# DEVELOPMENT TOOLS VALIDATION
# ===================================================================

Write-Log "Validating development tools..." "INFO"

# Test Python imports
Write-Log "Testing Python package imports..." "INFO"
$importTests = @(
    "import openai",
    "import azure.identity",
    "import azure.ai.projects",
    "from azure.core.credentials import AzureKeyCredential"
)

$importFailures = @()
foreach ($importTest in $importTests) {
    try {
        $testResult = & $venvPython -c $importTest 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Import test passed: $importTest" "SUCCESS"
        } else {
            Write-Log "Import test failed: $importTest - $testResult" "ERROR"
            $importFailures += $importTest
        }
    } catch {
        Write-Log "Import test error: $importTest - $($_.Exception.Message)" "ERROR"
        $importFailures += $importTest
    }
}

if ($importFailures.Count -eq 0) {
    Write-Log "All Python import tests passed" "SUCCESS"
    $RestoreResults.IntegrityValidated = $true
} else {
    Write-Log "Failed import tests: $($importFailures.Count)" "ERROR"
}

# ===================================================================
# DEVELOPMENT ENVIRONMENT INTEGRITY CHECK
# ===================================================================

Write-Log "Performing comprehensive integrity check..." "INFO"

# Validate Azure scripts
$scriptValidation = @()
$scripts = @("azure.py", "deploy_agent.py")

foreach ($script in $scripts) {
    if (Test-Path $script) {
        try {
            $syntaxCheck = & $venvPython -m py_compile $script 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Script validation passed: $script" "SUCCESS"
                $scriptValidation += $true
            } else {
                Write-Log "Script validation failed: $script - $syntaxCheck" "ERROR"
                $scriptValidation += $false
            }
        } catch {
            Write-Log "Script validation error: $script - $($_.Exception.Message)" "ERROR"
            $scriptValidation += $false
        }
    } else {
        Write-Log "Script not found: $script" "WARN"
        $scriptValidation += $false
    }
}

# Path configuration validation
$pathTests = @()
$pathTests += Test-Path $DevConfig.VirtualEnvPath
$pathTests += Test-Path (Join-Path $DevConfig.VirtualEnvPath "Scripts\python.exe")
$pathTests += Test-Path (Join-Path $DevConfig.VirtualEnvPath "Scripts\pip.exe")

if (($pathTests | Where-Object { $_ -eq $true }).Count -eq $pathTests.Count) {
    Write-Log "Path configuration validation passed" "SUCCESS"
} else {
    Write-Log "Path configuration validation failed" "ERROR"
}

# ===================================================================
# RESTORATION SUMMARY AND RECOMMENDATIONS
# ===================================================================

Write-Log "=== DEVELOPMENT ENVIRONMENT RESTORATION SUMMARY ===" "INFO"

$totalChecks = $RestoreResults.Count
$passedChecks = ($RestoreResults.Values | Where-Object { $_ -eq $true }).Count
$successRate = [math]::Round(($passedChecks / $totalChecks) * 100, 2)

Write-Log "Restoration Success Rate: $passedChecks/$totalChecks ($successRate%)" "INFO"
Write-Log "" "INFO"

foreach ($result in $RestoreResults.GetEnumerator()) {
    $status = if ($result.Value) { "SUCCESS" } else { "NEEDS ATTENTION" }
    $level = if ($result.Value) { "SUCCESS" } else { "WARN" }
    Write-Log "$($result.Key): $status" $level
}

Write-Log "" "INFO"

# Post-restoration recommendations
Write-Log "=== POST-RESTORATION RECOMMENDATIONS ===" "INFO"

if (-not $RestoreResults.AzureCLIConfigured) {
    Write-Log "1. Run 'az login' to authenticate with Azure" "INFO"
    Write-Log "2. Set correct subscription: az account set --subscription 831ed202-1c08-4b14-91eb-19ee3e5b3c78" "INFO"
}

if (-not $RestoreResults.GitConfigured) {
    Write-Log "3. Configure Git: git config --global user.name 'Your Name'" "INFO"
    Write-Log "4. Configure Git: git config --global user.email 'your.email@example.com'" "INFO"
}

Write-Log "5. Update .env file with actual Azure API keys and endpoints" "INFO"
Write-Log "6. Test the environment using: .\validate_azure_environment.ps1" "INFO"

if ($RestoreResults.MCPServerRestored) {
    Write-Log "7. MCP server is ready. Configure Cursor IDE using: .\setup_cursor_ide.ps1" "INFO"
}

# Create activation script
$activationScript = @"
@echo off
echo Activating Azure AI Development Environment...
call "$($DevConfig.VirtualEnvPath)\Scripts\activate.bat"
echo Virtual environment activated: $($DevConfig.VirtualEnvPath)
echo Python: 
python --version
echo Available packages:
pip list --format=columns
echo.
echo Environment ready for Azure AI development!
echo.
"@

try {
    $activationScript | Out-File -FilePath "activate_dev_env.bat" -Encoding ASCII
    Write-Log "Created activation script: activate_dev_env.bat" "SUCCESS"
} catch {
    Write-Log "Failed to create activation script: $($_.Exception.Message)" "WARN"
}

Write-Log "=== AZURE AI DEVELOPMENT ENVIRONMENT RESTORATION COMPLETED ===" "INFO"
Write-Log "Log file: $LogPath" "INFO"

if ($successRate -ge 75) {
    Write-Log "Environment restoration completed successfully" "SUCCESS"
    exit 0
} else {
    Write-Log "Environment restoration completed with issues. Please review the log and recommendations." "WARN"
    exit 1
}