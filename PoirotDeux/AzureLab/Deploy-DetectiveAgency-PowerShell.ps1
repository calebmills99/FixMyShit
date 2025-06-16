# Deploy Detective Agency Resources using Azure PowerShell
# By Hercule Poirot 2.0

Write-Host "DETECTIVE AGENCY DEPLOYMENT (POWERSHELL)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$resourceGroupName = "guardr"
$location = "eastus"
$baseName = "detective"

# Existing resources
$existingKeyVaultName = "midnightkeyvault03e7c773"
$existingAppInsightsName = "midnightinsightscbd64381"
$existingStorageAccountName = "midnightstoragefeedb3dcc"

# Ensure we're in the right subscription
$targetSubscriptionId = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"
Set-AzContext -SubscriptionId $targetSubscriptionId | Out-Null

Write-Host "Deploying to Resource Group: $resourceGroupName" -ForegroundColor Yellow
Write-Host "Location: $location" -ForegroundColor Yellow
Write-Host ""

# Get existing resources
Write-Host "[STEP 1] Retrieving existing resources..." -ForegroundColor Yellow
$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $existingKeyVaultName
$appInsights = Get-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $existingAppInsightsName
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $existingStorageAccountName

Write-Host "[FOUND] Key Vault: $($keyVault.VaultName)" -ForegroundColor Green
Write-Host "[FOUND] App Insights: $($appInsights.Name)" -ForegroundColor Green
Write-Host "[FOUND] Storage: $($storageAccount.StorageAccountName)" -ForegroundColor Green
Write-Host ""

# Create Log Analytics Workspace
Write-Host "[STEP 2] Creating Log Analytics Workspace..." -ForegroundColor Yellow
$logAnalyticsName = "${baseName}logs"
try {
    $workspace = New-AzOperationalInsightsWorkspace `
        -ResourceGroupName $resourceGroupName `
        -Name $logAnalyticsName `
        -Location $location `
        -Sku "PerGB2018" `
        -RetentionInDays 30 `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] Log Analytics Workspace created: $($workspace.Name)" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*") {
        Write-Host "[EXISTS] Log Analytics Workspace already exists" -ForegroundColor Yellow
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $logAnalyticsName
    } else {
        Write-Host "[ERROR] Failed to create Log Analytics: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Create App Service Plan
Write-Host "[STEP 3] Creating App Service Plan..." -ForegroundColor Yellow
$planName = "${baseName}-plan"
try {
    $plan = New-AzAppServicePlan `
        -ResourceGroupName $resourceGroupName `
        -Name $planName `
        -Location $location `
        -Tier "Dynamic" `
        -WorkerSize "Small" `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] App Service Plan created: $($plan.Name)" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*") {
        Write-Host "[EXISTS] App Service Plan already exists" -ForegroundColor Yellow
        $plan = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $planName
    } else {
        Write-Host "[ERROR] Failed to create App Service Plan: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Create Function App 1: Evidence Collector
Write-Host "[STEP 4] Creating Evidence Collector Function App..." -ForegroundColor Yellow
$func1Name = "${baseName}-evidence"
try {
    # Get storage account key
    $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $existingStorageAccountName)[0].Value
    $storageConnection = "DefaultEndpointsProtocol=https;AccountName=$existingStorageAccountName;AccountKey=$storageKey;EndpointSuffix=core.windows.net"
    
    $funcApp1 = New-AzFunctionApp `
        -ResourceGroupName $resourceGroupName `
        -Name $func1Name `
        -PlanName $planName `
        -StorageAccountName $existingStorageAccountName `
        -Runtime "PowerShell" `
        -RuntimeVersion "7.2" `
        -OSType "Windows" `
        -Location $location `
        -ApplicationInsightsName $existingAppInsightsName `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] Evidence Collector Function created: $($funcApp1.Name)" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*") {
        Write-Host "[EXISTS] Evidence Collector Function already exists" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Failed to create Evidence Collector: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Create Function App 2: Case Analyzer
Write-Host "[STEP 5] Creating Case Analyzer Function App..." -ForegroundColor Yellow
$func2Name = "${baseName}-analyzer"
try {
    $funcApp2 = New-AzFunctionApp `
        -ResourceGroupName $resourceGroupName `
        -Name $func2Name `
        -PlanName $planName `
        -StorageAccountName $existingStorageAccountName `
        -Runtime "DotNet" `
        -RuntimeVersion "6" `
        -OSType "Windows" `
        -Location $location `
        -ApplicationInsightsName $existingAppInsightsName `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] Case Analyzer Function created: $($funcApp2.Name)" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*") {
        Write-Host "[EXISTS] Case Analyzer Function already exists" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Failed to create Case Analyzer: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Create Logic App
Write-Host "[STEP 6] Creating Logic App..." -ForegroundColor Yellow
$logicAppName = "${baseName}-logic"

# Logic App definition
$definition = @{
    '$schema' = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
    contentVersion = "1.0.0.0"
    parameters = @{}
    triggers = @{
        manual = @{
            type = "Request"
            kind = "Http"
            inputs = @{
                schema = @{
                    type = "object"
                    properties = @{
                        caseId = @{ type = "string" }
                        action = @{ type = "string" }
                    }
                }
            }
        }
    }
    actions = @{
        Initialize_variable = @{
            type = "InitializeVariable"
            inputs = @{
                variables = @(
                    @{
                        name = "DetectiveStatus"
                        type = "string"
                        value = "Investigation Started"
                    }
                )
            }
        }
        Response = @{
            type = "Response"
            runAfter = @{ Initialize_variable = @("Succeeded") }
            inputs = @{
                statusCode = 200
                body = "@variables('DetectiveStatus')"
            }
        }
    }
    outputs = @{}
}

try {
    # Note: Logic Apps require the Microsoft.Logic provider
    $logicProvider = Get-AzResourceProvider -ProviderNamespace Microsoft.Logic
    if ($logicProvider.RegistrationState -ne "Registered") {
        Write-Host "Registering Microsoft.Logic provider..." -ForegroundColor Yellow
        Register-AzResourceProvider -ProviderNamespace Microsoft.Logic
        Start-Sleep -Seconds 30
    }
    
    # Create the Logic App using generic resource creation
    $logicApp = New-AzResource `
        -ResourceGroupName $resourceGroupName `
        -ResourceType "Microsoft.Logic/workflows" `
        -ResourceName $logicAppName `
        -Location $location `
        -Properties @{
            state = "Enabled"
            definition = $definition
        } `
        -Force `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] Logic App created: $logicAppName" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*") {
        Write-Host "[EXISTS] Logic App already exists" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Failed to create Logic App: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# List all detective resources
$detectiveResources = Get-AzResource -ResourceGroupName $resourceGroupName | Where-Object { $_.Name -like "*detective*" }

if ($detectiveResources) {
    Write-Host "Detective Agency Resources:" -ForegroundColor Cyan
    $detectiveResources | ForEach-Object {
        Write-Host "  - $($_.Name) [$($_.ResourceType)]" -ForegroundColor White
    }
} else {
    Write-Host "[WARNING] No detective resources found!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[COMPLETE] Detective Agency deployment finished!" -ForegroundColor Green
Write-Host ""
Write-Host "Portal URL:" -ForegroundColor Yellow
Write-Host "https://portal.azure.com/#@art.edu/resource/subscriptions/$targetSubscriptionId/resourceGroups/$resourceGroupName/overview" -ForegroundColor White
Write-Host ""