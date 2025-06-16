# Quick Inventory of guardr Resources
# By Hercule Poirot 2.0

Write-Host "GUARDR RESOURCE INVENTORY" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Get all resources with their key properties
$resources = az resource list --resource-group guardr --output json | ConvertFrom-Json

# Key infrastructure we care about for Detective Agency
Write-Host "[EXISTING INFRASTRUCTURE]" -ForegroundColor Green
Write-Host ""

# Key Vault
$keyVault = $resources | Where-Object { $_.type -eq "Microsoft.KeyVault/vaults" }
Write-Host "Key Vault: $($keyVault.name)" -ForegroundColor Yellow

# Application Insights
$appInsights = $resources | Where-Object { $_.type -eq "microsoft.insights/components" }
Write-Host "Application Insights: $($appInsights.name)" -ForegroundColor Yellow

# Storage Accounts
$storage = $resources | Where-Object { $_.type -eq "Microsoft.Storage/storageAccounts" }
Write-Host "Storage Accounts:" -ForegroundColor Yellow
$storage | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor White }

# Cognitive Services (including OpenAI)
$cognitive = $resources | Where-Object { $_.type -eq "Microsoft.CognitiveServices/accounts" }
Write-Host "Cognitive Services:" -ForegroundColor Yellow
$cognitive | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor White }

Write-Host ""
Write-Host "[MISSING FOR DETECTIVE AGENCY]" -ForegroundColor Red
Write-Host ""

# Check for Function Apps
$functionApps = $resources | Where-Object { $_.type -eq "Microsoft.Web/sites" -and $_.kind -like "*functionapp*" }
if ($functionApps.Count -eq 0) {
    Write-Host "- Function Apps: NONE FOUND (need to deploy)" -ForegroundColor Red
} else {
    Write-Host "- Function Apps: Found $($functionApps.Count)" -ForegroundColor Green
}

# Check for Logic Apps
$logicApps = $resources | Where-Object { $_.type -eq "Microsoft.Logic/workflows" }
if ($logicApps.Count -eq 0) {
    Write-Host "- Logic Apps: NONE FOUND (need to deploy)" -ForegroundColor Red
} else {
    Write-Host "- Logic Apps: Found $($logicApps.Count)" -ForegroundColor Green
}

# Check for Log Analytics
$logAnalytics = $resources | Where-Object { $_.type -eq "Microsoft.OperationalInsights/workspaces" }
if ($logAnalytics.Count -eq 0) {
    Write-Host "- Log Analytics Workspace: NONE FOUND (need to deploy)" -ForegroundColor Red
} else {
    Write-Host "- Log Analytics: $($logAnalytics.name)" -ForegroundColor Green
}

# Check for Service Bus
$serviceBus = $resources | Where-Object { $_.type -eq "Microsoft.ServiceBus/namespaces" }
if ($serviceBus.Count -eq 0) {
    Write-Host "- Service Bus: NONE FOUND (optional)" -ForegroundColor Yellow
} else {
    Write-Host "- Service Bus: $($serviceBus.name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "[EXPORT FOR BICEP]" -ForegroundColor Magenta

# Export key resource IDs for Bicep
@"
// Existing Resource References for Bicep
var existingKeyVaultName = '$($keyVault.name)'
var existingAppInsightsName = '$($appInsights.name)'
var existingStorageAccount = '$($storage[0].name)'  // Using first storage account
var resourceGroupName = 'guardr'
"@ | Out-File -FilePath "C:\FixMyShit\PoirotDeux\AzureLab\existing-resources.bicep" -Encoding UTF8

Write-Host ""
Write-Host "Exported to: C:\FixMyShit\PoirotDeux\AzureLab\existing-resources.bicep" -ForegroundColor Green
