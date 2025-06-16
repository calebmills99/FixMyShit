# Deploy-PoirotInfrastructure.ps1
Write-Host "🚀 DEPLOYING POIROT'S AZURE INFRASTRUCTURE" -ForegroundColor Magenta

$deploymentName = "poirot-deploy-$(Get-Date -Format 'yyyyMMdd-HHmm')"

az deployment group create `
    --name $deploymentName `
    --resource-group "guardr" `
    --template-file "C:\FixMyShit\PoirotDeux\AzureLab\ARM\PoirotSmartDeploy.json" `
    --parameters "@C:\FixMyShit\PoirotDeux\AzureLab\Parameters\poirot.parameters.json" `
    --output json

if ($?) {
    Write-Host "`n✅ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "🎉 Poirot's Azure Detective Agency is LIVE!" -ForegroundColor Magenta
}