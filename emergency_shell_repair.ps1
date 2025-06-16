#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Emergency Shell and COM Repair Script
.DESCRIPTION
    Immediate repair for critical shell/COM corruption issues
.NOTES
    Addresses PATH corruption, COM registration, and system integrity
#>

param(
    [switch]$ForceRepair
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\emergency_shell_repair_$timestamp.log"

function Write-RepairLog {
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

Write-RepairLog "=== EMERGENCY SHELL REPAIR STARTED ===" "INFO"

# Step 1: Diagnose PATH Environment Variable
Write-RepairLog "Checking PATH environment variable..." "INFO"
try {
    $currentPath = $env:PATH
    $systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    Write-RepairLog "Current PATH length: $($currentPath.Length) characters" "INFO"
    Write-RepairLog "System PATH length: $($systemPath.Length) characters" "INFO"
    Write-RepairLog "User PATH length: $($userPath.Length) characters" "INFO"
    
    # Check for critical Windows paths
    $criticalPaths = @(
        "$env:SystemRoot\System32",
        "$env:SystemRoot",
        "$env:SystemRoot\System32\Wbem",
        "$env:SystemRoot\System32\WindowsPowerShell\v1.0\"
    )
    
    $missingPaths = @()
    foreach ($path in $criticalPaths) {
        if ($currentPath -notlike "*$path*") {
            $missingPaths += $path
            Write-RepairLog "MISSING critical path: $path" "ERROR"
        } else {
            Write-RepairLog "Found critical path: $path" "SUCCESS"
        }
    }
    
    if ($missingPaths.Count -gt 0) {
        Write-RepairLog "Repairing PATH environment variable..." "INFO"
        
        # Rebuild PATH with critical Windows paths
        $newPath = $criticalPaths -join ";"
        if ($systemPath) {
            $newPath += ";$systemPath"
        }
        if ($userPath) {
            $newPath += ";$userPath"
        }
        
        # Set PATH for current session
        $env:PATH = $newPath
        Write-RepairLog "PATH repaired for current session" "SUCCESS"
        
        # Set system PATH permanently
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        Write-RepairLog "System PATH updated permanently" "SUCCESS"
    }
}
catch {
    Write-RepairLog "PATH repair failed: $($_.Exception.Message)" "ERROR"
}

# Step 2: Test Basic Commands After PATH Fix
Write-RepairLog "Testing basic commands after PATH fix..." "INFO"
$testCommands = @("cmd", "powershell", "regsvr32", "sfc")
foreach ($cmd in $testCommands) {
    try {
        $commandPath = Get-Command $cmd -ErrorAction Stop
        Write-RepairLog "Command '$cmd' found at: $($commandPath.Source)" "SUCCESS"
    }
    catch {
        Write-RepairLog "Command '$cmd' still not found" "ERROR"
    }
}

# Step 3: Critical COM Component Registration
Write-RepairLog "Re-registering critical COM components..." "INFO"
$criticalCOMDLLs = @(
    "ole32.dll",
    "oleaut32.dll", 
    "shell32.dll",
    "comctl32.dll",
    "shdocvw.dll",
    "browseui.dll",
    "urlmon.dll",
    "mshtml.dll"
)

foreach ($dll in $criticalCOMDLLs) {
    try {
        $dllPath = Join-Path "$env:SystemRoot\System32" $dll
        if (Test-Path $dllPath) {
            $regProcess = Start-Process "regsvr32" -ArgumentList "/s", $dllPath -Wait -PassThru -ErrorAction Stop
            if ($regProcess.ExitCode -eq 0) {
                Write-RepairLog "Successfully registered: $dll" "SUCCESS"
            } else {
                Write-RepairLog "Failed to register $dll (Exit: $($regProcess.ExitCode))" "ERROR"
            }
        } else {
            Write-RepairLog "DLL not found: $dllPath" "ERROR"
        }
    }
    catch {
        Write-RepairLog "Error registering $dll`: $($_.Exception.Message)" "ERROR"
    }
}

# Step 4: Windows Services Critical for Shell
Write-RepairLog "Checking critical Windows services..." "INFO"
$criticalServices = @(
    @{Name="Winmgmt"; DisplayName="Windows Management Instrumentation"},
    @{Name="ShellHWDetection"; DisplayName="Shell Hardware Detection"},
    @{Name="Themes"; DisplayName="Themes"},
    @{Name="AudioSrv"; DisplayName="Windows Audio"},
    @{Name="RpcSs"; DisplayName="Remote Procedure Call (RPC)"},
    @{Name="DcomLaunch"; DisplayName="DCOM Server Process Launcher"}
)

foreach ($svc in $criticalServices) {
    try {
        $service = Get-Service -Name $svc.Name -ErrorAction Stop
        if ($service.Status -ne "Running") {
            Write-RepairLog "Starting service: $($svc.DisplayName)" "INFO"
            Start-Service -Name $svc.Name -ErrorAction Stop
            Write-RepairLog "Service started: $($svc.DisplayName)" "SUCCESS"
        } else {
            Write-RepairLog "Service running: $($svc.DisplayName)" "SUCCESS"
        }
    }
    catch {
        Write-RepairLog "Service issue: $($svc.DisplayName) - $($_.Exception.Message)" "ERROR"
    }
}

# Step 5: Registry Keys for Shell Integration
Write-RepairLog "Checking shell registry keys..." "INFO"
$shellRegistryKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved",
    "HKLM:\SOFTWARE\Classes\CLSID",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace"
)

foreach ($key in $shellRegistryKeys) {
    try {
        $keyExists = Test-Path $key
        if ($keyExists) {
            $items = Get-ChildItem $key -ErrorAction SilentlyContinue
            Write-RepairLog "Registry key OK: $key ($($items.Count) items)" "SUCCESS"
        } else {
            Write-RepairLog "Registry key MISSING: $key" "ERROR"
        }
    }
    catch {
        Write-RepairLog "Registry key error: $key - $($_.Exception.Message)" "WARNING"
    }
}

# Step 6: System File Checker
Write-RepairLog "Running System File Checker (SFC)..." "INFO"
try {
    $sfcProcess = Start-Process "sfc" -ArgumentList "/scannow" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
    Write-RepairLog "SFC completed with exit code: $($sfcProcess.ExitCode)" "INFO"
    
    if ($sfcProcess.ExitCode -eq 0) {
        Write-RepairLog "SFC found no integrity violations" "SUCCESS"
    } else {
        Write-RepairLog "SFC detected issues (check CBS.log for details)" "WARNING"
    }
}
catch {
    Write-RepairLog "SFC execution failed: $($_.Exception.Message)" "ERROR"
}

# Step 7: DISM Health Check
Write-RepairLog "Running DISM health check..." "INFO"
try {
    $dismProcess = Start-Process "DISM" -ArgumentList "/Online", "/Cleanup-Image", "/CheckHealth" -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
    Write-RepairLog "DISM CheckHealth completed with exit code: $($dismProcess.ExitCode)" "INFO"
    
    if ($dismProcess.ExitCode -eq 0) {
        Write-RepairLog "DISM reports image is healthy" "SUCCESS"
    } else {
        Write-RepairLog "DISM detected image issues" "WARNING"
    }
}
catch {
    Write-RepairLog "DISM execution failed: $($_.Exception.Message)" "ERROR"
}

# Step 8: Environment Variable Verification
Write-RepairLog "Verifying environment variables..." "INFO"
$criticalEnvVars = @(
    @{Name="COMSPEC"; Expected="$env:SystemRoot\System32\cmd.exe"},
    @{Name="SystemRoot"; Expected="C:\Windows"},
    @{Name="windir"; Expected="C:\Windows"}
)

foreach ($envVar in $criticalEnvVars) {
    $currentValue = [Environment]::GetEnvironmentVariable($envVar.Name)
    if ($currentValue -eq $envVar.Expected) {
        Write-RepairLog "Environment variable OK: $($envVar.Name)=$currentValue" "SUCCESS"
    } else {
        Write-RepairLog "Environment variable INCORRECT: $($envVar.Name)=$currentValue (Expected: $($envVar.Expected))" "ERROR"
        # Fix it
        [Environment]::SetEnvironmentVariable($envVar.Name, $envVar.Expected, "Machine")
        Write-RepairLog "Fixed environment variable: $($envVar.Name)" "SUCCESS"
    }
}

# Step 9: Final Validation
Write-RepairLog "Performing final validation..." "INFO"
try {
    # Test COM object creation
    $shell = New-Object -ComObject "Shell.Application"
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
    Write-RepairLog "COM Shell.Application test: SUCCESS" "SUCCESS"
}
catch {
    Write-RepairLog "COM Shell.Application test: FAILED - $($_.Exception.Message)" "ERROR"
}

try {
    # Test WScript.Shell
    $wscript = New-Object -ComObject "WScript.Shell"
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wscript) | Out-Null
    Write-RepairLog "COM WScript.Shell test: SUCCESS" "SUCCESS"
}
catch {
    Write-RepairLog "COM WScript.Shell test: FAILED - $($_.Exception.Message)" "ERROR"
}

# Final Summary and Recommendations
Write-RepairLog "=== EMERGENCY REPAIR SUMMARY ===" "INFO"
Write-RepairLog "Emergency shell repair completed" "INFO"
Write-RepairLog "Log file: $logFile" "INFO"

Write-RepairLog "CRITICAL RECOMMENDATIONS:" "INFO"
Write-RepairLog "1. REBOOT the system to apply environment variable changes" "WARNING"
Write-RepairLog "2. Test basic commands after reboot (cmd, powershell, etc.)" "INFO"
Write-RepairLog "3. Run full diagnostic again: .\shell_com_diagnostic.ps1" "INFO"
Write-RepairLog "4. If issues persist, consider Windows repair install" "WARNING"

Write-RepairLog "=== EMERGENCY SHELL REPAIR COMPLETED ===" "INFO"

Write-Host "`n=== IMMEDIATE ACTIONS REQUIRED ===" -ForegroundColor Yellow
Write-Host "1. REBOOT THE SYSTEM NOW to apply all changes" -ForegroundColor Red
Write-Host "2. After reboot, test: cmd, powershell, basic Windows commands" -ForegroundColor Yellow
Write-Host "3. Report back with results" -ForegroundColor Green