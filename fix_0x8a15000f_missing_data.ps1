#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Emergency Fix for Error 0x8a15000f - Data Required by Source is Missing
.DESCRIPTION
    Addresses critical system data corruption causing 0x8a15000f errors during emergency recovery
.NOTES
    Requires Administrator privileges - Critical system repair script
#>

param(
    [switch]$ForceRepair
)

# Initialize logging
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\fix_0x8a15000f_$timestamp.log"

function Write-RepairLog {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) { "ERROR" {"Red"} "WARNING" {"Yellow"} "SUCCESS" {"Green"} default {"Cyan"} })
    Add-Content -Path $logFile -Value $logEntry
}

Write-RepairLog "=== EMERGENCY FIX FOR 0x8a15000f STARTED ===" "INFO"
Write-RepairLog "Target Error: Data required by the source is missing" "INFO"

# Step 1: Check Windows Component Store Health
Write-RepairLog "Step 1: Checking Windows Component Store Health..." "INFO"
try {
    Write-RepairLog "Running DISM CheckHealth..." "INFO"
    $dismCheck = Start-Process "dism" -ArgumentList "/Online", "/Cleanup-Image", "/CheckHealth" -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput ".\dism_check.log"
    
    if ($dismCheck.ExitCode -eq 0) {
        Write-RepairLog "DISM CheckHealth completed successfully" "SUCCESS"
    } else {
        Write-RepairLog "DISM CheckHealth detected issues (Exit Code: $($dismCheck.ExitCode))" "WARNING"
        
        # Run ScanHealth for detailed analysis
        Write-RepairLog "Running DISM ScanHealth for detailed analysis..." "INFO"
        $dismScan = Start-Process "dism" -ArgumentList "/Online", "/Cleanup-Image", "/ScanHealth" -Wait -PassThru -WindowStyle Hidden
        
        if ($dismScan.ExitCode -ne 0) {
            Write-RepairLog "DISM ScanHealth detected component store corruption" "ERROR"
            
            # Run RestoreHealth
            Write-RepairLog "Running DISM RestoreHealth to repair component store..." "INFO"
            $dismRestore = Start-Process "dism" -ArgumentList "/Online", "/Cleanup-Image", "/RestoreHealth" -Wait -PassThru -WindowStyle Hidden
            
            if ($dismRestore.ExitCode -eq 0) {
                Write-RepairLog "DISM RestoreHealth completed successfully" "SUCCESS"
            } else {
                Write-RepairLog "DISM RestoreHealth failed (Exit Code: $($dismRestore.ExitCode))" "ERROR"
            }
        }
    }
}
catch {
    Write-RepairLog "DISM health check failed: $($_.Exception.Message)" "ERROR"
}

# Step 2: Repair System File Corruption
Write-RepairLog "Step 2: Running System File Checker..." "INFO"
try {
    $sfcResult = Start-Process "sfc" -ArgumentList "/scannow" -Wait -PassThru -WindowStyle Hidden
    
    if ($sfcResult.ExitCode -eq 0) {
        Write-RepairLog "SFC scan completed - check CBS.log for details" "SUCCESS"
    } else {
        Write-RepairLog "SFC scan failed (Exit Code: $($sfcResult.ExitCode))" "ERROR"
    }
}
catch {
    Write-RepairLog "SFC execution failed: $($_.Exception.Message)" "ERROR"
}

# Step 3: Check and Repair PowerShell Module Store
Write-RepairLog "Step 3: Checking PowerShell Module Store..." "INFO"
try {
    # Check if PowerShell modules are accessible
    $modulePathExists = Test-Path "$env:ProgramFiles\WindowsPowerShell\Modules"
    $userModulePathExists = Test-Path "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
    
    Write-RepairLog "System PowerShell modules path exists: $modulePathExists" $(if ($modulePathExists) {"SUCCESS"} else {"ERROR"})
    Write-RepairLog "User PowerShell modules path exists: $userModulePathExists" $(if ($userModulePathExists) {"SUCCESS"} else {"WARNING"})
    
    # Create missing module directories
    if (-not $userModulePathExists) {
        New-Item -Path "$env:USERPROFILE\Documents\WindowsPowerShell\Modules" -ItemType Directory -Force
        Write-RepairLog "Created missing user PowerShell modules directory" "SUCCESS"
    }
    
    # Test PowerShell execution policy
    $executionPolicy = Get-ExecutionPolicy
    Write-RepairLog "Current PowerShell Execution Policy: $executionPolicy" "INFO"
    
    if ($executionPolicy -eq "Restricted") {
        Write-RepairLog "Setting ExecutionPolicy to RemoteSigned for emergency recovery" "INFO"
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    }
}
catch {
    Write-RepairLog "PowerShell module check failed: $($_.Exception.Message)" "ERROR"
}

# Step 4: Check and Repair .NET Framework
Write-RepairLog "Step 4: Checking .NET Framework Installation..." "INFO"
try {
    # Check .NET Framework versions
    $dotNetKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" -Recurse -ErrorAction SilentlyContinue |
                  Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
                  Where-Object { $_.Version }
    
    if ($dotNetKeys) {
        foreach ($key in $dotNetKeys) {
            Write-RepairLog ".NET Framework found: $($key.PSChildName) - Version: $($key.Version)" "SUCCESS"
        }
    } else {
        Write-RepairLog ".NET Framework registry entries missing or corrupted" "ERROR"
    }
    
    # Check .NET Core/5+ installations
    $dotNetCore = Get-Command "dotnet" -ErrorAction SilentlyContinue
    if ($dotNetCore) {
        try {
            $dotNetVersion = & dotnet --version 2>$null
            Write-RepairLog ".NET Core/5+ found: Version $dotNetVersion" "SUCCESS"
        }
        catch {
            Write-RepairLog ".NET Core/5+ command failed to execute" "WARNING"
        }
    } else {
        Write-RepairLog ".NET Core/5+ not found in PATH" "WARNING"
    }
}
catch {
    Write-RepairLog ".NET Framework check failed: $($_.Exception.Message)" "ERROR"
}

# Step 5: Repair Windows Registry Base
Write-RepairLog "Step 5: Checking Critical Registry Hives..." "INFO"
try {
    $criticalHives = @(
        "HKLM:\SYSTEM",
        "HKLM:\SOFTWARE", 
        "HKLM:\SECURITY",
        "HKLM:\SAM",
        "HKCU:\SOFTWARE"
    )
    
    foreach ($hive in $criticalHives) {
        try {
            $testAccess = Test-Path $hive
            Write-RepairLog "Registry hive '$hive' accessible: $testAccess" $(if ($testAccess) {"SUCCESS"} else {"ERROR"})
        }
        catch {
            Write-RepairLog "Registry hive '$hive' access failed: $($_.Exception.Message)" "ERROR"
        }
    }
}
catch {
    Write-RepairLog "Registry hive check failed: $($_.Exception.Message)" "ERROR"
}

# Step 6: Check WinSxS Component Store
Write-RepairLog "Step 6: Checking WinSxS Component Store..." "INFO"
try {
    $winsxsPath = "$env:SystemRoot\WinSxS"
    if (Test-Path $winsxsPath) {
        $winsxsSize = (Get-ChildItem $winsxsPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $winsxsSizeGB = [math]::Round($winsxsSize / 1GB, 2)
        Write-RepairLog "WinSxS component store found - Size: $winsxsSizeGB GB" "SUCCESS"
        
        # Check for manifest corruption
        $manifestPath = "$winsxsPath\Manifests"
        if (Test-Path $manifestPath) {
            $manifestCount = (Get-ChildItem $manifestPath -Filter "*.manifest" -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-RepairLog "Component manifests found: $manifestCount" "SUCCESS"
        } else {
            Write-RepairLog "Component manifests directory missing - CRITICAL" "ERROR"
        }
    } else {
        Write-RepairLog "WinSxS component store missing - CRITICAL SYSTEM CORRUPTION" "ERROR"
    }
}
catch {
    Write-RepairLog "WinSxS check failed: $($_.Exception.Message)" "ERROR"
}

# Step 7: Emergency COM Registration Repair
Write-RepairLog "Step 7: Emergency COM Component Registration..." "INFO"
try {
    $criticalCOMDLLs = @(
        "ole32.dll",
        "oleaut32.dll", 
        "shell32.dll",
        "comctl32.dll",
        "msxml6.dll",
        "msxml3.dll"
    )
    
    foreach ($dll in $criticalCOMDLLs) {
        try {
            $dllPath = "$env:SystemRoot\System32\$dll"
            if (Test-Path $dllPath) {
                $regResult = Start-Process "regsvr32" -ArgumentList "/s", $dllPath -Wait -PassThru -WindowStyle Hidden
                if ($regResult.ExitCode -eq 0) {
                    Write-RepairLog "Re-registered $dll successfully" "SUCCESS"
                } else {
                    Write-RepairLog "Failed to re-register $dll (Exit Code: $($regResult.ExitCode))" "ERROR"
                }
            } else {
                Write-RepairLog "Critical DLL missing: $dll" "ERROR"
            }
        }
        catch {
            Write-RepairLog "Error re-registering $dll`: $($_.Exception.Message)" "ERROR"
        }
    }
}
catch {
    Write-RepairLog "COM registration repair failed: $($_.Exception.Message)" "ERROR"
}

# Step 8: Reset Windows Update Components (if ForceRepair enabled)
if ($ForceRepair) {
    Write-RepairLog "Step 8: Force Reset Windows Update Components..." "INFO"
    try {
        # Stop Windows Update services
        $services = @("wuauserv", "cryptSvc", "bits", "msiserver")
        foreach ($service in $services) {
            try {
                Stop-Service $service -Force -ErrorAction SilentlyContinue
                Write-RepairLog "Stopped service: $service" "INFO"
            }
            catch {
                Write-RepairLog "Could not stop service: $service" "WARNING"
            }
        }
        
        # Rename SoftwareDistribution and catroot2
        if (Test-Path "$env:SystemRoot\SoftwareDistribution") {
            Rename-Item "$env:SystemRoot\SoftwareDistribution" "$env:SystemRoot\SoftwareDistribution.bak" -Force -ErrorAction SilentlyContinue
            Write-RepairLog "Renamed SoftwareDistribution folder" "INFO"
        }
        
        if (Test-Path "$env:SystemRoot\System32\catroot2") {
            Rename-Item "$env:SystemRoot\System32\catroot2" "$env:SystemRoot\System32\catroot2.bak" -Force -ErrorAction SilentlyContinue
            Write-RepairLog "Renamed catroot2 folder" "INFO"
        }
        
        # Restart services
        foreach ($service in $services) {
            try {
                Start-Service $service -ErrorAction SilentlyContinue
                Write-RepairLog "Restarted service: $service" "SUCCESS"
            }
            catch {
                Write-RepairLog "Could not restart service: $service" "WARNING"
            }
        }
    }
    catch {
        Write-RepairLog "Windows Update reset failed: $($_.Exception.Message)" "ERROR"
    }
}

Write-RepairLog "=== 0x8a15000f EMERGENCY FIX COMPLETED ===" "INFO"
Write-RepairLog "Log saved to: $logFile" "INFO"
Write-RepairLog "RECOMMENDATION: Restart system after repairs complete" "WARNING"

exit 0