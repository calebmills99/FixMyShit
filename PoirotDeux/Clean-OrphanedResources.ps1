# Clean-OrphanedResources.ps1
Write-Host "CLEANING ORPHANED RESOURCE REFERENCES" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta

# That pesky 'msdocs-tutorial-rg-3731556c' resource group
Write-Host "`n[CLEAN] Removing references to deleted resource groups..." -ForegroundColor Yellow

# List all resource groups
$validRGs = az group list --query "[].name" --output json | ConvertFrom-Json

Write-Host "[INFO] Valid resource groups: $($validRGs.Count)" -ForegroundColor Cyan

# Check for orphaned resources
$allResources = az resource list --output json 2>$null | ConvertFrom-Json
$orphaned = $allResources | Where-Object { $validRGs -notcontains $_.resourceGroup }

if ($orphaned) {
    Write-Host "[!] Found $($orphaned.Count) orphaned resource references" -ForegroundColor Yellow
    foreach ($resource in $orphaned) {
        Write-Host "   - $($resource.name) in deleted RG: $($resource.resourceGroup)" -ForegroundColor Red
    }
} else {
    Write-Host "[OK] No orphaned resources found!" -ForegroundColor Green
}