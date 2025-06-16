#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Compares startup programs between normal mode and safe mode
.DESCRIPTION
    This script logs all startup programs, services, and processes to help
    identify differences between normal mode and safe mode.
    Run this script in both modes and compare the results.
#>

$mode = if ((Get-WmiObject -Class Win32_ComputerSystem).BootupState -eq "Normal boot") { "NORMAL" } else { "SAFE" }
$logFile = ".\startup_comparison_${mode}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-CompareLog {
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

Write-CompareLog "=== STARTUP COMPARISON STARTED ($mode MODE) ===" "INFO"
Write-CompareLog "This script will log startup items to compare between normal and safe mode" "INFO"
Write-CompareLog "Current boot mode: $mode" "INFO"

# Section 1: Autorun Registry Keys
Write-CompareLog "Checking Autorun Registry Keys..." "INFO"

$autorunKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
)

foreach ($key in $autorunKeys) {
    if (Test-Path $key) {
        Write-CompareLog "Registry Key: $key" "INFO"
        try {
            $values = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            if ($values) {
                $values.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                    Write-CompareLog "  $($_.Name): $($_.Value)" "INFO"
                }
            } else {
                Write-CompareLog "  No entries found" "INFO"
            }
        } catch {
            Write-CompareLog "  Error reading key: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-CompareLog "Registry Key not found: $key" "WARNING"
    }
}

# Section 2: Startup Folders
Write-CompareLog "Checking Startup Folders..." "INFO"

$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)

foreach ($folder in $startupFolders) {
    Write-CompareLog "Startup Folder: $folder" "INFO"
    if (Test-Path $folder) {
        try {
            $items = Get-ChildItem -Path $folder -ErrorAction SilentlyContinue
            if ($items -and $items.Count -gt 0) {
                foreach ($item in $items) {
                    if ($item.Extension -eq ".lnk") {
                        try {
                            $shell = New-Object -ComObject WScript.Shell
                            $shortcut = $shell.CreateShortcut($item.FullName)
                            Write-CompareLog "  $($item.Name) -> $($shortcut.TargetPath)" "INFO"
                        } catch {
                            Write-CompareLog "  $($item.Name) (Could not read shortcut)" "WARNING"
                        }
                    } else {
                        Write-CompareLog "  $($item.Name)" "INFO"
                    }
                }
            } else {
                Write-CompareLog "  No items found" "INFO"
            }
        } catch {
            Write-CompareLog "  Error reading folder: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-CompareLog "  Folder not found" "WARNING"
    }
}

# Section 3: Scheduled Tasks that run at startup
Write-CompareLog "Checking Scheduled Tasks that run at startup..." "INFO"

try {
    $startupTasks = Get-ScheduledTask | Where-Object { 
        ($_.Triggers | Where-Object { 
            $_ -is [Microsoft.Management.Infrastructure.CimInstance] -and
            $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger'
        }) -or
        ($_.Settings.DisallowStartIfOnBatteries -eq $false -and $_.Settings.StopIfGoingOnBatteries -eq $false)
    } | Where-Object { $_.State -ne 'Disabled' }
    
    if ($startupTasks -and $startupTasks.Count -gt 0) {
        foreach ($task in $startupTasks) {
            Write-CompareLog "  Task: $($task.TaskName) - Status: $($task.State)" "INFO"
            
            $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
            if ($taskInfo) {
                Write-CompareLog "    Last Run: $($taskInfo.LastRunTime)" "INFO"
                Write-CompareLog "    Next Run: $($taskInfo.NextRunTime)" "INFO"
            }
            
            try {
                $taskAction = $task.Actions | Select-Object -First 1
                if ($taskAction -and $taskAction.Execute) {
                    Write-CompareLog "    Action: $($taskAction.Execute) $($taskAction.Arguments)" "INFO"
                }
            } catch {
                Write-CompareLog "    Could not read task action" "WARNING"
            }
        }
    } else {
        Write-CompareLog "  No startup tasks found" "INFO"
    }
} catch {
    Write-CompareLog "Error reading scheduled tasks: $($_.Exception.Message)" "ERROR"
}

# Section 4: Services
Write-CompareLog "Checking Auto-Start Services..." "INFO"

try {
    $autoServices = Get-WmiObject -Class Win32_Service -Filter "StartMode='Auto'" -ErrorAction SilentlyContinue
    Write-CompareLog "Auto-start services: $($autoServices.Count) found" "INFO"
    
    $autoServices | Sort-Object -Property DisplayName | ForEach-Object {
        $status = if ($_.State -eq "Running") { "Running" } else { "Stopped" }
        $statusLevel = if ($_.State -eq "Running") { "SUCCESS" } else { "WARNING" }
        Write-CompareLog "  Service: $($_.DisplayName) - Status: $status - Start: $($_.StartMode)" $statusLevel
        Write-CompareLog "    Path: $($_.PathName)" "INFO"
    }
} catch {
    Write-CompareLog "Error reading services: $($_.Exception.Message)" "ERROR"
}

# Section 5: Currently Running Processes
Write-CompareLog "Listing Running Processes..." "INFO"

try {
    $processes = Get-Process | Sort-Object -Property Company 
    Write-CompareLog "Total processes running: $($processes.Count)" "INFO"
    
    $processes | ForEach-Object {
        try {
            if ($_.Path) {
                $fileInfo = Get-ItemProperty -Path $_.Path -ErrorAction SilentlyContinue
                $company = if ($_.Company) { $_.Company } else { "Unknown" }
                $description = if ($_.Description) { $_.Description } else { "No description" }
                Write-CompareLog "  Process: $($_.Name) (PID: $($_.Id)) - Company: $company" "INFO"
                Write-CompareLog "    Path: $($_.Path)" "INFO"
                Write-CompareLog "    Description: $description" "INFO"
                
                # Check digital signature
                try {
                    $signature = Get-AuthenticodeSignature -FilePath $_.Path -ErrorAction SilentlyContinue
                    if ($signature) {
                        $sigStatus = $signature.Status.ToString()
                        $sigStatusLevel = if ($sigStatus -eq "Valid") { "SUCCESS" } else { "WARNING" }
                        Write-CompareLog "    Signature: $sigStatus" $sigStatusLevel
                    }
                } catch {
                    # Ignore signature errors
                }
            } else {
                Write-CompareLog "  Process: $($_.Name) (PID: $($_.Id)) - No path available" "WARNING"
            }
        } catch {
            Write-CompareLog "  Error checking process $($_.Name): $($_.Exception.Message)" "ERROR"
        }
    }
} catch {
    Write-CompareLog "Error listing processes: $($_.Exception.Message)" "ERROR"
}

# Section 6: Windows Shell Registered Handlers
Write-CompareLog "Checking Shell Components..." "INFO"

# COM components related to shell
$shellCOMComponents = @(
    "Shell.Application",
    "Shell.Explorer",
    "ShellWindows",
    "ShellFolderView",
    "ShellNameSpace"
)

foreach ($component in $shellCOMComponents) {
    try {
        $comObj = New-Object -ComObject $component -ErrorAction Stop
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObj) | Out-Null
        Write-CompareLog "  COM component '$component' is registered and working" "SUCCESS"
    } catch {
        Write-CompareLog "  COM component '$component' failed: $($_.Exception.Message)" "ERROR"
    }
}

# Section 7: Summary
Write-CompareLog "=== STARTUP COMPARISON COMPLETED ($mode MODE) ===" "INFO"
Write-CompareLog "Log saved to: $logFile" "INFO"

Write-Host "`n==== NEXT STEPS ====" -ForegroundColor Yellow
Write-Host "1. Run this script in both SAFE MODE and NORMAL MODE" -ForegroundColor Cyan
Write-Host "2. Compare the two log files to identify differences" -ForegroundColor Cyan
Write-Host "3. Focus on services and processes that run in normal mode but not safe mode" -ForegroundColor Cyan
Write-Host "4. Pay special attention to non-Microsoft services with invalid signatures" -ForegroundColor Cyan