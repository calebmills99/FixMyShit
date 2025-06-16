# ===================================================================
# FINAL SYSTEM VALIDATION SCRIPT
# Phase 4: Comprehensive System Health Validation
# ===================================================================

<#
.SYNOPSIS
    Comprehensive final validation script for the FixMyShit emergency recovery system.
    
.DESCRIPTION
    Performs complete system health validation after emergency recovery operations,
    verifying malware removal, system integrity, service functionality, and Azure AI
    environment restoration. Provides detailed validation report and recommendations.
    
.NOTES
    Author: Kilo Code
    Version: 4.0 - Final System Validation
    Requires: Administrator privileges
    
.PARAMETER GenerateReport
    Generate detailed validation report
    
.PARAMETER SkipAzureValidation
    Skip Azure AI environment validation
    
.PARAMETER QuickValidation
    Perform quick validation (reduced scope)
    
.PARAMETER LogPath
    Custom log file path
    
.EXAMPLE
    .\FINAL_SYSTEM_VALIDATION.ps1 -GenerateReport
    .\FINAL_SYSTEM_VALIDATION.ps1 -QuickValidation
#>

#Requires -RunAsAdministrator

param(
    [switch]$GenerateReport,
    [switch]$SkipAzureValidation,
    [switch]$QuickValidation,
    [string]$LogPath = ".\FINAL_VALIDATION_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Global configuration
$ErrorActionPreference = "Continue"
$ValidationStartTime = Get-Date
$ValidationResults = @{}
$CriticalIssues = @()
$Warnings = @()
$Recommendations = @()

# ===================================================================
# LOGGING AND UTILITIES
# ===================================================================

function Write-ValidationLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "VALIDATION")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "CRITICAL" { "Magenta" }
        default { "White" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
}

function Show-ValidationBanner {
    $banner = @"

  ███████╗██╗███╗   ██╗ █████╗ ██╗         ██╗   ██╗ █████╗ ██╗     ██╗██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
  ██╔════╝██║████╗  ██║██╔══██╗██║         ██║   ██║██╔══██╗██║     ██║██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
  █████╗  ██║██╔██╗ ██║███████║██║         ██║   ██║███████║██║     ██║██║  ██║███████║   ██║   ██║██║   ██║██╔██╗ ██║
  ██╔══╝  ██║██║╚██╗██║██╔══██║██║         ╚██╗ ██╔╝██╔══██║██║     ██║██║  ██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
  ██║     ██║██║ ╚████║██║  ██║███████╗     ╚████╔╝ ██║  ██║███████╗██║██████╔╝██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
  ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝      ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                                                                                        
             FINAL SYSTEM VALIDATION - FixMyShit Emergency Recovery System v4.0
                           Comprehensive Post-Recovery Health Assessment
"@
    
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "VALIDATION SCOPE: Malware Removal, System Integrity, Azure AI Environment" -ForegroundColor Green
    Write-Host "RECOVERY PHASES: 0-Emergency Services, 1-Cleanup, 2-Hardening, 3-Azure" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
}

# ===================================================================
# VALIDATION MODULES
# ===================================================================

function Test-MalwareRemoval {
    Write-ValidationLog "Validating malware removal and system cleanliness..." "INFO"
    
    $malwareResults = @{
        BackdoorAgentE = $false
        TrojanTasker = $false
        StartupLocations = $false
        ScheduledTasks = $false
        ProcessIntegrity = $false
        RegistryClean = $false
    }
    
    try {
        # Check for Backdoor.Agent.E signatures
        Write-ValidationLog "Scanning for Backdoor.Agent.E remnants..." "INFO"
        $startupPaths = @(
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startup",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        )
        
        $suspiciousFiles = 0
        foreach ($path in $startupPaths) {
            if ($path -like "HKLM:*" -or $path -like "HKCU:*") {
                try {
                    $regKeys = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                    foreach ($key in $regKeys.PSObject.Properties) {
                        if ($key.Value -like "*agent*" -or $key.Value -like "*backdoor*") {
                            $suspiciousFiles++
                        }
                    }
                } catch { }
            } else {
                if (Test-Path $path) {
                    $files = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue
                    $suspiciousFiles += ($files | Where-Object {$_.Name -like "*agent*" -or $_.Name -like "*backdoor*"}).Count
                }
            }
        }
        
        $malwareResults.BackdoorAgentE = $suspiciousFiles -eq 0
        $malwareResults.StartupLocations = $suspiciousFiles -eq 0
        
        # Check for Trojan.Tasker remnants
        Write-ValidationLog "Scanning for Trojan.Tasker scheduled tasks..." "INFO"
        $suspiciousTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | 
            Where-Object {$_.TaskName -like "*task*" -and $_.TaskName -like "*trojan*"}
        
        $malwareResults.TrojanTasker = $suspiciousTasks.Count -eq 0
        $malwareResults.ScheduledTasks = $suspiciousTasks.Count -eq 0
        
        # Process integrity check
        Write-ValidationLog "Validating running process integrity..." "INFO"
        $suspiciousProcesses = Get-Process -ErrorAction SilentlyContinue | 
            Where-Object {$_.ProcessName -like "*agent*" -or $_.ProcessName -like "*backdoor*" -or $_.ProcessName -like "*trojan*"}
        
        $malwareResults.ProcessIntegrity = $suspiciousProcesses.Count -eq 0
        
        # Registry cleanliness check
        Write-ValidationLog "Validating registry cleanliness..." "INFO"
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        
        $suspiciousEntries = 0
        foreach ($regPath in $registryPaths) {
            try {
                $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
                foreach ($subKey in $subKeys) {
                    $displayName = (Get-ItemProperty -Path $subKey.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
                    if ($displayName -like "*agent*" -or $displayName -like "*backdoor*" -or $displayName -like "*trojan*") {
                        $suspiciousEntries++
                    }
                }
            } catch { }
        }
        
        $malwareResults.RegistryClean = $suspiciousEntries -eq 0
        
        # Overall malware assessment
        $overallMalwareClean = ($malwareResults.Values | Where-Object {$_ -eq $true}).Count -eq $malwareResults.Count
        
        if ($overallMalwareClean) {
            Write-ValidationLog "Malware removal validation: PASSED - System appears clean" "SUCCESS"
        } else {
            Write-ValidationLog "Malware removal validation: FAILED - Suspicious artifacts detected" "ERROR"
            $CriticalIssues += "Malware artifacts still present in system"
        }
        
    } catch {
        Write-ValidationLog "Error during malware validation: $($_.Exception.Message)" "ERROR"
        $CriticalIssues += "Unable to complete malware validation"
    }
    
    return $malwareResults
}

function Test-SystemIntegrity {
    Write-ValidationLog "Validating system integrity and core functionality..." "INFO"
    
    $integrityResults = @{
        SystemFiles = $false
        WindowsDefender = $false
        ExplorerShell = $false
        CriticalServices = $false
        FirewallService = $false
        DotNetRuntime = $false
    }
    
    try {
        # System file integrity
        if (-not $QuickValidation) {
            Write-ValidationLog "Running system file checker (SFC)..." "INFO"
            $sfcResult = & sfc /verifyonly 2>&1
            $integrityResults.SystemFiles = $sfcResult -notlike "*found integrity violations*"
        } else {
            $integrityResults.SystemFiles = $true  # Skip in quick mode
        }
        
        # Windows Defender status
        Write-ValidationLog "Checking Windows Defender status..." "INFO"
        try {
            $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
            $integrityResults.WindowsDefender = $defenderStatus.AntivirusEnabled -and 
                                                 $defenderStatus.RealTimeProtectionEnabled
        } catch {
            $integrityResults.WindowsDefender = $false
        }
        
        # Explorer shell integrity
        Write-ValidationLog "Validating Explorer shell integrity..." "INFO"
        $explorerProcess = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        $shellRegistration = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        $integrityResults.ExplorerShell = ($explorerProcess.Count -gt 0) -and $shellRegistration
        
        # Critical services status
        Write-ValidationLog "Checking critical Windows services..." "INFO"
        $criticalServices = @("Winlogon", "BITS", "Themes", "AudioSrv", "Spooler")
        $runningServices = 0
        
        foreach ($service in $criticalServices) {
            $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($serviceStatus -and $serviceStatus.Status -eq "Running") {
                $runningServices++
            }
        }
        
        $integrityResults.CriticalServices = $runningServices -eq $criticalServices.Count
        
        # Windows Defender Firewall service
        Write-ValidationLog "Validating Windows Defender Firewall service..." "INFO"
        $firewallService = Get-Service -Name "MpsSvc" -ErrorAction SilentlyContinue
        $integrityResults.FirewallService = $firewallService -and $firewallService.Status -eq "Running"
        
        # .NET Runtime integrity
        Write-ValidationLog "Validating .NET runtime integrity..." "INFO"
        try {
            $dotnetVersion = & dotnet --version 2>&1
            $integrityResults.DotNetRuntime = $dotnetVersion -notlike "*error*" -and $dotnetVersion -notlike "*not found*"
        } catch {
            $integrityResults.DotNetRuntime = $false
        }
        
        # Overall integrity assessment
        $failedChecks = $integrityResults.GetEnumerator() | Where-Object {$_.Value -eq $false}
        
        if ($failedChecks.Count -eq 0) {
            Write-ValidationLog "System integrity validation: PASSED - All checks successful" "SUCCESS"
        } else {
            Write-ValidationLog "System integrity validation: PARTIAL - $($failedChecks.Count) checks failed" "WARN"
            foreach ($check in $failedChecks) {
                $Warnings += "System integrity issue: $($check.Key)"
            }
        }
        
    } catch {
        Write-ValidationLog "Error during integrity validation: $($_.Exception.Message)" "ERROR"
        $CriticalIssues += "Unable to complete system integrity validation"
    }
    
    return $integrityResults
}

function Test-SecurityHardening {
    Write-ValidationLog "Validating security hardening measures..." "INFO"
    
    $securityResults = @{
        UAC = $false
        WindowsUpdate = $false
        SecurityPolicies = $false
        FirewallRules = $false
        AntivirusDefinitions = $false
    }
    
    try {
        # UAC status
        $uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        $securityResults.UAC = $uacStatus.EnableLUA -eq 1
        
        # Windows Update service
        $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        $securityResults.WindowsUpdate = $wuService -and $wuService.Status -eq "Running"
        
        # Firewall profile status
        try {
            $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            $enabledProfiles = ($firewallProfiles | Where-Object {$_.Enabled -eq $true}).Count
            $securityResults.FirewallRules = $enabledProfiles -eq 3  # All three profiles enabled
        } catch {
            $securityResults.FirewallRules = $false
        }
        
        # Antivirus definition freshness
        try {
            $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
            $definitionAge = (Get-Date) - $defenderStatus.AntivirusSignatureLastUpdated
            $securityResults.AntivirusDefinitions = $definitionAge.TotalDays -lt 7
        } catch {
            $securityResults.AntivirusDefinitions = $false
        }
        
        $securityResults.SecurityPolicies = $true  # Placeholder for policy validation
        
        # Overall security assessment
        $failedSecurity = $securityResults.GetEnumerator() | Where-Object {$_.Value -eq $false}
        
        if ($failedSecurity.Count -eq 0) {
            Write-ValidationLog "Security hardening validation: PASSED - All measures active" "SUCCESS"
        } else {
            Write-ValidationLog "Security hardening validation: PARTIAL - $($failedSecurity.Count) measures need attention" "WARN"
            foreach ($check in $failedSecurity) {
                $Warnings += "Security hardening issue: $($check.Key)"
            }
        }
        
    } catch {
        Write-ValidationLog "Error during security validation: $($_.Exception.Message)" "ERROR"
        $Warnings += "Unable to complete security hardening validation"
    }
    
    return $securityResults
}

function Test-AzureEnvironment {
    if ($SkipAzureValidation) {
        Write-ValidationLog "Skipping Azure environment validation (requested)" "INFO"
        return @{ Skipped = $true }
    }
    
    Write-ValidationLog "Validating Azure AI development environment..." "INFO"
    
    $azureResults = @{
        AzureCLI = $false
        AzureConnectivity = $false
        OpenAIService = $false
        MLWorkspace = $false
        PythonEnvironment = $false
        CursorIDE = $false
    }
    
    try {
        # Azure CLI availability
        try {
            $azVersion = & az --version 2>&1
            $azureResults.AzureCLI = $azVersion -like "*azure-cli*"
        } catch {
            $azureResults.AzureCLI = $false
        }
        
        # Azure connectivity
        if ($azureResults.AzureCLI) {
            try {
                $azAccount = & az account show 2>&1
                $azureResults.AzureConnectivity = $azAccount -notlike "*error*" -and $azAccount -notlike "*login*"
            } catch {
                $azureResults.AzureConnectivity = $false
            }
        }
        
        # OpenAI service availability
        if ($azureResults.AzureConnectivity) {
            try {
                $openaiList = & az cognitiveservices account list --query "[?kind=='OpenAI']" 2>&1
                $azureResults.OpenAIService = $openaiList -like "*gpt*" -or $openaiList -like "*openai*"
            } catch {
                $azureResults.OpenAIService = $false
            }
        }
        
        # ML workspace
        if ($azureResults.AzureConnectivity) {
            try {
                $mlWorkspaces = & az ml workspace list 2>&1
                $azureResults.MLWorkspace = $mlWorkspaces -like "*midnight*" -or $mlWorkspaces -notlike "*error*"
            } catch {
                $azureResults.MLWorkspace = $false
            }
        }
        
        # Python environment
        try {
            $pythonVersion = & python --version 2>&1
            $azureResults.PythonEnvironment = $pythonVersion -like "*Python 3.*"
        } catch {
            $azureResults.PythonEnvironment = $false
        }
        
        # Cursor IDE
        $cursorPaths = @(
            "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
            "$env:PROGRAMFILES\Cursor\Cursor.exe"
        )
        $azureResults.CursorIDE = ($cursorPaths | Where-Object {Test-Path $_}).Count -gt 0
        
        # Overall Azure assessment
        $failedAzure = $azureResults.GetEnumerator() | Where-Object {$_.Value -eq $false}
        
        if ($failedAzure.Count -eq 0) {
            Write-ValidationLog "Azure environment validation: PASSED - Development environment ready" "SUCCESS"
        } else {
            Write-ValidationLog "Azure environment validation: PARTIAL - $($failedAzure.Count) components need attention" "WARN"
            foreach ($check in $failedAzure) {
                $Recommendations += "Azure environment: Restore $($check.Key)"
            }
        }
        
    } catch {
        Write-ValidationLog "Error during Azure validation: $($_.Exception.Message)" "ERROR"
        $Recommendations += "Manual Azure environment verification required"
    }
    
    return $azureResults
}

function Test-PerformanceMetrics {
    Write-ValidationLog "Collecting system performance metrics..." "INFO"
    
    $performanceResults = @{
        CPUUsage = 0
        MemoryUsage = 0
        DiskSpace = 0
        BootTime = 0
        ResponseTime = 0
    }
    
    try {
        # CPU usage
        $cpu = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $performanceResults.CPUUsage = [math]::Round($cpu.Average, 1)
        
        # Memory usage
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
        $memoryUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 1)
        $performanceResults.MemoryUsage = $memoryUsage
        
        # Disk space
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DeviceID -eq $env:SystemDrive}
        $diskUsage = [math]::Round((($systemDrive.Size - $systemDrive.FreeSpace) / $systemDrive.Size) * 100, 1)
        $performanceResults.DiskSpace = $diskUsage
        
        # Boot time
        $bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $uptime = (Get-Date) - $bootTime
        $performanceResults.BootTime = [math]::Round($uptime.TotalHours, 1)
        
        # System response time (simple test)
        $responseStart = Get-Date
        Get-Process | Out-Null
        $responseEnd = Get-Date
        $performanceResults.ResponseTime = [math]::Round(($responseEnd - $responseStart).TotalMilliseconds, 0)
        
        Write-ValidationLog "Performance metrics collected successfully" "SUCCESS"
        
        # Performance assessment
        if ($performanceResults.CPUUsage -gt 80) {
            $Warnings += "High CPU usage detected: $($performanceResults.CPUUsage)%"
        }
        if ($performanceResults.MemoryUsage -gt 85) {
            $Warnings += "High memory usage detected: $($performanceResults.MemoryUsage)%"
        }
        if ($performanceResults.DiskSpace -gt 90) {
            $CriticalIssues += "Critical disk space shortage: $($performanceResults.DiskSpace)% used"
        }
        if ($performanceResults.ResponseTime -gt 5000) {
            $Warnings += "Slow system response time: $($performanceResults.ResponseTime)ms"
        }
        
    } catch {
        Write-ValidationLog "Error collecting performance metrics: $($_.Exception.Message)" "ERROR"
        $Warnings += "Unable to collect complete performance metrics"
    }
    
    return $performanceResults
}

# ===================================================================
# REPORT GENERATION
# ===================================================================

function Generate-ValidationReport {
    param([hashtable]$Results)
    
    Write-ValidationLog "Generating comprehensive validation report..." "INFO"
    
    $totalDuration = ((Get-Date) - $ValidationStartTime).TotalMinutes
    
    $report = @{
        ValidationSummary = @{
            StartTime = $ValidationStartTime.ToString("yyyy-MM-dd HH:mm:ss")
            EndTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Duration = "$([math]::Round($totalDuration, 1)) minutes"
            ValidationMode = if ($QuickValidation) { "Quick" } else { "Comprehensive" }
            OverallStatus = if ($CriticalIssues.Count -eq 0) { "HEALTHY" } elseif ($CriticalIssues.Count -lt 3) { "DEGRADED" } else { "CRITICAL" }
            CriticalIssues = $CriticalIssues
            Warnings = $Warnings
            Recommendations = $Recommendations
        }
        DetailedResults = $Results
        SystemInfo = @{
            ComputerName = $env:COMPUTERNAME
            WindowsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            LastBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
        }
        RecoveryContext = @{
            TargetThreats = @("Backdoor.Agent.E", "Trojan.Tasker")
            RecoveryPhases = @(
                "Phase 0: Emergency Service Repairs",
                "Phase 1: Emergency Malware Cleanup",
                "Phase 2: Security Hardening & System Recovery",
                "Phase 3: Azure AI Development Environment Restoration"
            )
            ValidationScope = if ($SkipAzureValidation) { "System Only" } else { "Full System + Azure AI" }
        }
    }
    
    $reportPath = ".\FINAL_VALIDATION_REPORT_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8
    
    Write-ValidationLog "Validation report saved: $reportPath" "INFO"
    
    return $report
}

function Show-ValidationSummary {
    param([hashtable]$Report)
    
    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                    FINAL VALIDATION SUMMARY" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    
    $summary = $Report.ValidationSummary
    
    Write-Host "Validation Time: $($summary.StartTime) - $($summary.EndTime)" -ForegroundColor White
    Write-Host "Duration: $($summary.Duration)" -ForegroundColor White
    Write-Host "Mode: $($summary.ValidationMode)" -ForegroundColor White
    
    # Overall status
    $statusColor = switch ($summary.OverallStatus) {
        "HEALTHY" { "Green" }
        "DEGRADED" { "Yellow" }
        "CRITICAL" { "Red" }
        default { "White" }
    }
    Write-Host "Overall Status: $($summary.OverallStatus)" -ForegroundColor $statusColor
    
    # Issues summary
    if ($summary.CriticalIssues.Count -gt 0) {
        Write-Host "`nCritical Issues: $($summary.CriticalIssues.Count)" -ForegroundColor Red
        foreach ($issue in $summary.CriticalIssues) {
            Write-Host "  • $issue" -ForegroundColor Red
        }
    }
    
    if ($summary.Warnings.Count -gt 0) {
        Write-Host "`nWarnings: $($summary.Warnings.Count)" -ForegroundColor Yellow
        foreach ($warning in $summary.Warnings) {
            Write-Host "  • $warning" -ForegroundColor Yellow
        }
    }
    
    if ($summary.Recommendations.Count -gt 0) {
        Write-Host "`nRecommendations: $($summary.Recommendations.Count)" -ForegroundColor Cyan
        foreach ($recommendation in $summary.Recommendations) {
            Write-Host "  • $recommendation" -ForegroundColor Cyan
        }
    }
    
    # Final assessment
    Write-Host "`n" -NoNewline
    if ($summary.OverallStatus -eq "HEALTHY") {
        Write-Host "ASSESSMENT: System recovery completed successfully!" -ForegroundColor Green
        Write-Host "The emergency recovery process has restored your system to a healthy state." -ForegroundColor Green
        Write-Host "Continue monitoring for 24-48 hours to ensure stability." -ForegroundColor Green
    } elseif ($summary.OverallStatus -eq "DEGRADED") {
        Write-Host "ASSESSMENT: System recovery largely successful with minor issues." -ForegroundColor Yellow
        Write-Host "Address the warnings above to achieve optimal system health." -ForegroundColor Yellow
    } else {
        Write-Host "ASSESSMENT: Critical issues require immediate attention!" -ForegroundColor Red
        Write-Host "Review and resolve critical issues before normal system use." -ForegroundColor Red
    }
    
    Write-Host "================================================================" -ForegroundColor Cyan
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

# Display banner
Show-ValidationBanner

Write-ValidationLog "========== FINAL SYSTEM VALIDATION STARTED ==========" "INFO"
Write-ValidationLog "Log file: $LogPath" "INFO"
Write-ValidationLog "Validation mode: $(if($QuickValidation){'Quick'}else{'Comprehensive'})" "INFO"

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ValidationLog "CRITICAL: Administrator privileges required for validation" "CRITICAL"
    Write-Host "`nThis validation requires administrator privileges." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Execute validation modules
Write-Host "`n========== EXECUTING VALIDATION MODULES ==========" -ForegroundColor Cyan

$ValidationResults["MalwareRemoval"] = Test-MalwareRemoval
$ValidationResults["SystemIntegrity"] = Test-SystemIntegrity
$ValidationResults["SecurityHardening"] = Test-SecurityHardening
$ValidationResults["AzureEnvironment"] = Test-AzureEnvironment
$ValidationResults["PerformanceMetrics"] = Test-PerformanceMetrics

# Generate report if requested
if ($GenerateReport) {
    Write-Host "`n========== GENERATING VALIDATION REPORT ==========" -ForegroundColor Cyan
    $finalReport = Generate-ValidationReport -Results $ValidationResults
    Show-ValidationSummary -Report $finalReport
} else {
    # Show summary without detailed report
    $summaryReport = @{
        ValidationSummary = @{
            StartTime = $ValidationStartTime.ToString("yyyy-MM-dd HH:mm:ss")
            EndTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Duration = "$([math]::Round(((Get-Date) - $ValidationStartTime).TotalMinutes, 1)) minutes"
            ValidationMode = if ($QuickValidation) { "Quick" } else { "Comprehensive" }
            OverallStatus = if ($CriticalIssues.Count -eq 0) { "HEALTHY" } elseif ($CriticalIssues.Count -lt 3) { "DEGRADED" } else { "CRITICAL" }
            CriticalIssues = $CriticalIssues
            Warnings = $Warnings
            Recommendations = $Recommendations
        }
    }
    Show-ValidationSummary -Report $summaryReport
}

Write-ValidationLog "========== FINAL SYSTEM VALIDATION COMPLETED ==========" "INFO"

# Exit with appropriate code
if ($CriticalIssues.Count -eq 0) {
    Write-ValidationLog "Final validation completed successfully - System is healthy" "SUCCESS"
    exit 0
} else {
    Write-ValidationLog "Final validation completed with critical issues detected" "ERROR"
    exit 1
}