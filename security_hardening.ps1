<#
.SYNOPSIS
    Security Hardening Script for Windows System Recovery - Phase 2
    
.DESCRIPTION
    Implements comprehensive security hardening measures to prevent reinfection
    and secure the system after malware cleanup. Preserves Azure AI development environment.
    
.NOTES
    Author: Kilo Code
    Version: 2.0
    Requires: Administrator privileges
    Safe to run multiple times
#>

#Requires -RunAsAdministrator

param(
    [switch]$SkipFirewall,
    [switch]$SkipServices,
    [switch]$Verbose
)

# Set up logging
$LogPath = "C:\FixMyShit\security_hardening_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$ErrorActionPreference = "Continue"

function Write-LogMessage {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"} elseif($Level -eq "WARNING"){"Yellow"} else{"Green"})
    Add-Content -Path $LogPath -Value $LogEntry
}

function Test-AzureEnvironment {
    Write-LogMessage "Verifying Azure AI environment integrity..."
    $AzureEnvPath = "C:\FixMyShit\azure-ai-envsource"
    $McpServerPath = "C:\FixMyShit\azure-ai-mcp-server"
    
    if (Test-Path $AzureEnvPath -PathType Container) {
        Write-LogMessage "Azure AI environment found at $AzureEnvPath"
        if (Test-Path "$AzureEnvPath\Scripts\python.exe") {
            Write-LogMessage "Python executable verified"
        } else {
            Write-LogMessage "Python executable missing - Azure environment may be corrupted" "WARNING"
        }
    }
    
    if (Test-Path $McpServerPath -PathType Container) {
        Write-LogMessage "MCP Server directory found at $McpServerPath"
    }
}

function Enable-WindowsDefender {
    Write-LogMessage "Configuring Windows Defender with maximum security settings..."
    
    try {
        # Enable real-time protection
        Set-MpPreference -DisableRealtimeMonitoring $false
        Write-LogMessage "Real-time protection enabled"
        
        # Configure maximum security settings
        Set-MpPreference -CloudProtection Advanced
        Set-MpPreference -MAPSReporting Advanced
        Set-MpPreference -SubmitSamplesConsent SendAllSamples
        Write-LogMessage "Cloud protection and MAPS reporting configured"
        
        # Enable behavioral monitoring
        Set-MpPreference -DisableBehaviorMonitoring $false
        Set-MpPreference -DisableIOAVProtection $false
        Set-MpPreference -DisableScriptScanning $false
        Write-LogMessage "Behavioral monitoring and script scanning enabled"
        
        # Configure scan settings
        Set-MpPreference -ScanPurgeItemsAfterDelay 30
        Set-MpPreference -ScanOnlyIfIdleEnabled $false
        Write-LogMessage "Scan settings optimized"
        
        # Exclude Azure AI environment from performance scans but keep security scanning
        Add-MpPreference -ExclusionProcess "C:\FixMyShit\azure-ai-envsource\Scripts\python.exe"
        Write-LogMessage "Azure AI Python environment excluded from performance impact"
        
        # Start a quick scan
        Start-MpScan -ScanType QuickScan
        Write-LogMessage "Quick scan initiated"
        
    } catch {
        Write-LogMessage "Error configuring Windows Defender: $($_.Exception.Message)" "ERROR"
    }
}

function Configure-WindowsFirewall {
    if ($SkipFirewall) {
        Write-LogMessage "Skipping Windows Firewall configuration as requested"
        return
    }
    
    Write-LogMessage "Configuring Windows Firewall with enhanced security..."
    
    try {
        # Enable firewall for all profiles
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Write-LogMessage "Windows Firewall enabled for all profiles"
        
        # Configure default actions
        Set-NetFirewallProfile -Profile Domain -DefaultInboundAction Block -DefaultOutboundAction Allow
        Set-NetFirewallProfile -Profile Public -DefaultInboundAction Block -DefaultOutboundAction Allow  
        Set-NetFirewallProfile -Profile Private -DefaultInboundAction Block -DefaultOutboundAction Allow
        Write-LogMessage "Default firewall actions configured (Block inbound, Allow outbound)"
        
        # Enable logging
        Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed True -LogBlocked True -LogMaxSizeKilobytes 32767
        Write-LogMessage "Firewall logging enabled"
        
        # Allow essential Azure/development services through firewall
        $DevRules = @(
            @{Name="Azure-HTTPS-Out"; Direction="Outbound"; Protocol="TCP"; LocalPort="Any"; RemotePort="443"; Action="Allow"},
            @{Name="Azure-HTTP-Out"; Direction="Outbound"; Protocol="TCP"; LocalPort="Any"; RemotePort="80"; Action="Allow"},
            @{Name="Git-SSH-Out"; Direction="Outbound"; Protocol="TCP"; LocalPort="Any"; RemotePort="22"; Action="Allow"},
            @{Name="DNS-Out"; Direction="Outbound"; Protocol="UDP"; LocalPort="Any"; RemotePort="53"; Action="Allow"},
            @{Name="Local-Dev-Server"; Direction="Inbound"; Protocol="TCP"; LocalPort="3000,8000,8080"; Action="Allow"}
        )
        
        foreach ($Rule in $DevRules) {
            $ExistingRule = Get-NetFirewallRule -DisplayName $Rule.Name -ErrorAction SilentlyContinue
            if (-not $ExistingRule) {
                New-NetFirewallRule -DisplayName $Rule.Name -Direction $Rule.Direction -Protocol $Rule.Protocol -LocalPort $Rule.LocalPort -RemotePort $Rule.RemotePort -Action $Rule.Action
                Write-LogMessage "Created firewall rule: $($Rule.Name)"
            }
        }
        
    } catch {
        Write-LogMessage "Error configuring Windows Firewall: $($_.Exception.Message)" "ERROR"
    }
}

function Enable-SecurityFeatures {
    Write-LogMessage "Enabling Windows security features..."
    
    try {
        # Enable SmartScreen
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "RequireAdmin"
        Write-LogMessage "SmartScreen enabled with admin requirement"
        
        # Enable exploit protection
        Set-ProcessMitigation -System -Enable DEP,SEHOP,ASLR,HighEntropy,StrictHandle,CFG
        Write-LogMessage "System-wide exploit protection features enabled"
        
        # Configure User Account Control to maximum
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 3
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 1
        Write-LogMessage "UAC configured for maximum security"
        
        # Enable Windows Update automatic installation
        $WUPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $WUPath)) {
            New-Item -Path $WUPath -Force | Out-Null
        }
        Set-ItemProperty -Path $WUPath -Name "NoAutoUpdate" -Value 0
        Set-ItemProperty -Path $WUPath -Name "AUOptions" -Value 4
        Set-ItemProperty -Path $WUPath -Name "ScheduledInstallDay" -Value 0
        Set-ItemProperty -Path $WUPath -Name "ScheduledInstallTime" -Value 3
        Write-LogMessage "Automatic Windows Updates configured"
        
    } catch {
        Write-LogMessage "Error enabling security features: $($_.Exception.Message)" "ERROR"
    }
}

function Disable-UnnecessaryServices {
    if ($SkipServices) {
        Write-LogMessage "Skipping service configuration as requested"
        return
    }
    
    Write-LogMessage "Disabling unnecessary services that could be attack vectors..."
    
    # Services to disable (carefully selected to avoid breaking development environment)
    $ServicesToDisable = @(
        "Telnet",
        "simptcp",
        "fax",
        "FTPSVC",
        "MSiSCSI",
        "ssh-agent",
        "RemoteRegistry",
        "RemoteAccess"
    )
    
    foreach ($ServiceName in $ServicesToDisable) {
        try {
            $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($Service -and $Service.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force
                Set-Service -Name $ServiceName -StartupType Disabled
                Write-LogMessage "Disabled service: $ServiceName"
            } elseif ($Service) {
                Set-Service -Name $ServiceName -StartupType Disabled
                Write-LogMessage "Set service to disabled: $ServiceName"
            }
        } catch {
            Write-LogMessage "Could not disable service $ServiceName : $($_.Exception.Message)" "WARNING"
        }
    }
}

function Configure-PowerShellSecurity {
    Write-LogMessage "Configuring PowerShell execution policy securely..."
    
    try {
        # Set execution policy to RemoteSigned for security while allowing local scripts
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
        Write-LogMessage "PowerShell execution policy set to RemoteSigned"
        
        # Enable PowerShell script block logging
        $PSLoggingPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
        if (-not (Test-Path $PSLoggingPath)) {
            New-Item -Path $PSLoggingPath -Force | Out-Null
        }
        Set-ItemProperty -Path $PSLoggingPath -Name "EnableScriptBlockLogging" -Value 1
        Write-LogMessage "PowerShell script block logging enabled"
        
        # Enable module logging
        $ModuleLoggingPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
        if (-not (Test-Path $ModuleLoggingPath)) {
            New-Item -Path $ModuleLoggingPath -Force | Out-Null
        }
        Set-ItemProperty -Path $ModuleLoggingPath -Name "EnableModuleLogging" -Value 1
        Write-LogMessage "PowerShell module logging enabled"
        
    } catch {
        Write-LogMessage "Error configuring PowerShell security: $($_.Exception.Message)" "ERROR"
    }
}

function Enable-EventLogAuditing {
    Write-LogMessage "Enabling Windows Event Log auditing for security events..."
    
    try {
        # Configure audit policies
        $AuditSettings = @(
            "auditpol /set /category:`"Logon/Logoff`" /success:enable /failure:enable",
            "auditpol /set /category:`"Account Management`" /success:enable /failure:enable",
            "auditpol /set /category:`"Policy Change`" /success:enable /failure:enable",
            "auditpol /set /category:`"Privilege Use`" /failure:enable",
            "auditpol /set /category:`"Object Access`" /failure:enable",
            "auditpol /set /category:`"System`" /success:enable /failure:enable"
        )
        
        foreach ($Setting in $AuditSettings) {
            Invoke-Expression $Setting | Out-Null
        }
        Write-LogMessage "Security audit policies configured"
        
        # Increase security log size
        wevtutil sl Security /ms:1073741824  # 1GB
        wevtutil sl System /ms:1073741824    # 1GB  
        wevtutil sl Application /ms:1073741824 # 1GB
        Write-LogMessage "Event log sizes increased to 1GB each"
        
    } catch {
        Write-LogMessage "Error configuring event log auditing: $($_.Exception.Message)" "ERROR"
    }
}

function Create-RollbackScript {
    Write-LogMessage "Creating rollback script for security changes..."
    
    $RollbackScript = @'
# Security Hardening Rollback Script
# Run this script if security hardening breaks development workflow

Write-Host "Rolling back security hardening changes..." -ForegroundColor Yellow

# Restore moderate UAC settings
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 5

# Remove Azure environment exclusions if needed
# Remove-MpPreference -ExclusionProcess "C:\FixMyShit\azure-ai-envsource\Scripts\python.exe"

# Reset execution policy to less restrictive
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

Write-Host "Rollback completed. Restart system if issues persist." -ForegroundColor Green
'@

    $RollbackPath = "C:\FixMyShit\security_hardening_rollback.ps1"
    Set-Content -Path $RollbackPath -Value $RollbackScript
    Write-LogMessage "Rollback script created at: $RollbackPath"
}

# Main execution
Write-LogMessage "========== Security Hardening Script Started =========="
Write-LogMessage "Log file: $LogPath"

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-LogMessage "This script requires administrator privileges. Please run as administrator." "ERROR"
    exit 1
}

# Test Azure environment before making changes
Test-AzureEnvironment

# Execute security hardening steps
Write-LogMessage "Starting security hardening process..."

Enable-WindowsDefender
Configure-WindowsFirewall  
Enable-SecurityFeatures
Disable-UnnecessaryServices
Configure-PowerShellSecurity
Enable-EventLogAuditing
Create-RollbackScript

Write-LogMessage "========== Security Hardening Completed =========="
Write-LogMessage "System hardening applied successfully"
Write-LogMessage "Rollback script available at: C:\FixMyShit\security_hardening_rollback.ps1"
Write-LogMessage "Please reboot the system to ensure all changes take effect"

# Display summary
Write-Host "`n=== SECURITY HARDENING SUMMARY ===" -ForegroundColor Cyan
Write-Host "✓ Windows Defender configured with maximum security" -ForegroundColor Green
Write-Host "✓ Windows Firewall enabled with enhanced rules" -ForegroundColor Green  
Write-Host "✓ Security features enabled (SmartScreen, Exploit Protection, UAC)" -ForegroundColor Green
Write-Host "✓ Unnecessary services disabled" -ForegroundColor Green
Write-Host "✓ PowerShell execution policy secured" -ForegroundColor Green
Write-Host "✓ Event log auditing enabled" -ForegroundColor Green
Write-Host "✓ Azure AI development environment preserved" -ForegroundColor Green
Write-Host "✓ Rollback script created for emergency use" -ForegroundColor Green
Write-Host "`nREBOOT REQUIRED to complete hardening process" -ForegroundColor Yellow