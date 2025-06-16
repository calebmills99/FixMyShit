# Create proper Azure Functions project structure for Detective Agency
# By Hercule Poirot 2.0

Write-Host "CREATING DETECTIVE FUNCTION APP PROJECT" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Define project location
$projectPath = "C:\FixMyShit\PoirotDeux\FunctionApps\DetectiveAgency"

Write-Host "Creating project at: $projectPath" -ForegroundColor Yellow
Write-Host ""

# Create directory structure
Write-Host "[STEP 1] Creating directory structure..." -ForegroundColor Yellow
$directories = @(
    $projectPath,
    "$projectPath\CollectEvidence",
    "$projectPath\AnalyzeCase",
    "$projectPath\bin",
    "$projectPath\.vscode"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  [CREATED] $dir" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[STEP 2] Creating host.json..." -ForegroundColor Yellow

# Create host.json
$hostJson = @{
    version = "2.0"
    logging = @{
        applicationInsights = @{
            samplingSettings = @{
                isEnabled = $true
                excludedTypes = "Request"
            }
        }
    }
    extensionBundle = @{
        id = "Microsoft.Azure.Functions.ExtensionBundle"
        version = "[3.*, 4.0.0)"
    }
    functionTimeout = "00:10:00"
} | ConvertTo-Json -Depth 10

$hostJson | Out-File -FilePath "$projectPath\host.json" -Encoding UTF8
Write-Host "  [CREATED] host.json" -ForegroundColor Green

Write-Host ""
Write-Host "[STEP 3] Creating local.settings.json..." -ForegroundColor Yellow

# Create local.settings.json
$localSettings = @{
    IsEncrypted = $false
    Values = @{
        AzureWebJobsStorage = "UseDevelopmentStorage=true"
        FUNCTIONS_WORKER_RUNTIME = "powershell"
        FUNCTIONS_WORKER_RUNTIME_VERSION = "7.2"
    }
} | ConvertTo-Json -Depth 10

$localSettings | Out-File -FilePath "$projectPath\local.settings.json" -Encoding UTF8
Write-Host "  [CREATED] local.settings.json" -ForegroundColor Green

Write-Host ""
Write-Host "[STEP 4] Creating requirements.psd1..." -ForegroundColor Yellow

# Create requirements.psd1 for PowerShell dependencies
$requirements = @'
# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'.
    'Az' = '11.*'
}
'@

$requirements | Out-File -FilePath "$projectPath\requirements.psd1" -Encoding UTF8
Write-Host "  [CREATED] requirements.psd1" -ForegroundColor Green

Write-Host ""
Write-Host "[STEP 5] Creating profile.ps1..." -ForegroundColor Yellow

# Create profile.ps1
$profile = @'
# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity
}

# Detective Agency initialization
Write-Host "Detective Poirot 2.0 Azure Functions initialized!"
'@

$profile | Out-File -FilePath "$projectPath\profile.ps1" -Encoding UTF8
Write-Host "  [CREATED] profile.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "[STEP 6] Creating Function: CollectEvidence..." -ForegroundColor Yellow

# Create CollectEvidence function.json
$functionJson = @{
    bindings = @(
        @{
            authLevel = "function"
            type = "httpTrigger"
            direction = "in"
            name = "Request"
            methods = @("get", "post")
        },
        @{
            type = "http"
            direction = "out"
            name = "Response"
        }
    )
} | ConvertTo-Json -Depth 10

$functionJson | Out-File -FilePath "$projectPath\CollectEvidence\function.json" -Encoding UTF8

# Create CollectEvidence run.ps1
$runPs1 = @'
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Write-Host "Detective Poirot 2.0 - Evidence Collection Service"

# Parse the request
$evidence = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    requestId = [guid]::NewGuid().ToString()
    method = $Request.Method
    query = $Request.Query
    body = $Request.Body
}

# Log the evidence
Write-Information "Evidence collected: $($evidence | ConvertTo-Json -Compress)"

# Analyze based on request type
if ($Request.Query.case -or $Request.Body.case) {
    $caseId = $Request.Query.case ?? $Request.Body.case
    $response = @{
        status = "Evidence Collected"
        caseId = $caseId
        detective = "Poirot 2.0"
        message = "The little grey cells are working on case: $caseId"
        timestamp = $evidence.timestamp
    }
} else {
    $response = @{
        status = "Ready"
        detective = "Poirot 2.0"
        message = "Submit evidence with 'case' parameter"
        endpoint = "/api/CollectEvidence?case=YOUR_CASE_ID"
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Headers = @{
        "Content-Type" = "application/json"
    }
    Body = $response | ConvertTo-Json
})
'@

$runPs1 | Out-File -FilePath "$projectPath\CollectEvidence\run.ps1" -Encoding UTF8
Write-Host "  [CREATED] CollectEvidence function" -ForegroundColor Green

Write-Host ""
Write-Host "[STEP 7] Creating .gitignore..." -ForegroundColor Yellow

# Create .gitignore
$gitignore = @'
bin
obj
csx
.vs
edge
Publish

*.user
*.suo
*.cscfg
*.Cache
project.lock.json

/packages
/TestResults

/tools/NuGet.exe
/App_Data
/secrets
/data
.secrets
appsettings.json
local.settings.json

node_modules
dist

# Local python packages
.python_packages/

# Python Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Azurite artifacts
__blobstorage__
__queuestorage__
__azurite_db*__.json
'@

$gitignore | Out-File -FilePath "$projectPath\.gitignore" -Encoding UTF8
Write-Host "  [CREATED] .gitignore" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "PROJECT CREATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Project structure created at:" -ForegroundColor Cyan
Write-Host "$projectPath" -ForegroundColor White
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Navigate to project directory:" -ForegroundColor Cyan
Write-Host "   cd $projectPath" -ForegroundColor White
Write-Host ""
Write-Host "2. Test locally (requires Azure Functions Core Tools):" -ForegroundColor Cyan
Write-Host "   func start" -ForegroundColor White
Write-Host ""
Write-Host "3. Deploy to Azure:" -ForegroundColor Cyan
Write-Host "   func azure functionapp publish poirot2" -ForegroundColor White
Write-Host ""
Write-Host "4. Or use VS Code:" -ForegroundColor Cyan
Write-Host "   - Open the folder in VS Code" -ForegroundColor White
Write-Host "   - Install 'Azure Functions' extension" -ForegroundColor White
Write-Host "   - Right-click and deploy to Function App" -ForegroundColor White
Write-Host ""

# Create a quick test script
$testScript = @'
# Test the local function
$uri = "http://localhost:7071/api/CollectEvidence"
$body = @{
    case = "AZURE-001"
    type = "Deployment Mystery"
    evidence = "Function Apps working in Canada Central"
    priority = "High"
} | ConvertTo-Json

Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
'@

$testScript | Out-File -FilePath "$projectPath\Test-LocalFunction.ps1" -Encoding UTF8
Write-Host "[BONUS] Created Test-LocalFunction.ps1 for testing" -ForegroundColor Green