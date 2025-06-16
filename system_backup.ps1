<#
.SYNOPSIS
    System Restore and Backup Script - Phase 2
    
.DESCRIPTION
    Creates comprehensive system restore points and backups of critical configurations
    including registry areas, security settings, and Azure AI environment settings.
    
.NOTES
    Author: Kilo Code
    Version: 2.0
    Requires: Administrator privileges
    Safe to run multiple times
#>

#Requires -RunAsAdministrator

param(
    [switch]$CreateRestorePoint,
    [switch]$BackupRegistry,
    [switch]$BackupSecurity,
    [switch]$BackupAzureEnvironment,
    [switch]$ValidateBackups,
    [switch]$All,
    [string]$BackupLocation = "C:\FixMyShit\SystemBackups"
)

# Set up logging
$LogPath = "C:\FixMyShit\system_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupPath = "$BackupLocation\Backup_$Timestamp"
$ErrorActionPreference = "Continue"

function Write-LogMessage {
    param([string]$Message, [string]$Level = "INFO")
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$TimeStamp] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"} elseif($Level -eq "WARNING"){"Yellow"} else{"Green"})
    Add-Content -Path $LogPath -Value $LogEntry
}

function Initialize-BackupStructure {
    Write-LogMessage "Initializing backup directory structure..."
    
    # Create backup directory structure
    $Directories = @(
        $BackupLocation,
        $BackupPath,
        "$BackupPath\Registry",
        "$BackupPath\Security",
        "$BackupPath\AzureEnvironment",
        "$BackupPath\SystemState",
        "$BackupPath\Logs",
        "$BackupPath\Documentation"
    )
    
    foreach ($Dir in $Directories) {
        if (-not (Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force | Out-Null
            Write-LogMessage "Created directory: $Dir"
        }
    }
    
    # Create backup manifest
    $Manifest = @{
        BackupDate = (Get-Date).ToString()
        BackupID = $Timestamp
        ComputerName = $env:COMPUTERNAME
        WindowsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
        BackupLocation = $BackupPath
        BackupComponents = @()
        Status = "Initializing"
    }
    
    return $Manifest
}

function Create-SystemRestorePoint {
    Write-LogMessage "Creating comprehensive system restore point..."
    
    try {
        # Enable System Restore if not enabled
        $SystemDrive = $env:SystemDrive
        Enable-ComputerRestore -Drive $SystemDrive
        Write-LogMessage "System Restore enabled for drive $SystemDrive"
        
        # Create restore point with detailed description
        $Description = "FixMyShit Phase 2 - Security Hardening and Recovery Backup - $Timestamp"
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
        Write-LogMessage "System restore point created: $Description"
        
        # Get the restore point we just created
        $RestorePoints = Get-ComputerRestorePoint | Sort-Object CreationTime -Descending | Select-Object -First 1
        if ($RestorePoints) {
            Write-LogMessage "Restore point created successfully - Sequence Number: $($RestorePoints.SequenceNumber)"
            
            # Document restore point details
            $RestorePointInfo = @{
                SequenceNumber = $RestorePoints.SequenceNumber
                Description = $RestorePoints.Description
                CreationTime = $RestorePoints.CreationTime
                RestorePointType = $RestorePoints.RestorePointType
            }
            
            $RestorePointInfo | ConvertTo-Json -Depth 2 | Set-Content -Path "$BackupPath\Documentation\RestorePoint.json"
            Write-LogMessage "Restore point details documented"
            
            return $RestorePointInfo
        } else {
            Write-LogMessage "Could not verify restore point creation" "WARNING"
            return $null
        }
        
    } catch {
        Write-LogMessage "Error creating system restore point: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Backup-RegistryAreas {
    Write-LogMessage "Backing up critical registry areas..."
    
    try {
        # Define critical registry keys to backup
        $RegistryKeys = @(
            @{
                Key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
                File = "HKLM_Run.reg"
                Description = "System startup programs"
            },
            @{
                Key = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
                File = "HKCU_Run.reg"
                Description = "User startup programs"
            },
            @{
                Key = "HKLM\SYSTEM\CurrentControlSet\Services"
                File = "Services.reg"
                Description = "Windows services configuration"
            },
            @{
                Key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"
                File = "SystemPolicies.reg"
                Description = "System policies"
            },
            @{
                Key = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies"
                File = "UserPolicies.reg"
                Description = "User policies"
            },
            @{
                Key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
                File = "WindowsUpdate.reg"
                Description = "Windows Update policies"
            },
            @{
                Key = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                File = "Winlogon.reg"
                Description = "Windows logon configuration"
            },
            @{
                Key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
                File = "Explorer.reg"
                Description = "Windows Explorer settings"
            }
        )
        
        $BackupResults = @()
        
        foreach ($RegKey in $RegistryKeys) {
            try {
                $RegFile = "$BackupPath\Registry\$($RegKey.File)"
                $ExportResult = reg export $RegKey.Key $RegFile /y 2>$null
                
                if (Test-Path $RegFile) {
                    $FileSize = (Get-Item $RegFile).Length
                    Write-LogMessage "Exported $($RegKey.Description): $($RegKey.Key) ($FileSize bytes)"
                    
                    $BackupResults += @{
                        Key = $RegKey.Key
                        File = $RegKey.File
                        Description = $RegKey.Description
                        BackupPath = $RegFile
                        Size = $FileSize
                        Status = "Success"
                        Timestamp = (Get-Date).ToString()
                    }
                } else {
                    Write-LogMessage "Failed to export registry key: $($RegKey.Key)" "WARNING"
                    $BackupResults += @{
                        Key = $RegKey.Key
                        File = $RegKey.File
                        Description = $RegKey.Description
                        Status = "Failed"
                        Error = "Export operation failed"
                        Timestamp = (Get-Date).ToString()
                    }
                }
            } catch {
                Write-LogMessage "Error exporting $($RegKey.Key): $($_.Exception.Message)" "ERROR"
                $BackupResults += @{
                    Key = $RegKey.Key
                    File = $RegKey.File
                    Description = $RegKey.Description
                    Status = "Error"
                    Error = $_.Exception.Message
                    Timestamp = (Get-Date).ToString()
                }
            }
        }
        
        # Save registry backup manifest
        $BackupResults | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupPath\Documentation\RegistryBackup.json"
        Write-LogMessage "Registry backup manifest created"
        
        return $BackupResults
        
    } catch {
        Write-LogMessage "Error during registry backup: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Export-SecurityConfigurations {
    Write-LogMessage "Exporting current security configurations..."
    
    try {
        $SecurityBackups = @()
        
        # Export security policy
        $SecurityPolicyFile = "$BackupPath\Security\SecurityPolicy.inf"
        $SecEditResult = secedit /export /cfg $SecurityPolicyFile 2>$null
        if (Test-Path $SecurityPolicyFile) {
            Write-LogMessage "Security policy exported successfully"
            $SecurityBackups += @{
                Type = "SecurityPolicy"
                File = "SecurityPolicy.inf"
                Status = "Success"
            }
        } else {
            Write-LogMessage "Failed to export security policy" "WARNING"
            $SecurityBackups += @{
                Type = "SecurityPolicy"
                File = "SecurityPolicy.inf"
                Status = "Failed"
            }
        }
        
        # Export firewall configuration
        $FirewallFile = "$BackupPath\Security\FirewallConfig.wfw"
        $FirewallResult = netsh advfirewall export $FirewallFile 2>$null
        if (Test-Path $FirewallFile) {
            Write-LogMessage "Firewall configuration exported successfully"
            $SecurityBackups += @{
                Type = "FirewallConfig"
                File = "FirewallConfig.wfw"
                Status = "Success"
            }
        } else {
            Write-LogMessage "Failed to export firewall configuration" "WARNING"
            $SecurityBackups += @{
                Type = "FirewallConfig"
                File = "FirewallConfig.wfw"
                Status = "Failed"
            }
        }
        
        # Export audit policies
        $AuditFile = "$BackupPath\Security\AuditPolicies.csv"
        $AuditResult = auditpol /get /category:* /r | Out-File -FilePath $AuditFile -Encoding UTF8
        if (Test-Path $AuditFile) {
            Write-LogMessage "Audit policies exported successfully"
            $SecurityBackups += @{
                Type = "AuditPolicies"
                File = "AuditPolicies.csv"
                Status = "Success"
            }
        } else {
            Write-LogMessage "Failed to export audit policies" "WARNING"
            $SecurityBackups += @{
                Type = "AuditPolicies"
                File = "AuditPolicies.csv"
                Status = "Failed"
            }
        }
        
        # Export Windows Defender settings
        try {
            $DefenderSettings = Get-MpPreference | ConvertTo-Json -Depth 3
            $DefenderFile = "$BackupPath\Security\DefenderSettings.json"
            $DefenderSettings | Set-Content -Path $DefenderFile
            Write-LogMessage "Windows Defender settings exported successfully"
            $SecurityBackups += @{
                Type = "DefenderSettings"
                File = "DefenderSettings.json"
                Status = "Success"
            }
        } catch {
            Write-LogMessage "Failed to export Windows Defender settings: $($_.Exception.Message)" "WARNING"
            $SecurityBackups += @{
                Type = "DefenderSettings"
                File = "DefenderSettings.json"
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
        
        # Export UAC settings
        try {
            $UACSettings = @{
                EnableLUA = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA").EnableLUA
                ConsentPromptBehaviorAdmin = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin").ConsentPromptBehaviorAdmin
                ConsentPromptBehaviorUser = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser").ConsentPromptBehaviorUser
                PromptOnSecureDesktop = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop").PromptOnSecureDesktop
            }
            $UACFile = "$BackupPath\Security\UACSettings.json"
            $UACSettings | ConvertTo-Json | Set-Content -Path $UACFile
            Write-LogMessage "UAC settings exported successfully"
            $SecurityBackups += @{
                Type = "UACSettings"
                File = "UACSettings.json"
                Status = "Success"
            }
        } catch {
            Write-LogMessage "Failed to export UAC settings: $($_.Exception.Message)" "WARNING"
            $SecurityBackups += @{
                Type = "UACSettings"
                File = "UACSettings.json"
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
        
        # Save security backup manifest
        $SecurityBackups | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupPath\Documentation\SecurityBackup.json"
        Write-LogMessage "Security backup manifest created"
        
        return $SecurityBackups
        
    } catch {
        Write-LogMessage "Error during security configuration export: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Backup-AzureEnvironment {
    Write-LogMessage "Creating backup of Azure AI environment settings..."
    
    try {
        $AzureBackups = @()
        $AzureEnvPath = "C:\FixMyShit\azure-ai-envsource"
        $McpServerPath = "C:\FixMyShit\azure-ai-mcp-server"
        
        # Backup Python virtual environment configuration
        if (Test-Path "$AzureEnvPath\pyvenv.cfg") {
            Copy-Item -Path "$AzureEnvPath\pyvenv.cfg" -Destination "$BackupPath\AzureEnvironment\pyvenv.cfg" -Force
            Write-LogMessage "Python virtual environment configuration backed up"
            $AzureBackups += @{
                Type = "PythonVenvConfig"
                SourcePath = "$AzureEnvPath\pyvenv.cfg"
                BackupPath = "$BackupPath\AzureEnvironment\pyvenv.cfg"
                Status = "Success"
            }
        } else {
            Write-LogMessage "Python virtual environment configuration not found" "WARNING"
            $AzureBackups += @{
                Type = "PythonVenvConfig"
                Status = "NotFound"
            }
        }
        
        # Backup installed packages list
        if (Test-Path "$AzureEnvPath\Scripts\pip.exe") {
            try {
                $PipList = & "$AzureEnvPath\Scripts\pip.exe" list --format=freeze
                $PipList | Set-Content -Path "$BackupPath\AzureEnvironment\requirements.txt"
                Write-LogMessage "Python packages list backed up"
                $AzureBackups += @{
                    Type = "PythonPackages"
                    BackupPath = "$BackupPath\AzureEnvironment\requirements.txt"
                    Status = "Success"
                    PackageCount = ($PipList | Measure-Object).Count
                }
            } catch {
                Write-LogMessage "Failed to backup Python packages list: $($_.Exception.Message)" "WARNING"
                $AzureBackups += @{
                    Type = "PythonPackages"
                    Status = "Failed"
                    Error = $_.Exception.Message
                }
            }
        }
        
        # Backup MCP Server configuration
        if (Test-Path "$McpServerPath\package.json") {
            Copy-Item -Path "$McpServerPath\package.json" -Destination "$BackupPath\AzureEnvironment\mcp-package.json" -Force
            Write-LogMessage "MCP Server package.json backed up"
            $AzureBackups += @{
                Type = "MCPServerConfig"
                SourcePath = "$McpServerPath\package.json"
                BackupPath = "$BackupPath\AzureEnvironment\mcp-package.json"
                Status = "Success"
            }
        } else {
            Write-LogMessage "MCP Server package.json not found" "WARNING"
            $AzureBackups += @{
                Type = "MCPServerConfig"
                Status = "NotFound"
            }
        }
        
        # Backup MCP server main file
        if (Test-Path "$McpServerPath\index.ts") {
            Copy-Item -Path "$McpServerPath\index.ts" -Destination "$BackupPath\AzureEnvironment\mcp-index.ts" -Force
            Write-LogMessage "MCP Server index.ts backed up"
            $AzureBackups += @{
                Type = "MCPServerMain"
                SourcePath = "$McpServerPath\index.ts"
                BackupPath = "$BackupPath\AzureEnvironment\mcp-index.ts"
                Status = "Success"
            }
        }
        
        # Backup development scripts
        $DevFiles = @("azure.py", "deploy_agent.py")
        foreach ($DevFile in $DevFiles) {
            $SourcePath = "C:\FixMyShit\$DevFile"
            if (Test-Path $SourcePath) {
                Copy-Item -Path $SourcePath -Destination "$BackupPath\AzureEnvironment\$DevFile" -Force
                Write-LogMessage "Development file $DevFile backed up"
                $AzureBackups += @{
                    Type = "DevelopmentFile"
                    FileName = $DevFile
                    SourcePath = $SourcePath
                    BackupPath = "$BackupPath\AzureEnvironment\$DevFile"
                    Status = "Success"
                }
            } else {
                Write-LogMessage "Development file $DevFile not found" "WARNING"
                $AzureBackups += @{
                    Type = "DevelopmentFile"
                    FileName = $DevFile
                    Status = "NotFound"
                }
            }
        }
        
        # Test Azure connectivity and document current state
        try {
            $ConnectivityTest = Test-NetConnection -ComputerName "azure.microsoft.com" -Port 443 -InformationLevel Quiet
            $AzureStatus = @{
                ConnectivityTest = $ConnectivityTest
                TestDate = (Get-Date).ToString()
                PythonVersion = if (Test-Path "$AzureEnvPath\Scripts\python.exe") { 
                    & "$AzureEnvPath\Scripts\python.exe" --version 2>&1 
                } else { "Not Available" }
            }
            $AzureStatus | ConvertTo-Json | Set-Content -Path "$BackupPath\AzureEnvironment\connectivity_status.json"
            Write-LogMessage "Azure connectivity status documented"
        } catch {
            Write-LogMessage "Could not test Azure connectivity: $($_.Exception.Message)" "WARNING"
        }
        
        # Save Azure backup manifest
        $AzureBackups | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupPath\Documentation\AzureBackup.json"
        Write-LogMessage "Azure environment backup manifest created"
        
        return $AzureBackups
        
    } catch {
        Write-LogMessage "Error during Azure environment backup: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Document-SystemState {
    Write-LogMessage "Documenting current system state for future reference..."
    
    try {
        # System information
        $SystemInfo = @{
            ComputerName = $env:COMPUTERNAME
            WindowsVersion = (Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, TotalVisibleMemorySize)
            SystemUptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            Processor = (Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed)
            Memory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            Disks = (Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, Size, FreeSpace, @{Name="UsedPercent";Expression={[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)}})
        }
        
        $SystemInfo | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupPath\Documentation\SystemInfo.json"
        Write-LogMessage "System information documented"
        
        # Running services
        $Services = Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object Name, DisplayName, Status, StartType
        $Services | ConvertTo-Json | Set-Content -Path "$BackupPath\Documentation\RunningServices.json"
        Write-LogMessage "Running services documented ($($Services.Count) services)"
        
        # Installed software
        $Software = Get-CimInstance Win32_Product | Select-Object Name, Version, Vendor, InstallDate | Sort-Object Name
        $Software | ConvertTo-Json | Set-Content -Path "$BackupPath\Documentation\InstalledSoftware.json"
        Write-LogMessage "Installed software documented ($($Software.Count) applications)"
        
        # Network configuration
        $NetworkConfig = @{
            Adapters = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object Name, InterfaceDescription, LinkSpeed)
            IPConfiguration = (Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer)
            DNSSettings = (Get-DnsClientServerAddress | Select-Object InterfaceAlias, ServerAddresses)
        }
        $NetworkConfig | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupPath\Documentation\NetworkConfig.json"
        Write-LogMessage "Network configuration documented"
        
        # Security status
        try {
            $SecurityStatus = @{
                WindowsDefender = (Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled, IoavProtectionEnabled, NISEnabled)
                FirewallProfiles = (Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction)
                UACSettings = @{
                    EnableLUA = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
                    ConsentPromptBehaviorAdmin = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue).ConsentPromptBehaviorAdmin
                }
                WindowsUpdate = @{
                    LastSearchSuccessDate = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Search" -Name "LastSuccessTime" -ErrorAction SilentlyContinue).LastSuccessTime
                    LastInstallSuccessDate = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install" -Name "LastSuccessTime" -ErrorAction SilentlyContinue).LastSuccessTime
                }
            }
            $SecurityStatus | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupPath\Documentation\SecurityStatus.json"
            Write-LogMessage "Security status documented"
        } catch {
            Write-LogMessage "Could not document full security status: $($_.Exception.Message)" "WARNING"
        }
        
        # Event log summary
        try {
            $EventLogSummary = @()
            $LogNames = @("System", "Application", "Security")
            foreach ($LogName in $LogNames) {
                $RecentEvents = Get-WinEvent -LogName $LogName -MaxEvents 100 -ErrorAction SilentlyContinue
                if ($RecentEvents) {
                    $ErrorCount = ($RecentEvents | Where-Object {$_.LevelDisplayName -eq "Error"}).Count
                    $WarningCount = ($RecentEvents | Where-Object {$_.LevelDisplayName -eq "Warning"}).Count
                    
                    $EventLogSummary += @{
                        LogName = $LogName
                        TotalEvents = $RecentEvents.Count
                        ErrorCount = $ErrorCount
                        WarningCount = $WarningCount
                        LastEvent = $RecentEvents[0].TimeCreated
                    }
                }
            }
            $EventLogSummary | ConvertTo-Json | Set-Content -Path "$BackupPath\Documentation\EventLogSummary.json"
            Write-LogMessage "Event log summary documented"
        } catch {
            Write-LogMessage "Could not document event log summary: $($_.Exception.Message)" "WARNING"
        }
        
        return $true
        
    } catch {
        Write-LogMessage "Error documenting system state: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Validate-BackupIntegrity {
    Write-LogMessage "Validating backup integrity and accessibility..."
    
    try {
        $ValidationResults = @()
        
        # Check backup directory structure
        $RequiredDirs = @("Registry", "Security", "AzureEnvironment", "SystemState", "Logs", "Documentation")
        foreach ($Dir in $RequiredDirs) {
            $DirPath = "$BackupPath\$Dir"
            if (Test-Path $DirPath) {
                $FileCount = (Get-ChildItem $DirPath -File -ErrorAction SilentlyContinue).Count
                $ValidationResults += @{
                    Type = "Directory"
                    Name = $Dir
                    Status = "Exists"
                    FileCount = $FileCount
                }
                Write-LogMessage "Backup directory $Dir validated ($FileCount files)"
            } else {
                $ValidationResults += @{
                    Type = "Directory"
                    Name = $Dir
                    Status = "Missing"
                }
                Write-LogMessage "Backup directory $Dir is missing" "WARNING"
            }
        }
        
        # Validate critical backup files
        $CriticalFiles = @(
            "$BackupPath\Documentation\RestorePoint.json",
            "$BackupPath\Documentation\RegistryBackup.json",
            "$BackupPath\Documentation\SecurityBackup.json",
            "$BackupPath\Documentation\AzureBackup.json",
            "$BackupPath\Documentation\SystemInfo.json"
        )
        
        foreach ($File in $CriticalFiles) {
            if (Test-Path $File) {
                try {
                    $Content = Get-Content $File | ConvertFrom-Json -ErrorAction Stop
                    $ValidationResults += @{
                        Type = "File"
                        Name = (Split-Path $File -Leaf)
                        Status = "Valid"
                        Size = (Get-Item $File).Length
                    }
                    Write-LogMessage "File $(Split-Path $File -Leaf) validated"
                } catch {
                    $ValidationResults += @{
                        Type = "File"
                        Name = (Split-Path $File -Leaf)
                        Status = "Corrupted"
                        Error = $_.Exception.Message
                    }
                    Write-LogMessage "File $(Split-Path $File -Leaf) appears corrupted" "ERROR"
                }
            } else {
                $ValidationResults += @{
                    Type = "File"
                    Name = (Split-Path $File -Leaf)
                    Status = "Missing"
                }
                Write-LogMessage "Critical file $(Split-Path $File -Leaf) is missing" "WARNING"
            }
        }
        
        # Calculate total backup size
        $BackupSize = (Get-ChildItem $BackupPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $BackupSizeMB = [math]::Round($BackupSize / 1MB, 2)
        Write-LogMessage "Total backup size: ${BackupSizeMB}MB"
        
        # Save validation results
        $ValidationSummary = @{
            ValidationDate = (Get-Date).ToString()
            BackupPath = $BackupPath
            TotalBackupSize = $BackupSize
            TotalBackupSizeMB = $BackupSizeMB
            ValidationResults = $ValidationResults
            OverallStatus = if (($ValidationResults | Where-Object {$_.Status -eq "Missing" -or $_.Status -eq "Corrupted"}).Count -eq 0) { "Valid" } else { "Issues Found" }
        }
        
        $ValidationSummary | ConvertTo-Json -Depth 4 | Set-Content -Path "$BackupPath\Documentation\ValidationReport.json"
        Write-LogMessage "Backup validation report saved"
        
        return $ValidationSummary
        
    } catch {
        Write-LogMessage "Error during backup validation: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Create-RestoreInstructions {
    Write-LogMessage "Creating restore instructions for backup recovery..."
    
    $RestoreInstructions = @'
# SYSTEM BACKUP RESTORE INSTRUCTIONS

## Overview
This backup was created by the FixMyShit Phase 2 security hardening and recovery system.
Use these instructions to restore various components if needed.

## System Restore Point
To revert to the system restore point:
1. Open System Properties (sysdm.cpl)
2. Click "System Restore"
3. Select "Choose a different restore point"
4. Find the restore point with sequence number from RestorePoint.json
5. Follow the wizard to complete restoration

## Registry Restoration
To restore registry keys:
1. Open Registry Editor (regedit.exe) as Administrator
2. Navigate to File > Import
3. Import the desired .reg file from the Registry folder
4. Restart the computer if prompted

## Security Configuration Restoration
- Firewall: Run "netsh advfirewall import [path-to-FirewallConfig.wfw]"
- Security Policy: Run "secedit /configure /db %systemroot%\security\local.sdb /cfg [path-to-SecurityPolicy.inf]"
- Audit Policies: Review AuditPolicies.csv and apply manually using auditpol command

## Azure AI Environment Restoration
1. Ensure Python is installed and accessible
2. Create new virtual environment: python -m venv azure-ai-envsource
3. Activate environment: azure-ai-envsource\Scripts\activate
4. Install packages: pip install -r requirements.txt
5. Copy back development files (azure.py, deploy_agent.py)
6. Restore MCP server configuration

## Validation
After restoration:
1. Run recovery_verification.ps1 to validate system state
2. Test Azure connectivity and development environment
3. Verify security settings are properly applied

## Emergency Contacts
- Check Windows Event Log for restoration errors
- Review backup validation report in Documentation folder
- Contact system administrator if issues persist

## Backup Metadata
Backup ID: {BACKUP_ID}
Creation Date: {BACKUP_DATE}
Computer: {COMPUTER_NAME}
Windows Version: {WINDOWS_VERSION}
'@

    # Replace placeholders with actual values
    $RestoreInstructions = $RestoreInstructions -replace '\{BACKUP_ID\}', $Timestamp
    $RestoreInstructions = $RestoreInstructions -replace '\{BACKUP_DATE\}', (Get-Date).ToString()
    $RestoreInstructions = $RestoreInstructions -replace '\{COMPUTER_NAME\}', $env:COMPUTERNAME
    $RestoreInstructions = $RestoreInstructions -replace '\{WINDOWS_VERSION\}', (Get-CimInstance Win32_OperatingSystem).Caption
    
    Set-Content -Path "$BackupPath\RESTORE_INSTRUCTIONS.txt" -Value $RestoreInstructions
    Write-LogMessage "Restore instructions created"
}

# Main execution
Write-LogMessage "========== System Backup and Restore Script Started =========="
Write-LogMessage "Log file: $LogPath"
Write-LogMessage "Backup location: $BackupPath"

# Verify administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-LogMessage "This script requires administrator privileges. Please run as administrator." "ERROR"
    exit 1
}

# Set default to all operations if no specific parameters
if (-not ($CreateRestorePoint -or $BackupRegistry -or $BackupSecurity -or $BackupAzureEnvironment -or $ValidateBackups)) {
    $All = $true
}

# Initialize backup structure
$Manifest = Initialize-BackupStructure

# Execute backup operations
Write-Host "`n=== CREATING SYSTEM RESTORE POINT ===" -ForegroundColor Cyan
if ($All -or $CreateRestorePoint) {
    $RestorePointInfo = Create-SystemRestorePoint
    if ($RestorePointInfo) {
        $Manifest.BackupComponents += "SystemRestorePoint"
    }
}

Write-Host "`n=== BACKING UP REGISTRY AREAS ===" -ForegroundColor Cyan
if ($All -or $BackupRegistry) {
    $RegistryResults = Backup-RegistryAreas
    if ($RegistryResults.Count -gt 0) {
        $Manifest.BackupComponents += "RegistryBackup"
    }
}

Write-Host "`n=== EXPORTING SECURITY CONFIGURATIONS ===" -ForegroundColor Cyan
if ($All -or $BackupSecurity) {
    $SecurityResults = Export-SecurityConfigurations
    if ($SecurityResults.Count -gt 0) {
        $Manifest.BackupComponents += "SecurityConfigurations"
    }
}

Write-Host "`n=== BACKING UP AZURE AI ENVIRONMENT ===" -ForegroundColor Cyan
if ($All -or $BackupAzureEnvironment) {
    $AzureResults = Backup-AzureEnvironment
    if ($AzureResults.Count -gt 0) {
        $Manifest.BackupComponents += "AzureEnvironment"
    }
}

Write-Host "`n=== DOCUMENTING SYSTEM STATE ===" -ForegroundColor Cyan
$SystemStateResult = Document-SystemState
if ($SystemStateResult) {
    $Manifest.BackupComponents += "SystemState"
}

Write-Host "`n=== VALIDATING BACKUP INTEGRITY ===" -ForegroundColor Cyan
if ($All -or $ValidateBackups) {
    $ValidationResult = Validate-BackupIntegrity
    if ($ValidationResult) {
        $Manifest.BackupComponents += "ValidationReport"
    }
}

Write-Host "`n=== CREATING RESTORE INSTRUCTIONS ===" -ForegroundColor Cyan
Create-RestoreInstructions

# Finalize manifest
$Manifest.Status = "Completed"
$Manifest.CompletionDate = (Get-Date).ToString()
$Manifest | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupPath\BACKUP_MANIFEST.json"

Write-LogMessage "========== System Backup and Restore Script Completed =========="

# Display summary
Write-Host "`n=== BACKUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "✓ System restore point created" -ForegroundColor Green
Write-Host "✓ Critical registry areas backed up" -ForegroundColor Green
Write-Host "✓ Security configurations exported" -ForegroundColor Green
Write-Host "✓ Azure AI environment backed up" -ForegroundColor Green
Write-Host "✓ System state documented" -ForegroundColor Green
Write-Host "✓ Backup integrity validated" -ForegroundColor Green
Write-Host "✓ Restore instructions created" -ForegroundColor Green

$BackupSize = (Get-ChildItem $BackupPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
$BackupSizeMB = [math]::Round($BackupSize / 1MB, 2)

Write-Host "`nBackup Location: $BackupPath" -ForegroundColor White
Write-Host "Backup Size: ${BackupSizeMB}MB" -ForegroundColor White
Write-Host "Backup ID: $Timestamp" -ForegroundColor White
Write-Host "`nReview RESTORE_INSTRUCTIONS.txt for recovery procedures" -ForegroundColor Cyan
Write-Host "Backup manifest available at: $BackupPath\BACKUP_MANIFEST.json" -ForegroundColor Cyan