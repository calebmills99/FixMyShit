<#
.SYNOPSIS
    Hercule Poirot's Digital Detective Agency: Azure Cloud Solutions Framework
    
.DESCRIPTION
    This script sets up and manages the PoirotDeux Azure cloud investigation environment.
    It creates a structured framework for organizing cloud diagnostics, security governance,
    and CI/CD configurations with a detective theme while following Azure best practices.
    The script performs the following actions:
    - Creates organized directory structure for Azure investigations
    - Generates helper scripts for cloud diagnostics and monitoring
    - Establishes disaster recovery templates and documentation
    - Provides an interactive menu for various cloud operations
    
.PARAMETER WorkingDirectory
    The base directory for PoirotDeux operations. Defaults to current location.
    
.PARAMETER SkipDirectoryCreation
    Skip creating directories if they already exist (useful for menu-only access)
    
.PARAMETER MenuOnly
    Launch directly to the interactive menu without setup operations
    
.EXAMPLE
    .\LaunchInvestigation.ps1
    Runs the full setup and displays the interactive menu
    
.EXAMPLE
    .\LaunchInvestigation.ps1 -MenuOnly
    Skips setup and goes directly to the investigation menu
    
.EXAMPLE
    .\LaunchInvestigation.ps1 -WorkingDirectory "D:\CloudProjects\PoirotDeux"
    Runs setup in a custom directory location
    
.NOTES
    Script Name  : LaunchInvestigation.ps1

    Version      : 3.1.0
    Author       : Digital Detective Agency
    Date Created : 2024-01-15

    Last Modified: 2024-06-25
    
    Prerequisites:
    - PowerShell 7.0 or higher
    - Administrator privileges
    - Az PowerShell modules
    - Azure CLI
.LINK
    https://github.com/YourOrg/PoirotDeux
    
#>

#Requires -Version 7.0
#Requires -RunAsAdministrator
#Requires -Modules Az.Accounts, Az.Resources, Az.Security, Az.Monitor

[CmdletBinding(DefaultParameterSetName = 'Setup')]
param(
    [Parameter(ParameterSetName = 'Setup')]
    [Parameter(ParameterSetName = 'MenuOnly')]
    [ValidateScript({
        if (-not (Test-Path $_ -PathType Container)) {
            throw "Directory '$_' does not exist. Please create it first."
        }
        return $true
    })]
    [string]$WorkingDirectory = $PWD.Path,
    
    [Parameter(ParameterSetName = 'Setup')]
    [switch]$SkipDirectoryCreation,
    
    [Parameter(ParameterSetName = 'MenuOnly', Mandatory)]
    [switch]$MenuOnly
)

# Script configuration and validation
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'

# Validate execution context
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$expectedPath = Join-Path $WorkingDirectory "PoirotDeux"

if ($scriptRoot -ne $expectedPath -and -not $MenuOnly) {
    Write-Warning "⚠️  This script should be run from: $expectedPath"
    Write-Warning "   Current location: $scriptRoot"
    
    $response = Read-Host "Continue anyway? (Y/N)"
    if ($response -ne 'Y') {
        Write-Host "🎩 'One must be methodical, mon ami.' - Exiting." -ForegroundColor Yellow
        exit 1
    }
}

# Change to working directory
Set-Location -Path $WorkingDirectory

# Skip setup if MenuOnly is specified
if ($MenuOnly) {
    Write-Verbose "Menu-only mode: Skipping setup operations"
} else {
    Write-Host "🎩 Organizing Poirot's Digital Detective Agency: Azure Cloud Edition..." -ForegroundColor Magenta
}


# Create an improved directory structure for modern cloud operations
$directories = @(



















    ".\Evidence\Logs",                    # For Azure activity logs and diagnostic outputs
    ".\Evidence\Metrics",                 # For performance metrics and telemetry
    ".\Evidence\CostReports",             # For cost optimization and budgeting reports
    ".\CaseClosed",                       # Completed cloud solutions and configurations
    ".\ActiveCases",                      # Current cloud deployments and investigations
    ".\Suspects\SecurityAlerts",          # Security findings and vulnerabilities
    ".\Suspects\ComplianceIssues",        # Non-compliant resources
    ".\Suspects\PerformanceBottlenecks",  # Performance issues identified
    ".\Alibis\Backups",                   # Azure backup configurations
    ".\Alibis\DisasterRecovery",          # DR plans and replications
    ".\Alibis\BusinessContinuity",        # Business continuity documentation
    ".\Witnesses\Monitoring",             # Monitoring scripts and dashboards
    ".\Witnesses\Automation",             # Azure Automation runbooks
    ".\Witnesses\Observability",          # Observability configurations (Application Insights, Log Analytics)
    ".\Clues\ARM",                        # ARM templates
    ".\Clues\Bicep",                      # Bicep templates
    ".\Clues\Terraform",                  # Terraform configurations
    ".\Clues\Pulumi",                     # Pulumi configurations
    ".\TheGreyCells\Policies",            # Azure Policy definitions
    ".\TheGreyCells\Governance",          # Governance frameworks
    ".\TheGreyCells\ComplianceReports",   # Compliance reporting
    ".\TheGreyCells\Architecture",        # Reference architectures
    ".\SecretDrawer\KeyVault",            # Key Vault references
    ".\SecretDrawer\ServicePrincipals",   # Service principal credentials
    ".\SecretDrawer\ManagedIdentities",   # Managed Identity configurations
    ".\Pipeline\CI",                      # CI pipelines
    ".\Pipeline\CD",                      # CD pipelines
    ".\Pipeline\Templates",               # Reusable pipeline templates
    ".\WarRoom\Runbooks",                 # Incident response runbooks
    ".\WarRoom\Playbooks",                # Security and operational playbooks
    ".\WarRoom\Incidents"                 # Incident tracking and resolution
)

if (-not $SkipDirectoryCreation) {
foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "📁 Created: $dir" -ForegroundColor Green
}
}


# Create the Master Case File with improved guidance
@"
===============================================
     POIROT'S AZURE CLOUD DETECTIVE AGENCY

     Investigation HQ: $WorkingDirectory\PoirotDeux
===============================================

ACTIVE INVESTIGATIONS:
----------------------
1. The Case of the Perfect Azure Architecture
2. The Mystery of the Cost Optimization
3. The Adventure of the Secure Resource Group
4. The Curious Incident of the Failed Deployment
5. The Secret of the Resilient Application
6. The Riddle of the Containerized Microservices

METHODOLOGY:
-----------
"Order and method in the cloud, mes amis. That is the secret."









BEST PRACTICES:
--------------
- Use Infrastructure as Code for all deployments
- Implement Zero Trust security model
- Apply least privilege access control
- Maintain proper tagging for resources
- Implement multi-region resilience for critical workloads
- Automate routine maintenance tasks
- Regularly test disaster recovery procedures

TOOLS OF THE TRADE:
------------------
- Setup-AzurePoirot.ps1 (Main Investigation Tool)
- Resource monitoring in .\Witnesses\Monitoring
- Security posture in .\Suspects\SecurityAlerts
- IaC templates in .\Clues
- Disaster recovery plans in .\Alibis\DisasterRecovery
- Reference architectures in .\TheGreyCells\Architecture

EMERGENCY CONTACTS:
------------------
- Azure Security Center: Get-AzSecurityAlert
- Azure Advisor: Get-AzAdvisorRecommendation
- Azure Service Health: Get-AzHealthIssue
- The Little Grey Cells: Always available for architecture decisions
===============================================
"@ | Out-File -FilePath ".\AGENCY_README.txt" -Encoding UTF8


# Create a daily investigation log with more comprehensive checks
@"
# POIROT'S AZURE INVESTIGATION LOG
## Date: $(Get-Date -Format 'yyyy-MM-dd')

### Morning Briefing:
- [ ] Check Azure service health
- [ ] Review security alerts
- [ ] Monitor resource utilization
- [ ] Verify backup status
- [ ] Check cost against budget
- [ ] Review recent deployments
- [ ] Verify compliance status
- [ ] Review IAM changes

### Active Cloud Cases:
- Azure Architecture Optimization: IN PROGRESS
- Cost Management Investigation: PENDING
- Security Compliance Audit: ONGOING
- CI/CD Pipeline Implementation: PLANNED
- Multi-Region Resilience Testing: SCHEDULED
- Microservices Migration: DESIGN PHASE

### Resources to Monitor:
- [ ] Virtual Machines
- [ ] Kubernetes Clusters
- [ ] App Services
- [ ] Databases
- [ ] Storage Accounts
- [ ] Key Vaults
- [ ] Virtual Networks
- [ ] API Management

### Notes:
_"In the cloud, as in life, the impossible could not have happened, therefore the impossible must be possible in spite of appearances."_

---
"@ | Out-File -FilePath ".\Evidence\Logs\AzureLog_$(Get-Date -Format 'yyyyMMdd').md" -Encoding UTF8


# Create helper script: Comprehensive Azure Health Check with improved diagnostics
@'
# Poirot's Azure Health Investigation
Write-Host "`n🔍 POIROT'S AZURE INVESTIGATION" -ForegroundColor Magenta
Write-Host "================================`n" -ForegroundColor Magenta

# Verify Azure connection
Write-Host "🔑 Verifying Azure Connection:" -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if ($null -eq $context) {
        Write-Host "   Not connected to Azure. Initiating connection..." -ForegroundColor Cyan
        Connect-AzAccount
        $context = Get-AzContext
    }
    Write-Host "   Connected to: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
} catch {
    Write-Host "   Failed to connect to Azure: $_" -ForegroundColor Red
    exit 1
}

# Check Azure service health
Write-Host "`n🏥 Azure Service Health:" -ForegroundColor Yellow
try {
    $healthIssues = Get-AzHealthIssue
    if ($healthIssues.Count -gt 0) {
        Write-Host "   ⚠️ Active health issues detected: $($healthIssues.Count)" -ForegroundColor Red
        $healthIssues | ForEach-Object {
            Write-Host "      - $($_.Title) | Status: $($_.Status) | Service: $($_.Service)" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✅ No active service health issues" -ForegroundColor Green
    }
} catch {
    Write-Host "   Could not retrieve Azure health status: $_" -ForegroundColor Red
}


# Check security alerts with more detailed analysis
Write-Host "`n🛡️ Security Alerts:" -ForegroundColor Yellow
try {
    $securityAlerts = Get-AzSecurityAlert
    if ($securityAlerts.Count -gt 0) {
        $highSeverityAlerts = $securityAlerts | Where-Object { $_.AlertSeverity -in @('High', 'Critical') }
        $mediumSeverityAlerts = $securityAlerts | Where-Object { $_.AlertSeverity -eq 'Medium' }
        $lowSeverityAlerts = $securityAlerts | Where-Object { $_.AlertSeverity -in @('Low', 'Informational') }

        Write-Host "   ⚠️ Security alerts detected: $($securityAlerts.Count)" -ForegroundColor Red



        if ($highSeverityAlerts.Count -gt 0) {
            Write-Host "   🔴 High/Critical Severity Alerts: $($highSeverityAlerts.Count)" -ForegroundColor Red
            $highSeverityAlerts | ForEach-Object {
                Write-Host "      - $($_.AlertDisplayName) | Severity: $($_.AlertSeverity) | Resource: $($_.ResourceId -split '/')[-1]" -ForegroundColor Red
        }


    }



        if ($mediumSeverityAlerts.Count -gt 0) {
            Write-Host "   🟠 Medium Severity Alerts: $($mediumSeverityAlerts.Count)" -ForegroundColor DarkYellow
            $mediumSeverityAlerts | Select-Object -First 3 | ForEach-Object {
                Write-Host "      - $($_.AlertDisplayName) | Resource: $($_.ResourceId -split '/')[-1]" -ForegroundColor DarkYellow
}
            if ($mediumSeverityAlerts.Count -gt 3) {
                Write-Host "      - ... and $($mediumSeverityAlerts.Count - 3) more medium alerts" -ForegroundColor DarkYellow
            }
        }

























        if ($lowSeverityAlerts.Count -gt 0) {
            Write-Host "   🟡 Low/Informational Alerts: $($lowSeverityAlerts.Count)" -ForegroundColor Yellow
        }
            } else {

        Write-Host "   ✅ No active security alerts" -ForegroundColor Green
            }




} catch {

    Write-Host "   Could not retrieve security alerts: $_" -ForegroundColor Red
}






















# Check resource health with detailed status reporting
Write-Host "`n💻 Resource Health:" -ForegroundColor Yellow
try {






    $resources = Get-AzResource | Where-Object {$_.ResourceType -in @(
        "Microsoft.Compute/virtualMachines",
        "Microsoft.Web/sites",
        "Microsoft.ContainerService/managedClusters",
        "Microsoft.Sql/servers/databases",
        "Microsoft.DocumentDB/databaseAccounts",
        "Microsoft.Storage/storageAccounts",
        "Microsoft.KeyVault/vaults"
    )}

    Write-Host "   Analyzing $($resources.Count) critical resources..." -ForegroundColor Cyan

    $resourceGroups = $resources | Group-Object ResourceGroupName
    foreach ($rg in $resourceGroups) {
        Write-Host "   Resource Group: $($rg.Name)" -ForegroundColor Blue
        foreach ($resource in $rg.Group) {
            $health = Get-AzHealthResource -ResourceId $resource.Id -ErrorAction SilentlyContinue
            $status = if ($health.Properties.CurrentHealthStatus -eq "Available") { "✅" } else { "⚠️" }
            $resourceType = $resource.ResourceType -split '/' | Select-Object -Last 1
            Write-Host "     $status $($resource.Name) ($resourceType): $($health.Properties.CurrentHealthStatus)" -ForegroundColor $(if ($health.Properties.CurrentHealthStatus -eq "Available") { "Green" } else { "Red" })
}



}
} catch {
    Write-Host "   Could not retrieve resource health: $_" -ForegroundColor Red
}







# Check backup status with compliance reporting
Write-Host "`n💾 Backup Status:" -ForegroundColor Yellow
try {
    $backupVaults = Get-AzRecoveryServicesVault
    if ($backupVaults.Count -gt 0) {
        foreach ($vault in $backupVaults) {
            Write-Host "   Analyzing backup vault: $($vault.Name)..." -ForegroundColor Cyan
            $backupJobs = Get-AzRecoveryServicesBackupJob -VaultId $vault.ID
            $failedJobs = $backupJobs | Where-Object {$_.Status -eq "Failed"}
            $inProgressJobs = $backupJobs | Where-Object {$_.Status -eq "InProgress"}
            $completedJobs = $backupJobs | Where-Object {$_.Status -eq "Completed"}

            if ($failedJobs.Count -gt 0) {
                Write-Host "   ⚠️ $($failedJobs.Count) failed backup jobs in $($vault.Name)" -ForegroundColor Red
                $failedJobs | ForEach-Object {
                    Write-Host "      - Failed: $($_.WorkloadName) | Start Time: $($_.StartTime) | Operation: $($_.Operation)" -ForegroundColor Red
    }
}




























            if ($inProgressJobs.Count -gt 0) {
                Write-Host "   ⏳ $($inProgressJobs.Count) backup jobs in progress" -ForegroundColor Yellow
            }

            if ($completedJobs.Count -gt 0) {
                Write-Host "   ✅ $($completedJobs.Count) backup jobs completed successfully" -ForegroundColor Green
            }

            # Check backup item status
            $backupItems = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -BackupManagementType AzureVM
            $protectedItems = $backupItems | Where-Object {$_.ProtectionStatus -eq "Protected"}
            $unhealthyItems = $backupItems | Where-Object {$_.ProtectionStatus -ne "Protected"}

            Write-Host "   📊 Protection Status: $($protectedItems.Count) protected, $($unhealthyItems.Count) unprotected or unhealthy" -ForegroundColor $(if ($unhealthyItems.Count -eq 0) { "Green" } else { "Yellow" })
        }
                } else {

        Write-Host "   ⚠️ No backup vaults found" -ForegroundColor Yellow
                }
} catch {
    Write-Host "   Could not retrieve backup status: $_" -ForegroundColor Red
            }

# Check Azure Advisor recommendations
Write-Host "`n💡 Azure Advisor Recommendations:" -ForegroundColor Yellow
try {
    $recommendations = Get-AzAdvisorRecommendation
    $highImpact = $recommendations | Where-Object { $_.Impact -eq "High" }
    $mediumImpact = $recommendations | Where-Object { $_.Impact -eq "Medium" }
    $lowImpact = $recommendations | Where-Object { $_.Impact -eq "Low" }

    Write-Host "   Found $($recommendations.Count) recommendations:" -ForegroundColor Cyan
    Write-Host "   🔴 High Impact: $($highImpact.Count)" -ForegroundColor Red
    Write-Host "   🟠 Medium Impact: $($mediumImpact.Count)" -ForegroundColor DarkYellow
    Write-Host "   🟡 Low Impact: $($lowImpact.Count)" -ForegroundColor Yellow

    if ($highImpact.Count -gt 0) {
        Write-Host "`n   Top High Impact Recommendations:" -ForegroundColor Red
        $highImpact | Select-Object -First 3 | ForEach-Object {
            Write-Host "      - $($_.ShortDescription.Problem) | Category: $($_.Category)" -ForegroundColor Red
        }
    }









































































































































































} catch {
    Write-Host "   Could not retrieve Azure Advisor recommendations: $_" -ForegroundColor Red
}

# Check cost analysis
Write-Host "`n💰 Cost Analysis:" -ForegroundColor Yellow
try {
    $today = Get-Date
    $startDate = $today.AddDays(-30)
    $consumptionData = Get-AzConsumptionUsageDetail -StartDate $startDate -EndDate $today

    $totalCost = ($consumptionData | Measure-Object -Property PretaxCost -Sum).Sum
    $costByService = $consumptionData | Group-Object -Property ConsumedService |
                    Select-Object @{N='Service';E={$_.Name}}, @{N='Cost';E={($_.Group | Measure-Object -Property PretaxCost -Sum).Sum}} |
                    Sort-Object Cost -Descending

    Write-Host "   Total cost for last 30 days: $($totalCost.ToString('C'))" -ForegroundColor Cyan
    Write-Host "   Top 5 services by cost:" -ForegroundColor Cyan
    $costByService | Select-Object -First 5 | ForEach-Object {
        Write-Host "      - $($_.Service): $($_.Cost.ToString('C'))" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   Could not retrieve cost data: $_" -ForegroundColor Red
}

# Check Azure Policy compliance
Write-Host "`n📜 Azure Policy Compliance:" -ForegroundColor Yellow
try {
    $policyStates = Get-AzPolicyState -Top 100
    $nonCompliantPolicies = $policyStates | Where-Object { $_.ComplianceState -eq "NonCompliant" }

    if ($nonCompliantPolicies.Count -gt 0) {
        Write-Host "   ⚠️ Found $($nonCompliantPolicies.Count) non-compliant policy assignments" -ForegroundColor Red
        $nonCompliantByDefinition = $nonCompliantPolicies | Group-Object PolicyDefinitionName
        $nonCompliantByDefinition | Select-Object -First 5 | ForEach-Object {
            Write-Host "      - $($_.Name): $($_.Count) resources" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✅ All checked resources are policy compliant" -ForegroundColor Green
    }
} catch {
    Write-Host "   Could not retrieve policy compliance data: $_" -ForegroundColor Red
}

Write-Host "`n🎩 'The cloud, mon ami, is never silent if you know how to listen.'" -ForegroundColor Magenta
Write-Host ""
'@ | Out-File -FilePath ".\Witnesses\Monitoring\AzureHealthCheck.ps1" -Encoding UTF8

# Create a more comprehensive Azure Emergency Remediation Kit
@'
# AZURE EMERGENCY REMEDIATION KIT
# "When all else fails, we must return to the principles of good architecture"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Network", "VM", "Storage", "KeyVault", "App", "Database", "Kubernetes", "IAM", "All")]
    [string]$ResourceType,

    [switch]$Nuclear,

    [switch]$Report,

    [string]$OutputPath = ".\WarRoom\Incidents\Remediation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

function Write-Log {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )

    Write-Host $Message -ForegroundColor $ForegroundColor

    if ($Report) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $OutputPath -Append
    }
}

Write-Log "🚨 AZURE EMERGENCY REMEDIATION ACTIVATED" -ForegroundColor Red
Write-Log "====================================" -ForegroundColor Red

# Verify Azure connection
try {
    $context = Get-AzContext
    if ($null -eq $context) {
        Write-Log "Not connected to Azure. Connecting now..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    Write-Log "Connected to: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
}
catch {
    Write-Log "Failed to connect to Azure. Please run Connect-AzAccount manually." -ForegroundColor Red
    exit 1
}

if ($Nuclear) {
    Write-Log "`n⚠️  NUCLEAR OPTION SELECTED!" -ForegroundColor Yellow
    $confirm = Read-Host "This will apply aggressive remediation to $ResourceType resources. Continue? (yes/no)"
    if ($confirm -ne 'yes') {
        Write-Log "Operation cancelled." -ForegroundColor Green
        exit
    }
}

# Create remediation summary
$remediationSummary = @{
    "IssuesFound" = 0
    "IssuesFixed" = 0
    "ResourcesScanned" = 0
    "StartTime" = Get-Date
}

# Function to register issue
function Register-Issue {
    param(
        [switch]$Fixed
    )

    $remediationSummary.IssuesFound++
    if ($Fixed) {
        $remediationSummary.IssuesFixed++
    }
}

# Function to handle network security remediations
function Start-NetworkSecurityRemediation {
    Write-Log "🔍 Investigating network resources..." -ForegroundColor Cyan

    # Check Network Security Groups
    $nsgs = Get-AzNetworkSecurityGroup
    Write-Log "Found $($nsgs.Count) Network Security Groups" -ForegroundColor Yellow
    $remediationSummary.ResourcesScanned += $nsgs.Count

    foreach ($nsg in $nsgs) {
        # Check for overly permissive rules
        $dangerousRules = $nsg.SecurityRules | Where-Object {
            $_.SourceAddressPrefix -eq '*' -and
            $_.Access -eq 'Allow' -and
            $_.Direction -eq 'Inbound' -and
            ($_.DestinationPortRange -eq '*' -or $_.DestinationPortRange -in @('3389','22','1433','3306'))
        }

        if ($dangerousRules) {
            Write-Log "⚠️ Dangerous security rules found in NSG: $($nsg.Name)" -ForegroundColor Red
            Register-Issue

            foreach ($rule in $dangerousRules) {
                Write-Log "  - Rule: $($rule.Name) | Source: $($rule.SourceAddressPrefix) | Port: $($rule.DestinationPortRange)" -ForegroundColor Red
            }

            if ($Nuclear) {
                Write-Log "🔧 Applying remediation..." -ForegroundColor Yellow
                foreach ($rule in $dangerousRules) {
                    Write-Log "  - Removing dangerous rule: $($rule.Name)" -ForegroundColor Red
                    Remove-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $rule.Name
                }
                Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
                Write-Log "✅ NSG remediated" -ForegroundColor Green
                Register-Issue -Fixed
            } else {
                Write-Log "  - Recommendation: Restrict source IP addresses and limit port access" -ForegroundColor Yellow
                Write-Log "  - Run with -Nuclear to automatically fix these issues" -ForegroundColor Yellow
            }
        }
    }

    # Check for unassociated public IP addresses
    $publicIPs = Get-AzPublicIpAddress
    $unassociatedIPs = $publicIPs | Where-Object { $null -eq $_.IpConfiguration }

    if ($unassociatedIPs.Count -gt 0) {
        Write-Log "⚠️ Found $($unassociatedIPs.Count) unassociated public IP addresses" -ForegroundColor Yellow
        Register-Issue

        foreach ($ip in $unassociatedIPs) {
            Write-Log "  - $($ip.Name) ($($ip.IpAddress))" -ForegroundColor Yellow
        }

        if ($Nuclear) {
            Write-Log "🔧 Cleaning up unassociated public IPs..." -ForegroundColor Yellow
            foreach ($ip in $unassociatedIPs) {
                Remove-AzPublicIpAddress -ResourceGroupName $ip.ResourceGroupName -Name $ip.Name -Force
                Write-Log "  - Removed: $($ip.Name)" -ForegroundColor Green
            }
            Register-Issue -Fixed
        }
    }

    # Check virtual networks with overlapping address spaces
    $vnets = Get-AzVirtualNetwork
    $remediationSummary.ResourcesScanned += $vnets.Count

    for ($i = 0; $i -lt $vnets.Count; $i++) {
        for ($j = $i + 1; $j -lt $vnets.Count; $j++) {
            $vnet1 = $vnets[$i]
            $vnet2 = $vnets[$j]

            foreach ($addressSpace1 in $vnet1.AddressSpace.AddressPrefixes) {
                foreach ($addressSpace2 in $vnet2.AddressSpace.AddressPrefixes) {
                    # Simple check for exact match - a more complex CIDR overlap check would be better
                    if ($addressSpace1 -eq $addressSpace2) {
                        Write-Log "⚠️ VNets with overlapping address spaces detected:" -ForegroundColor Red
                        Write-Log "  - $($vnet1.Name): $addressSpace1" -ForegroundColor Red
                        Write-Log "  - $($vnet2.Name): $addressSpace2" -ForegroundColor Red
                        Register-Issue
                    }
                }
            }
        }
    }
}

# Function to handle VM security remediations
function Start-VMRemediation {
    Write-Log "🔍 Investigating virtual machines..." -ForegroundColor Cyan

    $vms = Get-AzVM
    Write-Log "Found $($vms.Count) Virtual Machines" -ForegroundColor Yellow
    $remediationSummary.ResourcesScanned += $vms.Count

    foreach ($vm in $vms) {
        # Check VM status
        $vmStatus = Get-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status
        $vmRunning = ($vmStatus.Statuses | Where-Object { $_.Code -eq 'PowerState/running' }) -ne $null
        $vmDeallocated = ($vmStatus.Statuses | Where-Object { $_.Code -eq 'PowerState/deallocated' }) -ne $null

        # Check if VM is running but idle
        if ($vmRunning) {
            $metrics = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU" -StartTime (Get-Date).AddDays(-3) -EndTime (Get-Date) -AggregationType Average -IntervalInSeconds 3600
            $avgCPU = ($metrics.Data | Measure-Object -Property Average -Average).Average

            if ($avgCPU -lt 5) {
                Write-Log "⚠️ VM $($vm.Name) is running but has very low CPU usage (avg: $($avgCPU)%)" -ForegroundColor Yellow
                Register-Issue

                if ($Nuclear) {
                    Write-Log "🔧 Stopping idle VM to save costs..." -ForegroundColor Yellow
                    Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force
                    Write-Log "✅ VM stopped" -ForegroundColor Green
                    Register-Issue -Fixed
                }
            }
        }

        # Check if VM doesn't have backup configured
        $backupItems = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM
        $vmHasBackup = ($backupItems | Where-Object { $_.Name -like "*$($vm.Name)*" }) -ne $null

        if (-not $vmHasBackup) {
            Write-Log "⚠️ VM $($vm.Name) does not have backup configured" -ForegroundColor Red
            Register-Issue
        }

        # Check for unattached disks
        if ($vmDeallocated) {
            $deallocatedTime = ($vmStatus.Statuses | Where-Object { $_.Code -eq 'PowerState/deallocated' }).Time
            $daysDeallocated = (New-TimeSpan -Start $deallocatedTime -End (Get-Date)).Days

            if ($daysDeallocated -gt 30) {
                Write-Log "⚠️ VM $($vm.Name) has been deallocated for $daysDeallocated days" -ForegroundColor Yellow
                Register-Issue

                if ($Nuclear) {
                    Write-Log "🔧 Considering decommissioning this VM to save costs" -ForegroundColor Yellow
                }
            }
        }

        # Check if VM has managed disks with encryption
        foreach ($disk in $vm.StorageProfile.OsDisk, $vm.StorageProfile.DataDisks) {
            if ($disk.ManagedDisk -and -not $disk.ManagedDisk.DiskEncryptionSet) {
                Write-Log "⚠️ Disk $($disk.Name) on VM $($vm.Name) is not encrypted" -ForegroundColor Yellow
                Register-Issue

                if ($Nuclear) {
                    Write-Log "  - Recommendation: Enable Azure Disk Encryption" -ForegroundColor Yellow
                    # Disk encryption requires more complex implementation
                }
            }
        }
    }

    # Check for unattached disks
    $allDisks = Get-AzDisk
    $unattachedDisks = $allDisks | Where-Object { $null -eq $_.ManagedBy }
    $remediationSummary.ResourcesScanned += $allDisks.Count

    if ($unattachedDisks.Count -gt 0) {
        Write-Log "⚠️ Found $($unattachedDisks.Count) unattached disks that may be costing money" -ForegroundColor Yellow
        Register-Issue

        foreach ($disk in $unattachedDisks) {
            Write-Log "  - $($disk.Name) | Size: $($disk.DiskSizeGB) GB | Type: $($disk.Sku.Name)" -ForegroundColor Yellow

            if ($Nuclear) {
                $confirmDiskDeletion = Read-Host "Delete unattached disk $($disk.Name)? (yes/no)"
                if ($confirmDiskDeletion -eq 'yes') {
                    Remove-AzDisk -ResourceGroupName $disk.ResourceGroupName -DiskName $disk.Name -Force
                    Write-Log "  - Deleted unattached disk: $($disk.Name)" -ForegroundColor Green
                    Register-Issue -Fixed
                }
            }
        }
    }
}

# Function to handle Storage Account remediations
function Start-StorageRemediation {
    Write-Log "🔍 Investigating storage accounts..." -ForegroundColor Cyan

    $storageAccounts = Get-AzStorageAccount
    Write-Log "Found $($storageAccounts.Count) Storage Accounts" -ForegroundColor Yellow
    $remediationSummary.ResourcesScanned += $storageAccounts.Count

    foreach ($sa in $storageAccounts) {
        # Check for public access
        if ($sa.AllowBlobPublicAccess -eq $true) {
            Write-Log "⚠️ Storage account $($sa.StorageAccountName) allows public blob access" -ForegroundColor Red
            Register-Issue

            if ($Nuclear) {
                Write-Log "🔧 Disabling public blob access..." -ForegroundColor Yellow
                $sa | Set-AzStorageAccount -AllowBlobPublicAccess $false
                Write-Log "✅ Public access disabled" -ForegroundColor Green
                Register-Issue -Fixed
            }
        }

        # Check for secure transfer
        if ($sa.EnableHttpsTrafficOnly -eq $false) {
            Write-Log "⚠️ Storage account $($sa.StorageAccountName) allows non-HTTPS traffic" -ForegroundColor Red
            Register-Issue

            if ($Nuclear) {
                Write-Log "🔧 Enabling HTTPS-only traffic..." -ForegroundColor Yellow
                $sa | Set-AzStorageAccount -EnableHttpsTrafficOnly $true
                Write-Log "✅ HTTPS-only traffic enabled" -ForegroundColor Green
                Register-Issue -Fixed
            }
        }

        # Check for minimum TLS version
        if ($sa.MinimumTlsVersion -ne 'TLS1_2') {
            Write-Log "⚠️ Storage account $($sa.StorageAccountName) uses outdated TLS version" -ForegroundColor Red
            Register-Issue

            if ($Nuclear) {
                Write-Log "🔧 Upgrading to TLS 1.2..." -ForegroundColor Yellow
                $sa | Set-AzStorageAccount -MinimumTlsVersion 'TLS1_2'
                Write-Log "✅ TLS 1.2 enforced" -ForegroundColor Green
                Register-Issue -Fixed
            }
        }

        # Check for network restrictions
        if ($sa.NetworkRuleSet.DefaultAction -eq 'Allow') {
# Azure Well-Architected Framework Checklist

## Cost Optimization
- [ ] Resources are appropriately sized
- [ ] Auto-scaling is implemented where applicable
- [ ] Reserved Instances utilized for predictable workloads
- [ ] Cost alerts and budgets configured
- [ ] Dev/Test resources shut down outside working hours
- [ ] Unused resources identified and removed

## Operational Excellence
- [ ] Infrastructure-as-Code templates established
- [ ] CI/CD pipelines implemented
- [ ] Monitoring and alerting configured
- [ ] Runbooks for common operations
- [ ] Documentation updated and accessible
- [ ] DevOps practices followed

## Performance Efficiency
- [ ] Services distributed across regions as needed
- [ ] CDN used for content delivery
- [ ] Caching implemented where appropriate
- [ ] Auto-scaling rules optimized
- [ ] Performance testing performed
- [ ] Resource performance metrics monitored

## Reliability
- [ ] High-availability patterns implemented
- [ ] Multi-region deployments for critical services
- [ ] Resilient data storage configured
- [ ] Recovery point objectives (RPO) defined
- [ ] Recovery time objectives (RTO) defined
- [ ] Disaster recovery plans tested

## Security
- [ ] Principle of least privilege enforced
- [ ] Network security groups properly configured
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Key rotation policies established
- [ ] Security monitoring and alerting enabled
- [ ] Regular security assessments performed
---

*"Architecture is not just about appearances, mon ami. It is about solid foundations."* - H. Poirot
'@ | Out-File -FilePath ".\TheGreyCells\Governance\WellArchitectedChecklist.md" -Encoding UTF8

# Create a Bicep template for secure Azure deployment
@'
// Secure Azure Resource Group Deployment
// "A good detective always secures the environment"

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Environment (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Tags to apply to resources')
param tags object = {
  Environment: environment
  Project: 'PoirotDeux'
  Detective: 'Hercule Poirot'
}

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@description('Network address space')
param vnetAddressPrefix string = '10.0.0.0/16'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'poirot${environment}${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: 'kv-poirot-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-poirot-${environment}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'subnet-app'
        properties: {
          addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 0)
          networkSecurityGroup: {
            id: nsgApp.id
          }
        }
      }
      {
        name: 'subnet-data'
        properties: {
          addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 1)
          networkSecurityGroup: {
            id: nsgData.id
          }
        }
      }
    ]
  }
}

// Network Security Group - Application Tier
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-app-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4000
          access: 'Deny'
          direction: 'Inbound'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// Network Security Group - Data Tier
resource nsgData 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-data-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSQLInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: cidrSubnet(vnetAddressPrefix, 24, 0)
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4000
          access: 'Deny'
          direction: 'Inbound'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: 'sql-poirot-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    administratorLogin: 'poirotAdmin'
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

// Enable SQL Server Auditing
resource sqlServerAudit 'Microsoft.Sql/servers/auditingSettings@2021-11-01-preview' = {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    storageAccountAccessKey: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
    retentionDays: 90
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  parent: sqlServer
  name: 'db-poirot-${environment}'
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'S1' : 'Basic'
    tier: environment == 'prod' ? 'Standard' : 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
  }
}

// Enable SQL Database TDE
resource sqlDatabaseTDE 'Microsoft.Sql/servers/databases/transparentDataEncryption@2021-11-01-preview' = {
  parent: sqlDatabase
  name: 'current'
  properties: {
    state: 'Enabled'
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: 'law-poirot-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-poirot-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// Azure Recovery Services Vault
resource recoveryVault 'Microsoft.RecoveryServices/vaults@2021-12-01' = {
  name: 'rsv-poirot-${environment}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

// Azure Policy Assignment for Security
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: 'pa-security-${environment}-${uniqueString(resourceGroup().id)}'
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/1a5bb27d-173f-493e-9568-eb56638dde4d' // Built-in policy for Azure Security Benchmark
    displayName: 'Poirot Security Standards'
    description: 'This policy enforces the Azure Security Benchmark standards'
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output keyVaultName string = keyVault.name
output sqlServerName string = sqlServer.name
output virtualNetworkName string = vnet.name
output logAnalyticsName string = logAnalytics.name
output recoveryVaultName string = recoveryVault.name
'@ | Out-File -FilePath ".\Clues\Bicep\SecureResourceDeployment.bicep" -Encoding UTF8

# Create CI/CD Pipeline Template for Azure DevOps
@'
# Azure DevOps Pipeline for PoirotDeux
# "A good investigation requires proper procedure"

trigger:
  branches:
    include:
    - main
    - feature/*
  paths:
    include:
    - src/*
    - infra/*
    - tests/*

variables:
  azureSubscription: 'PoirotAzureConnection'
  resourceGroupName: 'rg-poirot-$(Environment)'
  location: 'westeurope'
  bicepFilePath: 'infra/main.bicep'
  buildConfiguration: 'Release'
  vmImageName: 'ubuntu-latest'
  Environment: 'dev'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: BuildAndTest
    displayName: 'Build and Test'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: UseDotNet@2
      displayName: 'Install .NET SDK'
      inputs:
        packageType: 'sdk'
        version: '6.x'

    - task: DotNetCoreCLI@2
      displayName: 'Restore NuGet packages'
      inputs:
        command: 'restore'
        projects: 'src/**/*.csproj'

    - task: DotNetCoreCLI@2
      displayName: 'Build'
      inputs:
        command: 'build'
        projects: 'src/**/*.csproj'
        arguments: '--configuration $(buildConfiguration)'

    - task: DotNetCoreCLI@2
      displayName: 'Run tests'
      inputs:
        command: 'test'
        projects: 'tests/**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --collect "Code coverage"'

    - task: DotNetCoreCLI@2
      displayName: 'Publish'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
        zipAfterPublish: true

    - task: AzureBicepValidate@1
      displayName: 'Validate Bicep file'
      inputs:
        connectedServiceName: $(azureSubscription)
        deploymentScope: 'Resource Group'
        resourceGroupName: $(resourceGroupName)
        location: $(location)
        templateFile: $(bicepFilePath)

    - task: PublishBuildArtifacts@1
      displayName: 'Publish artifacts'
      inputs:
        pathToPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'drop'

- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: succeeded()
  variables:
    Environment: 'dev'
  jobs:
  - deployment: DeployInfrastructure
    displayName: 'Deploy Infrastructure'
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - checkout: self
          - task: AzureCLI@2
            displayName: 'Deploy Bicep template'
            inputs:
              azureSubscription: $(azureSubscription)
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az deployment group create \
                  --resource-group $(resourceGroupName) \
                  --template-file $(bicepFilePath) \
                  --parameters environment=$(Environment)

  - deployment: DeployApplication
    displayName: 'Deploy Application'
    dependsOn: DeployInfrastructure
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureRmWebAppDeployment@4
            displayName: 'Deploy to App Service'
            inputs:
              ConnectionType: 'AzureRM'
              azureSubscription: $(azureSubscription)
              appType: 'webApp'
              WebAppName: 'app-poirot-$(Environment)'
              packageForLinux: '$(Pipeline.Workspace)/drop/*.zip'
              enableCustomDeployment: true
              DeploymentType: 'webDeploy'
              TakeAppOfflineFlag: true

- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: DeployDev
  condition: succeeded()
  variables:
    Environment: 'prod'
  jobs:
  - deployment: DeployInfrastructure
    displayName: 'Deploy Infrastructure'
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - checkout: self
          - task: AzureCLI@2
            displayName: 'Deploy Bicep template'
            inputs:
              azureSubscription: $(azureSubscription)
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az deployment group create \
                  --resource-group $(resourceGroupName) \
                  --template-file $(bicepFilePath) \
                  --parameters environment=$(Environment)

  - deployment: DeployApplication
    displayName: 'Deploy Application'
    dependsOn: DeployInfrastructure
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureRmWebAppDeployment@4
            displayName: 'Deploy to App Service'
            inputs:
              ConnectionType: 'AzureRM'
              azureSubscription: $(azureSubscription)
              appType: 'webApp'
              WebAppName: 'app-poirot-$(Environment)'
              packageForLinux: '$(Pipeline.Workspace)/drop/*.zip'
              enableCustomDeployment: true
              DeploymentType: 'webDeploy'
              TakeAppOfflineFlag: true
'@ | Out-File -FilePath ".\Pipeline\CI\azure-pipelines.yml" -Encoding UTF8

# Create Disaster Recovery Plan
@'
# POIROT'S DISASTER RECOVERY PLAN
## "A detective must always prepare for the unexpected, mon ami!"

## 1. DISASTER SCENARIOS

### Critical Service Outage
- **Impact**: Complete loss of application availability
- **RTO**: 4 hours
- **RPO**: 15 minutes
- **Response Team**: Cloud Operations, Development Team, Management

### Regional Disaster
- **Impact**: Loss of primary region
- **RTO**: 8 hours
- **RPO**: 1 hour
- **Response Team**: Cloud Operations, Development Team, Management, Communications

### Data Corruption
- **Impact**: Application functional but data compromised
- **RTO**: 2 hours
- **RPO**: Most recent verified backup
- **Response Team**: Data Team, Development Team, Cloud Operations

### Security Breach
- **Impact**: Varies depending on breach
- **RTO**: Varies based on severity
- **RPO**: Last known clean state
- **Response Team**: Security Team, Cloud Operations, Management, Legal, Communications

## 2. PREPARATION

### Resource Redundancy
- Production applications deployed to primary and secondary regions
- Azure Traffic Manager configured for failover
- Azure SQL Database configured with geo-replication
- Azure Cosmos DB with multi-region writes where applicable

### Backup Strategy
- **Database**: Point-in-time restore + geo-backup
- **Blob Storage**: Geo-redundant storage with versioning
- **Configuration**: All IaC templates in version control
- **VM Workloads**: Azure Backup with daily snapshots

### Documentation & Access
- DR documentation reviewed quarterly
- Emergency access procedures documented
- Contact information updated monthly
- Role assignments verified quarterly

## 3. DETECTION

### Monitoring Systems
- Azure Monitor alerts configured for all critical services
- Application Insights for application telemetry
- Log Analytics for centralized logging
- Service Health alerts configured
- Security Center alerts enabled

### Alert Notification Paths
- Critical alerts → PagerDuty → On-call rotation
- Service health → Email + Teams channel
- Security alerts → Security team + Cloud Operations

## 4. RESPONSE PROCEDURES

### Initial Assessment
1. Identify affected services and impact scope
2. Determine if DR plan activation is required
3. Notify required team members
4. Begin incident documentation

### Failover Procedures
1. **App Service Plans**:
   - Verify secondary region deployment is healthy
   - Execute Traffic Manager failover or manual DNS change
   - Verify application functionality in secondary region

2. **Database Failover**:
   - For Azure SQL: Initiate geo-failover
   - For Cosmos DB: Verify multi-region writes or change preferred regions
   - Validate data consistency post-failover

3. **Storage Recovery**:
   - For critical data corruption: Restore from point-in-time backup
   - For regional outage: Ensure read access from secondary region
   - Update connection strings if necessary

### Communication Plan
1. Initial notification (within 30 minutes of incident)
2. Status updates (every hour during incident)
3. Mitigation progress updates
4. All-clear notification
5. Post-incident summary

## 5. RECOVERY & RESTORATION

### Service Restoration Checklist
- [ ] Verify all services are operational
- [ ] Confirm data integrity
- [ ] Validate security posture
- [ ] Verify monitoring systems
- [ ] Test critical business functions

### Return to Primary Region (if applicable)
1. Ensure primary region is stable
2. Synchronize any data changes from secondary region
3. Verify infrastructure in primary region
4. Execute planned failback during maintenance window
5. Verify functionality in primary region

## 6. POST-INCIDENT

### Review Process
1. Conduct detailed post-mortem (within 48 hours)
2. Document root cause
3. Identify prevention measures
4. Update DR plan based on lessons learned

### Testing Schedule
- Tabletop exercises: Quarterly
- Functional failover tests: Semi-annually
- Full DR simulation: Annually

---

*"The disaster, mon ami, is not the failure itself, but the failure to prepare."* - Hercule Poirot
'@ | Out-File -FilePath ".\Alibis\DisasterRecovery\DisasterRecoveryPlan.md" -Encoding UTF8

# Create Poirot's preferences file
@{
    AzureEnvironment = "AzureCloud"
    PreferredRegion = "westeurope"
    SecondaryRegion = "northeurope"
    MethodicalApproach = $true
    OrderAndMethod = "Essential"
    LittleGreyCells = "Always Active"
    SecurityScanFrequency = "Daily"
    ComplianceFrameworks = @("ISO 27001", "NIST 800-53", "GDPR")
    BackupRetention = "30 days"
    DisasterRecoveryStrategy = "Active-Passive"
    CostOptimizationFocus = "High"
    SecurityPosture = "Defense-in-depth"
    VirtualNetworkArchitecture = "Hub-and-Spoke"
    PreferredIaCLanguage = "Bicep"
    ResourceNamingConvention = "rtype-poirot-env-unique"
} | ConvertTo-Json | Out-File -FilePath ".\SecretDrawer\PoirotAzurePreferences.json" -Encoding UTF8
Write-Host "`n✅ Azure Cloud Detective Agency setup complete!" -ForegroundColor Green
Write-Host "📍 Your cloud investigation headquarters at C:\FixMyShit\PoirotDeux is ready." -ForegroundColor Cyan
Write-Host "🎩 'In the cloud, everything must be in its place, and a place for everything!'" -ForegroundColor Magenta

# Save as: C:\FixMyShit\PoirotDeux\LaunchInvestigation.ps1

@"
==================================================
    POIROT'S AZURE CLOUD DETECTIVE AGENCY LAUNCHER
==================================================

What would you like to investigate today?

1. Azure Environment Health Check
2. Security Posture Assessment
3. Resource Governance Analysis
4. Cost Optimization Investigation
5. Disaster Recovery Readiness
6. IaC Template Library
7. CI/CD Pipeline Management
8. Create New Cloud Architecture Case
9. Exit
==================================================
"@ 

$choice = Read-Host "Select an option (1-9)"

switch ($choice) {
    "1" { & ".\Witnesses\Monitoring\AzureHealthCheck.ps1" }
    "2" {
        Write-Host "Launching Security Investigation..." -ForegroundColor Cyan
        & ".\Witnesses\Automation\AzureEmergencyRemediation.ps1" -ResourceType "Network"
    }
    "3" {
        Get-AzPolicyAssignment | Format-Table -Property Name, DisplayName, PolicyDefinitionId
        Write-Host "Use Azure Policy to enforce organization standards" -ForegroundColor Yellow
        notepad ".\TheGreyCells\Governance\WellArchitectedChecklist.md"
    }
    "4" {
        Write-Host "Analyzing Azure costs..." -ForegroundColor Cyan
        Get-AzConsumptionUsageDetail -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) |
            Group-Object -Property ResourceGroup |
            Select-Object Name, Count, @{Name="Cost"; Expression={($_.Group | Measure-Object -Property PretaxCost -Sum).Sum}} |
            Sort-Object Cost -Descending |
            Format-Table
    }
    "5" { notepad ".\Alibis\DisasterRecovery\DisasterRecoveryPlan.md" }
    "6" {
        $templateChoice = Read-Host "Choose template format: 1) ARM 2) Bicep 3) Terraform"
        switch ($templateChoice) {
            "1" { explorer ".\Clues\ARM" }
            "2" { notepad ".\Clues\Bicep\SecureResourceDeployment.bicep" }
            "3" { explorer ".\Clues\Terraform" }
            default { Write-Host "Invalid selection!" -ForegroundColor Red }
        }
    }
    "7" { notepad ".\Pipeline\CI\azure-pipelines.yml" }
    "8" {
        $caseName = Read-Host "Enter cloud architecture case name"
        New-Item -ItemType File -Path ".\ActiveCases\$caseName.md" -Force
        notepad ".\ActiveCases\$caseName.md"
    }
    "9" { Write-Host "`n🎩 'The cloud investigation is never closed, only paused. Au revoir, mon ami!'" -ForegroundColor Magenta; exit }
    default { Write-Host "Invalid selection!" -ForegroundColor Red }
}
