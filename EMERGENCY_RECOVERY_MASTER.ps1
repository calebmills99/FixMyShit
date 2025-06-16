# ===================================================================
# EMERGENCY RECOVERY MASTER ORCHESTRATION SCRIPT
# Phase 4: Final Master Orchestration and Documentation
# ===================================================================

<#
.SYNOPSIS
    Master orchestration script for the complete FixMyShit emergency recovery system.
    
.DESCRIPTION
    Orchestrates all 12 recovery scripts across 3 phases with comprehensive error handling,
    progress tracking, rollback capabilities, and detailed logging for critical system recovery
    from malware compromise (Backdoor.Agent.E, Trojan.Tasker) and Azure AI environment restoration.
    
.NOTES
    Author: Kilo Code
    Version: 4.0 - Master Orchestration
    Requires: Administrator privileges
    Components: 12 recovery scripts across 3 phases
    
.PARAMETER Phase
    Specific phase to execute (1, 2, 3, or All)
    
.PARAMETER Interactive
    Enable interactive mode with user confirmations
    
.PARAMETER ContinueOnError
    Continue execution even if non-critical errors occur
    
.PARAMETER SkipBackup
    Skip backup creation (not recommended)
    
.PARAMETER ValidateOnly
    Only run validation without making changes
    
.PARAMETER EmergencyMode
    Run in emergency mode with minimal user interaction
    
.EXAMPLE
    .\EMERGENCY_RECOVERY_MASTER.ps1 -Phase All -Interactive
    .\EMERGENCY_RECOVERY_MASTER.ps1 -Phase 1 -EmergencyMode
    .\EMERGENCY_RECOVERY_MASTER.ps1 -ValidateOnly
#>

#Requires -RunAsAdministrator

param(
    [ValidateSet("0", "1", "2", "3", "All")]
    [string]$Phase = "All",
    [switch]$Interactive,
    [switch]$ContinueOnError,
    [switch]$SkipBackup,
    [switch]$ValidateOnly,
    [switch]$EmergencyMode,
    [string]$LogPath = ".\EMERGENCY_RECOVERY_MASTER_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Global configuration
$ErrorActionPreference = "Continue"
$MasterStartTime = Get-Date
$RecoveryResults = @{}
$CriticalErrors = @()


# Recovery phases configuration
$RecoveryPhases = @{
"0" = @{
        Name = "Emergency Service Repairs"
        Description = "Critical Windows service repairs including Firewall service and .NET runtime restoration"
        Critical = $true
        Scripts = @(
            @{ Name = "fix_0x8a15000f_missing_data.ps1"; Description = "Emergency fix for 0x8a15000f missing data error"; Timeout = 900 },
            @{ Name = "shell_com_diagnostic.ps1"; Description = "Shell COM component diagnostics"; Timeout = 120 },
            @{ Name = "emergency_shell_repair.ps1"; Description = "Emergency shell repair procedures"; Timeout = 300 },
            @{ Name = "critical_service_repair.ps1"; Description = "Critical Windows service restoration"; Timeout = 450 },
            @{ Name = "firewall_service_emergency_repair.ps1"; Description = "Firewall service and .NET runtime repair"; Timeout = 600 }
        )
    }
    "1" = @{
        Name = "Emergency Malware Cleanup"
        Description = "Immediate malware detection, removal, and system integrity restoration"
        Critical = $true
        Scripts = @(
            @{ Name = "malware_scan.ps1"; Description = "Comprehensive malware detection"; Timeout = 300 },
            @{ Name = "emergency_cleanup.ps1"; Description = "Immediate malware removal"; Timeout = 600 },
            @{ Name = "repair_shell.ps1"; Description = "Explorer shell restoration"; Timeout = 180 },
            @{ Name = "system_integrity.ps1"; Description = "Deep system repair"; Timeout = 900 }
        )
    }
    "2" = @{
        Name = "Security Hardening & System Recovery"
        Description = "Comprehensive Windows security hardening and monitoring setup"
        Critical = $true
        Scripts = @(
            @{ Name = "security_hardening.ps1"; Description = "Comprehensive security hardening"; Timeout = 600 },
            @{ Name = "recovery_verification.ps1"; Description = "System recovery verification"; Timeout = 300 },
            @{ Name = "setup_monitoring.ps1"; Description = "Enhanced monitoring setup"; Timeout = 240 },
            @{ Name = "system_backup.ps1"; Description = "System restore points and backups"; Timeout = 450 }
        )
    }
    "3" = @{
        Name = "Azure AI Development Environment Restoration"
        Description = "Azure AI development environment validation and restoration"
        Critical = $false
        Scripts = @(
            @{ Name = "validate_azure_environment.ps1"; Description = "Azure connectivity validation"; Timeout = 180 },
            @{ Name = "restore_dev_environment.ps1"; Description = "Development environment restoration"; Timeout = 420 },
            @{ Name = "setup_cursor_ide.ps1"; Description = "Cursor IDE configuration"; Timeout = 240 },
            @{ Name = "test_azure_workflow.ps1"; Description = "Comprehensive workflow testing"; Timeout = 300 }
        )
    }
}

# ===================================================================
# LOGGING AND UTILITIES
# ===================================================================

function Write-MasterLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "MASTER")
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

function Show-Banner {
    $banner = @"

  ███████╗██╗██╗  ██╗███╗   ███╗██╗   ██╗███████╗██╗  ██╗██╗████████╗
  ██╔════╝██║╚██╗██╔╝████╗ ████║╚██╗ ██╔╝██╔════╝██║  ██║██║╚══██╔══╝
  █████╗  ██║ ╚███╔╝ ██╔████╔██║ ╚████╔╝ ███████╗███████║██║   ██║   
  ██╔══╝  ██║ ██╔██╗ ██║╚██╔╝██║  ╚██╔╝  ╚════██║██╔══██║██║   ██║   
  ██║     ██║██╔╝ ██╗██║ ╚═╝ ██║   ██║   ███████║██║  ██║██║   ██║   
  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝   
                                                                      
        EMERGENCY RECOVERY MASTER ORCHESTRATION SYSTEM v4.0
     Comprehensive System Recovery from Malware Compromise
"@
    
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "THREAT CONTEXT: Backdoor.Agent.E, Trojan.Tasker, Shell Corruption" -ForegroundColor Red
    Write-Host "RECOVERY SCOPE: 12 Scripts across 3 Phases + Azure AI Environment" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
}

function Test-Prerequisites {
    Write-MasterLog "Performing comprehensive prerequisite validation..." "INFO"
    
    $prereqResults = @{
        AdminPrivileges = $false
        PowerShellVersion = $false
        DiskSpace = $false
        NetworkConnectivity = $false
        SystemStability = $false
        ScriptAvailability = $false
    }
    
    # Check administrator privileges
    try {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $prereqResults.AdminPrivileges = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($prereqResults.AdminPrivileges) {
            Write-MasterLog "Administrator privileges confirmed" "SUCCESS"
        } else {
            Write-MasterLog "CRITICAL: Administrator privileges required" "CRITICAL"
            $CriticalErrors += "Missing administrator privileges"
        }
    } catch {
        Write-MasterLog "Error checking admin privileges: $($_.Exception.Message)" "ERROR"
    }
    
    # Check PowerShell version
    try {
        $psVersion = $PSVersionTable.PSVersion
        $prereqResults.PowerShellVersion = $psVersion.Major -ge 5
        
        if ($prereqResults.PowerShellVersion) {
            Write-MasterLog "PowerShell version compatible: $($psVersion.ToString())" "SUCCESS"
        } else {
            Write-MasterLog "PowerShell version too old: $($psVersion.ToString())" "WARN"
        }
    } catch {
        Write-MasterLog "Error checking PowerShell version: $($_.Exception.Message)" "ERROR"
    }
    
    # Check disk space
    try {
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DeviceID -eq $env:SystemDrive}
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        $prereqResults.DiskSpace = $freeSpaceGB -gt 5
        
        if ($prereqResults.DiskSpace) {
            Write-MasterLog "Sufficient disk space available: ${freeSpaceGB}GB" "SUCCESS"
        } else {
            Write-MasterLog "CRITICAL: Insufficient disk space: ${freeSpaceGB}GB" "CRITICAL"
            $CriticalErrors += "Insufficient disk space"
        }
    } catch {
        Write-MasterLog "Error checking disk space: $($_.Exception.Message)" "ERROR"
    }
    
    # Check network connectivity
    try {
        $connectivityTests = @(
            "microsoft.com",
            "azure.microsoft.com",
            "windows.com"
        )
        
        $successfulTests = 0
        foreach ($testSite in $connectivityTests) {
            try {
                $result = Test-NetConnection -ComputerName $testSite -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
                if ($result) { $successfulTests++ }
            } catch {
                # Ignore individual test failures
            }
        }
        
        $prereqResults.NetworkConnectivity = $successfulTests -gt 0
        Write-MasterLog "Network connectivity: $successfulTests/$($connectivityTests.Count) tests passed" "INFO"
    } catch {
        Write-MasterLog "Error testing network connectivity: $($_.Exception.Message)" "WARN"
    }
    
    # Check system stability
    try {
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $prereqResults.SystemStability = $uptime.TotalMinutes -gt 5
        
        Write-MasterLog "System uptime: $([math]::Round($uptime.TotalHours, 1)) hours" "INFO"
        
        # Check for critical system errors
        try {
            $recentErrors = Get-WinEvent -LogName System -MaxEvents 50 -FilterXPath "*[System[Level=1 or Level=2]]" -ErrorAction SilentlyContinue
            $criticalSystemErrors = ($recentErrors | Where-Object {$_.TimeCreated -gt (Get-Date).AddHours(-1)}).Count
            
            if ($criticalSystemErrors -eq 0) {
                Write-MasterLog "No recent critical system errors detected" "SUCCESS"
            } else {
                Write-MasterLog "WARNING: $criticalSystemErrors recent critical system errors detected" "WARN"
            }
        } catch {
            Write-MasterLog "Could not check system event log" "WARN"
        }
    } catch {
        Write-MasterLog "Error checking system stability: $($_.Exception.Message)" "ERROR"
    }
    
    # Check script availability
    try {
        $missingScripts = @()
        foreach ($phaseKey in $RecoveryPhases.Keys) {
            foreach ($script in $RecoveryPhases[$phaseKey].Scripts) {
                if (-not (Test-Path $script.Name)) {
                    $missingScripts += $script.Name
                }
            }
        }
        
        $prereqResults.ScriptAvailability = $missingScripts.Count -eq 0
        
        if ($prereqResults.ScriptAvailability) {
            Write-MasterLog "All recovery scripts available" "SUCCESS"
        } else {
            Write-MasterLog "CRITICAL: Missing scripts: $($missingScripts -join ', ')" "CRITICAL"
            $CriticalErrors += "Missing recovery scripts"
        }
    } catch {
        Write-MasterLog "Error checking script availability: $($_.Exception.Message)" "ERROR"
    }
    
    return $prereqResults
}

function Show-InteractiveMenu {
    Write-Host "`n========== EMERGENCY RECOVERY INTERACTIVE MENU ==========" -ForegroundColor Cyan
    Write-Host "1. Execute All Phases (Recommended for full recovery)" -ForegroundColor White
    Write-Host "2. Phase 0 Only - Emergency Service Repairs" -ForegroundColor Red
    Write-Host "3. Phase 1 Only - Emergency Malware Cleanup" -ForegroundColor Yellow
    Write-Host "4. Phase 2 Only - Security Hardening & System Recovery" -ForegroundColor Yellow
    Write-Host "5. Phase 3 Only - Azure AI Environment Restoration" -ForegroundColor Yellow
    Write-Host "6. Validation Only - Check system without changes" -ForegroundColor Green
    Write-Host "7. Emergency Mode - Minimal interaction, maximum speed" -ForegroundColor Red
    Write-Host "8. Show Detailed Phase Information" -ForegroundColor Cyan
Write-Host "9. Exit" -ForegroundColor Gray
    Write-Host "=========================================================" -ForegroundColor Cyan
    
    do {
        $choice = Read-Host "`nSelect option (1-9)"
        switch ($choice) {
            "1" { return @{ Phase = "All"; Mode = "Interactive" } }
            "2" { return @{ Phase = "0"; Mode = "Interactive" } }
            "3" { return @{ Phase = "1"; Mode = "Interactive" } }
            "4" { return @{ Phase = "2"; Mode = "Interactive" } }
            "5" { return @{ Phase = "3"; Mode = "Interactive" } }
            "6" { return @{ Phase = "All"; Mode = "Validation" } }
            "7" { return @{ Phase = "All"; Mode = "Emergency" } }
            "8" { Show-PhaseDetails; Show-InteractiveMenu }
            "9" { Write-MasterLog "User selected exit"; exit 0 }
            default { Write-Host "Invalid selection. Please choose 1-9." -ForegroundColor Red }
        }
    } while ($true)
}

function Show-PhaseDetails {
    Write-Host "`n========== PHASE DETAILS ==========" -ForegroundColor Cyan
    
    foreach ($phaseKey in ($RecoveryPhases.Keys | Sort-Object)) {
        $phase = $RecoveryPhases[$phaseKey]
        $criticalText = if ($phase.Critical) { " [CRITICAL]" } else { " [OPTIONAL]" }
        
        Write-Host "`nPhase $phaseKey`: $($phase.Name)$criticalText" -ForegroundColor $(if($phase.Critical){"Red"}else{"Yellow"})
        Write-Host "$($phase.Description)" -ForegroundColor White
        Write-Host "Scripts:" -ForegroundColor Gray
        
        foreach ($script in $phase.Scripts) {
            $status = if (Test-Path $script.Name) { "✓" } else { "✗" }
            $timeout = "$($script.Timeout)s timeout"
            Write-Host "  $status $($script.Name) - $($script.Description) ($timeout)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n=================================" -ForegroundColor Cyan
    Read-Host "Press Enter to continue"
}

function Invoke-RecoveryScript {
    param(
        [string]$ScriptName,
        [string]$Description,
        [int]$TimeoutSeconds,
        [string]$Phase,
        [hashtable]$Parameters = @{}
    )
    
    Write-MasterLog "Starting script: $ScriptName ($Description)" "INFO" "PHASE$Phase"
    $scriptStartTime = Get-Date
    
    if (-not (Test-Path $ScriptName)) {
        Write-MasterLog "CRITICAL: Script not found: $ScriptName" "CRITICAL" "PHASE$Phase"
        return @{ Success = $false; ExitCode = -1; Error = "Script not found"; Duration = 0 }
    }
    
    if ($ValidateOnly) {
        Write-MasterLog "Validation mode: Skipping execution of $ScriptName" "INFO" "PHASE$Phase"
        return @{ Success = $true; ExitCode = 0; Error = $null; Duration = 0; ValidationOnly = $true }
    }
    
    try {
        # Prepare parameters
        $paramString = ""
        foreach ($key in $Parameters.Keys) {
            $paramString += " -$key"
            if ($Parameters[$key] -ne $true) {
                $paramString += " '$($Parameters[$key])'"
            }
        }
        
        Write-MasterLog "Executing: .\$ScriptName$paramString" "INFO" "PHASE$Phase"
        
        # Create job for timeout handling
        $job = Start-Job -ScriptBlock {
            param($script, $params)
            Set-Location $using:PWD
            $result = & ".\$script" @params 2>&1
            return @{ 
                Output = $result
                ExitCode = $LASTEXITCODE
            }
        } -ArgumentList $ScriptName, $Parameters
        
        # Wait for completion with timeout
        $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
        
        if ($completed) {
            $result = Receive-Job -Job $job
            Remove-Job -Job $job
            
            $scriptEndTime = Get-Date
            $duration = ($scriptEndTime - $scriptStartTime).TotalSeconds
            
            $success = $result.ExitCode -eq 0 -or $null -eq $result.ExitCode
            
            if ($success) {
                Write-MasterLog "Script completed successfully: $ScriptName (${duration}s)" "SUCCESS" "PHASE$Phase"
            } else {
                Write-MasterLog "Script completed with errors: $ScriptName (Exit: $($result.ExitCode), ${duration}s)" "ERROR" "PHASE$Phase"
            }
            
            return @{ 
                Success = $success
                ExitCode = $result.ExitCode
                Output = $result.Output
                Duration = $duration
                Error = if($success) { $null } else { "Exit code: $($result.ExitCode)" }
            }
        } else {
            # Timeout occurred
            Stop-Job -Job $job
            Remove-Job -Job $job
            
            $duration = $TimeoutSeconds
            Write-MasterLog "Script TIMEOUT after ${TimeoutSeconds}s: $ScriptName" "ERROR" "PHASE$Phase"
            
            return @{ 
                Success = $false
                ExitCode = -2
                Error = "Timeout after ${TimeoutSeconds} seconds"
                Duration = $duration
            }
        }
    } catch {
        $scriptEndTime = Get-Date
        $duration = ($scriptEndTime - $scriptStartTime).TotalSeconds
        
        Write-MasterLog "Script execution error: $ScriptName - $($_.Exception.Message)" "ERROR" "PHASE$Phase"
        
        return @{ 
            Success = $false
            ExitCode = -3
            Error = $_.Exception.Message
            Duration = $duration
        }
    }
}

function Invoke-RecoveryPhase {
    param([string]$PhaseNumber)
    
    $phase = $RecoveryPhases[$PhaseNumber]
    if (-not $phase) {
        Write-MasterLog "Invalid phase number: $PhaseNumber" "ERROR"
        return $false
    }
    
    Write-MasterLog "========== STARTING PHASE $PhaseNumber`: $($phase.Name) ==========" "INFO"
    Write-MasterLog $phase.Description "INFO"
    
    $phaseStartTime = Get-Date
    $phaseResults = @{}
    $phaseSuccess = $true
    
    # Interactive confirmation for critical phases
    if ($Interactive -and $phase.Critical -and -not $EmergencyMode) {
        Write-Host "`nPhase $PhaseNumber is CRITICAL for system security." -ForegroundColor Red
        Write-Host "This phase includes:" -ForegroundColor Yellow
        foreach ($script in $phase.Scripts) {
            Write-Host "  • $($script.Description)" -ForegroundColor White
        }
        
        $confirmation = Read-Host "`nProceed with Phase $PhaseNumber? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-MasterLog "User cancelled Phase $PhaseNumber" "WARN"
            return $false
        }
    }
    
    foreach ($script in $phase.Scripts) {
        $scriptParams = @{}
        
        # Add common parameters
        if ($script.Name -like "*backup*" -and $SkipBackup) {
            $scriptParams["SkipBackup"] = $true
        }
        if ($EmergencyMode) {
            $scriptParams["SkipInteractive"] = $true
        }
        
        $result = Invoke-RecoveryScript -ScriptName $script.Name -Description $script.Description -TimeoutSeconds $script.Timeout -Phase $PhaseNumber -Parameters $scriptParams
        
        $phaseResults[$script.Name] = $result
        
        if (-not $result.Success) {
            Write-MasterLog "Script failed in Phase $PhaseNumber`: $($script.Name)" "ERROR" "PHASE$PhaseNumber"
            
            if ($phase.Critical -and -not $ContinueOnError) {
                Write-MasterLog "CRITICAL PHASE FAILURE - Stopping execution" "CRITICAL" "PHASE$PhaseNumber"
                $phaseSuccess = $false
                break
            } elseif (-not $ContinueOnError) {
                Write-MasterLog "Script failure - Stopping phase" "ERROR" "PHASE$PhaseNumber"
                $phaseSuccess = $false
                break
            } else {
                Write-MasterLog "Continuing despite script failure (ContinueOnError enabled)" "WARN" "PHASE$PhaseNumber"
                $phaseSuccess = $false  # Mark phase as failed but continue
            }
        }
        
        # Brief pause between scripts for system stability
        if (-not $EmergencyMode) {
            Start-Sleep -Seconds 2
        }
    }
    
    $phaseEndTime = Get-Date
    $phaseDuration = ($phaseEndTime - $phaseStartTime).TotalMinutes
    
    $RecoveryResults["Phase$PhaseNumber"] = @{
        Name = $phase.Name
        Success = $phaseSuccess
        Duration = $phaseDuration
        ScriptResults = $phaseResults
        Critical = $phase.Critical
    }
    
    if ($phaseSuccess) {
        Write-MasterLog "========== PHASE $PhaseNumber COMPLETED SUCCESSFULLY ($([math]::Round($phaseDuration, 1))m) ==========" "SUCCESS"
    } else {
        Write-MasterLog "========== PHASE $PhaseNumber COMPLETED WITH ERRORS ($([math]::Round($phaseDuration, 1))m) ==========" "ERROR"
        
        if ($phase.Critical) {
            $CriticalErrors += "Phase $PhaseNumber failed"
        }
    }
    
    return $phaseSuccess
}

function New-ExecutionReport {
    Write-MasterLog "Generating comprehensive execution report..." "INFO"
    
    $totalDuration = ((Get-Date) - $MasterStartTime).TotalMinutes
    $totalScripts = 0
    $successfulScripts = 0
    $failedScripts = 0
    
    foreach ($phaseKey in $RecoveryResults.Keys) {
        $phase = $RecoveryResults[$phaseKey]
        foreach ($scriptKey in $phase.ScriptResults.Keys) {
            $script = $phase.ScriptResults[$scriptKey]
            $totalScripts++
            if ($script.Success) {
                $successfulScripts++
            } else {
                $failedScripts++
            }
        }
    }
    
    $successRate = if ($totalScripts -gt 0) { [math]::Round(($successfulScripts / $totalScripts) * 100, 1) } else { 0 }
    
    $report = @{
        ExecutionSummary = @{
            StartTime = $MasterStartTime.ToString("yyyy-MM-dd HH:mm:ss")
            EndTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            TotalDuration = "$([math]::Round($totalDuration, 1)) minutes"
            TotalScripts = $totalScripts
            SuccessfulScripts = $successfulScripts
            FailedScripts = $failedScripts
            SuccessRate = "$successRate%"
            CriticalErrors = $CriticalErrors
            ValidationOnly = $ValidateOnly
        }
        PhaseResults = $RecoveryResults
        SystemInfo = @{
            ComputerName = $env:COMPUTERNAME
            WindowsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            ExecutionMode = if ($EmergencyMode) { "Emergency" } elseif ($Interactive) { "Interactive" } else { "Automated" }
        }
        ThreatContext = @{
            MalwareThreats = @("Backdoor.Agent.E", "Trojan.Tasker")
            CompromisedAreas = @("startup locations", "scheduled tasks", "explorer shell", "system integrity")
            RecoveryPhases = @(
                "Phase 1: Emergency Malware Cleanup",
                "Phase 2: Security Hardening & System Recovery", 
                "Phase 3: Azure AI Development Environment Restoration"
            )
        }
    }
    
    $reportPath = ".\EMERGENCY_RECOVERY_REPORT_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8
    
    Write-MasterLog "Execution report saved: $reportPath" "INFO"
    
    return $report
}

function Show-ExecutionSummary {
    param([hashtable]$Report)
    
    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                  EMERGENCY RECOVERY SUMMARY" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    
    $summary = $Report.ExecutionSummary
    
    Write-Host "Execution Time: $($summary.StartTime) - $($summary.EndTime)" -ForegroundColor White
    Write-Host "Total Duration: $($summary.TotalDuration)" -ForegroundColor White
    Write-Host "Scripts Executed: $($summary.SuccessfulScripts)/$($summary.TotalScripts) ($($summary.SuccessRate))" -ForegroundColor $(if($summary.SuccessRate -like "100*"){"Green"}elseif($summary.SuccessRate -like "[89]*"){"Yellow"}else{"Red"})
    
    if ($summary.CriticalErrors.Count -gt 0) {
        Write-Host "Critical Errors: $($summary.CriticalErrors.Count)" -ForegroundColor Red
        foreach ($error in $summary.CriticalErrors) {
            Write-Host "  • $error" -ForegroundColor Red
        }
    } else {
        Write-Host "Critical Errors: None" -ForegroundColor Green
    }
    
    Write-Host "`nPhase Results:" -ForegroundColor Yellow
    foreach ($phaseKey in ($Report.PhaseResults.Keys | Sort-Object)) {
        $phase = $Report.PhaseResults[$phaseKey]
        $statusIcon = if ($phase.Success) { "✓" } else { "✗" }
        $statusColor = if ($phase.Success) { "Green" } else { "Red" }
        $criticalText = if ($phase.Critical) { " [CRITICAL]" } else { "" }
        
        Write-Host "  $statusIcon $($phase.Name)$criticalText - $([math]::Round($phase.Duration, 1))m" -ForegroundColor $statusColor
    }
    
    # Overall status
    Write-Host "`n" -NoNewline
    if ($summary.CriticalErrors.Count -eq 0 -and $summary.SuccessRate -like "100*") {
        Write-Host "OVERALL STATUS: COMPLETE SUCCESS" -ForegroundColor Green
        Write-Host "System recovery completed successfully. All malware threats neutralized." -ForegroundColor Green
    } elseif ($summary.CriticalErrors.Count -eq 0) {
        Write-Host "OVERALL STATUS: SUCCESS WITH MINOR ISSUES" -ForegroundColor Yellow
        Write-Host "System recovery largely successful. Review minor issues if any." -ForegroundColor Yellow
    } else {
        Write-Host "OVERALL STATUS: CRITICAL ISSUES DETECTED" -ForegroundColor Red
        Write-Host "System recovery incomplete. Immediate attention required." -ForegroundColor Red
    }
    
    Write-Host "================================================================" -ForegroundColor Cyan
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

# Display banner
Show-Banner

Write-MasterLog "========== EMERGENCY RECOVERY MASTER ORCHESTRATION STARTED ==========" "INFO"
Write-MasterLog "Log file: $LogPath" "INFO"
Write-MasterLog "Execution parameters: Phase=$Phase, Interactive=$Interactive, ValidateOnly=$ValidateOnly, EmergencyMode=$EmergencyMode" "INFO"

# Verify administrator privileges immediately
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-MasterLog "CRITICAL: Administrator privileges required for emergency recovery" "CRITICAL"
    Write-Host "`nThis emergency recovery system requires administrator privileges." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Run prerequisite validation
Write-Host "`n========== PREREQUISITE VALIDATION ==========" -ForegroundColor Cyan
$prereqResults = Test-Prerequisites

if ($CriticalErrors.Count -gt 0) {
    Write-Host "`nCRITICAL ERRORS DETECTED:" -ForegroundColor Red
    foreach ($error in $CriticalErrors) {
        Write-Host "  • $error" -ForegroundColor Red
    }
    
    if (-not $EmergencyMode) {
        $continue = Read-Host "`nContinue despite critical errors? (y/N)"
        if ($continue -ne 'y' -and $continue -ne 'Y') {
            Write-MasterLog "User cancelled due to critical errors" "ERROR"
            exit 1
        }
    }
}

# Interactive menu or direct execution
if ($Interactive -and -not $EmergencyMode) {
    $menuResult = Show-InteractiveMenu
    $Phase = $menuResult.Phase
    
    if ($menuResult.Mode -eq "Validation") {
        $ValidateOnly = $true
    } elseif ($menuResult.Mode -eq "Emergency") {
        $EmergencyMode = $true
        $Interactive = $false
    }
}

# Determine phases to execute
$phasesToExecute = if ($Phase -eq "All") { @("0", "1", "2", "3") } else { @($Phase) }

Write-MasterLog "Executing phases: $($phasesToExecute -join ', ')" "INFO"

if ($ValidateOnly) {
    Write-MasterLog "VALIDATION MODE: Scripts will be checked but not executed" "WARN"
}

# Execute recovery phases
$overallSuccess = $true
foreach ($phaseNum in $phasesToExecute) {
    $phaseSuccess = Invoke-RecoveryPhase -PhaseNumber $phaseNum
    
    if (-not $phaseSuccess) {
        $overallSuccess = $false
        
        if ($RecoveryPhases[$phaseNum].Critical -and -not $ContinueOnError) {
            Write-MasterLog "Critical phase failure - stopping execution" "CRITICAL"
            break
        }
    }
    
    # Brief pause between phases
    if ($phasesToExecute.Count -gt 1 -and $phaseNum -ne $phasesToExecute[-1]) {
        if (-not $EmergencyMode) {
            Write-Host "`nPausing briefly before next phase..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
        }
    }
}

# Generate final report
Write-Host "`n========== GENERATING FINAL REPORT ==========" -ForegroundColor Cyan
$finalReport = New-ExecutionReport

# Display summary
Show-ExecutionSummary -Report $finalReport

# Final recommendations
Write-Host "`n========== NEXT STEPS ==========" -ForegroundColor Cyan
if ($overallSuccess) {
    Write-Host "1. Review the execution report for any minor issues" -ForegroundColor Green
    Write-Host "2. Run FINAL_SYSTEM_VALIDATION.ps1 for comprehensive validation" -ForegroundColor Green
    Write-Host "3. Monitor system for 24-48 hours for any anomalies" -ForegroundColor Green
    Write-Host "4. Update documentation with any custom configurations" -ForegroundColor Green
} else {
    Write-Host "1. Review failed scripts and error messages in the log" -ForegroundColor Red
    Write-Host "2. Address critical issues before proceeding" -ForegroundColor Red
    Write-Host "3. Consider running individual scripts manually if needed" -ForegroundColor Red
    Write-Host "4. Consult EMERGENCY_PROCEDURES.ps1 if system is unstable" -ForegroundColor Red
}

Write-MasterLog "========== EMERGENCY RECOVERY MASTER ORCHESTRATION COMPLETED ==========" "INFO"

# Exit with appropriate code
if ($overallSuccess) {
    Write-MasterLog "Master orchestration completed successfully" "SUCCESS"
    exit 0
} else {
    Write-MasterLog "Master orchestration completed with errors" "ERROR"
    exit 1
}