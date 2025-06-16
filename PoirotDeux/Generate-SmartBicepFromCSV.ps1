# Generate-SmartBicepFromCSV.ps1
Write-Host "GENERATING SMART BICEP BASED ON YOUR MENU" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta

$bicepContent = @'
// POIROT'S SMART AZURE DEPLOYMENT
// Using existing resources where possible!

param location string = 'eastus'
param environment string = 'prod'

// EXISTING RESOURCES TO REUSE
resource existingStorage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: 'midnightstoragefeedb3dcc'
  scope: resourceGroup('guardr')  // Assuming from your CSV
}

resource existingOpenAI 'Microsoft.CognitiveServices/accounts@2022-12-01' existing = {
  name: 'midnight'
  scope: resourceGroup('guardr')
}

resource existingVNet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'Golden-vnet'
  scope: resourceGroup('guardr')
}

// NEW RESOURCES WE NEED TO CREATE

// 1. Key Vault (Essential for secrets!)
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-poirot-${environment}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

// 2. Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-poirot-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// 3. Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-poirot-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// 4. Function App for automation
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'func-poirot-${environment}'
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${existingStorage.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${existingStorage.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
    }
  }
}

// 5. Hosting plan for Function App
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-poirot-${environment}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// 6. Logic App for workflows
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-poirot-${environment}'
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      triggers: {}
      actions: {}
    }
  }
}

// OUTPUTS
output keyVaultName string = keyVault.name
output appInsightsName string = appInsights.name
output functionAppName string = functionApp.name
output logicAppName string = logicApp.name
output existingOpenAIName string = existingOpenAI.name
output existingStorageName string = existingStorage.name
'@

$bicepContent | Out-File -FilePath "C:\FixMyShit\PoirotDeux\AzureLab\Bicep\PoirotSmartDeploy.bicep" -Encoding UTF8
Write-Host "[OK] Smart Bicep template created!" -ForegroundColor Green
Write-Host "     Reuses: Storage, OpenAI, VNet" -ForegroundColor Cyan
Write-Host "     Creates: KeyVault, AppInsights, Functions, Logic Apps" -ForegroundColor Yellow