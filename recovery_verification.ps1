<#
.SYNOPSIS
    System Recovery Verification Script - Phase 2
    
.DESCRIPTION
    Verifies that Phase 1 malware cleanup was successful and tests all system functionality
    including Explorer shell, system files, services, and network connectivity.
    
.NOTES
    Author: Kilo Code
    Version: 2.0
    Can be run with standard user privileges for most checks
#>

param(
    [switch]$GenerateReport,
    [switch]$Verbose,
    [string]$ReportPath = "C:\FixMyShit\recovery_verification_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)

# Set up logging
$LogPath = "C:\FixMyShit\recovery_verification_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$ErrorActionPreference = "Continue"

# Global results storage
$VerificationResults = @()

function Write-LogMessage {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"} elseif($Level -eq "WARNING"){"Yellow"} else{"Green"})
    Add-Content -Path $LogPath -Value $LogEntry
}

function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Details,
        [string]$Recommendation = ""
    )
    
    $Result = [PSCustomObject]@{
        TestName = $TestName
        Status = $Status
        Details = $Details
        Recommendation = $Recommendation
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $script:VerificationResults += $Result
    
    $Color = switch($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "[$Status] $TestName - $Details" -ForegroundColor $Color
}

function Test-Phase1CleanupSuccess {
    Write-LogMessage "Verifying Phase 1 cleanup was successful..."
    
    # Check for Phase 1 script execution logs
    $Phase1Scripts = @("malware_scan.ps1", "emergency_cleanup.ps1", "repair_shell.ps1", "system_integrity.ps1")
    $CleanupSuccess = $true
    
    foreach ($Script in $Phase1Scripts) {
        if (Test-Path "C:\FixMyShit\$Script") {
            Add-TestResult "Phase 1 Script Presence" "PASS" "$Script found in cleanup directory"
        } else {
            Add-TestResult "Phase 1 Script Presence" "WARNING" "$Script not found - may indicate incomplete cleanup"
            $CleanupSuccess = $false
        }
    }
    
    # Check for malware scan logs
    $ScanLogs = Get-ChildItem "C:\FixMyShit\malware_scan_*.log" -ErrorAction SilentlyContinue
    if ($ScanLogs) {
        $LatestLog = $ScanLogs | Sort-Object LastWriteTime | Select-Object -Last 1
        Add-TestResult "Malware Scan Logs" "PASS" "Latest scan log: $($LatestLog.Name)"
    } else {
        Add-TestResult "Malware Scan Logs" "WARNING" "No malware scan logs found"
        $CleanupSuccess = $false
    }
    
    return $CleanupSuccess
}

function Test-ExplorerShellFunctionality {
    Write-LogMessage "Testing Explorer shell functionality..."
    
    try {
        # Test if Explorer process is running
        $ExplorerProcess = Get-Process "explorer" -ErrorAction SilentlyContinue
        if ($ExplorerProcess) {
            Add-TestResult "Explorer Process" "PASS" "Explorer.exe is running (PID: $($ExplorerProcess.Id))"
        } else {
            Add-TestResult "Explorer Process" "FAIL" "Explorer.exe is not running" "Restart Explorer or reboot system"
            return $false
        }
        
        # Test desktop functionality
        $DesktopPath = [Environment]::GetFolderPath("Desktop")
        if (Test-Path $DesktopPath) {
            Add-TestResult "Desktop Access" "PASS" "Desktop folder accessible at $DesktopPath"
        } else {
            Add-TestResult "Desktop Access" "FAIL" "Desktop folder not accessible" "Check user profile integrity"
        }
        
        # Test taskbar by checking registry
        $TaskbarKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (Test-Path $TaskbarKey) {
            Add-TestResult "Taskbar Registry" "PASS" "Taskbar registry keys accessible"
        } else {
            Add-TestResult "Taskbar Registry" "FAIL" "Taskbar registry keys missing" "Run repair_shell.ps1 again"
        }
        
        # Test Start Menu
        $StartMenuPath = [Environment]::GetFolderPath("StartMenu")
        if (Test-Path $StartMenuPath) {
            Add-TestResult "Start Menu" "PASS" "Start Menu folder accessible"
        } else {
            Add-TestResult "Start Menu" "FAIL" "Start Menu folder not accessible" "Check user profile integrity"
        }
        
        return $true
        
    } catch {
        Add-TestResult "Explorer Shell Test" "FAIL" "Error testing Explorer: $($_.Exception.Message)" "Run repair_shell.ps1"
        return $false
    }
}

function Test-SystemFileIntegrity {
    Write-LogMessage "Validating system file integrity post-repair..."
    
    try {
        # Check if SFC scan was run recently by looking for CBS logs
        $CBSLog = "C:\Windows\Logs\CBS\CBS.log"
        if (Test-Path $CBSLog) {
            $LogModified = (Get-Item $CBSLog).LastWriteTime
            $HoursAgo = ((Get-Date) - $LogModified).TotalHours
            
            if ($HoursAgo -lt 24) {
                Add-TestResult "Recent SFC Scan" "PASS" "SFC scan log updated $([math]::Round($HoursAgo, 1)) hours ago"
            } else {
                Add-TestResult "Recent SFC Scan" "WARNING" "SFC scan log is $([math]::Round($HoursAgo, 1)) hours old" "Consider running 'sfc /scannow'"
            }
        }
        
        # Test critical system files
        $CriticalFiles = @(
            "$env:SystemRoot\System32\kernel32.dll",
            "$env:SystemRoot\System32\ntdll.dll", 
            "$env:SystemRoot\System32\user32.dll",
            "$env:SystemRoot\System32\gdi32.dll",
            "$env:SystemRoot\explorer.exe"
        )
        
        foreach ($File in $CriticalFiles) {
            if (Test-Path $File) {
                $FileInfo = Get-Item $File
                Add-TestResult "Critical System File" "PASS" "$($FileInfo.Name) - Size: $($FileInfo.Length) bytes"
            } else {
                Add-TestResult "Critical System File" "FAIL" "$File is missing" "Run system_integrity.ps1"
            }
        }
        
        return $true
        
    } catch {
        Add-TestResult "System File Integrity" "FAIL" "Error checking system files: $($_.Exception.Message)"
        return $false
    }
}

function Test-MalwareArtifactRemoval {
    Write-LogMessage "Checking for remaining malware artifacts..."
    
    # Known malware locations to check
    $MalwareLocations = @(
        "$env:TEMP\*.tmp",
        "$env:SystemRoot\Temp\*",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\*",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\*"
    )
    
    $SuspiciousFound = $false
    
    foreach ($Location in $MalwareLocations) {
        try {
            $Items = Get-ChildItem $Location -Force -ErrorAction SilentlyContinue | Where-Object { 
                $_.LastWriteTime -gt (Get-Date).AddHours(-48) -and $_.Length -gt 0 
            }
            
            if ($Items) {
                foreach ($Item in $Items) {
                    Add-TestResult "Suspicious File Check" "WARNING" "Recent file found: $($Item.FullName)" "Review file manually"
                    $SuspiciousFound = $true
                }
            }
        } catch {
            Write-LogMessage "Could not check location $Location : $($_.Exception.Message)" "WARNING"
        }
    }
    
    if (-not $SuspiciousFound) {
        Add-TestResult "Malware Artifact Removal" "PASS" "No suspicious recent files found in common malware locations"
    }
    
    # Check for known malware registry keys
    $MalwareRegKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\Backdoor*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\Backdoor*"
    )
    
    foreach ($RegKey in $MalwareRegKeys) {
        try {
            $Keys = Get-ChildItem $RegKey -ErrorAction SilentlyContinue
            if ($Keys) {
                Add-TestResult "Malware Registry Check" "FAIL" "Suspicious registry entries found at $RegKey" "Run emergency_cleanup.ps1 again"
            } else {
                Add-TestResult "Malware Registry Check" "PASS" "No suspicious registry entries found"
            }
        } catch {
            # Expected when keys don't exist
        }
    }
}

function Test-WindowsServices {
    Write-LogMessage "Verifying Windows services are running correctly..."
    
    $CriticalServices = @(
        @{Name="Winmgmt"; DisplayName="Windows Management Instrumentation"},
        @{Name="EventLog"; DisplayName="Windows Event Log"},
        @{Name="Spooler"; DisplayName="Print Spooler"},
        @{Name="BITS"; DisplayName="Background Intelligent Transfer Service"},
        @{Name="Wuauserv"; DisplayName="Windows Update"},
        @{Name="MpsSvc"; DisplayName="Windows Defender Firewall"},
        @{Name="WinDefend"; DisplayName="Windows Defender Antivirus Service"}
    )
    
    foreach ($ServiceInfo in $CriticalServices) {
        try {
            $Service = Get-Service -Name $ServiceInfo.Name -ErrorAction Stop
            if ($Service.Status -eq "Running") {
                Add-TestResult "Windows Service" "PASS" "$($ServiceInfo.DisplayName) is running"
            } else {
                Add-TestResult "Windows Service" "WARNING" "$($ServiceInfo.DisplayName) is $($Service.Status)" "Start service if needed"
            }
        } catch {
            Add-TestResult "Windows Service" "FAIL" "$($ServiceInfo.DisplayName) not found" "Service may be corrupted"
        }
    }
}

function Test-NetworkConnectivity {
    Write-LogMessage "Testing network connectivity and DNS resolution..."
    
    try {
        # Test internet connectivity
        $PingResult = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
        if ($PingResult) {
            Add-TestResult "Internet Connectivity" "PASS" "Successfully connected to Google DNS (8.8.8.8:53)"
        } else {
            Add-TestResult "Internet Connectivity" "FAIL" "Cannot reach internet" "Check network configuration"
        }
        
        # Test DNS resolution
        try {
            $DNSResult = Resolve-DnsName "microsoft.com" -ErrorAction Stop
            if ($DNSResult) {
                Add-TestResult "DNS Resolution" "PASS" "Successfully resolved microsoft.com"
            }
        } catch {
            Add-TestResult "DNS Resolution" "FAIL" "DNS resolution failed" "Check DNS settings"
        }
        
        # Test Azure connectivity
        try {
            $AzureResult = Test-NetConnection -ComputerName "azure.microsoft.com" -Port 443 -InformationLevel Quiet
            if ($AzureResult) {
                Add-TestResult "Azure Connectivity" "PASS" "Successfully connected to Azure services"
            } else {
                Add-TestResult "Azure Connectivity" "WARNING" "Cannot reach Azure services" "Check firewall settings"
            }
        } catch {
            Add-TestResult "Azure Connectivity" "WARNING" "Error testing Azure connectivity: $($_.Exception.Message)"
        }
        
    } catch {
        Add-TestResult "Network Connectivity" "FAIL" "Error testing network: $($_.Exception.Message)"
    }
}

function Test-RegistryIntegrity {
    Write-LogMessage "Validating registry integrity in critical areas..."
    
    $CriticalRegKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion",
        "HKLM:\SYSTEM\CurrentControlSet\Services",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Classes"
    )
    
    foreach ($RegKey in $CriticalRegKeys) {
        try {
            if (Test-Path $RegKey) {
                $SubKeys = Get-ChildItem $RegKey -ErrorAction SilentlyContinue | Measure-Object
                Add-TestResult "Registry Integrity" "PASS" "$RegKey accessible with $($SubKeys.Count) subkeys"
            } else {
                Add-TestResult "Registry Integrity" "FAIL" "$RegKey not accessible" "Registry may be corrupted"
            }
        } catch {
            Add-TestResult "Registry Integrity" "FAIL" "Error accessing $RegKey : $($_.Exception.Message)"
        }
    }
}

function Test-AzureEnvironment {
    Write-LogMessage "Testing Azure AI development environment..."
    
    $AzureEnvPath = "C:\FixMyShit\azure-ai-envsource"
    $McpServerPath = "C:\FixMyShit\azure-ai-mcp-server"
    
    # Test Python environment
    if (Test-Path "$AzureEnvPath\Scripts\python.exe") {
        try {
            $PythonVersion = & "$AzureEnvPath\Scripts\python.exe" --version 2>&1
            Add-TestResult "Azure Python Environment" "PASS" "Python available: $PythonVersion"
        } catch {
            Add-TestResult "Azure Python Environment" "WARNING" "Python executable found but error running: $($_.Exception.Message)"
        }
    } else {
        Add-TestResult "Azure Python Environment" "FAIL" "Python executable not found in Azure environment" "Reinstall Python environment"
    }
    
    # Test MCP Server
    if (Test-Path "$McpServerPath\package.json") {
        Add-TestResult "MCP Server" "PASS" "MCP Server package.json found"
        
        # Test if Node.js can read the package
        try {
            $PackageContent = Get-Content "$McpServerPath\package.json" | ConvertFrom-Json
            Add-TestResult "MCP Server Config" "PASS" "Package name: $($PackageContent.name)"
        } catch {
            Add-TestResult "MCP Server Config" "WARNING" "Package.json exists but may be corrupted"
        }
    } else {
        Add-TestResult "MCP Server" "WARNING" "MCP Server package.json not found" "Check MCP server installation"
    }
    
    # Test development files
    $DevFiles = @("azure.py", "deploy_agent.py")
    foreach ($File in $DevFiles) {
        if (Test-Path "C:\FixMyShit\$File") {
            Add-TestResult "Development File" "PASS" "$File found in project directory"
        } else {
            Add-TestResult "Development File" "WARNING" "$File not found" "File may have been moved or deleted"
        }
    }
}

function Generate-SystemHealthReport {
    if (-not $GenerateReport) {
        return
    }
    
    Write-LogMessage "Generating comprehensive system health report..."
    
    $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Recovery Verification Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .pass { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .test-result { margin: 5px 0; padding: 5px; border-left: 3px solid #ccc; }
        .summary { background-color: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>System Recovery Verification Report</h1>
        <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p>Computer: $env:COMPUTERNAME</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p>Total Tests: $($VerificationResults.Count)</p>
        <p>Passed: $($VerificationResults | Where-Object {$_.Status -eq "PASS"} | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Failed: $($VerificationResults | Where-Object {$_.Status -eq "FAIL"} | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Warnings: $($VerificationResults | Where-Object {$_.Status -eq "WARNING"} | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>
    
    <h2>Test Results</h2>
    <table>
        <tr>
            <th>Test Name</th>
            <th>Status</th>
            <th>Details</th>
            <th>Recommendation</th>
            <th>Timestamp</th>
        </tr>
"@

    foreach ($Result in $VerificationResults) {
        $StatusClass = $Result.Status.ToLower()
        $RecommendationText = if ($Result.Recommendation) { $Result.Recommendation } else { "None" }
        
        $ReportHTML += @"
        <tr>
            <td>$($Result.TestName)</td>
            <td class="$StatusClass">$($Result.Status)</td>
            <td>$($Result.Details)</td>
            <td>$RecommendationText</td>
            <td>$($Result.Timestamp)</td>
        </tr>
"@
    }
    
    $ReportHTML += @"
    </table>
    
    <div class="summary">
        <h2>Recommendations</h2>
        <ul>
"@
    
    $FailedTests = $VerificationResults | Where-Object {$_.Status -eq "FAIL" -and $_.Recommendation}
    foreach ($Failed in $FailedTests) {
        $ReportHTML += "<li><strong>$($Failed.TestName):</strong> $($Failed.Recommendation)</li>"
    }
    
    $ReportHTML += @"
        </ul>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $ReportPath -Value $ReportHTML -Encoding UTF8
    Write-LogMessage "System health report generated: $ReportPath"
}

# Main execution
Write-LogMessage "========== System Recovery Verification Started =========="
Write-LogMessage "Log file: $LogPath"

# Execute all verification tests
Write-Host "`n=== PHASE 1 CLEANUP VERIFICATION ===" -ForegroundColor Cyan
Test-Phase1CleanupSuccess

Write-Host "`n=== EXPLORER SHELL FUNCTIONALITY ===" -ForegroundColor Cyan
Test-ExplorerShellFunctionality

Write-Host "`n=== SYSTEM FILE INTEGRITY ===" -ForegroundColor Cyan
Test-SystemFileIntegrity

Write-Host "`n=== MALWARE ARTIFACT REMOVAL ===" -ForegroundColor Cyan
Test-MalwareArtifactRemoval

Write-Host "`n=== WINDOWS SERVICES ===" -ForegroundColor Cyan
Test-WindowsServices

Write-Host "`n=== NETWORK CONNECTIVITY ===" -ForegroundColor Cyan
Test-NetworkConnectivity

Write-Host "`n=== REGISTRY INTEGRITY ===" -ForegroundColor Cyan
Test-RegistryIntegrity

Write-Host "`n=== AZURE AI ENVIRONMENT ===" -ForegroundColor Cyan
Test-AzureEnvironment

# Generate report if requested
if ($GenerateReport) {
    Write-Host "`n=== GENERATING REPORT ===" -ForegroundColor Cyan
    Generate-SystemHealthReport
}

Write-LogMessage "========== System Recovery Verification Completed =========="

# Display final summary
$PassedTests = $VerificationResults | Where-Object {$_.Status -eq "PASS"} | Measure-Object | Select-Object -ExpandProperty Count
$FailedTests = $VerificationResults | Where-Object {$_.Status -eq "FAIL"} | Measure-Object | Select-Object -ExpandProperty Count
$WarningTests = $VerificationResults | Where-Object {$_.Status -eq "WARNING"} | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "`n=== VERIFICATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests Run: $($VerificationResults.Count)" -ForegroundColor White
Write-Host "Passed: $PassedTests" -ForegroundColor Green
Write-Host "Failed: $FailedTests" -ForegroundColor Red
Write-Host "Warnings: $WarningTests" -ForegroundColor Yellow

if ($FailedTests -eq 0) {
    Write-Host "`n✓ System recovery verification SUCCESSFUL" -ForegroundColor Green
    Write-Host "All critical tests passed. System appears to be fully recovered." -ForegroundColor Green
} else {
    Write-Host "`n⚠ System recovery verification found issues" -ForegroundColor Yellow
    Write-Host "Please review failed tests and follow recommendations." -ForegroundColor Yellow
}

if ($GenerateReport) {
    Write-Host "`nDetailed report available at: $ReportPath" -ForegroundColor Cyan
}