# Compare-RequiredVsExisting.ps1
Write-Host "🔬 ANALYZING GAPS IN AZURE RESOURCES" -ForegroundColor Magenta
Write-Host "===================================" -ForegroundColor Magenta

# What we need for Poirot's setup
$requiredResources = @{
    "Storage Account" = @{
        Required = $true
        Type = "Premium performance"
        Purpose = "High-throughput evidence storage"
    }
    "Key Vault" = @{
        Required = $true
        Type = "Standard"
        Purpose = "Secure credential storage"
    }
    "Application Insights" = @{
        Required = $true
        Type = "Web"
        Purpose = "Performance monitoring"
    }
    "Cognitive Services" = @{
        Required = $true
        Type = "Multi-service"
        Purpose = "AI capabilities"
    }
    "Azure OpenAI" = @{
        Required = $true
        Type = "GPT-4 deployment"
        Purpose = "Advanced AI detective"
    }
    "ML Workspace" = @{
        Required = $true
        Type = "Standard"
        Purpose = "Model training"
    }
    "Log Analytics" = @{
        Required = $true
        Type = "PerGB2018"
        Purpose = "Centralized logging"
    }
    "Sentinel" = @{
        Required = $true
        Type = "SIEM"
        Purpose = "Security monitoring"
    }
    "Function App" = @{
        Required = $true
        Type = "Consumption"
        Purpose = "Automated responses"
    }
    "Logic Apps" = @{
        Required = $true
        Type = "Consumption"
        Purpose = "Workflow automation"
    }
    "Virtual Network" = @{
        Required = $true
        Type = "With NSG"
        Purpose = "Network security"
    }
    "Anomaly Detector" = @{
        Required = $true
        Type = "S0"
        Purpose = "Pattern detection"
    }
}

# Load existing inventory (from previous script)
$inventoryPath = Get-ChildItem "C:\FixMyShit\PoirotDeux\Evidence\AzureInventory_*.json" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($inventoryPath) {
    $existing = Get-Content $inventoryPath.FullName | ConvertFrom-Json
    
    Write-Host "`n📋 RESOURCE GAP ANALYSIS" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Yellow
    
    foreach ($resource in $requiredResources.Keys) {
        $found = $false
        $existingName = ""
        
        # Check if resource exists
        switch ($resource) {
            "Storage Account" { $found = $existing.'Storage Accounts'.Count -gt 0 }
            "Key Vault" { $found = $existing.'Key Vaults'.Count -gt 0 }
            "Application Insights" { $found = $existing.'App Insights'.Count -gt 0 }
            # ... etc
        }
        
        if ($found) {
            Write-Host "✅ $resource : EXISTS" -ForegroundColor Green
            Write-Host "   Consider reusing existing resource" -ForegroundColor Cyan
        } else {
            Write-Host "❌ $resource : MISSING" -ForegroundColor Red
            Write-Host "   Purpose: $($requiredResources[$resource].Purpose)" -ForegroundColor Yellow
        }
    }
}