# Investigate-ExistingAzureResources-FIXED.ps1
Write-Host "POIROT'S AZURE RESOURCE INVESTIGATION v2.0" -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host ""

# Ensure Evidence folder exists
$evidencePath = "C:\FixMyShit\PoirotDeux\Evidence"
if (!(Test-Path $evidencePath)) {
    New-Item -ItemType Directory -Path $evidencePath -Force | Out-Null
}

# Fix the extension warning
$null = az config set extension.use_dynamic_install=yes_without_prompt 2>$null

# Auth check with proper JSON handling
Write-Host "[AUTH] Checking Azure authentication..." -ForegroundColor Yellow
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "[ERROR] Not logged in to Azure!" -ForegroundColor Red
    Write-Host "[INFO] Please run: az login" -ForegroundColor Cyan
    exit 1
}

Write-Host "[OK] Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "[INFO] Subscription: $($account.name) [$($account.id)]" -ForegroundColor Cyan
Write-Host ""

# Create investigation report
$timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
$reportPath = "$evidencePath\AzureInventory_$timestamp.txt"
$jsonReportPath = "$evidencePath\AzureInventory_$timestamp.json"

# Start investigation
$report = @"
AZURE RESOURCE INVESTIGATION REPORT
==================================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
Investigator: Detective Poirot Deux
Subscription: $($account.name)
ID: $($account.id)
==================================

"@

# Investigate Resource Groups (with error handling)
Write-Host "[SEARCH] Investigating Resource Groups..." -ForegroundColor Yellow
try {
    $resourceGroups = az group list --output json 2>$null | ConvertFrom-Json
    $report += "`nRESOURCE GROUPS FOUND: $($resourceGroups.Count)`n"
    $report += "------------------------`n"
    foreach ($rg in $resourceGroups) {
        $report += "  - $($rg.name) (Location: $($rg.location))`n"
        Write-Host "   [+] $($rg.name)" -ForegroundColor Green
    }
} catch {
    Write-Host "   [!] Error retrieving resource groups" -ForegroundColor Yellow
}

# Fix the JSON parsing for resource queries
Write-Host "`n[SEARCH] Investigating Specific Resources..." -ForegroundColor Yellow

# Use simpler queries without az graph (which seems problematic)
$resourcesToCheck = @{
    "Storage Accounts" = @{
        Command = { az storage account list --output json 2>$null }
        Icon = "[DISK]"
    }
    "Key Vaults" = @{
        Command = { az keyvault list --output json 2>$null }
        Icon = "[LOCK]"
    }
    "Function Apps" = @{
        Command = { az functionapp list --output json 2>$null }
        Icon = "[FUNC]"
    }
    "Virtual Networks" = @{
        Command = { az network vnet list --output json 2>$null }
        Icon = "[NET]"
    }
    "Log Analytics" = @{
        Command = { az monitor log-analytics workspace list --output json 2>$null }
        Icon = "[LOGS]"
    }
    "Logic Apps" = @{
        Command = { az logic workflow list --output json 2>$null }
        Icon = "[FLOW]"
    }
    "App Insights" = @{
        Command = { az monitor app-insights component list --output json 2>$null }
        Icon = "[CHART]"
    }
    "ML Workspaces" = @{
        Command = { az ml workspace list --output json 2>$null }
        Icon = "[AI]"
    }
    "Cognitive Services" = @{
        Command = { az cognitiveservices account list --output json 2>$null }
        Icon = "[BRAIN]"
    }
}

$existingResources = @{}

foreach ($resourceType in $resourcesToCheck.Keys) {
    Write-Host "`n$($resourcesToCheck[$resourceType].Icon) Checking $resourceType..." -ForegroundColor Cyan
    
    try {
        $resources = & $resourcesToCheck[$resourceType].Command | ConvertFrom-Json
        $existingResources[$resourceType] = $resources
        
        $report += "`n$resourceType FOUND: $($resources.Count)`n"
        $report += "------------------------`n"
        
        if ($resources.Count -gt 0) {
            foreach ($resource in $resources) {
                $rgName = if ($resource.resourceGroup) { $resource.resourceGroup } else { "N/A" }
                $report += "  - $($resource.name) (RG: $rgName)`n"
                Write-Host "   [OK] $($resource.name)" -ForegroundColor Green
            }
        } else {
            Write-Host "   [--] None found" -ForegroundColor Yellow
            $report += "  [NONE FOUND]`n"
        }
    } catch {
        Write-Host "   [!] Error checking $resourceType" -ForegroundColor Yellow
        $report += "  [ERROR CHECKING]`n"
    }
}

# Special OpenAI check (filter out deleted resource groups)
Write-Host "`n[AI] Special Investigation: Azure OpenAI..." -ForegroundColor Cyan
try {
    $allCogServices = az cognitiveservices account list --output json 2>$null | ConvertFrom-Json
    $openAIResources = $allCogServices | Where-Object { $_.kind -eq 'OpenAI' }
    
    if ($openAIResources) {
        $report += "`nAZURE OPENAI SERVICES: $($openAIResources.Count)`n"
        $report += "------------------------`n"
        foreach ($oai in $openAIResources) {
            # Check if resource group still exists
            $rgExists = az group show --name $oai.resourceGroup --output json 2>$null
            if ($rgExists) {
                $report += "  - $($oai.name) (RG: $($oai.resourceGroup))`n"
                Write-Host "   [OK] OpenAI: $($oai.name)" -ForegroundColor Green
            } else {
                Write-Host "   [!] OpenAI: $($oai.name) (RG deleted)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "   [--] No OpenAI services found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [!] Error checking OpenAI services" -ForegroundColor Yellow
}

# Save reports with error handling
try {
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    $existingResources | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding UTF8
    
    Write-Host "`n[SAVE] Investigation reports saved:" -ForegroundColor Magenta
    Write-Host "   [>] Text Report: $reportPath" -ForegroundColor Green
    Write-Host "   [>] JSON Report: $jsonReportPath" -ForegroundColor Green
} catch {
    Write-Host "`n[ERROR] Could not save reports!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`n[SUMMARY] INVESTIGATION COMPLETE" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta
Write-Host "[INFO] Despite some errors, we found many resources!" -ForegroundColor Cyan