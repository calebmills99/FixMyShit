# The Azure CLI Subscription Detective Script
# By Hercule Poirot 2.0 - "Order and Method!"
# Location: C:\FixMyShit\PoirotDeux\Scripts\

Write-Host "HERCULE POIROT 2.0: AZURE CLI DETECTIVE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# First, let's set the correct subscription (the one from the CSV)
$targetSubscriptionId = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"
Write-Host "Setting context to 'Azure subscription 1' (from CSV evidence)..." -ForegroundColor Yellow
az account set --subscription $targetSubscriptionId

# Verify we're in the right subscription
Write-Host ""
Write-Host "Current subscription context:" -ForegroundColor Cyan
az account show --output table
Write-Host ""

# Step 1: List all resource groups in this subscription
Write-Host "STEP 1: Searching for resource groups in this subscription..." -ForegroundColor Yellow
Write-Host ""

$resourceGroups = az group list --output json | ConvertFrom-Json

if ($resourceGroups.Count -eq 0) {
    Write-Host "[ERROR] No resource groups found in this subscription!" -ForegroundColor Red
} else {
    Write-Host "Found $($resourceGroups.Count) resource group(s):" -ForegroundColor Green
    foreach ($rg in $resourceGroups) {
        Write-Host "  - $($rg.name) (Location: $($rg.location))" -ForegroundColor White
        
        # Check if this is our phantom guardr
        if ($rg.name -eq "guardr") {
            Write-Host "    [FOUND] This is our missing 'guardr'!" -ForegroundColor Green
        }
    }
}

Write-Host ""

# Step 2: Specifically search for guardr
Write-Host "STEP 2: Direct search for 'guardr' resource group..." -ForegroundColor Yellow
$guardrCheck = az group exists --name guardr

if ($guardrCheck -eq "true") {
    Write-Host "[SUCCESS] Resource group 'guardr' EXISTS in this subscription!" -ForegroundColor Green
    Write-Host ""
    
    # Get details about guardr
    Write-Host "Details about 'guardr':" -ForegroundColor Cyan
    az group show --name guardr --output table
    
    # Count resources in guardr
    Write-Host ""
    Write-Host "Counting resources in 'guardr'..." -ForegroundColor Yellow
    $resources = az resource list --resource-group guardr --output json | ConvertFrom-Json
    Write-Host "Found $($resources.Count) resources in 'guardr'" -ForegroundColor Green
    
    if ($resources.Count -gt 0) {
        Write-Host ""
        Write-Host "Resource types in 'guardr':" -ForegroundColor Cyan
        $resources | Group-Object type | ForEach-Object {
            Write-Host "  * $($_.Count) x $($_.Name)" -ForegroundColor White
        }
    }
} else {
    Write-Host "[ERROR] Resource group 'guardr' NOT FOUND in this subscription!" -ForegroundColor Red
    Write-Host ""
    Write-Host "This is most peculiar! The CSV shows it should exist..." -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Check all three subscriptions
Write-Host "STEP 3: Let me check ALL your subscriptions for 'guardr'..." -ForegroundColor Yellow
Write-Host ""

$subscriptions = @(
    @{Name="Subscription 1 (first)"; Id="04fb6ed6-bd77-449c-8b88-e200a21ded5c"},
    @{Name="Azure subscription 1"; Id="831ed202-1c08-4b14-91eb-19ee3e5b3c78"},
    @{Name="Subscription 1 (default)"; Id="f7717a09-66d2-488b-9f21-6af0d0b3af92"}
)

$foundIn = @()

foreach ($sub in $subscriptions) {
    Write-Host "[CHECKING] $($sub.Name)..." -ForegroundColor White
    az account set --subscription $sub.Id 2>$null
    $exists = az group exists --name guardr
    
    if ($exists -eq "true") {
        Write-Host "  [FOUND] 'guardr' exists here!" -ForegroundColor Green
        $foundIn += $sub
    } else {
        Write-Host "  [NOT FOUND]" -ForegroundColor DarkGray
    }
}

Write-Host ""

# Step 4: Summary and recommendations
Write-Host "DETECTIVE'S FINDINGS:" -ForegroundColor Magenta
Write-Host "========================" -ForegroundColor Magenta
Write-Host ""

if ($foundIn.Count -gt 0) {
    Write-Host "The resource group 'guardr' was found in:" -ForegroundColor Green
    foreach ($location in $foundIn) {
        Write-Host "  [LOCATION] $($location.Name) (ID: $($location.Id))" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "To work with 'guardr', use:" -ForegroundColor Yellow
    Write-Host "  az account set --subscription $($foundIn[0].Id)" -ForegroundColor White -BackgroundColor DarkBlue
} else {
    Write-Host "[RESULT] The phantom 'guardr' was not found in ANY subscription!" -ForegroundColor Red
    Write-Host ""
    Write-Host "POSSIBLE EXPLANATIONS:" -ForegroundColor Yellow
    Write-Host "1. The CSV might be from a different Azure account" -ForegroundColor White
    Write-Host "2. The resource group was recently deleted" -ForegroundColor White
    Write-Host "3. Permission issues (let me check...)" -ForegroundColor White
    Write-Host ""
    
    # Check current user's role assignments
    az account set --subscription $targetSubscriptionId
    Write-Host "Your role assignments in 'Azure subscription 1':" -ForegroundColor Cyan
    az role assignment list --assignee CSTEWART13@art.edu --output table --query "[].{Role:roleDefinitionName, Scope:scope}"
    Write-Host ""
    
    Write-Host "RECOMMENDATION:" -ForegroundColor Magenta
    Write-Host "Create 'guardr' fresh in 'Azure subscription 1':" -ForegroundColor Yellow
    Write-Host "  az group create --name guardr --location eastus" -ForegroundColor White -BackgroundColor DarkBlue
}

# Reset to the target subscription
az account set --subscription $targetSubscriptionId

Write-Host ""
Write-Host "Investigation complete! - H. Poirot 2.0" -ForegroundColor Cyan
Write-Host ""