# Deploy Azure Detective Agency to guardr
# By Hercule Poirot 2.0

Write-Host "AZURE DETECTIVE AGENCY DEPLOYMENT" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Ensure we're in the right subscription
Write-Host "[STEP 1] Setting Azure context..." -ForegroundColor Yellow
az account set --subscription "831ed202-1c08-4b14-91eb-19ee3e5b3c78"

# Quick verification
$currentSub = az account show --query name --output tsv
Write-Host "Current subscription: $currentSub" -ForegroundColor Green
Write-Host ""

# Run inventory first
Write-Host "[STEP 2] Running inventory..." -ForegroundColor Yellow
& "C:\FixMyShit\PoirotDeux\Scripts\Get-GuardrInventory.ps1"
Write-Host ""

# Deploy the Bicep template
Write-Host "[STEP 3] Deploying Detective Agency components..." -ForegroundColor Yellow
Write-Host "This will create:" -ForegroundColor White
Write-Host "  - Log Analytics Workspace" -ForegroundColor White
Write-Host "  - App Service Plan" -ForegroundColor White
Write-Host "  - Evidence Collector Function" -ForegroundColor White
Write-Host "  - Case Analyzer Function" -ForegroundColor White
Write-Host "  - Detective Orchestrator Logic App" -ForegroundColor White
Write-Host ""
Write-Host "Using existing:" -ForegroundColor Green
Write-Host "  - Key Vault: midnightkeyvault03e7c773" -ForegroundColor Green
Write-Host "  - App Insights: midnightinsightscbd64381" -ForegroundColor Green
Write-Host "  - Storage: midnightstoragefeedb3dcc" -ForegroundColor Green
Write-Host ""

# Create deployment
$deploymentName = "detective-agency-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "Starting deployment: $deploymentName" -ForegroundColor Yellow
Write-Host ""

# Deploy using Azure CLI
$deploymentResult = az deployment group create `
    --resource-group guardr `
    --template-file "C:\FixMyShit\PoirotDeux\AzureLab\detective-agency-deployment.bicep" `
    --name $deploymentName `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Deployment completed!" -ForegroundColor Green
    Write-Host ""
    
    # Show deployed resources
    Write-Host "Deployed Resources:" -ForegroundColor Cyan
    Write-Host "  - Log Analytics: $($deploymentResult.properties.outputs.logAnalyticsWorkspaceId.value)" -ForegroundColor White
    Write-Host "  - Evidence Collector: $($deploymentResult.properties.outputs.evidenceCollectorFunctionId.value)" -ForegroundColor White
    Write-Host "  - Case Analyzer: $($deploymentResult.properties.outputs.caseAnalyzerFunctionId.value)" -ForegroundColor White
    Write-Host "  - Logic App: $($deploymentResult.properties.outputs.logicAppId.value)" -ForegroundColor White
    
    Write-Host ""
    Write-Host "[NEXT STEPS]" -ForegroundColor Magenta
    Write-Host "1. Configure Function App code" -ForegroundColor White
    Write-Host "2. Set up Logic App workflows" -ForegroundColor White
    Write-Host "3. Configure diagnostic collection" -ForegroundColor White
    Write-Host "4. Test the Detective Agency!" -ForegroundColor White
} else {
    Write-Host "[ERROR] Deployment failed!" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Name conflicts (try changing baseName parameter)" -ForegroundColor White
    Write-Host "  - Missing permissions" -ForegroundColor White
    Write-Host "  - Resource quotas" -ForegroundColor White
}

Write-Host ""
Write-Host "Deployment script complete! - H. Poirot 2.0" -ForegroundColor Cyan
