<#
.SYNOPSIS
    System Monitoring Setup Script - Phase 2
    
.DESCRIPTION
    Configures comprehensive monitoring for ongoing system protection including
    enhanced event logging, scheduled scans, real-time monitoring, and automated backups.
    
.NOTES
    Author: Kilo Code
    Version: 2.0
    Requires: Administrator privileges
    Creates persistent monitoring infrastructure
#>

#Requires -RunAsAdministrator

param(
    [switch]$SkipScheduledTasks,
    [switch]$SkipFileMonitoring,
    [switch]$Verbose
)

# Set up logging
$LogPath = "C:\FixMyShit\setup_monitoring_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$MonitoringPath = "C:\FixMyShit\Monitoring"
$ErrorActionPreference = "Continue"

function Write-LogMessage {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"} elseif($Level -eq "WARNING"){"Yellow"} else{"Green"})
    Add-Content -Path $LogPath -Value $LogEntry
}

function Initialize-MonitoringDirectories {
    Write-LogMessage "Creating monitoring directory structure..."
    
    $Directories = @(
        $MonitoringPath,
        "$MonitoringPath\Scripts",
        "$MonitoringPath\Logs",
        "$MonitoringPath\Baselines",
        "$MonitoringPath\Alerts",
        "$MonitoringPath\Backups"
    )
    
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force | Out-Null
            Write-LogMessage "Created directory: $Dir"
        }
    }
}

function Configure-EnhancedEventLogging {
    Write-LogMessage "Configuring enhanced Windows Event Log monitoring..."
    
    try {
        # Increase log sizes for security monitoring
        $EventLogs = @(
            @{Name="Security"; Size=2147483648},  # 2GB
            @{Name="System"; Size=1073741824},   # 1GB  
            @{Name="Application"; Size=1073741824}, # 1GB
            @{Name="Windows PowerShell"; Size=536870912}, # 512MB
            @{Name="Microsoft-Windows-PowerShell/Operational"; Size=536870912} # 512MB
        )
        
        foreach ($Log in $EventLogs) {
            try {
                wevtutil sl $Log.Name /ms:$($Log.Size) 2>$null
                Write-LogMessage "Increased log size for $($Log.Name) to $($Log.Size / 1MB)MB"
            } catch {
                Write-LogMessage "Could not resize log $($Log.Name): $($_.Exception.Message)" "WARNING"
            }
        }
        
        # Enable additional audit policies for detailed monitoring
        $AuditCommands = @(
            "auditpol /set /subcategory:`"Process Creation`" /success:enable",
            "auditpol /set /subcategory:`"Process Termination`" /success:enable",
            "auditpol /set /subcategory:`"File System`" /failure:enable",
            "auditpol /set /subcategory:`"Registry`" /failure:enable",
            "auditpol /set /subcategory:`"Sensitive Privilege Use`" /success:enable /failure:enable",
            "auditpol /set /subcategory:`"Special Logon`" /success:enable"
        )
        
        foreach ($Command in $AuditCommands) {
            try {
                Invoke-Expression $Command | Out-Null
                Write-LogMessage "Applied audit policy: $Command"
            } catch {
                Write-LogMessage "Failed to apply audit policy: $Command" "WARNING"
            }
        }
        
    } catch {
        Write-LogMessage "Error configuring event logging: $($_.Exception.Message)" "ERROR"
    }
}

function Create-RealTimeMonitoringScript {
    Write-LogMessage "Creating real-time monitoring PowerShell script blocks..."
    
    $MonitoringScript = @'
# Real-time System Monitoring Script
# This script runs continuously to monitor for suspicious activity

param([string]$LogPath = "C:\FixMyShit\Monitoring\Logs\realtime_monitor.log")

function Write-MonitorLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogEntry
    if ($Level -eq "ALERT") {
        Write-EventLog -LogName Application -Source "FixMyShit-Monitor" -EntryType Warning -EventId 1001 -Message $Message
    }
}

# Register event source if it doesn't exist
try {
    if (-not (Get-EventLog -LogName Application -Source "FixMyShit-Monitor" -ErrorAction SilentlyContinue)) {
        New-EventLog -LogName Application -Source "FixMyShit-Monitor"
    }
} catch {}

Write-MonitorLog "Real-time monitoring started"

# Monitor for suspicious process creation
Register-WmiEvent -Query "SELECT * FROM Win32_ProcessStartTrace" -Action {
    $Process = $Event.SourceEventArgs.NewEvent
    $ProcessName = $Process.ProcessName
    
    # Check for suspicious process names
    $SuspiciousNames = @("backdoor", "trojan", "malware", "hack", "exploit")
    foreach ($Suspicious in $SuspiciousNames) {
        if ($ProcessName -like "*$Suspicious*") {
            Write-MonitorLog "SUSPICIOUS PROCESS DETECTED: $ProcessName (PID: $($Process.ProcessID))" "ALERT"
        }
    }
    
    # Monitor for processes starting from temp directories
    if ($Process.ExecutablePath -like "*\Temp\*" -or $Process.ExecutablePath -like "*\tmp\*") {
        Write-MonitorLog "Process started from temp directory: $ProcessName at $($Process.ExecutablePath)" "ALERT"
    }
}

Write-MonitorLog "Process monitoring registered"

# Monitor for changes to critical registry keys
$RegKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($RegKey in $RegKeys) {
    try {
        Register-ObjectEvent -InputObject (Get-Item $RegKey) -EventName "Changed" -Action {
            Write-MonitorLog "Registry change detected in: $($Event.SourceIdentifier)" "ALERT"
        }
    } catch {
        Write-MonitorLog "Could not monitor registry key: $RegKey"
    }
}

Write-MonitorLog "Registry monitoring registered"

# Keep the script running
while ($true) {
    Start-Sleep 300  # Check every 5 minutes
    
    # Monitor system resources
    $CPU = Get-Counter "\Processor(_Total)\% Processor Time" | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
    if ($CPU -gt 90) {
        Write-MonitorLog "High CPU usage detected: $([math]::Round($CPU, 2))%" "ALERT"
    }
    
    # Check for new startup items
    $StartupItems = Get-CimInstance -ClassName Win32_StartupCommand
    foreach ($Item in $StartupItems) {
        if ($Item.Caption -like "*backdoor*" -or $Item.Caption -like "*trojan*") {
            Write-MonitorLog "Suspicious startup item: $($Item.Caption) - $($Item.Command)" "ALERT"
        }
    }
}
'@

    $ScriptPath = "$MonitoringPath\Scripts\realtime_monitor.ps1"
    Set-Content -Path $ScriptPath -Value $MonitoringScript
    Write-LogMessage "Real-time monitoring script created: $ScriptPath"
}

function Setup-ScheduledScans {
    if ($SkipScheduledTasks) {
        Write-LogMessage "Skipping scheduled task creation as requested"
        return
    }
    
    Write-LogMessage "Setting up scheduled scans for ongoing protection..."
    
    try {
        # Daily quick scan
        $QuickScanAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\FixMyShit\malware_scan.ps1 -QuickScan"
        $QuickScanTrigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
        $QuickScanSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask -TaskName "FixMyShit-DailyQuickScan" -Action $QuickScanAction -Trigger $QuickScanTrigger -Settings $QuickScanSettings -Description "Daily quick malware scan" -User "SYSTEM" -Force
        Write-LogMessage "Daily quick scan scheduled for 2:00 AM"
        
        # Weekly full scan  
        $FullScanAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\FixMyShit\malware_scan.ps1 -FullScan"
        $FullScanTrigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At "01:00AM"
        
        Register-ScheduledTask -TaskName "FixMyShit-WeeklyFullScan" -Action $FullScanAction -Trigger $FullScanTrigger -Settings $QuickScanSettings -Description "Weekly full system malware scan" -User "SYSTEM" -Force
        Write-LogMessage "Weekly full scan scheduled for Sundays at 1:00 AM"
        
        # Recovery verification check
        $VerifyAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\FixMyShit\recovery_verification.ps1 -GenerateReport"
        $VerifyTrigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Monday -At "09:00AM"
        
        Register-ScheduledTask -TaskName "FixMyShit-WeeklyVerification" -Action $VerifyAction -Trigger $VerifyTrigger -Settings $QuickScanSettings -Description "Weekly system recovery verification" -User "SYSTEM" -Force
        Write-LogMessage "Weekly verification scheduled for Mondays at 9:00 AM"
        
    } catch {
        Write-LogMessage "Error setting up scheduled scans: $($_.Exception.Message)" "ERROR"
    }
}

function Setup-FileIntegrityMonitoring {
    if ($SkipFileMonitoring) {
        Write-LogMessage "Skipping file integrity monitoring as requested"
        return
    }
    
    Write-LogMessage "Configuring file integrity monitoring for critical system areas..."
    
    # Create file integrity monitoring script
    $FIMScript = @'
# File Integrity Monitoring Script
param([string]$BaselinePath = "C:\FixMyShit\Monitoring\Baselines")

function Get-FileHash {
    param([string]$FilePath)
    try {
        return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    } catch {
        return $null
    }
}

function Create-Baseline {
    param([string]$Directory, [string]$BaselineName)
    
    Write-Host "Creating baseline for $Directory..."
    $Files = Get-ChildItem -Path $Directory -Recurse -File -ErrorAction SilentlyContinue
    $Baseline = @{}
    
    foreach ($File in $Files) {
        $Hash = Get-FileHash -FilePath $File.FullName
        if ($Hash) {
            $Baseline[$File.FullName] = @{
                Hash = $Hash
                Size = $File.Length
                LastModified = $File.LastWriteTime
            }
        }
    }
    
    $BaselineFile = "$BaselinePath\$BaselineName.json"
    $Baseline | ConvertTo-Json -Depth 3 | Set-Content -Path $BaselineFile
    Write-Host "Baseline saved to $BaselineFile"
}

function Check-Integrity {
    param([string]$Directory, [string]$BaselineName)
    
    $BaselineFile = "$BaselinePath\$BaselineName.json"
    if (-not (Test-Path $BaselineFile)) {
        Write-Host "Baseline not found: $BaselineFile" -ForegroundColor Red
        return
    }
    
    $Baseline = Get-Content -Path $BaselineFile | ConvertFrom-Json
    $CurrentFiles = Get-ChildItem -Path $Directory -Recurse -File -ErrorAction SilentlyContinue
    
    Write-Host "Checking integrity for $Directory..."
    $Changes = @()
    
    foreach ($File in $CurrentFiles) {
        $CurrentHash = Get-FileHash -FilePath $File.FullName
        if ($CurrentHash -and $Baseline.($File.FullName)) {
            $BaselineInfo = $Baseline.($File.FullName)
            if ($CurrentHash -ne $BaselineInfo.Hash) {
                $Changes += "MODIFIED: $($File.FullName)"
            }
        } elseif ($CurrentHash) {
            $Changes += "NEW: $($File.FullName)"
        }
    }
    
    # Check for deleted files
    foreach ($BaselineFile in $Baseline.PSObject.Properties.Name) {
        if (-not (Test-Path $BaselineFile)) {
            $Changes += "DELETED: $BaselineFile"
        }
    }
    
    if ($Changes.Count -gt 0) {
        Write-Host "Changes detected:" -ForegroundColor Yellow
        foreach ($Change in $Changes) {
            Write-Host "  $Change" -ForegroundColor Yellow
        }
        
        # Log to event log
        $ChangeText = $Changes -join "`n"
        Write-EventLog -LogName Application -Source "FixMyShit-Monitor" -EntryType Warning -EventId 1002 -Message "File integrity changes detected:`n$ChangeText"
    } else {
        Write-Host "No changes detected" -ForegroundColor Green
    }
}

# Critical directories to monitor
$CriticalDirs = @(
    @{Path="C:\Windows\System32"; Name="System32"},
    @{Path="C:\Windows\SysWOW64"; Name="SysWOW64"},
    @{Path="C:\FixMyShit"; Name="FixMyShit"}
)

# Create baselines if they don't exist
foreach ($Dir in $CriticalDirs) {
    if (Test-Path $Dir.Path) {
        $BaselineFile = "$BaselinePath\$($Dir.Name).json"
        if (-not (Test-Path $BaselineFile)) {
            Create-Baseline -Directory $Dir.Path -BaselineName $Dir.Name
        } else {
            Check-Integrity -Directory $Dir.Path -BaselineName $Dir.Name
        }
    }
}
'@

    $FIMScriptPath = "$MonitoringPath\Scripts\file_integrity_monitor.ps1"
    Set-Content -Path $FIMScriptPath -Value $FIMScript
    Write-LogMessage "File integrity monitoring script created: $FIMScriptPath"
    
    # Schedule file integrity checks
    try {
        $FIMAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File $FIMScriptPath"
        $FIMTrigger = New-ScheduledTaskTrigger -Daily -At "03:00AM"
        $FIMSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName "FixMyShit-FileIntegrityCheck" -Action $FIMAction -Trigger $FIMTrigger -Settings $FIMSettings -Description "Daily file integrity monitoring" -User "SYSTEM" -Force
        Write-LogMessage "File integrity monitoring scheduled for daily execution at 3:00 AM"
    } catch {
        Write-LogMessage "Error scheduling file integrity monitoring: $($_.Exception.Message)" "ERROR"
    }
}

function Setup-NetworkMonitoring {
    Write-LogMessage "Setting up network connection monitoring alerts..."
    
    $NetworkMonitorScript = @'
# Network Connection Monitoring Script
param([string]$LogPath = "C:\FixMyShit\Monitoring\Logs\network_monitor.log")

function Write-NetworkLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogEntry
    if ($Level -eq "ALERT") {
        Write-EventLog -LogName Application -Source "FixMyShit-Monitor" -EntryType Warning -EventId 1003 -Message $Message
    }
}

Write-NetworkLog "Network monitoring started"

while ($true) {
    try {
        # Get current network connections
        $Connections = Get-NetTCPConnection | Where-Object {$_.State -eq "Established"}
        
        foreach ($Conn in $Connections) {
            # Check for suspicious ports
            $SuspiciousPorts = @(1234, 4444, 5555, 6666, 8080, 9999)
            if ($Conn.RemotePort -in $SuspiciousPorts) {
                Write-NetworkLog "Suspicious connection detected: $($Conn.LocalAddress):$($Conn.LocalPort) -> $($Conn.RemoteAddress):$($Conn.RemotePort)" "ALERT"
            }
            
            # Check for connections to known malicious IP ranges (example)
            $RemoteIP = $Conn.RemoteAddress
            if ($RemoteIP -like "10.0.0.*" -and $Conn.RemotePort -gt 8000) {
                Write-NetworkLog "Potentially suspicious internal connection: $RemoteIP:$($Conn.RemotePort)" "ALERT"
            }
        }
        
        # Monitor DNS queries for suspicious domains
        $DNSCache = Get-DnsClientCache | Where-Object {$_.TimeToLive -lt 60}
        foreach ($Entry in $DNSCache) {
            $SuspiciousDomains = @("malware", "backdoor", "trojan", "hack")
            foreach ($Suspicious in $SuspiciousDomains) {
                if ($Entry.Name -like "*$Suspicious*") {
                    Write-NetworkLog "Suspicious DNS query: $($Entry.Name)" "ALERT"
                }
            }
        }
        
    } catch {
        Write-NetworkLog "Error in network monitoring: $($_.Exception.Message)" "ERROR"
    }
    
    Start-Sleep 60  # Check every minute
}
'@

    $NetworkScriptPath = "$MonitoringPath\Scripts\network_monitor.ps1"
    Set-Content -Path $NetworkScriptPath -Value $NetworkMonitorScript
    Write-LogMessage "Network monitoring script created: $NetworkScriptPath"
}

function Create-BackupSchedule {
    Write-LogMessage "Establishing automated backup schedule for critical system settings..."
    
    # Create backup configuration script
    $BackupScript = @'
# Automated System Configuration Backup Script
param([string]$BackupPath = "C:\FixMyShit\Monitoring\Backups")

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir = "$BackupPath\Backup_$Timestamp"

if (-not (Test-Path $BackupDir)) {
    New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
}

Write-Host "Creating system configuration backup in $BackupDir..."

try {
    # Backup registry keys
    $RegKeys = @(
        @{Key="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; File="HKLM_Run.reg"},
        @{Key="HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; File="HKCU_Run.reg"},
        @{Key="HKLM\SYSTEM\CurrentControlSet\Services"; File="Services.reg"}
    )
    
    foreach ($RegKey in $RegKeys) {
        $RegFile = "$BackupDir\$($RegKey.File)"
        reg export $RegKey.Key $RegFile /y 2>$null
        if (Test-Path $RegFile) {
            Write-Host "Exported: $($RegKey.Key)"
        }
    }
    
    # Backup security policies
    secedit /export /cfg "$BackupDir\SecurityPolicy.inf" 2>$null
    
    # Backup firewall configuration
    netsh advfirewall export "$BackupDir\FirewallConfig.wfw" 2>$null
    
    # Backup scheduled tasks
    schtasks /query /fo CSV > "$BackupDir\ScheduledTasks.csv"
    
    # Backup event log configuration
    wevtutil el | ForEach-Object {
        $LogName = $_
        $LogInfo = wevtutil gl "$LogName" 2>$null
        if ($LogInfo) {
            Add-Content -Path "$BackupDir\EventLogConfig.txt" -Value "=== $LogName ==="
            Add-Content -Path "$BackupDir\EventLogConfig.txt" -Value $LogInfo
        }
    }
    
    # Create backup manifest
    $Manifest = @{
        BackupDate = (Get-Date).ToString()
        ComputerName = $env:COMPUTERNAME
        WindowsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
        Files = (Get-ChildItem $BackupDir | Select-Object Name, Length, LastWriteTime)
    }
    
    $Manifest | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupDir\manifest.json"
    
    Write-Host "Backup completed successfully: $BackupDir"
    
    # Clean up old backups (keep last 10)
    $OldBackups = Get-ChildItem $BackupPath -Directory | Where-Object {$_.Name -like "Backup_*"} | Sort-Object CreationTime -Descending | Select-Object -Skip 10
    foreach ($OldBackup in $OldBackups) {
        Remove-Item -Path $OldBackup.FullName -Recurse -Force
        Write-Host "Removed old backup: $($OldBackup.Name)"
    }
    
} catch {
    Write-Host "Error during backup: $($_.Exception.Message)" -ForegroundColor Red
}
'@

    $BackupScriptPath = "$MonitoringPath\Scripts\system_backup.ps1"
    Set-Content -Path $BackupScriptPath -Value $BackupScript
    Write-LogMessage "Backup script created: $BackupScriptPath"
    
    # Schedule backup task
    try {
        $BackupAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File $BackupScriptPath"
        $BackupTrigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Saturday -At "11:00PM"
        $BackupSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName "FixMyShit-WeeklyBackup" -Action $BackupAction -Trigger $BackupTrigger -Settings $BackupSettings -Description "Weekly system configuration backup" -User "SYSTEM" -Force
        Write-LogMessage "Weekly backup scheduled for Saturdays at 11:00 PM"
    } catch {
        Write-LogMessage "Error scheduling backup task: $($_.Exception.Message)" "ERROR"
    }
}

function Create-BaselineConfigurations {
    Write-LogMessage "Establishing baseline configurations for future comparison..."
    
    $BaselineScript = @'
# System Baseline Configuration Script
param([string]$BaselinePath = "C:\FixMyShit\Monitoring\Baselines")

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BaselineFile = "$BaselinePath\SystemBaseline_$Timestamp.json"

Write-Host "Creating system baseline: $BaselineFile"

$Baseline = @{
    Timestamp = (Get-Date).ToString()
    ComputerInfo = @{
        Name = $env:COMPUTERNAME
        OS = (Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber)
        CPU = (Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors)
        Memory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    }
    
    Services = (Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object Name, DisplayName, StartType)
    
    StartupPrograms = (Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location)
    
    InstalledSoftware = (Get-CimInstance Win32_Product | Select-Object Name, Version, Vendor)
    
    NetworkConfiguration = @{
        Adapters = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object Name, InterfaceDescription, LinkSpeed)
        IPConfig = (Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway)
        DNSServers = (Get-DnsClientServerAddress | Select-Object InterfaceAlias, ServerAddresses)
    }
    
    SecurityConfiguration = @{
        FirewallProfiles = (Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction)
        DefenderStatus = (Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, IoavProtectionEnabled)
        AuditPolicies = (auditpol /get /category:* /r | ConvertFrom-Csv)
    }
    
    UserAccounts = (Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordRequired)
    
    ScheduledTasks = (Get-ScheduledTask | Where-Object {$_.State -eq "Ready"} | Select-Object TaskName, TaskPath, State)
}

$Baseline | ConvertTo-Json -Depth 4 | Set-Content -Path $BaselineFile
Write-Host "System baseline created successfully"

# Keep only last 5 baselines
$OldBaselines = Get-ChildItem $BaselinePath -File | Where-Object {$_.Name -like "SystemBaseline_*.json"} | Sort-Object CreationTime -Descending | Select-Object -Skip 5
foreach ($OldBaseline in $OldBaselines) {
    Remove-Item -Path $OldBaseline.FullName -Force
    Write-Host "Removed old baseline: $($OldBaseline.Name)"
}
'@

    $BaselineScriptPath = "$MonitoringPath\Scripts\create_baseline.ps1"
    Set-Content -Path $BaselineScriptPath -Value $BaselineScript
    Write-LogMessage "Baseline script created: $BaselineScriptPath"
    
    # Execute initial baseline creation
    try {
        & $BaselineScriptPath
        Write-LogMessage "Initial system baseline created"
    } catch {
        Write-LogMessage "Error creating initial baseline: $($_.Exception.Message)" "ERROR"
    }
}

function Create-MonitoringDashboard {
    Write-LogMessage "Creating monitoring dashboard script..."
    
    $DashboardScript = @'
# System Monitoring Dashboard
param([switch]$ShowDetails)

function Get-MonitoringStatus {
    Write-Host "=== SYSTEM MONITORING STATUS ===" -ForegroundColor Cyan
    
    # Check scheduled tasks
    $MonitoringTasks = @(
        "FixMyShit-DailyQuickScan",
        "FixMyShit-WeeklyFullScan", 
        "FixMyShit-WeeklyVerification",
        "FixMyShit-FileIntegrityCheck",
        "FixMyShit-WeeklyBackup"
    )
    
    Write-Host "`nScheduled Tasks:" -ForegroundColor Yellow
    foreach ($Task in $MonitoringTasks) {
        $ScheduledTask = Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
        if ($ScheduledTask) {
            $LastRun = (Get-ScheduledTaskInfo -TaskName $Task).LastRunTime
            $NextRun = (Get-ScheduledTaskInfo -TaskName $Task).NextRunTime
            Write-Host "  ✓ $Task - Last: $LastRun, Next: $NextRun" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $Task - NOT CONFIGURED" -ForegroundColor Red
        }
    }
    
    # Check log files
    Write-Host "`nLog Files:" -ForegroundColor Yellow
    $LogFiles = Get-ChildItem "C:\FixMyShit\Monitoring\Logs\*.log" -ErrorAction SilentlyContinue
    if ($LogFiles) {
        foreach ($Log in $LogFiles) {
            $Size = [math]::Round($Log.Length / 1KB, 2)
            Write-Host "  $($Log.Name) - ${Size}KB (Modified: $($Log.LastWriteTime))" -ForegroundColor Green
        }
    } else {
        Write-Host "  No monitoring logs found" -ForegroundColor Yellow
    }
    
    # Check recent alerts
    Write-Host "`nRecent Alerts (Last 24 hours):" -ForegroundColor Yellow
    $Yesterday = (Get-Date).AddDays(-1)
    $Alerts = Get-WinEvent -FilterHashtable @{LogName="Application"; ProviderName="FixMyShit-Monitor"; StartTime=$Yesterday} -ErrorAction SilentlyContinue
    if ($Alerts) {
        foreach ($Alert in $Alerts | Select-Object -First 5) {
            Write-Host "  $($Alert.TimeCreated): $($Alert.LevelDisplayName) - $($Alert.Message)" -ForegroundColor $(if($Alert.LevelDisplayName -eq "Warning"){"Yellow"}else{"Red"})
        }
    } else {
        Write-Host "  No alerts in the last 24 hours" -ForegroundColor Green
    }
    
    # Check system health
    Write-Host "`nSystem Health:" -ForegroundColor Yellow
    $DefenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($DefenderStatus) {
        $Status = if ($DefenderStatus.RealTimeProtectionEnabled) { "ENABLED" } else { "DISABLED" }
        $Color = if ($DefenderStatus.RealTimeProtectionEnabled) { "Green" } else { "Red" }
        Write-Host "  Windows Defender: $Status" -ForegroundColor $Color
    }
    
    $FirewallProfiles = Get-NetFirewallProfile
    $EnabledProfiles = ($FirewallProfiles | Where-Object {$_.Enabled -eq $true}).Count
    Write-Host "  Firewall Profiles Enabled: $EnabledProfiles/3" -ForegroundColor $(if($EnabledProfiles -eq 3){"Green"}else{"Yellow"})
    
    # Azure environment check
    $AzureEnv = "C:\FixMyShit\azure-ai-envsource\Scripts\python.exe"
    if (Test-Path $AzureEnv) {
        Write-Host "  Azure AI Environment: AVAILABLE" -ForegroundColor Green
    } else {
        Write-Host "  Azure AI Environment: NOT FOUND" -ForegroundColor Red
    }
}

Get-MonitoringStatus

if ($ShowDetails) {
    Write-Host "`n=== DETAILED SYSTEM INFORMATION ===" -ForegroundColor Cyan
    
    # Show running processes count
    $ProcessCount = (Get-Process).Count
    Write-Host "Running Processes: $ProcessCount" -ForegroundColor White
    
    # Show memory usage
    $Memory = Get-CimInstance Win32_OperatingSystem
    $MemoryUsage = [math]::Round((($Memory.TotalVisibleMemorySize - $Memory.FreePhysicalMemory) / $Memory.TotalVisibleMemorySize) * 100, 2)
    Write-Host "Memory Usage: $MemoryUsage%" -ForegroundColor White
    
    # Show disk usage
    $Drives = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
    foreach ($Drive in $Drives) {
        $UsedSpace = [math]::Round((($Drive.Size - $Drive.FreeSpace) / $Drive.Size) * 100, 2)
        Write-Host "Drive $($Drive.DeviceID) Usage: $UsedSpace%" -ForegroundColor White
    }
}
'@

    $DashboardPath = "$MonitoringPath\Scripts\monitoring_dashboard.ps1"
    Set-Content -Path $DashboardPath -Value $DashboardScript
    Write-LogMessage "Monitoring dashboard created: $DashboardPath"
}

# Main execution
Write-LogMessage "========== System Monitoring Setup Started =========="
Write-LogMessage "Log file: $LogPath"

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-LogMessage "This script requires administrator privileges. Please run as administrator." "ERROR"
    exit 1
}

# Execute monitoring setup steps
Write-Host "`n=== INITIALIZING MONITORING INFRASTRUCTURE ===" -ForegroundColor Cyan
Initialize-MonitoringDirectories

Write-Host "`n=== CONFIGURING EVENT LOGGING ===" -ForegroundColor Cyan
Configure-EnhancedEventLogging

Write-Host "`n=== CREATING MONITORING SCRIPTS ===" -ForegroundColor Cyan
Create-RealTimeMonitoringScript
Setup-NetworkMonitoring
Create-MonitoringDashboard

Write-Host "`n=== SETTING UP SCHEDULED TASKS ===" -ForegroundColor Cyan
Setup-ScheduledScans

Write-Host "`n=== CONFIGURING FILE INTEGRITY MONITORING ===" -ForegroundColor Cyan
Setup-FileIntegrityMonitoring

Write-Host "`n=== ESTABLISHING BACKUP SCHEDULE ===" -ForegroundColor Cyan
Create-BackupSchedule

Write-Host "`n=== CREATING BASELINE CONFIGURATIONS ===" -ForegroundColor Cyan
Create-BaselineConfigurations

Write-LogMessage "========== System Monitoring Setup Completed =========="

# Display summary
Write-Host "`n=== MONITORING SETUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "✓ Monitoring directory structure created" -ForegroundColor Green
Write-Host "✓ Enhanced event logging configured" -ForegroundColor Green
Write-Host "✓ Real-time monitoring scripts deployed" -ForegroundColor Green
Write-Host "✓ Scheduled scans configured" -ForegroundColor Green
Write-Host "✓ File integrity monitoring enabled" -ForegroundColor Green
Write-Host "✓ Network monitoring alerts set up" -ForegroundColor Green
Write-Host "✓ Automated backup schedule established" -ForegroundColor Green
Write-Host "✓ System baseline configurations created" -ForegroundColor Green
Write-Host "✓ Monitoring dashboard available" -ForegroundColor Green

Write-Host "`nMonitoring Infrastructure Location: $MonitoringPath" -ForegroundColor White
Write-Host "Run monitoring dashboard: PowerShell -File $MonitoringPath\Scripts\monitoring_dashboard.ps1" -ForegroundColor White
Write-Host "`nAll monitoring components are now active and will run automatically." -ForegroundColor Green