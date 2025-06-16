# Setup-DetectiveSecurityInfra.ps1
# Establishes proper security foundations for the Detective Agency

Write-Host "🔒 SETTING UP DETECTIVE AGENCY SECURITY INFRASTRUCTURE" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta

# 1. Create Key Vault with proper access policies
$keyVaultName = "kv-detective-${environment}-${uniqueSuffix}"
az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location --sku standard --enable-rbac-authorization true

# 2. Assign managed identity to Function App
az functionapp identity assign --name $functionAppName --resource-group $resourceGroupName

# 3. Get the principal ID of the function app's managed identity
$principalId = $(az functionapp identity show --name $functionAppName --resource-group $resourceGroupName --query principalId -o tsv)

# 4. Assign Key Vault Secrets User role to the function app
az role assignment create --assignee $principalId --role "Key Vault Secrets User" --scope $(az keyvault show --name $keyVaultName --query id -o tsv)

# 5. Enable diagnostic logging
az monitor diagnostic-settings create --name "KeyVaultLogging" --resource $(az keyvault show --name $keyVaultName --query id -o tsv) --workspace $(az monitor log-analytics workspace show --resource-group $resourceGroupName --workspace-name $logAnalyticsName --query id -o tsv) --logs '[{"category":"AuditEvent","enabled":true}]'

Write-Host "✅ Security infrastructure established with proper segregation of duties" -ForegroundColor Green