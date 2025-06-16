// Azure Detective Agency - Incremental Deployment
// Deploys ONLY missing components, uses existing Key Vault and App Insights
// Location: C:\FixMyShit\PoirotDeux\AzureLab\

@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for Detective Agency resources')
param baseName string = 'detective'

@description('Existing Key Vault name')
param existingKeyVaultName string = 'midnightkeyvault03e7c773'

@description('Existing Application Insights name')
param existingAppInsightsName string = 'midnightinsightscbd64381'

@description('Existing Storage Account name')
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

// Deploy Log Analytics Workspace (if not exists)
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${baseName}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// App Service Plan for Function Apps
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${baseName}-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: false
  }
}

// Function App 1: Evidence Collector
resource evidenceCollectorFunc 'Microsoft.Web/sites@2022-09-01' = {
  name: '${baseName}-evidence-collector'
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

// Function App 2: Case Analyzer
resource caseAnalyzerFunc 'Microsoft.Web/sites@2022-09-01' = {
  name: '${baseName}-case-analyzer'
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

// Logic App for Orchestration
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${baseName}-orchestrator'
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                caseId: {
                  type: 'string'
                }
                action: {
                  type: 'string'
                }
              }
            }
          }
        }
      }
      actions: {
        Initialize_variable: {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'DetectiveStatus'
                type: 'string'
                value: 'Investigation Started'
              }
            ]
          }
        }
      }
      outputs: {}
    }
  }
}

// Diagnostic Settings for new resources
resource funcDiagnostics1 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: evidenceCollectorFunc
  name: 'send-to-analytics'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource funcDiagnostics2 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: caseAnalyzerFunc
  name: 'send-to-analytics'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
output logAnalyticsWorkspaceId string = logAnalytics.id
output evidenceCollectorFunctionId string = evidenceCollectorFunc.id
output caseAnalyzerFunctionId string = caseAnalyzerFunc.id
output logicAppId string = logicApp.id
output existingKeyVaultId string = existingKeyVault.id
output existingAppInsightsId string = existingAppInsights.id
