# ===================================================================
# AZURE AI DEVELOPMENT ENVIRONMENT VALIDATION SCRIPT
# Phase 3: Azure Environment Restoration and Validation
# ===================================================================

param(
    [switch]$Detailed,
    [switch]$SkipInteractive,
    [string]$LogPath = ".\azure_validation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Initialize logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
}

# Azure Environment Configuration
$AzureConfig = @{
    SubscriptionId = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"
    ResourceGroup = "guardr"
    OpenAIEndpoint = "https://eastus.api.cognitive.microsoft.com/"
    MLWorkspace = "midnight"
    VirtualEnvPath = ".\azure-ai-envsource"
    MCPServerPath = ".\azure-ai-mcp-server"
    PythonScripts = @("azure.py", "deploy_agent.py")
}

Write-Log "=== AZURE AI ENVIRONMENT VALIDATION STARTED ===" "INFO"
Write-Log "Log file: $LogPath" "INFO"

# Test Results Storage
$TestResults = @{
    AzureCLI = $false
    AzureAuth = $false
    OpenAIConnectivity = $false
    MLWorkspace = $false
    PythonEnvironment = $false
    PythonPackages = $false
    AzureScripts = $false
    MCPServer = $false
    NetworkConnectivity = $false
    CredentialSecurity = $false
}

# ===================================================================
# AZURE CLI VALIDATION
# ===================================================================

Write-Log "Testing Azure CLI installation and configuration..." "INFO"

try {
    $azVersion = az --version 2>$null
    if ($azVersion) {
        Write-Log "Azure CLI is installed" "SUCCESS"
        if ($Detailed) {
            Write-Log "Azure CLI Version: $($azVersion[0])" "INFO"
        }
        $TestResults.AzureCLI = $true
    } else {
        Write-Log "Azure CLI not found or not accessible" "ERROR"
    }
} catch {
    Write-Log "Error checking Azure CLI: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# AZURE AUTHENTICATION VALIDATION
# ===================================================================

Write-Log "Validating Azure authentication and subscription access..." "INFO"

try {
    $accountInfo = az account show --output json 2>$null | ConvertFrom-Json
    if ($accountInfo) {
        Write-Log "Azure authentication successful" "SUCCESS"
        Write-Log "Logged in as: $($accountInfo.user.name)" "INFO"
        Write-Log "Current subscription: $($accountInfo.name) ($($accountInfo.id))" "INFO"
        
        if ($accountInfo.id -eq $AzureConfig.SubscriptionId) {
            Write-Log "Correct subscription is active" "SUCCESS"
            $TestResults.AzureAuth = $true
        } else {
            Write-Log "WARNING: Different subscription is active. Expected: $($AzureConfig.SubscriptionId)" "WARN"
            
            # Try to set the correct subscription
            try {
                az account set --subscription $AzureConfig.SubscriptionId
                Write-Log "Successfully switched to target subscription" "SUCCESS"
                $TestResults.AzureAuth = $true
            } catch {
                Write-Log "Failed to switch to target subscription" "ERROR"
            }
        }
    } else {
        Write-Log "Azure authentication failed. Please run 'az login'" "ERROR"
    }
} catch {
    Write-Log "Error validating Azure authentication: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# AZURE OPENAI CONNECTIVITY VALIDATION
# ===================================================================

Write-Log "Testing Azure OpenAI connectivity..." "INFO"

# Test network connectivity to OpenAI endpoint
try {
    $endpoint = [System.Uri]$AzureConfig.OpenAIEndpoint
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect($endpoint.Host, 443, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
    
    if ($wait) {
        $tcpClient.EndConnect($connect)
        $tcpClient.Close()
        Write-Log "Network connectivity to Azure OpenAI endpoint successful" "SUCCESS"
        $TestResults.NetworkConnectivity = $true
    } else {
        Write-Log "Network connectivity to Azure OpenAI endpoint failed" "ERROR"
    }
} catch {
    Write-Log "Error testing network connectivity: $($_.Exception.Message)" "ERROR"
}

# Test OpenAI resource access
try {
    $openaiResources = az cognitiveservices account list --resource-group $AzureConfig.ResourceGroup --output json 2>$null | ConvertFrom-Json
    $openaiResource = $openaiResources | Where-Object { $_.kind -eq "OpenAI" }
    
    if ($openaiResource) {
        Write-Log "Azure OpenAI resource found: $($openaiResource.name)" "SUCCESS"
        Write-Log "Resource location: $($openaiResource.location)" "INFO"
        Write-Log "Provisioning state: $($openaiResource.properties.provisioningState)" "INFO"
        
        # Test deployments
        try {
            $deployments = az cognitiveservices account deployment list --name $openaiResource.name --resource-group $AzureConfig.ResourceGroup --output json 2>$null | ConvertFrom-Json
            if ($deployments) {
                Write-Log "Found $($deployments.Count) OpenAI deployment(s):" "SUCCESS"
                foreach ($deployment in $deployments) {
                    Write-Log "  - $($deployment.name): $($deployment.properties.model.name) v$($deployment.properties.model.version)" "INFO"
                }
                $TestResults.OpenAIConnectivity = $true
            } else {
                Write-Log "No OpenAI deployments found" "WARN"
            }
        } catch {
            Write-Log "Error listing OpenAI deployments: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "No Azure OpenAI resource found in resource group" "ERROR"
    }
} catch {
    Write-Log "Error accessing Azure OpenAI resources: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# AZURE ML WORKSPACE VALIDATION
# ===================================================================

Write-Log "Validating Azure ML workspace access..." "INFO"

try {
    $mlWorkspace = az ml workspace show --name $AzureConfig.MLWorkspace --resource-group $AzureConfig.ResourceGroup --output json 2>$null | ConvertFrom-Json
    if ($mlWorkspace) {
        Write-Log "Azure ML workspace '$($AzureConfig.MLWorkspace)' found" "SUCCESS"
        Write-Log "Workspace location: $($mlWorkspace.location)" "INFO"
        Write-Log "Discovery URL: $($mlWorkspace.discovery_url)" "INFO"
        $TestResults.MLWorkspace = $true
    } else {
        Write-Log "Azure ML workspace '$($AzureConfig.MLWorkspace)' not found" "ERROR"
    }
} catch {
    Write-Log "Error accessing Azure ML workspace: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# PYTHON VIRTUAL ENVIRONMENT VALIDATION
# ===================================================================

Write-Log "Validating Python virtual environment..." "INFO"

if (Test-Path $AzureConfig.VirtualEnvPath) {
    Write-Log "Virtual environment directory found: $($AzureConfig.VirtualEnvPath)" "SUCCESS"
    
    # Check pyvenv.cfg
    $pyvenvConfig = Join-Path $AzureConfig.VirtualEnvPath "pyvenv.cfg"
    if (Test-Path $pyvenvConfig) {
        $configContent = Get-Content $pyvenvConfig
        Write-Log "Virtual environment configuration:" "INFO"
        foreach ($line in $configContent) {
            Write-Log "  $line" "INFO"
        }
    }
    
    # Check Python executable
    $pythonExe = Join-Path $AzureConfig.VirtualEnvPath "Scripts\python.exe"
    if (Test-Path $pythonExe) {
        Write-Log "Python executable found in virtual environment" "SUCCESS"
        
        # Test Python execution
        try {
            $pythonVersion = & $pythonExe --version 2>&1
            Write-Log "Python version: $pythonVersion" "INFO"
            $TestResults.PythonEnvironment = $true
        } catch {
            Write-Log "Error executing Python: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "Python executable not found in virtual environment" "ERROR"
    }
} else {
    Write-Log "Virtual environment directory not found: $($AzureConfig.VirtualEnvPath)" "ERROR"
}

# ===================================================================
# PYTHON PACKAGES VALIDATION
# ===================================================================

Write-Log "Validating Azure Python packages..." "INFO"

if ($TestResults.PythonEnvironment) {
    $pythonExe = Join-Path $AzureConfig.VirtualEnvPath "Scripts\python.exe"
    
    $requiredPackages = @(
        "openai",
        "azure-identity",
        "azure-ai-projects",
        "azure-core",
        "azure-keyvault-secrets"
    )
    
    $missingPackages = @()
    
    foreach ($package in $requiredPackages) {
        try {
            $packageInfo = & $pythonExe -m pip show $package 2>$null
            if ($packageInfo) {
                Write-Log "Package '$package' is installed" "SUCCESS"
            } else {
                Write-Log "Package '$package' is missing" "WARN"
                $missingPackages += $package
            }
        } catch {
            Write-Log "Error checking package '$package': $($_.Exception.Message)" "ERROR"
            $missingPackages += $package
        }
    }
    
    if ($missingPackages.Count -eq 0) {
        $TestResults.PythonPackages = $true
        Write-Log "All required Python packages are installed" "SUCCESS"
    } else {
        Write-Log "Missing packages: $($missingPackages -join ', ')" "WARN"
    }
}

# ===================================================================
# AZURE SCRIPTS VALIDATION
# ===================================================================

Write-Log "Validating Azure Python scripts..." "INFO"

$scriptIssues = @()

foreach ($script in $AzureConfig.PythonScripts) {
    if (Test-Path $script) {
        Write-Log "Script found: $script" "SUCCESS"
        
        # Basic syntax validation
        if ($TestResults.PythonEnvironment) {
            $pythonExe = Join-Path $AzureConfig.VirtualEnvPath "Scripts\python.exe"
            try {
                $syntaxCheck = & $pythonExe -m py_compile $script 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Script syntax validation passed: $script" "SUCCESS"
                } else {
                    Write-Log "Script syntax errors found in $script`: $syntaxCheck" "ERROR"
                    $scriptIssues += $script
                }
            } catch {
                Write-Log "Error validating script syntax for $script`: $($_.Exception.Message)" "ERROR"
                $scriptIssues += $script
            }
        }
        
        # Check for potential security issues
        $content = Get-Content $script -Raw
        if ($content -match "(api|key|secret|password|token)\s*=\s*[`"'].+[`"']") {
            Write-Log "WARNING: Potential hardcoded credentials found in $script" "WARN"
            Write-Log "Please review and ensure credentials are properly secured" "WARN"
        }
    } else {
        Write-Log "Script not found: $script" "ERROR"
        $scriptIssues += $script
    }
}

if ($scriptIssues.Count -eq 0) {
    $TestResults.AzureScripts = $true
}

# ===================================================================
# MCP SERVER VALIDATION
# ===================================================================

Write-Log "Validating MCP server configuration..." "INFO"

if (Test-Path $AzureConfig.MCPServerPath) {
    Write-Log "MCP server directory found: $($AzureConfig.MCPServerPath)" "SUCCESS"
    
    # Check package.json
    $packageJson = Join-Path $AzureConfig.MCPServerPath "package.json"
    if (Test-Path $packageJson) {
        Write-Log "MCP server package.json found" "SUCCESS"
        
        # Check for TypeScript file
        $indexTs = Join-Path $AzureConfig.MCPServerPath "index.ts"
        if (Test-Path $indexTs) {
            Write-Log "MCP server TypeScript source found" "SUCCESS"
            
            # Check if Node.js is available
            try {
                $nodeVersion = node --version 2>$null
                if ($nodeVersion) {
                    Write-Log "Node.js is available: $nodeVersion" "SUCCESS"
                    
                    # Check npm dependencies
                    Push-Location $AzureConfig.MCPServerPath
                    try {
                        $npmList = npm list --depth=0 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Write-Log "MCP server dependencies are installed" "SUCCESS"
                            $TestResults.MCPServer = $true
                        } else {
                            Write-Log "MCP server dependencies may be missing" "WARN"
                        }
                    } catch {
                        Write-Log "Error checking MCP server dependencies: $($_.Exception.Message)" "ERROR"
                    } finally {
                        Pop-Location
                    }
                } else {
                    Write-Log "Node.js not found. Required for MCP server" "ERROR"
                }
            } catch {
                Write-Log "Error checking Node.js: $($_.Exception.Message)" "ERROR"
            }
        } else {
            Write-Log "MCP server TypeScript source not found" "ERROR"
        }
    } else {
        Write-Log "MCP server package.json not found" "ERROR"
    }
} else {
    Write-Log "MCP server directory not found: $($AzureConfig.MCPServerPath)" "ERROR"
}

# ===================================================================
# CREDENTIAL SECURITY VALIDATION
# ===================================================================

Write-Log "Performing credential security validation..." "INFO"

# Check for exposed credentials in scripts
$credentialIssues = @()

foreach ($script in $AzureConfig.PythonScripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        
        # Check for hardcoded API keys
        if ($content -match "(?:api[_-]?key|secret|password|token)\s*=\s*['`"]([a-zA-Z0-9+/=]{20,})['`"]") {
            $credentialIssues += "Potential hardcoded credential in $script"
        }
        
        # Check for Azure subscription IDs in code
        if ($content -match "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}") {
            Write-Log "Azure subscription ID found in $script (may be acceptable)" "INFO"
        }
    }
}

if ($credentialIssues.Count -eq 0) {
    Write-Log "No obvious credential security issues found" "SUCCESS"
    $TestResults.CredentialSecurity = $true
} else {
    foreach ($issue in $credentialIssues) {
        Write-Log $issue "WARN"
    }
}

# ===================================================================
# COMPREHENSIVE TEST REPORT
# ===================================================================

Write-Log "=== AZURE ENVIRONMENT VALIDATION REPORT ===" "INFO"

$totalTests = $TestResults.Count
$passedTests = ($TestResults.Values | Where-Object { $_ -eq $true }).Count
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)

Write-Log "Overall Success Rate: $passedTests/$totalTests ($successRate%)" "INFO"
Write-Log "" "INFO"

foreach ($test in $TestResults.GetEnumerator()) {
    $status = if ($test.Value) { "PASS" } else { "FAIL" }
    $level = if ($test.Value) { "SUCCESS" } else { "ERROR" }
    Write-Log "$($test.Key): $status" $level
}

Write-Log "" "INFO"

# Recommendations
if (-not $TestResults.AzureCLI) {
    Write-Log "RECOMMENDATION: Install Azure CLI from https://docs.microsoft.com/cli/azure/install-azure-cli" "WARN"
}

if (-not $TestResults.AzureAuth) {
    Write-Log "RECOMMENDATION: Run 'az login' to authenticate with Azure" "WARN"
}

if (-not $TestResults.PythonEnvironment) {
    Write-Log "RECOMMENDATION: Recreate Python virtual environment using restore_dev_environment.ps1" "WARN"
}

if (-not $TestResults.PythonPackages) {
    Write-Log "RECOMMENDATION: Install missing Python packages using restore_dev_environment.ps1" "WARN"
}

if (-not $TestResults.MCPServer) {
    Write-Log "RECOMMENDATION: Install Node.js and MCP server dependencies" "WARN"
}

# Security recommendations
if (-not $TestResults.CredentialSecurity) {
    Write-Log "SECURITY RECOMMENDATION: Review and secure hardcoded credentials" "WARN"
    Write-Log "Consider using Azure Key Vault or environment variables" "WARN"
}

Write-Log "=== AZURE AI ENVIRONMENT VALIDATION COMPLETED ===" "INFO"
Write-Log "Detailed log saved to: $LogPath" "INFO"

# Return results for automation
if ($successRate -ge 80) {
    Write-Log "Environment validation PASSED with $successRate% success rate" "SUCCESS"
    exit 0
} else {
    Write-Log "Environment validation FAILED with $successRate% success rate" "ERROR"
    exit 1
}