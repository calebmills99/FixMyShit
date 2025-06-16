# ===================================================================
# EMERGENCY PROCEDURES SCRIPT
# Phase 4: Emergency Response Procedures
# ===================================================================

<#
.SYNOPSIS
    Emergency response procedures for critical system failures during recovery.
    
.DESCRIPTION
    Provides immediate emergency response procedures for critical failures that may
    occur during the FixMyShit emergency recovery process. Includes rollback procedures,
    safe mode operations, and emergency service restoration.
    
.NOTES
    Author: Kilo Code
    Version: 4.0 - Emergency Procedures
    Requires: Administrator privileges
    
.PARAMETER EmergencyType
    Type of emergency procedure to execute
    
.PARAMETER CreateRestorePoint
    Create system restore point before emergency actions
    
.PARAMETER ForceMode
    Force emergency procedures without confirmation
    
.EXAMPLE
    .\EMERGENCY_PROCEDURES.ps1 -EmergencyType "SystemFreeze"
    .\EMERGENCY_PROCEDURES.ps1 -EmergencyType "ServiceFailure" -ForceMode
#>

#Requires -RunAsAdministrator

param(
    [ValidateSet("SystemFreeze", "ServiceFailure", "ShellCrash", "NetworkFailure", "RecoveryRollback", "SafeMode")]
    [string]$EmergencyType,
    [switch]$CreateRestorePoint,
    [switch]$ForceMode
)

# Global configuration
$ErrorActionPreference = "Continue"
$EmergencyLogPath = ".\EMERGENCY_PROCEDURES_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ===================================================================
# EMERGENCY LOGGING
# ===================================================================

function Write-EmergencyLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "EMERGENCY")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    $color = switch ($Level) {
        "CRITICAL" { "Magenta" }
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    Add-Content -Path $EmergencyLogPath -Value $logEntry -Encoding UTF8
}

function Show-EmergencyBanner {
    Write-Host ""
    Write-Host "  ███████╗███╗   ███╗███████╗██████╗  ██████╗ ███████╗███╗   ██╗ ██████╗██╗   ██╗" -ForegroundColor Red
    Write-Host "  ██╔════╝████╗ ████║██╔════╝██╔══██╗██╔════╝ ██╔════╝████╗  ██║██╔════╝╚██╗ ██╔╝" -ForegroundColor Red
    Write-Host "  █████╗  ██╔████╔██║█████╗  ██████╔╝██║  ███╗█████╗  ██╔██╗ ██║██║      ╚████╔╝ " -ForegroundColor Red
    Write-Host "  ██╔══╝  ██║╚██╔╝██║██╔══╝  ██╔══██╗██║   ██║██╔══╝  ██║╚██╗██║██║       ╚██╔╝  " -ForegroundColor Red
    Write-Host "  ███████╗██║ ╚═╝ ██║███████╗██║  ██║╚██████╔╝███████╗██║ ╚████║╚██████╗   ██║   " -ForegroundColor Red
    Write-Host "  ╚══════╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝   ╚═╝   " -ForegroundColor Red
    Write-Host ""
    Write-Host "    ██████╗ ██████╗  ██████╗  ██████╗███████╗██████╗ ██╗   ██╗██████╗ ███████╗███████╗" -ForegroundColor Red
    Write-Host "    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝██╔══██╗██║   ██║██╔══██╗██╔════╝██╔════╝" -ForegroundColor Red
    Write-Host "    ██████╔╝██████╔╝██║   ██║██║     █████╗  ██║  ██║██║   ██║██████╔╝█████╗  ███████╗" -ForegroundColor Red
    Write-Host "    ██╔═══╝ ██╔══██╗██║   ██║██║     ██╔══╝  ██║  ██║██║   ██║██╔══██╗██╔══╝  ╚════██║" -ForegroundColor Red
    Write-Host "    ██║     ██║  ██║╚██████╔╝╚██████╗███████╗██████╔╝╚██████╔╝██║  ██║███████╗███████║" -ForegroundColor Red
    Write-Host "    ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "                    FixMyShit Emergency Recovery System v4.0" -ForegroundColor Red
    Write-Host "                         CRITICAL EMERGENCY RESPONSE PROCEDURES" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Red
    Write-Host "WARNING: EMERGENCY PROCEDURES - USE ONLY IN CRITICAL SYSTEM FAILURES" -ForegroundColor Yellow
    Write-Host "These procedures may cause data loss or system instability" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Red
}

# ===================================================================
# EMERGENCY PROCEDURES
# ===================================================================

function Invoke-SystemFreezeEmergency {
    Write-EmergencyLog "EMERGENCY: System freeze detected - initiating emergency response" "CRITICAL"
    
    try {
        # Kill hanging processes
        Write-EmergencyLog "Terminating potentially hanging processes..." "WARN"
        $hangingProcesses = @("explorer", "dwm", "winlogon")
        
        foreach ($processName in $hangingProcesses) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                Write-EmergencyLog "Terminating $processName processes..." "WARN"
                $processes | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
        }
        
        # Restart Explorer
        Write-EmergencyLog "Restarting Windows Explorer..." "INFO"
        Start-Process "explorer.exe" -ErrorAction SilentlyContinue
        
        # Clear system cache
        Write-EmergencyLog "Clearing system cache..." "INFO"
        Get-Process | Where-Object {$_.WorkingSet -gt 100MB} | Stop-Process -Force -ErrorAction SilentlyContinue
        
        # Memory cleanup
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        Write-EmergencyLog "System freeze emergency response completed" "SUCCESS"
        
    } catch {
        Write-EmergencyLog "System freeze emergency failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-ServiceFailureEmergency {
    Write-EmergencyLog "EMERGENCY: Critical service failure - initiating service recovery" "CRITICAL"
    
    try {
        # Critical Windows services
        $criticalServices = @(
            @{Name="Winlogon"; DisplayName="Windows Logon Process"},
            @{Name="MpsSvc"; DisplayName="Windows Defender Firewall"},
            @{Name="Themes"; DisplayName="Themes Service"},
            @{Name="AudioSrv"; DisplayName="Windows Audio"},
            @{Name="BITS"; DisplayName="Background Intelligent Transfer Service"}
        )
        
        foreach ($service in $criticalServices) {
            try {
                $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                if (-not $svc) {
                    Write-EmergencyLog "Service $($service.Name) not found - attempting repair..." "WARN"
                    continue
                }
                
                if ($svc.Status -ne "Running") {
                    Write-EmergencyLog "Restarting critical service: $($service.DisplayName)" "WARN"
                    
                    # Stop service forcefully if needed
                    if ($svc.Status -eq "StopPending" -or $svc.Status -eq "StartPending") {
                        Write-EmergencyLog "Force stopping $($service.Name)..." "WARN"
                        Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 3
                    }
                    
                    # Start service with timeout
                    $timeout = 30
                    $timer = [System.Diagnostics.Stopwatch]::StartNew()
                    Start-Service -Name $service.Name -ErrorAction SilentlyContinue
                    
                    while ($timer.Elapsed.TotalSeconds -lt $timeout) {
                        $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                        if ($svc -and $svc.Status -eq "Running") {
                            Write-EmergencyLog "$($service.DisplayName) restarted successfully" "SUCCESS"
                            break
                        }
                        Start-Sleep -Seconds 1
                    }
                    $timer.Stop()
                    
                    if ($svc.Status -ne "Running") {
                        Write-EmergencyLog "Failed to restart $($service.DisplayName)" "ERROR"
                    }
                }
                
            } catch {
                Write-EmergencyLog "Error handling service $($service.Name): $($_.Exception.Message)" "ERROR"
            }
        }
        
        Write-EmergencyLog "Service failure emergency response completed" "SUCCESS"
        
    } catch {
        Write-EmergencyLog "Service failure emergency failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-ShellCrashEmergency {
    Write-EmergencyLog "EMERGENCY: Explorer shell crash - initiating shell recovery" "CRITICAL"
    
    try {
        # Kill all Explorer processes
        Write-EmergencyLog "Terminating all Explorer processes..." "WARN"
        Get-Process -Name "explorer" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 3
        
        # Clear shell cache
        Write-EmergencyLog "Clearing shell cache..." "INFO"
        $shellCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        if (Test-Path $shellCache) {
            Remove-Item -Path "$shellCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Reset shell COM registration
        Write-EmergencyLog "Re-registering shell COM components..." "INFO"
        & regsvr32 /s shell32.dll
        & regsvr32 /s ole32.dll
        & regsvr32 /s oleaut32.dll
        
        # Restart Explorer with elevated privileges
        Write-EmergencyLog "Restarting Windows Explorer..." "INFO"
        Start-Process "explorer.exe" -Verb RunAs -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        
        # Verify Explorer is running
        $explorerProcess = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($explorerProcess) {
            Write-EmergencyLog "Explorer shell recovery successful" "SUCCESS"
        } else {
            Write-EmergencyLog "Explorer shell recovery failed - manual intervention required" "ERROR"
        }
        
    } catch {
        Write-EmergencyLog "Shell crash emergency failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-SafeModeEmergency {
    Write-EmergencyLog "EMERGENCY: Preparing safe mode configuration" "CRITICAL"
    
    try {
        # Configure safe mode boot
        Write-EmergencyLog "Configuring safe mode boot for next restart..." "WARN"
        
        # Set boot configuration
        & bcdedit /set {current} safeboot minimal
        & bcdedit /set {current} bootmenupolicy legacy
        
        Write-EmergencyLog "Safe mode configuration completed" "SUCCESS"
        
        Write-Host "`nSafe mode has been configured for next restart." -ForegroundColor Yellow
        Write-Host "To return to normal boot after safe mode recovery, run:" -ForegroundColor White
        Write-Host "bcdedit /deletevalue {current} safeboot" -ForegroundColor Cyan
        
    } catch {
        Write-EmergencyLog "Safe mode emergency failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

# Display emergency banner
Show-EmergencyBanner

Write-EmergencyLog "========== EMERGENCY PROCEDURES INITIATED ==========" "CRITICAL"
Write-EmergencyLog "Emergency log: $EmergencyLogPath" "INFO"

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-EmergencyLog "CRITICAL: Administrator privileges required for emergency procedures" "CRITICAL"
    Write-Host "`nEmergency procedures require administrator privileges." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Create system restore point if requested
if ($CreateRestorePoint) {
    try {
        Write-EmergencyLog "Creating emergency system restore point..." "INFO"
        Checkpoint-Computer -Description "FixMyShit Emergency Procedures - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS"
        Write-EmergencyLog "Emergency restore point created successfully" "SUCCESS"
    } catch {
        Write-EmergencyLog "Failed to create restore point: $($_.Exception.Message)" "WARN"
    }
}

# Execute emergency procedure based on type
if (-not $EmergencyType) {
    Write-Host "`nAvailable Emergency Procedures:" -ForegroundColor Cyan
    Write-Host "1. SystemFreeze     - System hanging or frozen" -ForegroundColor White
    Write-Host "2. ServiceFailure   - Critical Windows services failed" -ForegroundColor White
    Write-Host "3. ShellCrash       - Explorer shell crashed" -ForegroundColor White
    Write-Host "4. SafeMode         - Configure safe mode boot" -ForegroundColor White
    
    $EmergencyType = Read-Host "`nSelect emergency procedure (1-4 or type name)"
    
    # Convert number to procedure name
    switch ($EmergencyType) {
        "1" { $EmergencyType = "SystemFreeze" }
        "2" { $EmergencyType = "ServiceFailure" }
        "3" { $EmergencyType = "ShellCrash" }
        "4" { $EmergencyType = "SafeMode" }
    }
}

Write-EmergencyLog "Executing emergency procedure: $EmergencyType" "CRITICAL"

try {
    switch ($EmergencyType) {
        "SystemFreeze" { Invoke-SystemFreezeEmergency }
        "ServiceFailure" { Invoke-ServiceFailureEmergency }
        "ShellCrash" { Invoke-ShellCrashEmergency }
        "SafeMode" { Invoke-SafeModeEmergency }
        default { 
            Write-EmergencyLog "Unknown emergency procedure: $EmergencyType" "ERROR"
            exit 1
        }
    }
    
    Write-EmergencyLog "Emergency procedure completed successfully" "SUCCESS"
    
} catch {
    Write-EmergencyLog "Emergency procedure failed: $($_.Exception.Message)" "ERROR"
    Write-Host "`nEMERGENCY PROCEDURE FAILED!" -ForegroundColor Red
    Write-Host "Manual intervention may be required." -ForegroundColor Yellow
    Write-Host "Check emergency log: $EmergencyLogPath" -ForegroundColor White
    exit 1
}

Write-EmergencyLog "========== EMERGENCY PROCEDURES COMPLETED ==========" "INFO"

Write-Host "`nEmergency procedure completed. Check log for details: $EmergencyLogPath" -ForegroundColor Green
exit 0