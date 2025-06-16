# Setup-DetectiveMonitoring.ps1
# Establishes comprehensive monitoring for all Detective Agency resources

# 1. Create Log Analytics workspace
az monitor log-analytics workspace create --resource-group $resourceGroupName --workspace-name $logAnalyticsName --location $location

# 2. Enable Azure Monitor for all resources
$resourceIds = $(az resource list --resource-group $resourceGroupName --query "[].id" -o tsv)
foreach ($resourceId in $resourceIds) {
    # Enable diagnostics
    az monitor diagnostic-settings create --name "AllResourcesDiagnostics" --resource $resourceId --workspace $(az monitor log-analytics workspace show --resource-group $resourceGroupName --workspace-name $logAnalyticsName --query id -o tsv) --logs @"$PWD\monitoring-config.json"
}

# 3. Set up custom dashboards
az portal dashboard create --resource-group $resourceGroupName --name "DetectiveAgencyOperations" --location $location --input-path "$PWD\dashboard-template.json"

# 4. Configure alerts
az monitor alert-rule create --name "HighSeverityEvents" --resource-group $resourceGroupName --condition "count requests where severity >= 2 > 5" --window-size "PT5M" --action $(az monitor action-group show --resource-group $resourceGroupName --name "SecurityTeam" --query id -o tsv)