# Simple deployment without JSON parsing issues
# By Hercule Poirot 2.0

Write-Host "AZURE DETECTIVE AGENCY DEPLOYMENT (SIMPLIFIED)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Deploy without parsing JSON output
$deploymentName = "detective-agency-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "Starting deployment: $deploymentName" -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Yellow
Write-Host ""

# Deploy using Azure CLI without JSON parsing
az deployment group create `
    --resource-group guardr `
    --template-file "C:\FixMyShit\PoirotDeux\AzureLab\detective-agency-deployment.bicep" `
    --name $deploymentName `
    --output table

# Check deployment status
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] Deployment completed!" -ForegroundColor Green
    Write-Host ""
    
    # Show what was deployed
    Write-Host "Verifying deployed resources..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check for new Function Apps
    Write-Host "Function Apps:" -ForegroundColor Cyan
    az functionapp list --resource-group guardr --query "[?contains(name, 'detective')].{Name:name, State:state}" --output table
    
    # Check for Logic Apps
    Write-Host ""
    Write-Host "Logic Apps:" -ForegroundColor Cyan
    az logic workflow list --resource-group guardr --query "[?contains(name, 'detective')].{Name:name, State:state}" --output table
    
    # Check for Log Analytics
    Write-Host ""
    Write-Host "Log Analytics Workspaces:" -ForegroundColor Cyan
    az monitor log-analytics workspace list --resource-group guardr --query "[?contains(name, 'detective')].{Name:name, Location:location}" --output table
    
    Write-Host ""
    Write-Host "[DEPLOYMENT COMPLETE]" -ForegroundColor Green
    Write-Host ""
    Write-Host "View in Azure Portal:" -ForegroundColor Yellow
    Write-Host "https://portal.azure.com/#@art.edu/resource/subscriptions/831ed202-1c08-4b14-91eb-19ee3e5b3c78/resourceGroups/guardr/overview" -ForegroundColor White
    
} else {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check deployment history:" -ForegroundColor Yellow
    Write-Host "az deployment group list --resource-group guardr --output table" -ForegroundColor White
    Write-Host ""
    Write-Host "View detailed error:" -ForegroundColor Yellow
    Write-Host "az deployment group show --resource-group guardr --name $deploymentName --query properties.error" -ForegroundColor White
}

Write-Host ""
Write-Host "Script complete! - H. Poirot 2.0" -ForegroundColor Cyan