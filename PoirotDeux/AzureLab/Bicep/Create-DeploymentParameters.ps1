# Create-DeploymentParameters.ps1
$parameters = @{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        location = @{ value = 'eastus' }
        environment = @{ value = 'prod' }
    }
}

$parameters | ConvertTo-Json -Depth 10 | Out-File -FilePath "C:\FixMyShit\PoirotDeux\AzureLab\Parameters\poirot.parameters.json" -Encoding UTF8
Write-Host "[OK] Parameter file created!" -ForegroundColor Green