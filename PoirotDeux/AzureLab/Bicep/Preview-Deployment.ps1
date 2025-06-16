# Preview-Deployment.ps1
Write-Host "PREVIEW DEPLOYMENT CHANGES" -ForegroundColor Magenta

az deployment group what-if `
    --resource-group "guardr" `
    --template-file "C:\FixMyShit\PoirotDeux\AzureLab\ARM\PoirotSmartDeploy.json" `
    --parameters "@C:\FixMyShit\PoirotDeux\AzureLab\Parameters\poirot.parameters.json"