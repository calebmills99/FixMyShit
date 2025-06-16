# The Azure Subscription Context Detective Script
# By Hercule Poirot 2.0 - "Order and Method!"
# Location: C:\FixMyShit\PoirotDeux\Scripts\

Write-Host "HERCULE POIROT 2.0: AZURE SUBSCRIPTION DETECTIVE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Examine ALL subscriptions (the suspect lineup!)
Write-Host "STEP 1: Examining all available Azure subscriptions..." -ForegroundColor Yellow
Write-Host "Sometimes, mon ami, the resource group hides in another subscription!" -ForegroundColor Gray
Write-Host ""

try {
    $allSubscriptions = Get-AzSubscription
    
    if ($allSubscriptions.Count -eq 0) {
        Write-Host "[ERROR] No subscriptions found! Please login first with Connect-AzAccount" -ForegroundColor Red
        return
    }
    
    Write-Host "Found $($allSubscriptions.Count) subscription(s):" -ForegroundColor Green
    $allSubscriptions | ForEach-Object {
        Write-Host "  - $($_.Name) (ID: $($_.Id))" -ForegroundColor Cyan
    }
    Write-Host ""
    
    # Step 2: Hunt for guardr across ALL subscriptions
    Write-Host "STEP 2: The Hunt for 'guardr' begins!" -ForegroundColor Yellow
    Write-Host "I shall search every subscription like searching every room in the Orient Express!" -ForegroundColor Gray
    Write-Host ""
    
    $foundResourceGroup = $false
    $correctSubscription = $null
    
    foreach ($subscription in $allSubscriptions) {
        Write-Host "[INVESTIGATING] Subscription: $($subscription.Name)..." -ForegroundColor White
        
        # Switch context
        $null = Set-AzContext -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue
        
        # Search for the resource group
        $resourceGroups = Get-AzResourceGroup -ErrorAction SilentlyContinue
        $guardr = $resourceGroups | Where-Object { $_.ResourceGroupName -eq 'guardr' }
        
        if ($guardr) {
            $foundResourceGroup = $true
            $correctSubscription = $subscription
            Write-Host "  [SUCCESS] EUREKA! Found 'guardr' in this subscription!" -ForegroundColor Green
            Write-Host "  [LOCATION] $($guardr.Location)" -ForegroundColor Green
            
            # Count resources in this group
            $resources = Get-AzResource -ResourceGroupName 'guardr' -ErrorAction SilentlyContinue
            Write-Host "  [RESOURCES] Contains $($resources.Count) resources" -ForegroundColor Green
            break
        } else {
            Write-Host "  [NOT FOUND] Not in this subscription" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    
    # Step 3: The Revelation!
    if ($foundResourceGroup) {
        Write-Host "THE SOLUTION REVEALS ITSELF!" -ForegroundColor Green
        Write-Host "============================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Mon ami, the mystery is solved! The resource group 'guardr' exists in:" -ForegroundColor Yellow
        Write-Host "Subscription: $($correctSubscription.Name)" -ForegroundColor Cyan
        Write-Host "Subscription ID: $($correctSubscription.Id)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To proceed with our deployment, we must ensure we're in the correct subscription:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Set-AzContext -SubscriptionId '$($correctSubscription.Id)'" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host ""
        
        # Verify we're in the right context now
        Write-Host "Setting the correct context now..." -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $correctSubscription.Id
        
        $currentContext = Get-AzContext
        Write-Host "[SUCCESS] Current context set to: $($currentContext.Subscription.Name)" -ForegroundColor Green
        
    } else {
        Write-Host "MOST PECULIAR!" -ForegroundColor Red
        Write-Host "===============" -ForegroundColor Red
        Write-Host ""
        Write-Host "The resource group 'guardr' was not found in any subscription!" -ForegroundColor Yellow
        Write-Host "Yet the CSV evidence shows it exists... This suggests:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. The CSV might be from a different Azure account" -ForegroundColor White
        Write-Host "2. The resource group might have been recently deleted" -ForegroundColor White
        Write-Host "3. There might be permission issues hiding it from view" -ForegroundColor White
        Write-Host ""
        Write-Host "Let me check your current permissions..." -ForegroundColor Yellow
        
        $currentContext = Get-AzContext
        if ($currentContext) {
            $roleAssignments = Get-AzRoleAssignment -SignInName $currentContext.Account.Id -ErrorAction SilentlyContinue
            Write-Host ""
            Write-Host "Your roles in current subscription:" -ForegroundColor Cyan
            $roleAssignments | Select-Object RoleDefinitionName, Scope | Format-Table
        }
    }
    
    # Step 4: Next steps
    Write-Host ""
    Write-Host "DETECTIVE'S RECOMMENDATION:" -ForegroundColor Magenta
    Write-Host "===========================" -ForegroundColor Magenta
    Write-Host ""
    
    if ($foundResourceGroup) {
        Write-Host "Now that we've found the correct subscription, we can proceed with deployment!" -ForegroundColor Green
        Write-Host "Run the deployment script from the AzureLab folder." -ForegroundColor Green
    } else {
        Write-Host "We have two options, mon ami:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "OPTION 1: Create 'guardr' resource group fresh" -ForegroundColor Cyan
        Write-Host "  New-AzResourceGroup -Name 'guardr' -Location 'eastus'" -ForegroundColor White
        Write-Host ""
        Write-Host "OPTION 2: Use a different resource group name" -ForegroundColor Cyan
        Write-Host "  (We can modify our Bicep templates accordingly)" -ForegroundColor White
    }
    
} catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Mon ami, it appears we need to login first:" -ForegroundColor Yellow
    Write-Host "Connect-AzAccount" -ForegroundColor White -BackgroundColor DarkBlue
}

Write-Host ""
Write-Host "Investigation complete! - H. Poirot 2.0" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan