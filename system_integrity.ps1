#Requires -RunAsAdministrator
<#
.SYNOPSIS
    System Integrity Check and Repair Script - EMERGENCY RESPONSE
.DESCRIPTION
    Runs SFC scan and DISM repair, checks file system integrity,
    validates critical system files, and creates system restore point.
.NOTES
    Author: Kilo Code - Emergency Malware Response
    Version: 1.0
    Created: 2025-06-14
    CRITICAL: Run with Administrator privileges
    WARNING: This script performs deep system repairs
#>

param(
    [string]$LogPath = ".\system_integrity_$(Get-Date -Format 'yyyyMMdd_HHmmss').log",
    [switch]$SkipRestorePoint = $false,
    [switch]$QuickCheck = $false,
    [switch]$Force = $false
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
    Write-Progress -Activity "System Integrity Check" -Status "$Activity - $Status" -PercentComplete $percentComplete
}

# Run command with detailed logging
function Invoke-SystemCommand {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$Description,
        [int]$TimeoutMinutes = 30
    )
    
    try {
        Write-LogMessage "Starting: $Description" "INFO"
        Write-LogMessage "Command: $Command $($Arguments -join ' ')" "INFO"
        
        $startTime = Get-Date
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\stdout.tmp" -RedirectStandardError "$env:TEMP\stderr.tmp"
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Read output
        $stdout = ""
        $stderr = ""
        if (Test-Path "$env:TEMP\stdout.tmp") {
            $stdout = Get-Content "$env:TEMP\stdout.tmp" -Raw -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\stdout.tmp" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$env:TEMP\stderr.tmp") {
            $stderr = Get-Content "$env:TEMP\stderr.tmp" -Raw -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\stderr.tmp" -Force -ErrorAction SilentlyContinue
        }
        
        Write-LogMessage "Command completed in $($duration.TotalMinutes.ToString('F2')) minutes with exit code: $($process.ExitCode)" "INFO"
        
        if ($stdout) {
            Write-LogMessage "STDOUT: $stdout" "INFO"
        }
        if ($stderr) {
            Write-LogMessage "STDERR: $stderr" "WARNING"
        }
        
        $result = [PSCustomObject]@{
            ExitCode = $process.ExitCode
            Duration = $duration
            StandardOutput = $stdout
            StandardError = $stderr
            Success = ($process.ExitCode -eq 0)
        }
        
        if ($result.Success) {
            Write-LogMessage "$Description completed successfully" "SUCCESS"
        }
        else {
            Write-LogMessage "$Description failed with exit code $($process.ExitCode)" "ERROR"
        }
        
        return $result
    }
    catch {
        Write-LogMessage "Error running $Description : $($_.Exception.Message)" "ERROR"
        return [PSCustomObject]@{
            ExitCode = -1
            Duration = [TimeSpan]::Zero
            StandardOutput = ""
            StandardError = $_.Exception.Message
            Success = $false
        }
    }
}

# Check disk space
function Test-DiskSpace {
    param([string]$Drive = "C:", [int]$RequiredGB = 2)
    
    try {
        $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $Drive }
        if ($disk) {
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
            
            Write-LogMessage "Disk $Drive - Free: ${freeSpaceGB}GB / Total: ${totalSpaceGB}GB" "INFO"
            
            if ($freeSpaceGB -lt $RequiredGB) {
                Write-LogMessage "Insufficient disk space. Required: ${RequiredGB}GB, Available: ${freeSpaceGB}GB" "ERROR"
                return $false
            }
            return $true
        }
        else {
            Write-LogMessage "Could not get disk information for $Drive" "ERROR"
            return $false
        }
    }
    catch {
        Write-LogMessage "Error checking disk space: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Create system restore point
function New-SystemRestorePoint {
    param([string]$Description = "Emergency Malware Cleanup - Before System Integrity Repair")
    
    try {
        # Check if restore points are enabled
        $restoreEnabled = (Get-ComputerRestorePoint -ErrorAction SilentlyContinue) -ne $null -or 
                         (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "RPSessionInterval" -ErrorAction SilentlyContinue) -ne $null
        
        if (-not $restoreEnabled) {
            Write-LogMessage "System Restore appears to be disabled, attempting to enable..." "WARNING"
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        }
        
        Write-LogMessage "Creating system restore point: $Description" "INFO"
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
        Write-LogMessage "System restore point created successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-LogMessage "Failed to create restore point: $($_.Exception.Message)" "ERROR"
        Write-LogMessage "Continuing without restore point..." "WARNING"
        return $false
    }
}

# Validate critical system files
function Test-CriticalSystemFiles {
    $CriticalFiles = @(
        "$env:WINDIR\System32\kernel32.dll",
        "$env:WINDIR\System32\ntdll.dll",
        "$env:WINDIR\System32\user32.dll",
        "$env:WINDIR\System32\shell32.dll",
        "$env:WINDIR\System32\explorer.exe",
        "$env:WINDIR\System32\winlogon.exe",
        "$env:WINDIR\System32\lsass.exe",
        "$env:WINDIR\System32\csrss.exe",
        "$env:WINDIR\System32\services.exe"
    )
    
    $missingFiles = @()
    $corruptFiles = @()
    
    foreach ($file in $CriticalFiles) {
        if (-not (Test-Path $file)) {
            $missingFiles += $file
            Write-LogMessage "CRITICAL FILE MISSING: $file" "ERROR"
        }
        else {
            try {
                # Check file signature/version
                $fileInfo = Get-ItemProperty $file
                if ($fileInfo.Length -eq 0) {
                    $corruptFiles += $file
                    Write-LogMessage "CRITICAL FILE CORRUPTED (zero bytes): $file" "ERROR"
                }
                else {
                    Write-LogMessage "Critical file OK: $file" "INFO"
                }
            }
            catch {
                $corruptFiles += $file
                Write-LogMessage "CRITICAL FILE ACCESS ERROR: $file - $($_.Exception.Message)" "ERROR"
            }
        }
    }
    
    return [PSCustomObject]@{
        MissingFiles = $missingFiles
        CorruptFiles = $corruptFiles
        TotalCriticalIssues = ($missingFiles.Count + $corruptFiles.Count)
    }
}

try {
    Write-LogMessage "=== SYSTEM INTEGRITY CHECK INITIATED ===" "WARNING"
    Write-LogMessage "Integrity check started at: $(Get-Date)"
    Write-LogMessage "Log file: $LogPath"
    
    # Task 1: Pre-flight checks
    Update-Progress "Pre-flight Checks" "Validating system state"
    
    Write-LogMessage "Checking system prerequisites..." "INFO"
    
    # Check if running as Administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Script must be run as Administrator"
    }
    
    # Check disk space
    if (-not (Test-DiskSpace -RequiredGB 5)) {
        if (-not $Force) {
            throw "Insufficient disk space for system repairs"
        }
        else {
            Write-LogMessage "Continuing with insufficient disk space due to -Force parameter" "WARNING"
        }
    }
    
    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    Write-LogMessage "Windows Version: $($osVersion.Major).$($osVersion.Minor) Build $($osVersion.Build)" "INFO"

    # Task 2: Create system restore point
    Update-Progress "Backup" "Creating system restore point"
    
    if (-not $SkipRestorePoint) {
        New-SystemRestorePoint
    }
    else {
        Write-LogMessage "Skipping restore point creation as requested" "WARNING"
    }

    # Task 3: Validate critical system files
    Update-Progress "File Validation" "Checking critical system files"
    
    $fileCheck = Test-CriticalSystemFiles
    if ($fileCheck.TotalCriticalIssues -gt 0) {
        Write-LogMessage "Found $($fileCheck.TotalCriticalIssues) critical file issues" "ERROR"
        Write-LogMessage "Missing files: $($fileCheck.MissingFiles.Count)" "ERROR"
        Write-LogMessage "Corrupt files: $($fileCheck.CorruptFiles.Count)" "ERROR"
    }
    else {
        Write-LogMessage "All critical system files validated successfully" "SUCCESS"
    }

    # Task 4: Run System File Checker (SFC)
    Update-Progress "SFC Scan" "Running System File Checker"
    
    Write-LogMessage "Starting SFC scan - this may take 15-30 minutes..." "INFO"
    $sfcResult = Invoke-SystemCommand -Command "sfc" -Arguments @("/scannow") -Description "System File Checker scan" -TimeoutMinutes 45
    
    if ($sfcResult.Success) {
        if ($sfcResult.StandardOutput -match "found corrupt files and successfully repaired them") {
            Write-LogMessage "SFC found and repaired corrupt files" "SUCCESS"
        }
        elseif ($sfcResult.StandardOutput -match "found corrupt files but was unable to fix some of them") {
            Write-LogMessage "SFC found corrupt files but could not repair all of them" "WARNING"
        }
        elseif ($sfcResult.StandardOutput -match "did not find any integrity violations") {
            Write-LogMessage "SFC scan completed - no integrity violations found" "SUCCESS"
        }
        else {
            Write-LogMessage "SFC scan completed with unknown result" "WARNING"
        }
    }
    else {
        Write-LogMessage "SFC scan failed or encountered errors" "ERROR"
    }

    # Task 5: Run DISM health check
    Update-Progress "DISM Health Check" "Checking Windows image health"
    
    Write-LogMessage "Running DISM health check..." "INFO"
    $dismCheckResult = Invoke-SystemCommand -Command "dism" -Arguments @("/online", "/cleanup-image", "/checkhealth") -Description "DISM health check" -TimeoutMinutes 10
    
    if ($dismCheckResult.Success) {
        if ($dismCheckResult.StandardOutput -match "No component store corruption detected") {
            Write-LogMessage "DISM health check: No corruption detected" "SUCCESS"
        }
        else {
            Write-LogMessage "DISM health check detected potential issues" "WARNING"
        }
    }

    # Task 6: Run DISM scan health (if needed)
    Update-Progress "DISM Scan" "Scanning Windows image health"
    
    if (-not $QuickCheck -or $dismCheckResult.StandardOutput -notmatch "No component store corruption detected") {
        Write-LogMessage "Running DISM scan health - this may take 10-20 minutes..." "INFO"
        $dismScanResult = Invoke-SystemCommand -Command "dism" -Arguments @("/online", "/cleanup-image", "/scanhealth") -Description "DISM scan health" -TimeoutMinutes 25
        
        if ($dismScanResult.Success) {
            if ($dismScanResult.StandardOutput -match "component store corruption detected") {
                Write-LogMessage "DISM scan detected component store corruption - repair needed" "ERROR"
                
                # Task 7: Run DISM restore health
                Update-Progress "DISM Repair" "Repairing Windows image"
                
                Write-LogMessage "Running DISM restore health - this may take 30-60 minutes..." "WARNING"
                $dismRepairResult = Invoke-SystemCommand -Command "dism" -Arguments @("/online", "/cleanup-image", "/restorehealth") -Description "DISM restore health" -TimeoutMinutes 75
                
                if ($dismRepairResult.Success) {
                    Write-LogMessage "DISM repair completed successfully" "SUCCESS"
                }
                else {
                    Write-LogMessage "DISM repair encountered errors" "ERROR"
                }
            }
            else {
                Write-LogMessage "DISM scan completed - no corruption detected" "SUCCESS"
            }
        }
    }
    else {
        Write-LogMessage "Skipping DISM scan health - quick check mode enabled and no issues detected" "INFO"
        $global:CurrentTask++ # Increment for skipped task
    }

    # Task 8: Final validation and cleanup
    Update-Progress "Final Validation" "Performing final system checks"
    
    # Re-check critical files after repairs
    Write-LogMessage "Re-validating critical system files after repairs..." "INFO"
    $finalFileCheck = Test-CriticalSystemFiles
    
    if ($finalFileCheck.TotalCriticalIssues -lt $fileCheck.TotalCriticalIssues) {
        $improvementCount = $fileCheck.TotalCriticalIssues - $finalFileCheck.TotalCriticalIssues
        Write-LogMessage "System integrity improved: $improvementCount critical file issues resolved" "SUCCESS"
    }
    
    if ($finalFileCheck.TotalCriticalIssues -eq 0) {
        Write-LogMessage "All critical system files validated successfully after repairs" "SUCCESS"
    }
    else {
        Write-LogMessage "Warning: $($finalFileCheck.TotalCriticalIssues) critical file issues remain after repairs" "WARNING"
    }
    
    # Check if reboot is recommended
    $rebootRequired = $false
    if ($sfcResult.StandardOutput -match "reboot" -or $dismRepairResult.StandardOutput -match "reboot") {
        $rebootRequired = $true
        Write-LogMessage "System reboot is recommended to complete repairs" "WARNING"
    }
    
    # Clean up temporary files
    try {
        $cbsLogPath = "$env:WINDIR\Logs\CBS\CBS.log"
        if (Test-Path $cbsLogPath) {
            $cbsLogSize = (Get-Item $cbsLogPath).Length / 1MB
            Write-LogMessage "CBS log size: $([math]::Round($cbsLogSize, 2)) MB" "INFO"
        }
        
        $dismLogPath = "$env:WINDIR\Logs\DISM\dism.log"
        if (Test-Path $dismLogPath) {
            $dismLogSize = (Get-Item $dismLogPath).Length / 1MB
            Write-LogMessage "DISM log size: $([math]::Round($dismLogSize, 2)) MB" "INFO"
        }
    }
    catch {
        Write-LogMessage "Error checking system log files: $($_.Exception.Message)" "WARNING"
    }

    # Final Summary
    Write-Progress -Activity "System Integrity Check" -Completed
    Write-LogMessage "=== SYSTEM INTEGRITY CHECK COMPLETED ===" "SUCCESS"
    Write-LogMessage "Integrity check completed at: $(Get-Date)"
    
    # Display comprehensive summary
    Write-Host "`n=== SYSTEM INTEGRITY SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Log file created: $LogPath" -ForegroundColor Green
    
    Write-Host "`nSystem File Checker (SFC):" -ForegroundColor White
    if ($sfcResult.Success) {
        Write-Host "  ✓ SFC scan completed successfully" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ SFC scan encountered errors" -ForegroundColor Red
    }
    
    Write-Host "`nDeployment Image Servicing (DISM):" -ForegroundColor White
    if ($dismCheckResult.Success) {
        Write-Host "  ✓ DISM health check completed" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ DISM health check failed" -ForegroundColor Red
    }
    
    Write-Host "`nCritical System Files:" -ForegroundColor White
    if ($finalFileCheck.TotalCriticalIssues -eq 0) {
        Write-Host "  ✓ All critical files validated" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ $($finalFileCheck.TotalCriticalIssues) critical file issues remain" -ForegroundColor Yellow
    }
    
    if ($rebootRequired) {
        Write-Host "`n⚠ REBOOT REQUIRED" -ForegroundColor Yellow
        Write-Host "A system reboot is recommended to complete the integrity repairs." -ForegroundColor Yellow
    }
    else {
        Write-Host "`n✓ No reboot required" -ForegroundColor Green
    }
    
    Write-Host "`nSystem integrity check completed successfully." -ForegroundColor White
    Write-Host "Review the detailed logs for complete analysis." -ForegroundColor White

}
catch {
    Write-LogMessage "CRITICAL ERROR during integrity check: $($_.Exception.Message)" "ERROR"
    Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    
    Write-Host "`n=== CRITICAL ERROR ===" -ForegroundColor Red
    Write-Host "System integrity check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check the log file for detailed error information: $LogPath" -ForegroundColor Yellow
    
    exit 1
}
finally {
    Write-Progress -Activity "System Integrity Check" -Completed
}