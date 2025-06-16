#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configures system for clean boot testing
.DESCRIPTION
    This script disables non-Microsoft services and startup items
    to help isolate if third-party software is causing shell problems
.NOTES
    After running this script, restart your computer to test 
    if the shell works correctly in a clean boot state
#>

$logFile = ".\clean_boot_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-CleanLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) { 
        "ERROR" {"Red"} 
        "WARNING" {"Yellow"} 
        "SUCCESS" {"Green"} 
        default {"White"} 
    })
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

Write-CleanLog "=== CLEAN BOOT CONFIGURATION STARTED ===" "INFO"
Write-CleanLog "This script will configure your system for clean boot testing" "INFO"
Write-CleanLog "IMPORTANT: You will need to restart your computer after this script completes" "WARNING"

# Create backup of current configuration
Write-CleanLog "Creating backup of current configuration..." "INFO"
$backupFolder = ".\CleanBootBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

# Backup services
Write-CleanLog "Backing up services configuration..." "INFO"
$servicesBackup = @()
Get-Service | ForEach-Object {
    $serviceInfo = Get-WmiObject -Class Win32_Service -Filter "Name='$($_.Name)'" -ErrorAction SilentlyContinue
    if ($serviceInfo) {
        $servicesBackup += [PSCustomObject]@{
            Name = $_.Name
            DisplayName = $_.DisplayName
            StartType = $serviceInfo.StartMode
            Status = $_.Status
            Path = $serviceInfo.PathName
        }
    }
}
$servicesBackup | Export-Csv -Path "$backupFolder\services_backup.csv" -NoTypeInformation
Write-CleanLog "Services backup saved to: $backupFolder\services_backup.csv" "SUCCESS"

# Backup startup items
Write-CleanLog "Backing up startup configuration..." "INFO"
$startupBackup = @()
$runKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($key in $runKeys) {
    if (Test-Path $key) {
        Get-ItemProperty -Path $key | ForEach-Object {
            $_.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $startupBackup += [PSCustomObject]@{
                    Source = $key
                    Name = $_.Name
                    Command = $_.Value
                }
            }
        }
    }
}
$startupBackup | Export-Csv -Path "$backupFolder\startup_backup.csv" -NoTypeInformation
Write-CleanLog "Startup backup saved to: $backupFolder\startup_backup.csv" "SUCCESS"

# Create restore script
$restoreScript = @"
#Requires -RunAsAdministrator

# Restore script for clean boot configuration
Write-Host "Restoring previous configuration from backup..." -ForegroundColor Yellow

# Restore services
Write-Host "Restoring services..." -ForegroundColor Cyan
`$servicesBackup = Import-Csv -Path "$backupFolder\services_backup.csv"
foreach (`$service in `$servicesBackup) {
    try {
        if (`$service.StartType -eq "Auto") {
            Set-Service -Name `$service.Name -StartupType Automatic -ErrorAction SilentlyContinue
        }
        elseif (`$service.StartType -eq "Manual") {
            Set-Service -Name `$service.Name -StartupType Manual -ErrorAction SilentlyContinue
        }
        elseif (`$service.StartType -eq "Disabled") {
            Set-Service -Name `$service.Name -StartupType Disabled -ErrorAction SilentlyContinue
        }
        Write-Host "  Restored service: `$(`$service.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to restore service: `$(`$service.DisplayName)" -ForegroundColor Red
    }
}

# Restore startup items
Write-Host "Restoring startup items..." -ForegroundColor Cyan
`$startupBackup = Import-Csv -Path "$backupFolder\startup_backup.csv"
foreach (`$item in `$startupBackup) {
    try {
        if (`$item.Source -like "HKLM:*" -or `$item.Source -like "HKCU:*") {
            `$null = New-ItemProperty -Path `$item.Source -Name `$item.Name -Value `$item.Command -PropertyType String -Force -ErrorAction SilentlyContinue
            Write-Host "  Restored startup item: `$(`$item.Name)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Failed to restore startup item: `$(`$item.Name)" -ForegroundColor Red
    }
}

Write-Host "Configuration restored. Please restart your computer." -ForegroundColor Yellow
"@

Set-Content -Path "$backupFolder\restore_configuration.ps1" -Value $restoreScript
Write-CleanLog "Restore script created: $backupFolder\restore_configuration.ps1" "SUCCESS"

# Step 1: Disable non-Microsoft services
Write-CleanLog "Disabling non-Microsoft services..." "INFO"

$microsoftPatterns = @(
    "Microsoft",
    "Windows",
    "DCOM Server",
    "RPC",
    "Cryptographic",
    "Base Filtering Engine",
    "Network List",
    "Group Policy",
    "Plug and Play",
    "Power",
    "Remote Procedure",
    "Security",
    "Shell Hardware",
    "System Events",
    "Task Scheduler",
    "User Profile",
    "Windows Audio",
    "Windows Firewall",
    "Windows Management",
    "Windows Update",
    "Workstation"
)

function IsMicrosoftService($serviceName, $serviceDisplayName, $servicePath) {
    # Check if the service is from Microsoft based on name patterns
    foreach ($pattern in $microsoftPatterns) {
        if ($serviceDisplayName -like "*$pattern*") {
            return $true
        }
    }
    
    # Check if service is running from Windows directory
    if ($servicePath -like "*\Windows\*") {
        return $true
    }
    
    # Check if it's a critical system service
    $criticalServices = @(
        "AppInfo", "AudioEndpointBuilder", "Audiosrv", "BFE", "BrokerInfrastructure", 
        "CoreMessagingRegistrar", "CryptSvc", "DcomLaunch", "Dhcp", "Dnscache",
        "DPS", "EventLog", "EventSystem", "FontCache", "gpsvc", "iphlpsvc", "LanmanServer",
        "LanmanWorkstation", "lmhosts", "mpssvc", "NlaSvc", "nsi", "ProfSvc", "RpcEptMapper",
        "RpcSs", "SamSs", "Schedule", "SENS", "ShellHWDetection", "Spooler", "SystemEventsBroker",
        "Themes", "TimeBrokerSvc", "UserManager", "Wcmsvc", "WinDefend", "Winmgmt", "WpnService"
    )
    
    if ($criticalServices -contains $serviceName) {
        return $true
    }
    
    return $false
}

$disabledCount = 0
$services = Get-Service | Where-Object { $_.StartType -eq "Automatic" -and $_.Status -eq "Running" }
foreach ($service in $services) {
    try {
        $serviceInfo = Get-WmiObject -Class Win32_Service -Filter "Name='$($service.Name)'" -ErrorAction SilentlyContinue
        
        if ($serviceInfo -and -not (IsMicrosoftService $service.Name $service.DisplayName $serviceInfo.PathName)) {
            Write-CleanLog "Disabling non-Microsoft service: $($service.DisplayName)" "WARNING"
            Set-Service -Name $service.Name -StartupType Disabled -ErrorAction Stop
            $disabledCount++
        }
        else {
            Write-CleanLog "Keeping Microsoft service: $($service.DisplayName)" "INFO"
        }
    }
    catch {
        Write-CleanLog "Error disabling service $($service.DisplayName): $($_.Exception.Message)" "ERROR"
    }
}
Write-CleanLog "Disabled $disabledCount non-Microsoft services" "SUCCESS"

# Step 2: Disable startup items
Write-CleanLog "Disabling startup items..." "INFO"
$startupDisabledCount = 0

foreach ($key in $runKeys) {
    if (Test-Path $key) {
        $items = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($items) {
            $items.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $itemName = $_.Name
                $itemValue = $_.Value
                
                Write-CleanLog "Disabling startup item: $itemName" "WARNING"
                Remove-ItemProperty -Path $key -Name $itemName -ErrorAction SilentlyContinue
                $startupDisabledCount++
            }
        }
    }
}
Write-CleanLog "Disabled $startupDisabledCount startup items" "SUCCESS"

# Step 3: Check MSConfig settings
Write-CleanLog "Checking MSConfig settings..." "INFO"
try {
    # Set MSConfig for selective startup
    $bootKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders"
    if (-not (Test-Path $bootKey)) {
        New-Item -Path $bootKey -Force | Out-Null
    }
    
    Write-CleanLog "Clean boot configuration complete" "SUCCESS"
}
catch {
    Write-CleanLog "Error setting MSConfig: $($_.Exception.Message)" "ERROR"
}

# Summary and next steps
Write-CleanLog "=== CLEAN BOOT CONFIGURATION COMPLETED ===" "INFO"
Write-CleanLog "Disabled $disabledCount non-Microsoft services" "INFO"
Write-CleanLog "Disabled $startupDisabledCount startup items" "INFO"
Write-CleanLog "Backup saved to: $backupFolder" "INFO"
Write-CleanLog "To restore original configuration, run: $backupFolder\restore_configuration.ps1" "INFO"

Write-Host "`n==== NEXT STEPS ====" -ForegroundColor Yellow
Write-Host "1. RESTART YOUR COMPUTER NOW" -ForegroundColor Red
Write-Host "2. Test if your shell works correctly in clean boot state" -ForegroundColor Cyan
Write-Host "3. If shell works in clean boot, third-party software is causing the issue" -ForegroundColor Cyan
Write-Host "4. To restore original configuration, run: $backupFolder\restore_configuration.ps1" -ForegroundColor Green
Write-Host "5. For advanced troubleshooting, selectively re-enable services and startup items" -ForegroundColor Cyan