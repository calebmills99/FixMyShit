# Deploy Detective Agency using only basic Az.Resources module
# No specialized modules required!
# By Hercule Poirot 2.0

Write-Host "DETECTIVE AGENCY DEPLOYMENT (BASIC AZ)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$resourceGroupName = "guardr"
$location = "eastus"
$baseName = "detective"
$subscriptionId = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"

# Set context
Set-AzContext -SubscriptionId $subscriptionId | Out-Null

Write-Host "Using Bicep template deployment..." -ForegroundColor Yellow
Write-Host ""

# First, let's create a simplified Bicep template
$bicepContent = @'
// Simplified Detective Agency Deployment
param location string = resourceGroup().location
param baseName string = 'detective'

// Existing resources
param existingKeyVaultName string = 'midnightkeyvault03e7c773'
param existingAppInsightsName string = 'midnightinsightscbd64381'
param existingStorageAccountName string = 'midnightstoragefeedb3dcc'

// Reference existing resources
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: existingKeyVaultName
}

resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: existingAppInsightsName
}

resource existingStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: existingStorageAccountName
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${baseName}logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${baseName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Function App 1
resource evidenceCollector 'Microsoft.Web/sites@2022-09-01' = {
  name: '${baseName}-evidence'
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${existingStorage.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: existingAppInsights.properties.InstrumentationKey
        }
      ]
    }
  }
}

// Function App 2
resource caseAnalyzer 'Microsoft.Web/sites@2022-09-01' = {
  name: '${baseName}-analyzer'
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${existingStorage.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: existingAppInsights.properties.InstrumentationKey
        }
      ]
    }
  }
}

output deploymentStatus string = 'Success'
output logAnalyticsName string = logAnalytics.name
output functionApp1 string = evidenceCollector.name
output functionApp2 string = caseAnalyzer.name
'@

# Save Bicep template
$bicepPath = "C:\FixMyShit\PoirotDeux\AzureLab\detective-simple.bicep"
$bicepContent | Out-File -FilePath $bicepPath -Encoding UTF8
Write-Host "[SAVED] Bicep template to: $bicepPath" -ForegroundColor Green
Write-Host ""

# Deploy using New-AzResourceGroupDeployment
Write-Host "Starting deployment..." -ForegroundColor Yellow
$deploymentName = "detective-$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    $deployment = New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $bicepPath `
        -Verbose
    
    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host ""
        Write-Host "[SUCCESS] Deployment completed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Deployed resources:" -ForegroundColor Cyan
        Write-Host "  - Log Analytics: $($deployment.Outputs.logAnalyticsName.Value)" -ForegroundColor White
        Write-Host "  - Evidence Collector: $($deployment.Outputs.functionApp1.Value)" -ForegroundColor White
        Write-Host "  - Case Analyzer: $($deployment.Outputs.functionApp2.Value)" -ForegroundColor White
    } else {
        Write-Host "[ERROR] Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Deployment failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checking deployment history..." -ForegroundColor Yellow
    
    # Get deployment details
    $failedDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName
    if ($failedDeployment.CorrelationId) {
        Write-Host "Correlation ID: $($failedDeployment.CorrelationId)" -ForegroundColor Yellow
        Write-Host "Check Azure Portal for detailed error information" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Checking what was created..." -ForegroundColor Yellow
$detectiveResources = Get-AzResource -ResourceGroupName $resourceGroupName | Where-Object { $_.Name -like "*detective*" }

if ($detectiveResources) {
    Write-Host ""
    Write-Host "Detective resources found:" -ForegroundColor Green
    $detectiveResources | ForEach-Object {
        Write-Host "  - $($_.Name) [$($_.ResourceType)]" -ForegroundColor White
    }
} else {
    Write-Host "No detective resources found yet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[COMPLETE] Script finished!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Portal URL:" -ForegroundColor Yellow
Write-Host "https://portal.azure.com/#@art.edu/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/overview" -ForegroundColor White