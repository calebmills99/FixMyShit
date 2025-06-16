# ===================================================================
# CURSOR IDE AZURE AI CONFIGURATION SCRIPT
# Phase 3: Azure Environment Restoration and Validation
# ===================================================================

param(
    [switch]$Force,
    [switch]$SkipMCP,
    [switch]$Detailed,
    [string]$LogPath = ".\cursor_setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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
$CursorConfig = @{
    CursorConfigPath = "$env:APPDATA\Cursor\User"
    WorkspaceSettingsPath = ".\.vscode"
    MCPConfigPath = "$env:USERPROFILE\.cursor"
    MCPServerPath = ".\azure-ai-mcp-server"
    AzureEndpoint = "https://eastus.api.cognitive.microsoft.com/"
    ModelDeployment = "gpt-4.1"
}

Write-Log "=== CURSOR IDE AZURE AI CONFIGURATION STARTED ===" "INFO"
Write-Log "Log file: $LogPath" "INFO"

# Setup Results
$SetupResults = @{
    CursorDetected = $false
    WorkspaceConfigured = $false
    MCPServerConfigured = $false
    CursorRulesCreated = $false
    AzureModelConfigured = $false
    ExtensionsConfigured = $false
    DebuggingConfigured = $false
    GitIntegrated = $false
}

# ===================================================================
# CURSOR IDE DETECTION AND VALIDATION
# ===================================================================

Write-Log "Detecting Cursor IDE installation..." "INFO"

# Check for Cursor installation
$cursorPaths = @(
    "${env:LOCALAPPDATA}\Programs\cursor\Cursor.exe",
    "${env:PROGRAMFILES}\Cursor\Cursor.exe",
    "${env:PROGRAMFILES(X86)}\Cursor\Cursor.exe"
)

$cursorFound = $false
foreach ($path in $cursorPaths) {
    if (Test-Path $path) {
        Write-Log "Cursor IDE found at: $path" "SUCCESS"
        $cursorFound = $true
        $SetupResults.CursorDetected = $true
        break
    }
}

if (-not $cursorFound) {
    Write-Log "Cursor IDE not found. Please install from https://cursor.sh/" "ERROR"
    Write-Log "Continuing with configuration assuming Cursor will be installed..." "WARN"
}

# ===================================================================
# WORKSPACE CONFIGURATION
# ===================================================================

Write-Log "Configuring workspace settings for Azure AI development..." "INFO"

# Create .vscode directory if it doesn't exist
if (-not (Test-Path $CursorConfig.WorkspaceSettingsPath)) {
    New-Item -ItemType Directory -Path $CursorConfig.WorkspaceSettingsPath -Force | Out-Null
    Write-Log "Created workspace settings directory" "SUCCESS"
}

# Workspace settings for Azure AI development
$workspaceSettings = @{
    "python.pythonPath" = ".\azure-ai-envsource\Scripts\python.exe"
    "python.terminal.activateEnvironment" = $true
    "python.defaultInterpreterPath" = ".\azure-ai-envsource\Scripts\python.exe"
    "python.formatting.provider" = "black"
    "python.linting.enabled" = $true
    "python.linting.pylintEnabled" = $true
    "files.associations" = @{
        "*.py" = "python"
        "*.ps1" = "powershell"
        "*.env" = "dotenv"
    }
    "git.enableSmartCommit" = $true
    "git.confirmSync" = $false
    "terminal.integrated.defaultProfile.windows" = "PowerShell"
    "azure.resourceFilter" = @("831ed202-1c08-4b14-91eb-19ee3e5b3c78")
    "azureLogicApps.enablePreview" = $true
    "cursor.cpp.enableInlineCompletion" = $true
    "cursor.general.enableCodeActions" = $true
    "editor.formatOnSave" = $true
    "editor.codeActionsOnSave" = @{
        "source.organizeImports" = $true
    }
}

try {
    $settingsPath = Join-Path $CursorConfig.WorkspaceSettingsPath "settings.json"
    $workspaceSettings | ConvertTo-Json -Depth 3 | Out-File -FilePath $settingsPath -Encoding UTF8
    Write-Log "Workspace settings configured: $settingsPath" "SUCCESS"
    $SetupResults.WorkspaceConfigured = $true
} catch {
    Write-Log "Failed to create workspace settings: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# CURSOR RULES CONFIGURATION
# ===================================================================

Write-Log "Creating .cursorrules file for Azure AI development standards..." "INFO"

$cursorRules = @"
# Azure AI Development Rules for Cursor IDE

## Project Context
This is an Azure AI development environment focused on:
- Azure OpenAI integration (gpt-4.1 deployment)
- Azure ML workspace operations
- MCP (Model Context Protocol) server development
- Python-based AI agent development

## Development Standards

### Python Code Style
- Use Python 3.12+ features and type hints
- Follow PEP 8 style guidelines
- Use async/await for Azure API calls
- Implement proper error handling with try/except blocks
- Use logging instead of print statements
- Validate all inputs and handle edge cases

### Azure Integration
- Always use environment variables for sensitive data
- Implement proper authentication using Azure Identity
- Use Azure SDK best practices for resource management
- Handle rate limiting and retries for API calls
- Implement proper session management for long-running operations

### Security Requirements
- Never hardcode API keys, secrets, or connection strings
- Use Azure Key Vault for sensitive configuration
- Validate all user inputs to prevent injection attacks
- Implement proper access controls and permission checks
- Log security-relevant events for monitoring

### Error Handling
- Provide meaningful error messages to users
- Log detailed error information for debugging
- Implement graceful degradation when services are unavailable
- Use proper HTTP status codes for API responses
- Handle network timeouts and connection errors

### Testing
- Write unit tests for all core functionality
- Mock Azure services for offline testing
- Test error conditions and edge cases
- Validate API responses and data structures
- Use pytest for testing framework

### Documentation
- Document all functions with clear docstrings
- Include usage examples in docstrings
- Maintain README with setup and usage instructions
- Document API endpoints and data schemas
- Keep changelog updated for version releases

## Azure-Specific Guidelines

### OpenAI Integration
- Use the latest Azure OpenAI SDK
- Implement token counting and cost tracking
- Handle model-specific limitations and capabilities
- Implement proper prompt engineering practices
- Cache responses when appropriate for performance

### ML Workspace Operations
- Use proper workspace authentication
- Implement dataset versioning and tracking
- Handle compute resource management efficiently
- Monitor training jobs and provide status updates
- Implement proper model registry operations

### MCP Server Development
- Follow MCP protocol specifications strictly
- Implement proper tool registration and discovery
- Handle tool execution with proper error boundaries
- Provide clear tool descriptions and schemas
- Test tool integration with various MCP clients

## File Organization
- Keep Azure-specific code in dedicated modules
- Separate configuration from business logic
- Use clear, descriptive file and function names
- Organize imports at the top of files
- Group related functionality in classes or modules

## Performance Considerations
- Implement connection pooling for Azure services
- Use async operations for I/O-bound tasks
- Cache frequently accessed data appropriately
- Monitor and optimize API call patterns
- Implement proper resource cleanup

## Cursor IDE Specific
- Use the integrated Azure OpenAI model for code assistance
- Leverage MCP tools for Azure resource management
- Take advantage of real-time collaboration features
- Use the AI chat for architecture and design discussions
- Implement proper workspace-specific configurations
"@

try {
    $cursorRules | Out-File -FilePath ".cursorrules" -Encoding UTF8
    Write-Log ".cursorrules file created successfully" "SUCCESS"
    $SetupResults.CursorRulesCreated = $true
} catch {
    Write-Log "Failed to create .cursorrules file: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# MCP SERVER CONFIGURATION
# ===================================================================

if (-not $SkipMCP) {
    Write-Log "Configuring MCP server for Cursor IDE integration..." "INFO"
    
    # Create MCP configuration directory
    if (-not (Test-Path $CursorConfig.MCPConfigPath)) {
        New-Item -ItemType Directory -Path $CursorConfig.MCPConfigPath -Force | Out-Null
        Write-Log "Created MCP configuration directory" "SUCCESS"
    }
    
    # MCP configuration for Azure AI server
    $mcpConfig = @{
        "mcpServers" = @{
            "azure-ai-server" = @{
                "command" = "node"
                "args" = @("index.js")
                "cwd" = (Resolve-Path $CursorConfig.MCPServerPath).Path
                "env" = @{
                    "AZURE_SUBSCRIPTION_ID" = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"
                    "AZURE_RESOURCE_GROUP" = "guardr"
                    "AZURE_OPENAI_ENDPOINT" = $CursorConfig.AzureEndpoint
                    "AZURE_ML_WORKSPACE_NAME" = "midnight"
                }
            }
        }
    }
    
    try {
        $mcpConfigPath = Join-Path $CursorConfig.MCPConfigPath "mcp.json"
        $mcpConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $mcpConfigPath -Encoding UTF8
        Write-Log "MCP server configuration created: $mcpConfigPath" "SUCCESS"
        $SetupResults.MCPServerConfigured = $true
    } catch {
        Write-Log "Failed to create MCP configuration: $($_.Exception.Message)" "ERROR"
    }
}

# ===================================================================
# AZURE OPENAI MODEL CONFIGURATION
# ===================================================================

Write-Log "Configuring Azure OpenAI custom model for Cursor..." "INFO"

# Check if MCP server is available
if (Test-Path $CursorConfig.MCPServerPath) {
    $indexJsPath = Join-Path $CursorConfig.MCPServerPath "index.js"
    $indexTsPath = Join-Path $CursorConfig.MCPServerPath "index.ts"
    
    if (Test-Path $indexTsPath) {
        Write-Log "TypeScript MCP server found, checking for compiled JavaScript..." "INFO"
        
        # Check if we need to compile TypeScript
        if (-not (Test-Path $indexJsPath) -or ((Get-Item $indexTsPath).LastWriteTime -gt (Get-Item $indexJsPath).LastWriteTime)) {
            Write-Log "Compiling TypeScript MCP server..." "INFO"
            
            Push-Location $CursorConfig.MCPServerPath
            try {
                # Try to compile with TypeScript
                $tscResult = npx tsc index.ts 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "TypeScript compilation successful" "SUCCESS"
                } else {
                    Write-Log "TypeScript compilation failed: $tscResult" "ERROR"
                }
            } catch {
                Write-Log "Error during TypeScript compilation: $($_.Exception.Message)" "ERROR"
            } finally {
                Pop-Location
            }
        }
        
        if (Test-Path $indexJsPath) {
            Write-Log "MCP server JavaScript file is ready" "SUCCESS"
            $SetupResults.AzureModelConfigured = $true
        } else {
            Write-Log "MCP server compilation failed" "ERROR"
        }
    } elseif (Test-Path $indexJsPath) {
        Write-Log "JavaScript MCP server found and ready" "SUCCESS"
        $SetupResults.AzureModelConfigured = $true
    } else {
        Write-Log "No MCP server files found" "ERROR"
    }
} else {
    Write-Log "MCP server directory not found: $($CursorConfig.MCPServerPath)" "ERROR"
}

# ===================================================================
# CURSOR EXTENSIONS AND PLUGINS
# ===================================================================

Write-Log "Configuring recommended extensions for Azure AI development..." "INFO"

$recommendedExtensions = @{
    "extensions.json" = @{
        "recommendations" = @(
            "ms-python.python",
            "ms-python.vscode-pylance",
            "ms-vscode.azure-account",
            "ms-azuretools.vscode-azureresourcegroups",
            "ms-azuretools.vscode-azurefunctions",
            "ms-toolsai.jupyter",
            "ms-vscode.powershell",
            "ms-vscode.vscode-json",
            "bradlc.vscode-tailwindcss",
            "esbenp.prettier-vscode",
            "ms-vscode.vscode-typescript-next"
        )
    }
}

try {
    $extensionsPath = Join-Path $CursorConfig.WorkspaceSettingsPath "extensions.json"
    $recommendedExtensions | ConvertTo-Json -Depth 3 | Out-File -FilePath $extensionsPath -Encoding UTF8
    Write-Log "Extension recommendations configured: $extensionsPath" "SUCCESS"
    $SetupResults.ExtensionsConfigured = $true
} catch {
    Write-Log "Failed to create extensions configuration: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# DEBUGGING CONFIGURATION
# ===================================================================

Write-Log "Setting up debugging configuration for Azure AI development..." "INFO"

$debugConfig = @{
    "version" = "0.2.0"
    "configurations" = @(
        @{
            "name" = "Python: Azure Script Debug"
            "type" = "python"
            "request" = "launch"
            "program" = "`${file}"
            "console" = "integratedTerminal"
            "python" = ".\azure-ai-envsource\Scripts\python.exe"
            "env" = @{
                "PYTHONPATH" = "`${workspaceFolder}"
                "AZURE_SUBSCRIPTION_ID" = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"
                "AZURE_RESOURCE_GROUP" = "guardr"
                "AZURE_ML_WORKSPACE_NAME" = "midnight"
            }
            "envFile" = "`${workspaceFolder}\.env"
        },
        @{
            "name" = "MCP Server Debug"
            "type" = "node"
            "request" = "launch"
            "program" = "`${workspaceFolder}\azure-ai-mcp-server\index.js"
            "console" = "integratedTerminal"
            "env" = @{
                "NODE_ENV" = "development"
            }
            "envFile" = "`${workspaceFolder}\.env"
        },
        @{
            "name" = "Python: Test Azure Connection"
            "type" = "python"
            "request" = "launch"
            "program" = "`${workspaceFolder}\azure.py"
            "console" = "integratedTerminal"
            "python" = ".\azure-ai-envsource\Scripts\python.exe"
            "envFile" = "`${workspaceFolder}\.env"
        }
    )
}

try {
    $launchPath = Join-Path $CursorConfig.WorkspaceSettingsPath "launch.json"
    $debugConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $launchPath -Encoding UTF8
    Write-Log "Debug configuration created: $launchPath" "SUCCESS"
    $SetupResults.DebuggingConfigured = $true
} catch {
    Write-Log "Failed to create debug configuration: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# GIT INTEGRATION SETUP
# ===================================================================

Write-Log "Configuring Git integration for Cursor IDE..." "INFO"

# Create or update .gitignore for Azure AI development
$gitignoreContent = @"
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environment
azure-ai-envsource/
azure-ai-envsource-backup-*/
venv/
env/
ENV/

# Azure & Sensitive Data
.env
.env.local
.env.production
*.key
*.pem
*.p12
azure_credentials.json

# Logs
*.log
logs/
azure_*.log
dev_restoration_*.log
cursor_setup_*.log
test_azure_workflow_*.log

# IDE
.vscode/settings.json
.cursor/
.idea/

# OS
.DS_Store
Thumbs.db
desktop.ini

# Azure
.azure/
azure-pipelines.yml

# Node.js (for MCP server)
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
package-lock.json

# Compiled files
*.js.map
dist/
build/

# Temporary files
temp/
tmp/
*.tmp
*.temp
"@

try {
    if (-not (Test-Path ".gitignore") -or $Force) {
        $gitignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8
        Write-Log ".gitignore file created/updated" "SUCCESS"
        $SetupResults.GitIntegrated = $true
    } else {
        Write-Log ".gitignore already exists (use -Force to overwrite)" "INFO"
        $SetupResults.GitIntegrated = $true
    }
} catch {
    Write-Log "Failed to create .gitignore: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# CURSOR-SPECIFIC CONFIGURATION FILES
# ===================================================================

Write-Log "Creating Cursor-specific configuration files..." "INFO"

# Create cursor.json for workspace-specific settings
$cursorWorkspaceConfig = @{
    "composer.enabled" = $true
    "composer.autoAcceptEnabled" = $false
    "composer.models" = @("claude-3.5-sonnet", "gpt-4", "azure-openai")
    "azure" = @{
        "enabled" = $true
        "endpoint" = $CursorConfig.AzureEndpoint
        "deployment" = $CursorConfig.ModelDeployment
        "subscriptionId" = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"
    }
    "chat.enabled" = $true
    "chat.models" = @("claude-3.5-sonnet", "azure-openai")
    "completion.enabled" = $true
    "completion.models" = @("azure-openai")
}

try {
    $cursorWorkspaceConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "cursor.json" -Encoding UTF8
    Write-Log "Cursor workspace configuration created" "SUCCESS"
} catch {
    Write-Log "Failed to create Cursor configuration: $($_.Exception.Message)" "ERROR"
}

# ===================================================================
# VALIDATION AND TESTING
# ===================================================================

Write-Log "Validating Cursor IDE configuration..." "INFO"

# Test MCP server availability
if ($SetupResults.MCPServerConfigured) {
    if (Test-Path $CursorConfig.MCPServerPath) {
        Push-Location $CursorConfig.MCPServerPath
        try {
            Write-Log "Testing MCP server startup..." "INFO"
            $nodeCheck = node --version 2>$null
            if ($nodeCheck) {
                Write-Log "Node.js is available for MCP server: $nodeCheck" "SUCCESS"
                
                # Quick syntax check
                if (Test-Path "index.js") {
                    $syntaxCheck = node -c index.js 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "MCP server syntax validation passed" "SUCCESS"
                    } else {
                        Write-Log "MCP server syntax validation failed" "WARN"
                    }
                }
            } else {
                Write-Log "Node.js not found for MCP server" "ERROR"
            }
        } catch {
            Write-Log "Error testing MCP server: $($_.Exception.Message)" "ERROR"
        } finally {
            Pop-Location
        }
    }
}

# ===================================================================
# SETUP SUMMARY AND INSTRUCTIONS
# ===================================================================

Write-Log "=== CURSOR IDE AZURE AI CONFIGURATION SUMMARY ===" "INFO"

$totalChecks = $SetupResults.Count
$passedChecks = ($SetupResults.Values | Where-Object { $_ -eq $true }).Count
$successRate = [math]::Round(($passedChecks / $totalChecks) * 100, 2)

Write-Log "Configuration Success Rate: $passedChecks/$totalChecks ($successRate%)" "INFO"
Write-Log "" "INFO"

foreach ($result in $SetupResults.GetEnumerator()) {
    $status = if ($result.Value) { "CONFIGURED" } else { "NEEDS ATTENTION" }
    $level = if ($result.Value) { "SUCCESS" } else { "WARN" }
    Write-Log "$($result.Key): $status" $level
}

Write-Log "" "INFO"
Write-Log "=== NEXT STEPS ===" "INFO"

if (-not $SetupResults.CursorDetected) {
    Write-Log "1. Install Cursor IDE from https://cursor.sh/" "INFO"
}

Write-Log "2. Open Cursor IDE and load this workspace" "INFO"
Write-Log "3. Install recommended extensions when prompted" "INFO"
Write-Log "4. Configure Azure OpenAI API key in .env file" "INFO"

if ($SetupResults.MCPServerConfigured) {
    Write-Log "5. Test MCP server connection in Cursor IDE settings" "INFO"
    Write-Log "6. Verify Azure model integration in AI chat" "INFO"
} else {
    Write-Log "5. Set up MCP server manually if needed" "INFO"
}

Write-Log "7. Test the development environment using: .\test_azure_workflow.ps1" "INFO"

# Create quick start guide
$quickStartGuide = @"
# Cursor IDE Azure AI Development - Quick Start Guide

## Opening the Workspace
1. Launch Cursor IDE
2. Open this folder as a workspace
3. Install recommended extensions when prompted

## Testing Azure Integration
1. Open the Command Palette (Ctrl+Shift+P)
2. Search for "Azure: Sign In" and authenticate
3. Test the Python environment by running azure.py
4. Verify MCP server connection in settings

## Using Azure OpenAI in Cursor
1. Open AI Chat panel (Ctrl+L)
2. Select the Azure OpenAI model
3. Test with a simple query about Azure services

## Development Workflow
1. Activate the Python environment: .\azure-ai-envsource\Scripts\activate
2. Edit Python files with full IntelliSense support
3. Use debugging configurations for testing
4. Leverage MCP tools for Azure resource management

## Troubleshooting
- Check .env file for correct Azure credentials
- Verify MCP server is running: check Task Manager for node.js process
- Review logs in the log file
- Run validation: .\validate_azure_environment.ps1

## Key Files Created
- .cursorrules: Development standards and guidelines
- cursor.json: Workspace-specific Cursor configuration
- .vscode/settings.json: VSCode/Cursor workspace settings
- .vscode/launch.json: Debug configurations
- .vscode/extensions.json: Recommended extensions
- $($CursorConfig.MCPConfigPath)\mcp.json: MCP server configuration

For detailed troubleshooting, check the log file.
"@

try {
    $quickStartGuide | Out-File -FilePath "CURSOR_QUICK_START.md" -Encoding UTF8
    Write-Log "Quick start guide created: CURSOR_QUICK_START.md" "SUCCESS"
} catch {
    Write-Log "Failed to create quick start guide: $($_.Exception.Message)" "WARN"
}

Write-Log "=== CURSOR IDE AZURE AI CONFIGURATION COMPLETED ===" "INFO"
Write-Log "Log file: $LogPath" "INFO"

if ($successRate -ge 75) {
    Write-Log "Cursor IDE configuration completed successfully" "SUCCESS"
    exit 0
} else {
    Write-Log "Cursor IDE configuration completed with issues. Please review the log and follow next steps." "WARN"
    exit 1
}