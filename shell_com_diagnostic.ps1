#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Comprehensive Shell and COM Level Diagnostic Script
.DESCRIPTION
    Diagnoses shell, COM, and system-level issues that may persist after malware cleanup
.NOTES
    Requires Administrator privileges
#>

param(
    [switch]$Detailed,
    [switch]$FixIssues
)

# Initialize logging
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\shell_com_diagnostic_$timestamp.log"
$errorCount = 0
$warningCount = 0

function Write-DiagnosticLog {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) { "ERROR" {"Red"} "WARNING" {"Yellow"} "SUCCESS" {"Green"} default {"White"} })
    Add-Content -Path $logFile -Value $logEntry
    
    if ($Level -eq "ERROR") { $script:errorCount++ }
    if ($Level -eq "WARNING") { $script:warningCount++ }
}

Write-DiagnosticLog "=== SHELL AND COM DIAGNOSTIC STARTED ===" "INFO"
Write-DiagnosticLog "Log file: $logFile" "INFO"

# Test 1: PowerShell Core Functionality
Write-DiagnosticLog "Testing PowerShell Core Functionality..." "INFO"
try {
    $psVersion = $PSVersionTable.PSVersion
    $currentEdition = $PSVersionTable.PSEdition
    Write-DiagnosticLog "PowerShell Version: $psVersion, Edition: $psEdition" "SUCCESS"
    
    # Test basic cmdlets
    $testCommands = @("Get-Process", "Get-Service", "Get-WmiObject", "Get-CimInstance")
    foreach ($cmd in $testCommands) {
        try {
            if ($cmd -eq "Get-WmiObject") {
                $null = & $cmd -Class "Win32_ComputerSystem" -ErrorAction Stop | Select-Object -First 1
            } elseif ($cmd -eq "Get-CimInstance") {
                $null = & $cmd -ClassName "Win32_ComputerSystem" -ErrorAction Stop | Select-Object -First 1
            } else {
                $null = & $cmd -ErrorAction Stop | Select-Object -First 1
            }
            Write-DiagnosticLog "Command '$cmd' working" "SUCCESS"
        }
        catch {
            Write-DiagnosticLog "Command '$cmd' FAILED: $($_.Exception.Message)" "ERROR"
        }
    }
}
catch {
    Write-DiagnosticLog "PowerShell Core Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 2: COM Component Registration
Write-DiagnosticLog "Testing COM Component Registration..." "INFO"
try {
    # Test critical COM components
    $comComponents = @(
        @{Name="Shell.Application"; ProgID="Shell.Application"},
        @{Name="Scripting.FileSystemObject"; ProgID="Scripting.FileSystemObject"},
        @{Name="WScript.Shell"; ProgID="WScript.Shell"},
        @{Name="Excel.Application"; ProgID="Excel.Application"; Optional=$true},
        @{Name="Word.Application"; ProgID="Word.Application"; Optional=$true}
    )
    
    foreach ($com in $comComponents) {
        try {
            $obj = New-Object -ComObject $com.ProgID -ErrorAction Stop
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($obj) | Out-Null
            Write-DiagnosticLog "COM '$($com.Name)' registered and functional" "SUCCESS"
        }
        catch {
            if ($com.Optional) {
                Write-DiagnosticLog "Optional COM '$($com.Name)' not available: $($_.Exception.Message)" "WARNING"
            } else {
                Write-DiagnosticLog "Critical COM '$($com.Name)' FAILED: $($_.Exception.Message)" "ERROR"
            }
        }
    }
}
catch {
    Write-DiagnosticLog "COM Registration Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 3: Registry Shell Extensions (WITH TIMEOUT PROTECTION)
Write-DiagnosticLog "Testing Registry Shell Extensions..." "INFO"
try {
    $shellKeys = @(
        "HKLM:\SOFTWARE\Classes\*\shellex\ContextMenuHandlers",
        "HKLM:\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers",
        "HKLM:\SOFTWARE\Classes\Folder\shellex\ContextMenuHandlers",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved"
    )
    
    foreach ($key in $shellKeys) {
        try {
            # Use job timeout to prevent hanging on corrupted registry keys
            Write-DiagnosticLog "Checking registry key: $key (timeout-protected)" "INFO"
            
            $job = Start-Job -ScriptBlock {
                param($registryPath)
                if (Test-Path $registryPath) {
                    Get-ChildItem -Path $registryPath -ErrorAction Stop | Select-Object -First 100
                } else {
                    throw "Registry path not found: $registryPath"
                }
            } -ArgumentList $key
            
            $timeoutJob = Wait-Job $job -Timeout 10
            if ($timeoutJob) {
                $items = Receive-Job $job -ErrorAction SilentlyContinue
                $itemCount = ($items | Measure-Object).Count
                Write-DiagnosticLog "Registry key '$key' accessible with $itemCount items (timeout-protected)" "SUCCESS"
            } else {
                Write-DiagnosticLog "Registry key '$key' TIMEOUT - likely corrupted by malware" "ERROR"
            }
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-DiagnosticLog "Registry key '$key' FAILED: $($_.Exception.Message)" "ERROR"
        }
    }
}
catch {
    Write-DiagnosticLog "Registry Shell Extensions Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 4: Windows Shell Services
Write-DiagnosticLog "Testing Windows Shell Services..." "INFO"
try {
    $shellServices = @("ShellHWDetection", "Themes", "AudioSrv", "AudioEndpointBuilder", "Winmgmt")
    
    foreach ($service in $shellServices) {
        try {
            $svc = Get-Service -Name $service -ErrorAction Stop
            Write-DiagnosticLog "Service '$service' status: $($svc.Status)" $(if ($svc.Status -eq "Running") {"SUCCESS"} else {"WARNING"})
        }
        catch {
            Write-DiagnosticLog "Service '$service' FAILED: $($_.Exception.Message)" "ERROR"
        }
    }
}
catch {
    Write-DiagnosticLog "Shell Services Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 5: DLL Registration Status
Write-DiagnosticLog "Testing Critical Shell DLL Registration..." "INFO"
try {
    $criticalDLLs = @(
        "shell32.dll", "ole32.dll", "oleaut32.dll", "comctl32.dll", 
        "shdocvw.dll", "browseui.dll", "explorer.exe"
    )
    
    foreach ($dll in $criticalDLLs) {
        try {
            $dllPath = Join-Path $env:SystemRoot "System32\$dll"
            if (Test-Path $dllPath) {
                $fileInfo = Get-ItemProperty $dllPath
                Write-DiagnosticLog "DLL '$dll' found, size: $($fileInfo.Length) bytes" "SUCCESS"
            } else {
                Write-DiagnosticLog "DLL '$dll' NOT FOUND at expected location" "ERROR"
            }
        }
        catch {
            Write-DiagnosticLog "DLL '$dll' check FAILED: $($_.Exception.Message)" "ERROR"
        }
    }
}
catch {
    Write-DiagnosticLog "DLL Registration Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 6: Event Log Errors
Write-DiagnosticLog "Checking Recent Event Log Errors..." "INFO"
try {
    $recentErrors = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=(Get-Date).AddHours(-2)} -MaxEvents 50 -ErrorAction SilentlyContinue
    
    if ($recentErrors) {
        $shellErrors = $recentErrors | Where-Object { $_.LevelDisplayName -eq "Error" -and ($_.Message -like "*shell*" -or $_.Message -like "*com*" -or $_.Message -like "*ole*") }
        
        if ($shellErrors) {
            Write-DiagnosticLog "Found $($shellErrors.Count) shell/COM related errors in recent logs" "ERROR"
            foreach ($error in $shellErrors | Select-Object -First 5) {
                Write-DiagnosticLog "Event ID $($error.Id): $($error.LevelDisplayName) - $($error.Message.Substring(0, [Math]::Min(100, $error.Message.Length)))" "ERROR"
            }
        } else {
            Write-DiagnosticLog "No shell/COM related errors found in recent logs" "SUCCESS"
        }
    } else {
        Write-DiagnosticLog "No recent error events found" "SUCCESS"
    }
}
catch {
    Write-DiagnosticLog "Event Log Check FAILED: $($_.Exception.Message)" "WARNING"
}

# Test 7: File Associations
Write-DiagnosticLog "Testing File Associations..." "INFO"
try {
    $testExtensions = @(".txt", ".exe", ".dll", ".ps1", ".bat")
    
    foreach ($ext in $testExtensions) {
        try {
            $assoc = cmd /c "assoc $ext" 2>$null
            if ($assoc) {
                Write-DiagnosticLog "File association '$ext': $assoc" "SUCCESS"
            } else {
                Write-DiagnosticLog "File association '$ext': NOT FOUND" "WARNING"
            }
        }
        catch {
            Write-DiagnosticLog "File association '$ext' check FAILED: $($_.Exception.Message)" "WARNING"
        }
    }
}
catch {
    Write-DiagnosticLog "File Associations Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 8: Shell Namespace Extensions (WITH TIMEOUT PROTECTION)
Write-DiagnosticLog "Testing Shell Namespace Extensions..." "INFO"
try {
    $namespaceKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace"
    
    # Use job timeout for namespace registry access
    $job = Start-Job -ScriptBlock {
        param($registryPath)
        if (Test-Path $registryPath) {
            Get-ChildItem -Path $registryPath -ErrorAction Stop
        } else {
            throw "Registry path not found: $registryPath"
        }
    } -ArgumentList $namespaceKey
    
    $timeoutJob = Wait-Job $job -Timeout 10
    if ($timeoutJob) {
        $namespaceItems = Receive-Job $job -ErrorAction SilentlyContinue
        $itemCount = ($namespaceItems | Measure-Object).Count
        Write-DiagnosticLog "Found $itemCount namespace extensions (timeout-protected)" "SUCCESS"
        
        # Check for critical namespace extensions
        $criticalNamespaces = @(
            "{20D04FE0-3AEA-1069-A2D8-08002B30309D}", # My Computer
            "{450D8FBA-AD25-11D0-98A8-0800361B1103}", # My Documents
            "{208D2C60-3AEA-1069-A2D7-08002B30309D}"  # Network Places
        )
        
        foreach ($ns in $criticalNamespaces) {
            if ($namespaceItems.Name -like "*$ns*") {
                Write-DiagnosticLog "Critical namespace '$ns' present" "SUCCESS"
            } else {
                Write-DiagnosticLog "Critical namespace '$ns' MISSING" "ERROR"
            }
        }
    } else {
        Write-DiagnosticLog "Shell Namespace Extensions registry TIMEOUT - likely corrupted" "ERROR"
    }
    Remove-Job $job -Force -ErrorAction SilentlyContinue
}
catch {
    Write-DiagnosticLog "Shell Namespace Extensions Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 9: User Profile and Shell Folders
Write-DiagnosticLog "Testing User Profile and Shell Folders..." "INFO"
try {
    $shellFolders = @{
        "Desktop" = [Environment]::GetFolderPath("Desktop")
        "Documents" = [Environment]::GetFolderPath("MyDocuments")
        "StartMenu" = [Environment]::GetFolderPath("StartMenu")
        "Programs" = [Environment]::GetFolderPath("Programs")
    }
    
    foreach ($folder in $shellFolders.GetEnumerator()) {
        if (Test-Path $folder.Value) {
            Write-DiagnosticLog "Shell folder '$($folder.Key)': $($folder.Value) - OK" "SUCCESS"
        } else {
            Write-DiagnosticLog "Shell folder '$($folder.Key)': $($folder.Value) - NOT FOUND" "ERROR"
        }
    }
}
catch {
    Write-DiagnosticLog "User Profile Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Test 10: Terminal and Console Functionality
Write-DiagnosticLog "Testing Terminal and Console Functionality..." "INFO"
try {
    # Test console modes
    $consoleInfo = Get-Host
    Write-DiagnosticLog "Console Host: $($consoleInfo.Name) Version: $($consoleInfo.Version)" "SUCCESS"
    
    # Test command execution
    $testResult = cmd /c "echo TEST" 2>$null
    if ($testResult -eq "TEST") {
        Write-DiagnosticLog "CMD execution working" "SUCCESS"
    } else {
        Write-DiagnosticLog "CMD execution FAILED" "ERROR"
    }
    
    # Test PowerShell ISE if available
    if (Get-Command "powershell_ise.exe" -ErrorAction SilentlyContinue) {
        Write-DiagnosticLog "PowerShell ISE available" "SUCCESS"
    } else {
        Write-DiagnosticLog "PowerShell ISE not available" "WARNING"
    }
}
catch {
    Write-DiagnosticLog "Terminal Test FAILED: $($_.Exception.Message)" "ERROR"
}

# Generate Repair Recommendations
Write-DiagnosticLog "Generating Repair Recommendations..." "INFO"

$recommendations = @()

if ($errorCount -gt 0) {
    $recommendations += "Critical shell/COM issues detected. Recommend running System File Checker (sfc /scannow)"
    $recommendations += "Run DISM health check: DISM /Online /Cleanup-Image /CheckHealth"
    $recommendations += "Re-register critical COM components using regsvr32"
    $recommendations += "Reset Windows shell components using PowerShell cmdlets"
}

if ($warningCount -gt 5) {
    $recommendations += "Multiple warnings detected. Consider system restart after repairs"
    $recommendations += "Update Windows to latest patches"
    $recommendations += "Run Windows built-in troubleshooters"
}

# Auto-fix option
if ($FixIssues -and $errorCount -gt 0) {
    Write-DiagnosticLog "AUTO-FIX MODE: Attempting to repair detected issues..." "INFO"
    
    # Re-register critical COM components
    $comDLLs = @("ole32.dll", "oleaut32.dll", "shell32.dll", "comctl32.dll")
    foreach ($dll in $comDLLs) {
        try {
            $regResult = Start-Process "regsvr32" -ArgumentList "/s", "$env:SystemRoot\System32\$dll" -Wait -PassThru
            if ($regResult.ExitCode -eq 0) {
                Write-DiagnosticLog "Re-registered $dll successfully" "SUCCESS"
            } else {
                Write-DiagnosticLog "Failed to re-register $dll (Exit Code: $($regResult.ExitCode))" "ERROR"
            }
        }
        catch {
            Write-DiagnosticLog "Error re-registering $dll`: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Run system file checker
    Write-DiagnosticLog "Running System File Checker..." "INFO"
    try {
        $sfcResult = Start-Process "sfc" -ArgumentList "/scannow" -Wait -PassThru -WindowStyle Hidden
        Write-DiagnosticLog "SFC completed with exit code: $($sfcResult.ExitCode)" "INFO"
    }
    catch {
        Write-DiagnosticLog "SFC execution failed: $($_.Exception.Message)" "ERROR"
    }
}

# Final Summary
Write-DiagnosticLog "=== DIAGNOSTIC SUMMARY ===" "INFO"
Write-DiagnosticLog "Total Errors: $errorCount" $(if ($errorCount -eq 0) {"SUCCESS"} else {"ERROR"})
Write-DiagnosticLog "Total Warnings: $warningCount" $(if ($warningCount -eq 0) {"SUCCESS"} else {"WARNING"})

if ($recommendations.Count -gt 0) {
    Write-DiagnosticLog "RECOMMENDATIONS:" "INFO"
    foreach ($rec in $recommendations) {
        Write-DiagnosticLog "- $rec" "INFO"
    }
}

Write-DiagnosticLog "Diagnostic complete. Log saved to: $logFile" "INFO"
Write-DiagnosticLog "=== SHELL AND COM DIAGNOSTIC COMPLETED ===" "INFO"

# Return status
if ($errorCount -eq 0) {
    Write-Host "`nSYSTEM STATUS: HEALTHY" -ForegroundColor Green
    exit 0
} elseif ($errorCount -lt 3) {
    Write-Host "`nSYSTEM STATUS: ISSUES DETECTED - REPAIRABLE" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`nSYSTEM STATUS: CRITICAL ISSUES - MANUAL INTERVENTION REQUIRED" -ForegroundColor Red
    exit 2
}