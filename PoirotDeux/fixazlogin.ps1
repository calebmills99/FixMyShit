# Set-CorrectDefaultSubscription.ps1
Write-Host "SETTING CORRECT DEFAULT SUBSCRIPTION" -ForegroundColor Magenta

# The one with your resources!
$correctSubId = "f7717a09-66d2-488b-9f21-6af0d0b3af92"

# Set as default
az account set --subscription $correctSubId
Write-Host "[OK] Default set to subscription with resources!" -ForegroundColor Green

# Mark it as default permanently
az account list --output json | ConvertFrom-Json | ForEach-Object {
    if ($_.id -eq $correctSubId) {
        az account set --subscription $_.id
        Write-Host "[OK] Subscription '$($_.name)' is now default" -ForegroundColor Green
        Write-Host "     This one has your midnight, keyvault, etc.!" -ForegroundColor Cyan
    }
}

# Test
Write-Host "`n[TEST] Checking resources in current subscription..." -ForegroundColor Yellow
$resources = az resource list --output json | ConvertFrom-Json
Write-Host "[OK] Found $($resources.Count) resources!" -ForegroundColor Green

# List some to verify
$resources | Select-Object -First 5 | ForEach-Object {
    Write-Host "   - $($_.name) [$($_.type)]" -ForegroundColor Green
}