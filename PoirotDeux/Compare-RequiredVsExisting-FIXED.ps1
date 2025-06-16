# Compare-RequiredVsExisting-FIXED.ps1
Write-Host "ANALYZING GAPS IN AZURE RESOURCES" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# What we need vs what you have
$requiredVsExisting = @{
    "Storage Account" = @{
        Required = $true
        Found = $false  # You don't have one yet
        Existing = @()
        Action = "CREATE NEW"
    }
    "Key Vault" = @{
        Required = $true
        Found = $true
        Existing = @("midnightkeyvault03e7c773")
        Action = "USE EXISTING"
    }
    "Application Insights" = @{
        Required = $true
        Found = $true
        Existing = @("insights", "midnightinsightscbd64381")
        Action = "USE EXISTING (insights)"
    }
    "Cognitive Services" = @{
        Required = $true
        Found = $true
        Existing = @("midnight", "midnight-foundry", "guareye", "zaaaa", "cstewart13-0895-resource")
        Action = "USE EXISTING (midnight)"
    }
    "Azure OpenAI" = @{
        Required = $true
        Found = $false  # None showed as OpenAI type
        Existing = @()
        Action = "CHECK IF 'midnight' IS OPENAI ENABLED"
    }
    "ML Workspace" = @{
        Required = $true
        Found = $true
        Existing = @("midnight")
        Action = "USE EXISTING"
    }
    "Log Analytics" = @{
        Required = $true
        Found = $true
        Existing = @("DefaultWorkspace-eastus")
        Action = "USE EXISTING"
    }
    "Function App" = @{
        Required = $true
        Found = $false
        Existing = @()
        Action = "CREATE NEW"
    }
    "Logic Apps" = @{
        Required = $true
        Found = $false
        Existing = @()
        Action = "CREATE NEW"
    }
    "Virtual Network" = @{
        Required = $true
        Found = $true
        Existing = @("Golden-vnet", "guarnet")
        Action = "USE EXISTING (guarnet)"
    }
}

Write-Host "`n[ANALYSIS] Resource Status:" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow

foreach ($resource in $requiredVsExisting.Keys) {
    $info = $requiredVsExisting[$resource]
    $status = if ($info.Found) { "[EXISTS]" } else { "[MISSING]" }
    $color = if ($info.Found) { "Green" } else { "Red" }
    
    Write-Host "`n$status $resource" -ForegroundColor $color
    Write-Host "   Action: $($info.Action)" -ForegroundColor Cyan
    if ($info.Existing.Count -gt 0) {
        Write-Host "   Available: $($info.Existing -join ', ')" -ForegroundColor Gray
    }
}

Write-Host "`n[SUMMARY]" -ForegroundColor Magenta
Write-Host "=========" -ForegroundColor Magenta
Write-Host "Resources to CREATE: 3" -ForegroundColor Red
Write-Host "  - Storage Account (Premium)" -ForegroundColor Red
Write-Host "  - Function App" -ForegroundColor Red
Write-Host "  - Logic Apps" -ForegroundColor Red
Write-Host "`nResources to REUSE: 7" -ForegroundColor Green
Write-Host "  - All others can use existing!" -ForegroundColor Green