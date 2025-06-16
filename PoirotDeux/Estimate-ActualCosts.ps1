# Estimate-ActualCosts.ps1
Write-Host "`nCOST ESTIMATE (Using Your Existing Resources):" -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta

$costs = @{
    "Existing Storage (already paying)" = 0
    "Existing OpenAI (already paying)" = 0
    "Existing VNet (already paying)" = 0
    "NEW Key Vault" = 5
    "NEW App Insights" = 50
    "NEW Log Analytics" = 100
    "NEW Function App (Consumption)" = 20
    "NEW Logic App" = 10
}

$newCostOnly = 0
foreach ($item in $costs.Keys) {
    $cost = $costs[$item]
    if ($item -match "NEW") {
        $newCostOnly += $cost
        Write-Host "$item : `$$cost/month" -ForegroundColor Yellow
    } else {
        Write-Host "$item : `$$cost/month" -ForegroundColor Green
    }
}

Write-Host "`nADDITIONAL Monthly Cost: `$$newCostOnly" -ForegroundColor Magenta
Write-Host "You're already paying for the expensive stuff!" -ForegroundColor Green