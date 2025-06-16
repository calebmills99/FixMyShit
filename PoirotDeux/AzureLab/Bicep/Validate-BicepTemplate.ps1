# Validate-BicepTemplate.ps1
Write-Host "VALIDATING BICEP TEMPLATE" -ForegroundColor Magenta

# Build Bicep to ARM
$bicepFile = "C:\FixMyShit\PoirotDeux\AzureLab\Bicep\PoirotSmartDeploy.bicep"
$armFile = "C:\FixMyShit\PoirotDeux\AzureLab\ARM\PoirotSmartDeploy.json"

az bicep build --file $bicepFile --outfile $armFile

if ($?) {
    Write-Host "[OK] Bicep compiled successfully!" -ForegroundColor Green
    
    # Validate against Azure
    Write-Host "`n[VALIDATE] Testing deployment..." -ForegroundColor Yellow
    
    $result = az deployment group validate `
        --resource-group "guardr" `
        --template-file $armFile `
        --parameters "@C:\FixMyShit\PoirotDeux\AzureLab\Parameters\poirot.parameters.json" `
        --output json
        
    if ($?) {
        Write-Host "[OK] Template validation passed!" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Validation failed!" -ForegroundColor Red
    }
}