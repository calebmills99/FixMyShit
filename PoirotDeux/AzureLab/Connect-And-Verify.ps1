# Connect to Azure and Verify Setup
# Using Azure PowerShell Modules
# By Hercule Poirot 2.0

Write-Host "AZURE POWERSHELL CONNECTION & VERIFICATION" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Connect to Azure
Write-Host "[STEP 1] Connecting to Azure..." -ForegroundColor Yellow
try {
    # Check if already connected
    $context = Get-AzContext
    if ($context) {
        Write-Host "Already connected as: $($context.Account.Id)" -ForegroundColor Green
        Write-Host "Current subscription: $($context.Subscription.Name)" -ForegroundColor Green
    } else {
        Connect-AzAccount
    }
} catch {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

Write-Host ""
Write-Host "[STEP 2] Setting correct subscription..." -ForegroundColor Yellow
$targetSubscriptionId = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"

Set-AzContext -SubscriptionId $targetSubscriptionId
$currentContext = Get-AzContext
Write-Host "Active subscription: $($currentContext.Subscription.Name) [$($currentContext.Subscription.Id)]" -ForegroundColor Green

Write-Host ""
Write-Host "[STEP 3] Verifying guardr resource group..." -ForegroundColor Yellow
$resourceGroup = Get-AzResourceGroup -Name "guardr" -ErrorAction SilentlyContinue

if ($resourceGroup) {
    Write-Host "[FOUND] Resource group 'guardr' exists in $($resourceGroup.Location)" -ForegroundColor Green
    
    # Count resources
    $resources = Get-AzResource -ResourceGroupName "guardr"
    Write-Host "Contains $($resources.Count) resources" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Resource group 'guardr' not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "[STEP 4] Checking existing infrastructure..." -ForegroundColor Yellow

# Check Key Vault
$keyVault = Get-AzKeyVault -ResourceGroupName "guardr" -VaultName "midnightkeyvault03e7c773" -ErrorAction SilentlyContinue
if ($keyVault) {
    Write-Host "[EXISTS] Key Vault: $($keyVault.VaultName)" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Key Vault: midnightkeyvault03e7c773" -ForegroundColor Red
}

# Check Application Insights
$appInsights = Get-AzApplicationInsights -ResourceGroupName "guardr" -Name "midnightinsightscbd64381" -ErrorAction SilentlyContinue
if ($appInsights) {
    Write-Host "[EXISTS] Application Insights: $($appInsights.Name)" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Application Insights: midnightinsightscbd64381" -ForegroundColor Red
}

# Check Storage Account
$storage = Get-AzStorageAccount -ResourceGroupName "guardr" -Name "midnightstoragefeedb3dcc" -ErrorAction SilentlyContinue
if ($storage) {
    Write-Host "[EXISTS] Storage Account: $($storage.StorageAccountName)" -ForegroundColor Green
} else {
    Write-Host "[MISSING] Storage Account: midnightstoragefeedb3dcc" -ForegroundColor Red
}

Write-Host ""
Write-Host "[READY] Azure PowerShell is configured and ready!" -ForegroundColor Green
Write-Host ""