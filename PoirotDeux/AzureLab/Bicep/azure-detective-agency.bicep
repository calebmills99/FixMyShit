// Azure Detective Agency - Modern Cloud Architecture
// A proper modular Bicep template with best practices

targetScope = 'subscription'

@description('Primary region for deployment')
param primaryLocation string = 'eastus'

@description('Secondary region for disaster recovery')
param secondaryLocation string = 'westus2'

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Unique suffix for resources')
param uniqueSuffix string = uniqueString(subscription().id)

// Resource group definitions
resource primaryRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-detective-${environment}-${primaryLocation}'
  location: primaryLocation
  tags: {
    Environment: environment
    Project: 'Detective Agency'
    CaseFile: 'PoirotDeux'
  }
}

resource secondaryRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-detective-${environment}-${secondaryLocation}'
  location: secondaryLocation
  tags: {
    Environment: environment
    Project: 'Detective Agency'
    CaseFile: 'PoirotDeux'
  }
}

// Call modular templates for each component
module coreInfrastructure 'modules/core-infrastructure.bicep' = {
  name: 'coreInfraDeployment'
  scope: primaryRG
  params: {
    location: primaryLocation
    environment: environment
    uniqueSuffix: uniqueSuffix
  }
}

module disasterRecovery 'modules/disaster-recovery.bicep' = {
  name: 'drDeployment'
  scope: secondaryRG
  params: {
    primaryLocation: primaryLocation
    secondaryLocation: secondaryLocation
    environment: environment
    uniqueSuffix: uniqueSuffix
    primaryStorageId: coreInfrastructure.outputs.storageAccountId
  }
}

// Additional modules - security, monitoring, etc.
