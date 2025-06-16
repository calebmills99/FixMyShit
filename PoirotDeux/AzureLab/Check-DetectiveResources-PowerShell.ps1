# Check Detective Agency Resources using PowerShell
# By Hercule Poirot 2.0

Write-Host "DETECTIVE AGENCY RESOURCE CHECK" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

$resourceGroupName = "guardr"
$baseName = "detective"

# Ensure correct subscription
Set-AzContext -SubscriptionId "831ed202-1c08-4b14-91eb-19ee3e5b3c78" | Out-Null

Write-Host "Checking resources in resource group: $resourceGroupName" -ForegroundColor Yellow
Write-Host ""

# Get all resources
$allResources = Get-AzResource -ResourceGroupName $resourceGroupName

# Filter detective resources
$detectiveResources = $allResources | Where-Object { $_.Name -like "*$baseName*" }

if ($detectiveResources) {
    Write-Host "[FOUND] Detective Agency Resources:" -ForegroundColor Green
    Write-Host ""
    
    # Group by type
    $grouped = $detectiveResources | Group-Object ResourceType
    
    foreach ($group in $grouped) {
        Write-Host "  $($group.Name):" -ForegroundColor Cyan
        foreach ($resource in $group.Group) {
            Write-Host "    - $($resource.Name)" -ForegroundColor White
            
            # Get additional details based on type
            switch ($resource.ResourceType) {
                "Microsoft.Web/sites" {
                    $app = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $resource.Name -ErrorAction SilentlyContinue
                    if ($app) {
                        Write-Host "      State: $($app.State)" -ForegroundColor Gray
                        Write-Host "      URL: https://$($app.DefaultHostName)" -ForegroundColor Gray
                    }
                }
                "Microsoft.Logic/workflows" {
                    $logic = Get-AzResource -ResourceId $resource.ResourceId -ExpandProperties
                    Write-Host "      State: $($logic.Properties.state)" -ForegroundColor Gray
                }
                "Microsoft.OperationalInsights/workspaces" {
                    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $resource.Name -ErrorAction SilentlyContinue
                    if ($workspace) {
                        Write-Host "      Retention: $($workspace.RetentionInDays) days" -ForegroundColor Gray
                    }
                }
            }
        }
        Write-Host ""
    }
} else {
    Write-Host "[NOT FOUND] No Detective Agency resources found!" -ForegroundColor Red
    Write-Host ""
}

# Check for required components
Write-Host "Component Status:" -ForegroundColor Yellow
$components = @{
    "Log Analytics" = ($detectiveResources | Where-Object { $_.ResourceType -eq "Microsoft.OperationalInsights/workspaces" })
    "App Service Plan" = ($allResources | Where-Object { $_.Name -eq "$baseName-plan" })
    "Function Apps" = ($detectiveResources | Where-Object { $_.ResourceType -eq "Microsoft.Web/sites" })
    "Logic Apps" = ($detectiveResources | Where-Object { $_.ResourceType -eq "Microsoft.Logic/workflows" })
}

foreach ($component in $components.GetEnumerator()) {
    if ($component.Value) {
        Write-Host "  [EXISTS] $($component.Key)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $($component.Key)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Total Detective Resources: $($detectiveResources.Count)" -ForegroundColor Cyan
Write-Host ""