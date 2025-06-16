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
