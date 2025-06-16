#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Emergency Malware Cleanup Script - IMMEDIATE RESPONSE
.DESCRIPTION
    Removes malware artifacts, cleans registry entries, terminates malicious processes,
    removes scheduled tasks, and quarantines suspicious files.
.NOTES
    Author: Kilo Code - Emergency Malware Response
    Version: 1.0
    Created: 2025-06-14
    CRITICAL: Run with Administrator privileges
    WARNING: This script makes system changes - create backup first
#>

param(
    [string]$LogPath = ".\emergency_cleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log",
    [string]$QuarantinePath = ".\Quarantine",
    [switch]$Force = $false,
    [switch]$DryRun = $false
)

# Initialize logging
function Write-LogMessage {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) { "ERROR" {"Red"} "WARNING" {"Yellow"} "SUCCESS" {"Green"} default {"White"} })
    Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

# Progress tracking
$global:TotalTasks = 8
$global:CurrentTask = 0

function Update-Progress {
    param([string]$Activity, [string]$Status)
    $global:CurrentTask++
    $percentComplete = [math]::Round(($global:CurrentTask / $global:TotalTasks) * 100)
    Write-Progress -Activity "Emergency Malware Cleanup" -Status "$Activity - $Status" -PercentComplete $percentComplete
}

# Create quarantine directory
function Initialize-Quarantine {
    if (-not (Test-Path $QuarantinePath)) {
        try {
            New-Item -Path $QuarantinePath -ItemType Directory -Force | Out-Null
            Write-LogMessage "Created quarantine directory: $QuarantinePath" "SUCCESS"
        }
        catch {
            Write-LogMessage "Failed to create quarantine directory: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    return $true
}

# Quarantine suspicious file
function Move-ToQuarantine {
    param([string]$FilePath, [string]$Reason)
    
    if (-not (Test-Path $FilePath)) {
        Write-LogMessage "File not found for quarantine: $FilePath" "WARNING"
        return $false
    }
    
    try {
        $fileName = Split-Path $FilePath -Leaf
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $quarantineFile = Join-Path $QuarantinePath "$fileName.$timestamp.quarantine"
        
        if ($DryRun) {
            Write-LogMessage "[DRY RUN] Would quarantine: $FilePath -> $quarantineFile (Reason: $Reason)" "INFO"
        }
        else {
            Move-Item -Path $FilePath -Destination $quarantineFile -Force
            Write-LogMessage "Quarantined file: $FilePath -> $quarantineFile (Reason: $Reason)" "SUCCESS"
            
            # Create metadata file
            $metadata = @{
                OriginalPath = $FilePath
                QuarantineTime = Get-Date
                Reason = $Reason
                FileHash = (Get-FileHash -Path $quarantineFile -Algorithm SHA256).Hash
            } | ConvertTo-Json
            
            Set-Content -Path "$quarantineFile.metadata" -Value $metadata
        }
        return $true
    }
    catch {
        Write-LogMessage "Failed to quarantine $FilePath : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Terminate malicious process
function Stop-MaliciousProcess {
    param([string]$ProcessName, [int]$ProcessId, [string]$Reason)
    
    try {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($process) {
            if ($DryRun) {
                Write-LogMessage "[DRY RUN] Would terminate process: $ProcessName (PID: $ProcessId) - $Reason" "INFO"
            }
            else {
                $process | Stop-Process -Force
                Write-LogMessage "Terminated malicious process: $ProcessName (PID: $ProcessId) - $Reason" "SUCCESS"
            }
            return $true
        }
        else {
            Write-LogMessage "Process not found: $ProcessName (PID: $ProcessId)" "WARNING"
            return $false
        }
    }
    catch {
        Write-LogMessage "Failed to terminate process $ProcessName (PID: $ProcessId): $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Remove malicious scheduled task
function Remove-MaliciousTask {
    param([string]$TaskName, [string]$Reason)
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            if ($DryRun) {
                Write-LogMessage "[DRY RUN] Would remove scheduled task: $TaskName - $Reason" "INFO"
            }
            else {
                Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
                Write-LogMessage "Removed malicious scheduled task: $TaskName - $Reason" "SUCCESS"
            }
            return $true
        }
        else {
            Write-LogMessage "Scheduled task not found: $TaskName" "WARNING"
            return $false
        }
    }
    catch {
        Write-LogMessage "Failed to remove scheduled task $TaskName : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Clean registry entry
function Remove-MaliciousRegistryEntry {
    param([string]$RegistryPath, [string]$ValueName, [string]$Reason)
    
    try {
        if (Test-Path $RegistryPath) {
            $property = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue
            if ($property) {
                if ($DryRun) {
                    Write-LogMessage "[DRY RUN] Would remove registry entry: $RegistryPath\$ValueName - $Reason" "INFO"
                }
                else {
                    Remove-ItemProperty -Path $RegistryPath -Name $ValueName -Force
                    Write-LogMessage "Removed malicious registry entry: $RegistryPath\$ValueName - $Reason" "SUCCESS"
                }
                return $true
            }
        }
        Write-LogMessage "Registry entry not found: $RegistryPath\$ValueName" "WARNING"
        return $false
    }
    catch {
        Write-LogMessage "Failed to remove registry entry $RegistryPath\$ValueName : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

try {
    Write-LogMessage "=== EMERGENCY MALWARE CLEANUP INITIATED ===" "WARNING"
    Write-LogMessage "Cleanup started at: $(Get-Date)"
    Write-LogMessage "Log file: $LogPath"
    Write-LogMessage "Quarantine path: $QuarantinePath"
    if ($DryRun) { Write-LogMessage "DRY RUN MODE - No changes will be made" "WARNING" }

    # Initialize quarantine directory
    if (-not (Initialize-Quarantine)) {
        throw "Failed to initialize quarantine directory"
    }

    # Task 1: Remove known malware artifacts
    Update-Progress "Artifact Removal" "Removing known malware files"
    
    $KnownMalwareFiles = @(
        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\app.lnk",
        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup\APP.LNK"
    )
    
    foreach ($malwareFile in $KnownMalwareFiles) {
        if (Test-Path $malwareFile) {
            Move-ToQuarantine -FilePath $malwareFile -Reason "Known malware: Backdoor.Agent.E"
        }
    }

    # Task 2: Clean suspicious startup entries
    Update-Progress "Startup Cleanup" "Removing malicious startup entries"
    
    $StartupKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    )

    foreach ($key in $StartupKeys) {
        try {
            $entries = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            if ($entries) {
                $entries.PSObject.Properties | ForEach-Object {
                    if ($_.Name -notmatch "^PS" -and $_.Value) {
                        # Check for suspicious patterns
                        if ($_.Value -match "(temp|appdata|programdata)" -and $_.Value -notmatch "(microsoft|windows)" -and $_.Name -match "(app|update|service)") {
                            Remove-MaliciousRegistryEntry -RegistryPath $key -ValueName $_.Name -Reason "Suspicious startup entry"
                        }
                    }
                }
            }
        }
        catch {
            Write-LogMessage "Error cleaning startup key $key : $($_.Exception.Message)" "ERROR"
        }
    }

    # Task 3: Terminate suspicious processes
    Update-Progress "Process Termination" "Stopping malicious processes"
    
    $processes = Get-Process
    foreach ($proc in $processes) {
        try {
            $procPath = $proc.Path
            if ($procPath) {
                # Terminate processes from suspicious locations
                if ($procPath -match "(temp|appdata|programdata)" -and $procPath -notmatch "(microsoft|windows)" -and $proc.Name -match "(app|update|service)") {
                    Stop-MaliciousProcess -ProcessName $proc.Name -ProcessId $proc.Id -Reason "Process running from suspicious location"
                }
                
                # Check for system processes in wrong locations
                $systemProcesses = @("svchost.exe", "winlogon.exe", "explorer.exe", "lsass.exe", "csrss.exe")
                if ($proc.Name -in $systemProcesses -and $procPath -notmatch "system32") {
                    Stop-MaliciousProcess -ProcessName $proc.Name -ProcessId $proc.Id -Reason "System process in wrong location"
                }
            }
        }
        catch {
            # Process may have exited
        }
    }

    # Task 4: Remove malicious scheduled tasks
    Update-Progress "Task Cleanup" "Removing malicious scheduled tasks"
    
    try {
        $tasks = Get-ScheduledTask | Where-Object { $_.State -eq "Ready" -or $_.State -eq "Running" }
        foreach ($task in $tasks) {
            $actions = (Get-ScheduledTask -TaskName $task.TaskName).Actions
            
            foreach ($action in $actions) {
                if ($action.Execute) {
                    # Remove tasks with suspicious execution paths
                    if ($action.Execute -match "(temp|appdata|programdata)" -and $action.Execute -notmatch "(microsoft|windows)" -and $task.TaskName -match "(app|update|service)") {
                        Remove-MaliciousTask -TaskName $task.TaskName -Reason "Suspicious task execution path"
                    }
                }
            }
        }
    }
    catch {
        Write-LogMessage "Error during task cleanup: $($_.Exception.Message)" "ERROR"
    }

    # Task 5: Stop malicious services
    Update-Progress "Service Cleanup" "Stopping malicious services"
    
    $services = Get-Service | Where-Object { $_.Status -eq "Running" }
    foreach ($service in $services) {
        try {
            $serviceDetails = Get-WmiObject -Class Win32_Service -Filter "Name='$($service.Name)'" -ErrorAction SilentlyContinue
            if ($serviceDetails -and $serviceDetails.PathName) {
                if ($serviceDetails.PathName -match "(temp|appdata|programdata)" -and $serviceDetails.PathName -notmatch "(microsoft|windows)") {
                    if ($DryRun) {
                        Write-LogMessage "[DRY RUN] Would stop suspicious service: $($service.Name)" "INFO"
                    }
                    else {
                        Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                        Set-Service -Name $service.Name -StartupType Disabled -ErrorAction SilentlyContinue
                        Write-LogMessage "Stopped and disabled suspicious service: $($service.Name)" "SUCCESS"
                    }
                }
            }
        }
        catch {
            Write-LogMessage "Error checking service $($service.Name): $($_.Exception.Message)" "ERROR"
        }
    }

    # Task 6: Quarantine suspicious files
    Update-Progress "File Quarantine" "Quarantining suspicious files"
    
    $SuspiciousExtensions = @(".scr", ".pif", ".bat", ".cmd", ".com", ".exe", ".vbs", ".js")
    $MalwareLocations = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:APPDATA",
        "$env:LOCALAPPDATA"
    )

    foreach ($location in $MalwareLocations) {
        if (Test-Path $location) {
            try {
                $suspiciousFiles = Get-ChildItem -Path $location -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $_.LastWriteTime -gt (Get-Date).AddDays(-7) -and 
                        $_.Extension -in $SuspiciousExtensions -and
                        -not $_.PSIsContainer -and
                        $_.Name -match "(app|update|service)" -and
                        $_.Length -lt 10MB
                    } | Select-Object -First 10
                
                foreach ($file in $suspiciousFiles) {
                    Move-ToQuarantine -FilePath $file.FullName -Reason "Recently modified suspicious file"
                }
            }
            catch {
                Write-LogMessage "Error quarantining files in $location : $($_.Exception.Message)" "ERROR"
            }
        }
    }

    # Task 7: Clear temporary folders
    Update-Progress "Temp Cleanup" "Clearing temporary folders"
    
    $TempFolders = @("$env:TEMP", "$env:WINDIR\Temp")
    foreach ($tempFolder in $TempFolders) {
        if (Test-Path $tempFolder) {
            try {
                if ($DryRun) {
                    $items = Get-ChildItem -Path $tempFolder -Force -ErrorAction SilentlyContinue
                    Write-LogMessage "[DRY RUN] Would clean $($items.Count) items from $tempFolder" "INFO"
                }
                else {
                    Get-ChildItem -Path $tempFolder -Force -ErrorAction SilentlyContinue | 
                        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    Write-LogMessage "Cleaned temporary folder: $tempFolder" "SUCCESS"
                }
            }
            catch {
                Write-LogMessage "Error cleaning $tempFolder : $($_.Exception.Message)" "ERROR"
            }
        }
    }

    # Task 8: Force restart Explorer (if not corrupted)
    Update-Progress "Explorer Restart" "Restarting Windows Explorer"
    
    try {
        $explorerProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($explorerProcesses) {
            if ($DryRun) {
                Write-LogMessage "[DRY RUN] Would restart Windows Explorer" "INFO"
            }
            else {
                $explorerProcesses | Stop-Process -Force
                Start-Sleep -Seconds 2
                Start-Process "explorer.exe"
                Write-LogMessage "Restarted Windows Explorer" "SUCCESS"
            }
        }
    }
    catch {
        Write-LogMessage "Error restarting Explorer: $($_.Exception.Message)" "ERROR"
    }

    # Final Summary
    Write-Progress -Activity "Emergency Malware Cleanup" -Completed
    Write-LogMessage "=== EMERGENCY CLEANUP COMPLETED ===" "SUCCESS"
    Write-LogMessage "Cleanup completed at: $(Get-Date)"
    
    # Display summary
    Write-Host "`n=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Log file created: $LogPath" -ForegroundColor Green
    Write-Host "Quarantine directory: $QuarantinePath" -ForegroundColor Green
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No actual changes were made" -ForegroundColor Yellow
        Write-Host "Run without -DryRun parameter to perform actual cleanup" -ForegroundColor Yellow
    }
    else {
        Write-Host "Emergency cleanup completed successfully" -ForegroundColor Green
        Write-Host "Run repair_shell.ps1 to fix Explorer shell issues" -ForegroundColor Yellow
        Write-Host "Run system_integrity.ps1 to verify system integrity" -ForegroundColor Yellow
    }

}
catch {
    Write-LogMessage "CRITICAL ERROR during cleanup: $($_.Exception.Message)" "ERROR"
    Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
finally {
    Write-Progress -Activity "Emergency Malware Cleanup" -Completed
}