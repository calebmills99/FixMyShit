# Investigate-AzureResources.ps1
# A properly structured Azure resource investigation tool

[CmdletBinding()]
param (
    [Parameter()]
    [string]$SubscriptionId,
    
    [Parameter()]
    [string]$ResourceGroupName,
    
    [Parameter()]
    [string]$OutputPath = ".\Evidence",
    
    [Parameter()]
    [switch]$ExportToLogAnalytics
)

# Module imports and validation
Import-Module Az.Accounts, Az.Resources, Az.Monitor, Az.Storage, Az.KeyVault

# Authentication with proper error handling
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
    }
    
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
} catch {
    Write-Error "Authentication failed: $_"
    exit 1
}

# Structured investigation class
class ResourceInvestigation {
    [string]$ResourceId
    [string]$ResourceName
    [string]$ResourceType
    [string]$Location
    [hashtable]$Tags
    [PSCustomObject]$Properties
    [PSCustomObject]$Metrics
    [PSCustomObject]$Diagnostics
    [PSCustomObject]$ComplianceState
}

# Main investigation logic with proper error handling and progress reporting
$investigations = @()

# Get resource groups or specific resource group
$resourceGroups = if ($ResourceGroupName) { 
    Get-AzResourceGroup -Name $ResourceGroupName 
} else { 
    Get-AzResourceGroup 
}

foreach ($rg in $resourceGroups) {
    Write-Progress -Activity "Investigating Resource Group" -Status $rg.ResourceGroupName
    
    $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
    
    foreach ($resource in $resources) {
        Write-Progress -Activity "Investigating Resources" -Status $resource.Name -PercentComplete (($resources.IndexOf($resource) / $resources.Count) * 100)
        
        $investigation = [ResourceInvestigation]::new()
        $investigation.ResourceId = $resource.ResourceId
        $investigation.ResourceName = $resource.Name
        $investigation.ResourceType = $resource.ResourceType
        $investigation.Location = $resource.Location
        $investigation.Tags = $resource.Tags
        
        # Get detailed properties based on resource type
        try {
            switch -Wildcard ($resource.ResourceType) {
                "Microsoft.Storage/storageAccounts" {
                    $investigation.Properties = Get-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $resource.Name
                }
                "Microsoft.KeyVault/vaults" {
                    $investigation.Properties = Get-AzKeyVault -ResourceGroupName $rg.ResourceGroupName -VaultName $resource.Name
                }
                # Add more resource type handlers here
                default {
                    $investigation.Properties = Get-AzResource -ResourceId $resource.ResourceId -ExpandProperties
                }
            }
        } catch {
            Write-Warning "Could not get detailed properties for $($resource.Name): $_"
        }
        
        # Get metrics
        try {
            $endTime = Get-Date
            $startTime = $endTime.AddDays(-1)
            $timeGrain = '01:00:00'
            $investigation.Metrics = Get-AzMetric -ResourceId $resource.ResourceId -StartTime $startTime -EndTime $endTime -TimeGrain $timeGrain
        } catch {
            Write-Warning "Could not get metrics for $($resource.Name): $_"
        }
        
        $investigations += $investigation
    }
}

# Export findings with proper formatting
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportPath = Join-Path -Path $OutputPath -ChildPath "AzureInvestigation_$timestamp.json"

# Ensure output directory exists
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

# Export to JSON
$investigations | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath

# Optional export to Log Analytics
if ($ExportToLogAnalytics) {
    $workspaceId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "LogAnalyticsWorkspaceId" -AsPlainText
    $workspaceKey = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "LogAnalyticsWorkspaceKey" -AsPlainText
    
    # Use Log Analytics API to send custom logs
    foreach ($investigation in $investigations) {
        $logEntry = @{
            ResourceName = $investigation.ResourceName
            ResourceType = $investigation.ResourceType
            Location = $investigation.Location
            InvestigationTimestamp = Get-Date -Format o
            InvestigatedBy = $env:USERNAME
            Findings = $investigation
        }
        
        # Send to Log Analytics
        Send-LogAnalyticsData -WorkspaceId $workspaceId -SharedKey $workspaceKey -LogType "AzureResourceInvestigation" -LogEntry $logEntry
    }
}

Write-Host "✅ Investigation complete! Report saved to: $reportPath" -ForegroundColor Green