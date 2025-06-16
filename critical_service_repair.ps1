#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Critical Windows Service Repair Script
.DESCRIPTION
    Fixes Windows Defender Firewall and resets essential services to proper startup modes
.NOTES
    Addresses service corruption from malware damage
#>

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\critical_service_repair_$timestamp.log"

function Write-ServiceLog {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    $color = switch($Level) { 
        "ERROR" {"Red"} 
        "WARNING" {"Yellow"} 
        "SUCCESS" {"Green"} 
        default {"White"} 
    }
    Write-Host $logEntry -ForegroundColor $color
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

Write-ServiceLog "=== CRITICAL SERVICE REPAIR STARTED ===" "INFO"

# Critical Windows Services that MUST be Automatic
$criticalServices = @(
    # Security Services
    @{Name="MpsSvc"; DisplayName="Windows Defender Firewall"; StartupType="Automatic"},
    @{Name="WinDefend"; DisplayName="Windows Defender Antivirus Service"; StartupType="Automatic"},
    @{Name="SecurityHealthService"; DisplayName="Windows Security Health Service"; StartupType="Automatic"},
    @{Name="wscsvc"; DisplayName="Security Center"; StartupType="Automatic"},
    
    # Core System Services
    @{Name="Winmgmt"; DisplayName="Windows Management Instrumentation"; StartupType="Automatic"},
    @{Name="RpcSs"; DisplayName="Remote Procedure Call (RPC)"; StartupType="Automatic"},
    @{Name="DcomLaunch"; DisplayName="DCOM Server Process Launcher"; StartupType="Automatic"},
    @{Name="EventLog"; DisplayName="Windows Event Log"; StartupType="Automatic"},
    @{Name="ProfSvc"; DisplayName="User Profile Service"; StartupType="Automatic"},
    @{Name="Schedule"; DisplayName="Task Scheduler"; StartupType="Automatic"},
    
    # Network Services
    @{Name="Dhcp"; DisplayName="DHCP Client"; StartupType="Automatic"},
    @{Name="Dnscache"; DisplayName="DNS Client"; StartupType="Automatic"},
    @{Name="LanmanWorkstation"; DisplayName="Workstation"; StartupType="Automatic"},
    @{Name="LanmanServer"; DisplayName="Server"; StartupType="Automatic"},
    @{Name="NlaSvc"; DisplayName="Network Location Awareness"; StartupType="Automatic"},
    
    # Audio and Hardware
    @{Name="AudioSrv"; DisplayName="Windows Audio"; StartupType="Automatic"},
    @{Name="AudioEndpointBuilder"; DisplayName="Windows Audio Endpoint Builder"; StartupType="Automatic"},
    @{Name="Themes"; DisplayName="Themes"; StartupType="Automatic"},
    @{Name="ShellHWDetection"; DisplayName="Shell Hardware Detection"; StartupType="Automatic"},
    
    # Windows Update and Maintenance
    @{Name="wuauserv"; DisplayName="Windows Update"; StartupType="Automatic (Delayed Start)"},
    @{Name="BITS"; DisplayName="Background Intelligent Transfer Service"; StartupType="Automatic (Delayed Start)"},
    @{Name="CryptSvc"; DisplayName="Cryptographic Services"; StartupType="Automatic"},
    @{Name="TrustedInstaller"; DisplayName="Windows Modules Installer"; StartupType="Manual"}, # This one should be Manual
    
    # Other Essential Services
    @{Name="Power"; DisplayName="Power"; StartupType="Automatic"},
    @{Name="BFE"; DisplayName="Base Filtering Engine"; StartupType="Automatic"},
    @{Name="PolicyAgent"; DisplayName="IPsec Policy Agent"; StartupType="Automatic"}
)

Write-ServiceLog "Checking and repairing $($criticalServices.Count) critical services..." "INFO"

$repairedCount = 0
$errorCount = 0

foreach ($svc in $criticalServices) {
    try {
        $service = Get-Service -Name $svc.Name -ErrorAction Stop
        $currentStartMode = (Get-WmiObject -Class Win32_Service -Filter "Name='$($svc.Name)'").StartMode
        
        Write-ServiceLog "Service: $($svc.DisplayName)" "INFO"
        Write-ServiceLog "  Current Status: $($service.Status)" "INFO"
        Write-ServiceLog "  Current StartMode: $currentStartMode" "INFO"
        Write-ServiceLog "  Required StartMode: $($svc.StartupType)" "INFO"
        
        # Fix startup type if incorrect
        if ($currentStartMode -ne $svc.StartupType -and $currentStartMode -ne "Auto" -and $svc.StartupType -like "*Automatic*") {
            Write-ServiceLog "  FIXING startup type..." "WARNING"
            
            if ($svc.StartupType -eq "Automatic (Delayed Start)") {
                Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction Stop
                & sc.exe config $svc.Name start= delayed-auto | Out-Null
            } else {
                Set-Service -Name $svc.Name -StartupType $svc.StartupType -ErrorAction Stop
            }
            
            Write-ServiceLog "  Fixed startup type to: $($svc.StartupType)" "SUCCESS"
            $repairedCount++
        }
        
        # Start service if it should be running
        if ($service.Status -ne "Running" -and $svc.StartupType -like "*Automatic*") {
            Write-ServiceLog "  STARTING service..." "WARNING"
            Start-Service -Name $svc.Name -ErrorAction Stop
            Write-ServiceLog "  Service started successfully" "SUCCESS"
        }
        
        if ($service.Status -eq "Running") {
            Write-ServiceLog "  Status: OK" "SUCCESS"
        }
    }
    catch {
        Write-ServiceLog "  ERROR: $($_.Exception.Message)" "ERROR"
        $errorCount++
    }
    Write-ServiceLog "  ---" "INFO"
}

# Check for services that are incorrectly set to Manual
Write-ServiceLog "Scanning for services incorrectly set to Manual..." "INFO"
try {
    $manualServices = Get-WmiObject -Class Win32_Service | Where-Object { 
        $_.StartMode -eq "Manual" -and 
        $_.Name -in @("MpsSvc", "WinDefend", "Winmgmt", "RpcSs", "EventLog", "Dhcp", "Dnscache", "AudioSrv", "Themes")
    }
    
    foreach ($manualSvc in $manualServices) {
        Write-ServiceLog "Found incorrectly manual service: $($manualSvc.DisplayName) ($($manualSvc.Name))" "WARNING"
        try {
            Set-Service -Name $manualSvc.Name -StartupType Automatic
            Write-ServiceLog "Fixed: $($manualSvc.DisplayName) set to Automatic" "SUCCESS"
            $repairedCount++
        }
        catch {
            Write-ServiceLog "Failed to fix: $($manualSvc.DisplayName) - $($_.Exception.Message)" "ERROR"
            $errorCount++
        }
    }
}
catch {
    Write-ServiceLog "Manual service scan error: $($_.Exception.Message)" "ERROR"
}

# Final verification
Write-ServiceLog "Performing final service verification..." "INFO"
$finalIssues = 0

foreach ($svc in $criticalServices) {
    try {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($service) {
            $startMode = (Get-WmiObject -Class Win32_Service -Filter "Name='$($svc.Name)'").StartMode
            if ($svc.StartupType -like "*Automatic*" -and $startMode -notin @("Auto", "Automatic")) {
                Write-ServiceLog "STILL BROKEN: $($svc.DisplayName) is $startMode (should be $($svc.StartupType))" "ERROR"
                $finalIssues++
            }
        }
    }
    catch {
        $finalIssues++
    }
}

# Summary
Write-ServiceLog "=== CRITICAL SERVICE REPAIR SUMMARY ===" "INFO"
Write-ServiceLog "Services repaired: $repairedCount" "SUCCESS"
Write-ServiceLog "Errors encountered: $errorCount" "$(if ($errorCount -eq 0) {'SUCCESS'} else {'ERROR'})"
Write-ServiceLog "Remaining issues: $finalIssues" "$(if ($finalIssues -eq 0) {'SUCCESS'} else {'WARNING'})"

if ($finalIssues -eq 0 -and $errorCount -eq 0) {
    Write-ServiceLog "ALL CRITICAL SERVICES REPAIRED SUCCESSFULLY" "SUCCESS"
} elseif ($finalIssues -lt 3) {
    Write-ServiceLog "Most issues resolved - restart recommended" "WARNING"
} else {
    Write-ServiceLog "Significant issues remain - manual intervention may be required" "ERROR"
}

Write-ServiceLog "Log saved to: $logFile" "INFO"
Write-ServiceLog "=== CRITICAL SERVICE REPAIR COMPLETED ===" "INFO"

# Immediate recommendations
Write-Host "`n=== IMMEDIATE ACTIONS ===" -ForegroundColor Yellow
Write-Host "1. RESTART the system to apply all service changes" -ForegroundColor Red
Write-Host "2. After restart, verify Windows Defender Firewall is enabled" -ForegroundColor Yellow
Write-Host "3. Check services.msc to confirm critical services are running" -ForegroundColor Green
Write-Host "4. Run Windows Update to ensure system is current" -ForegroundColor Yellow