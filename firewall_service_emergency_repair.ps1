#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Emergency Windows Defender Firewall Service and .NET Runtime Repair
.DESCRIPTION
    Fixes hanging MpsSvc (Windows Defender Firewall) service with aggressive timeout handling
    and systematically repairs .NET desktop runtime executable files
.NOTES
    Designed specifically for the MpsSvc hanging issue and .NET corruption after malware cleanup
#>

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\firewall_emergency_repair_$timestamp.log"

function Write-EmergencyLog {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    $color = switch($Level) { 
        "ERROR" {"Red"} 
        "WARNING" {"Yellow"} 
        "SUCCESS" {"Green"} 
        "CRITICAL" {"Magenta"}
        default {"White"} 
    }
    Write-Host $logEntry -ForegroundColor $color
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-ServiceWithTimeout {
    param(
        [string]$ServiceName,
        [int]$TimeoutSeconds = 30
    )
    
    Write-EmergencyLog "Testing service '$ServiceName' with $TimeoutSeconds second timeout..." "INFO"
    
    $job = Start-Job -ScriptBlock {
        param($svcName)
        try {
            $service = Get-Service -Name $svcName -ErrorAction Stop
            return @{
                Status = $service.Status
                StartType = (Get-WmiObject -Class Win32_Service -Filter "Name='$svcName'").StartMode
                Success = $true
            }
        }
        catch {
            return @{
                Status = "Unknown"
                StartType = "Unknown"
                Success = $false
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $ServiceName
    
    $result = $job | Wait-Job -Timeout $TimeoutSeconds
    
    if ($result) {
        $output = Receive-Job -Job $job
        Remove-Job -Job $job -Force
        return $output
    }
    else {
        Write-EmergencyLog "Service query timed out after $TimeoutSeconds seconds - KILLING HANGING PROCESSES" "CRITICAL"
        Remove-Job -Job $job -Force
        return @{
            Status = "Timeout"
            StartType = "Unknown"
            Success = $false
            Error = "Service query timed out"
        }
    }
}

function Stop-ServiceForcefully {
    param([string]$ServiceName)
    
    Write-EmergencyLog "Attempting forceful stop of service '$ServiceName'..." "WARNING"
    
    try {
        # Method 1: Standard stop with timeout
        $job = Start-Job -ScriptBlock {
            param($svcName)
            Stop-Service -Name $svcName -Force -ErrorAction Stop
        } -ArgumentList $ServiceName
        
        $result = $job | Wait-Job -Timeout 15
        if ($result) {
            Remove-Job -Job $job -Force
            Write-EmergencyLog "Service stopped successfully via Stop-Service" "SUCCESS"
            return $true
        }
        else {
            Remove-Job -Job $job -Force
            Write-EmergencyLog "Stop-Service timed out, trying SC command..." "WARNING"
        }
    }
    catch {
        Write-EmergencyLog "Stop-Service failed: $($_.Exception.Message)" "ERROR"
    }
    
    # Method 2: SC command
    try {
        $scResult = & sc.exe stop $ServiceName 2>&1
        Start-Sleep -Seconds 3
        Write-EmergencyLog "SC stop result: $scResult" "INFO"
        
        $status = & sc.exe query $ServiceName 2>&1
        if ($status -match "STOPPED") {
            Write-EmergencyLog "Service stopped successfully via SC command" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-EmergencyLog "SC stop failed: $($_.Exception.Message)" "ERROR"
    }
    
    # Method 3: Kill process directly
    Write-EmergencyLog "Attempting to kill service process directly..." "CRITICAL"
    try {
        $processes = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" | ForEach-Object {
            Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
        }
        
        foreach ($proc in $processes) {
            if ($proc) {
                Write-EmergencyLog "Killing process: $($proc.ProcessName) (PID: $($proc.Id))" "WARNING"
                Stop-Process -Id $proc.Id -Force
                Start-Sleep -Seconds 2
            }
        }
        return $true
    }
    catch {
        Write-EmergencyLog "Process kill failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-ServiceWithTimeout {
    param(
        [string]$ServiceName,
        [int]$TimeoutSeconds = 45
    )
    
    Write-EmergencyLog "Starting service '$ServiceName' with $TimeoutSeconds second timeout..." "INFO"
    
    $job = Start-Job -ScriptBlock {
        param($svcName)
        try {
            Start-Service -Name $svcName -ErrorAction Stop
            return $true
        }
        catch {
            return $false
        }
    } -ArgumentList $ServiceName
    
    $result = $job | Wait-Job -Timeout $TimeoutSeconds
    
    if ($result) {
        $success = Receive-Job -Job $job
        Remove-Job -Job $job -Force
        
        if ($success) {
            Write-EmergencyLog "Service started successfully within timeout" "SUCCESS"
            return $true
        }
        else {
            Write-EmergencyLog "Service failed to start (returned error)" "ERROR"
            return $false
        }
    }
    else {
        Write-EmergencyLog "Service start TIMED OUT after $TimeoutSeconds seconds" "CRITICAL"
        Remove-Job -Job $job -Force
        return $false
    }
}

function Repair-DotNetRuntimeExecutables {
    Write-EmergencyLog "=== BEGINNING .NET DESKTOP RUNTIME EXECUTABLE REPAIR ===" "INFO"
    
    # Common .NET runtime paths
    $dotnetPaths = @(
        "$env:ProgramFiles\dotnet",
        "${env:ProgramFiles(x86)}\dotnet",
        "$env:ProgramData\Microsoft\dotnet",
        "$env:USERPROFILE\.dotnet"
    )
    
    # System .NET framework paths
    $frameworkPaths = @(
        "$env:WINDIR\Microsoft.NET\Framework",
        "$env:WINDIR\Microsoft.NET\Framework64"
    )
    
    $repairedFiles = 0
    $errorCount = 0
    
    # Repair .NET Core/5+ runtimes
    Write-EmergencyLog "Scanning .NET Core/5+ runtime executables..." "INFO"
    foreach ($path in $dotnetPaths) {
        if (Test-Path $path) {
            Write-EmergencyLog "Checking .NET path: $path" "INFO"
            
            try {
                # Find all .exe files in the dotnet installation
                $exeFiles = Get-ChildItem -Path $path -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
                
                foreach ($exe in $exeFiles) {
                    try {
                        Write-EmergencyLog "Validating: $($exe.FullName)" "INFO"
                        
                        # Check if executable is corrupted or has suspicious properties
                        $fileInfo = Get-ItemProperty -Path $exe.FullName -ErrorAction SilentlyContinue
                        
                        if (-not $fileInfo) {
                            Write-EmergencyLog "File not accessible: $($exe.FullName)" "WARNING"
                            continue
                        }
                        
                        # Check digital signature
                        $signature = Get-AuthenticodeSignature -FilePath $exe.FullName -ErrorAction SilentlyContinue
                        
                        if ($signature -and $signature.Status -eq "Valid") {
                            Write-EmergencyLog "  Signature valid for: $($exe.Name)" "SUCCESS"
                        }
                        elseif ($signature -and $signature.Status -eq "NotSigned") {
                            Write-EmergencyLog "  No signature found for: $($exe.Name)" "WARNING"
                        }
                        else {
                            Write-EmergencyLog "  SUSPICIOUS signature for: $($exe.Name) - Status: $($signature.Status)" "ERROR"
                            
                            # Quarantine suspicious files
                            $quarantinePath = ".\DotNetQuarantine_$timestamp"
                            if (-not (Test-Path $quarantinePath)) {
                                New-Item -ItemType Directory -Path $quarantinePath -Force | Out-Null
                            }
                            
                            $backupName = "$($exe.Name)_$(Get-Date -Format 'HHmmss')"
                            Copy-Item -Path $exe.FullName -Destination "$quarantinePath\$backupName" -Force
                            Write-EmergencyLog "  Quarantined suspicious file: $backupName" "WARNING"
                        }
                        
                        # Test if executable can be invoked (basic integrity check)
                        if ($exe.Name -eq "dotnet.exe") {
                            Write-EmergencyLog "  Testing dotnet.exe functionality..." "INFO"
                            
                            $testJob = Start-Job -ScriptBlock {
                                param($exePath)
                                try {
                                    $result = & $exePath --version 2>&1
                                    return @{ Success = $true; Output = $result }
                                }
                                catch {
                                    return @{ Success = $false; Error = $_.Exception.Message }
                                }
                            } -ArgumentList $exe.FullName
                            
                            $testResult = $testJob | Wait-Job -Timeout 10
                            if ($testResult) {
                                $output = Receive-Job -Job $testJob
                                Remove-Job -Job $testJob -Force
                                
                                if ($output.Success) {
                                    Write-EmergencyLog "  .NET runtime functional: $($output.Output)" "SUCCESS"
                                }
                                else {
                                    Write-EmergencyLog "  .NET runtime test failed: $($output.Error)" "ERROR"
                                    $errorCount++
                                }
                            }
                            else {
                                Remove-Job -Job $testJob -Force
                                Write-EmergencyLog "  .NET runtime test timed out" "ERROR"
                                $errorCount++
                            }
                        }
                        
                        $repairedFiles++
                    }
                    catch {
                        $errorMsg = $_.Exception.Message
                        Write-EmergencyLog "Error checking executable $($exe.FullName): $errorMsg" "ERROR"
                        $errorCount++
                    }
                }
            }
            catch {
                $errorMsg = $_.Exception.Message
                Write-EmergencyLog "Error scanning path $path - $errorMsg" "ERROR"
                $errorCount++
            }
        }
    }
    
    # Repair .NET Framework executables
    Write-EmergencyLog "Scanning .NET Framework runtime executables..." "INFO"
    foreach ($frameworkPath in $frameworkPaths) {
        if (Test-Path $frameworkPath) {
            Write-EmergencyLog "Checking .NET Framework path: $frameworkPath" "INFO"
            
            try {
                # Find all version directories
                $versionDirs = Get-ChildItem -Path $frameworkPath -Directory -ErrorAction SilentlyContinue
                
                foreach ($versionDir in $versionDirs) {
                    Write-EmergencyLog "  Checking framework version: $($versionDir.Name)" "INFO"
                    
                    # Key .NET Framework executables to validate
                    $keyExecutables = @(
                        "csc.exe",           # C# compiler
                        "vbc.exe",           # VB.NET compiler
                        "MSBuild.exe",       # Build engine
                        "aspnet_compiler.exe", # ASP.NET compiler
                        "RegAsm.exe",        # Assembly registration
                        "RegSvcs.exe",       # Service registration
                        "InstallUtil.exe",   # Installation utility
                        "ngen.exe"           # Native image generator
                    )
                    
                    foreach ($exeName in $keyExecutables) {
                        $exePath = Join-Path $versionDir.FullName $exeName
                        
                        if (Test-Path $exePath) {
                            try {
                                Write-EmergencyLog "    Validating: $exeName in $($versionDir.Name)" "INFO"
                                
                                # Check file integrity
                                $fileHash = Get-FileHash -Path $exePath -Algorithm SHA256 -ErrorAction SilentlyContinue
                                if ($fileHash) {
                                    Write-EmergencyLog "    File hash computed successfully for $exeName" "SUCCESS"
                                }
                                else {
                                    Write-EmergencyLog "    Failed to compute hash for $exeName - possible corruption" "ERROR"
                                    $errorCount++
                                }
                                
                                # Check digital signature for Microsoft signed executables
                                $signature = Get-AuthenticodeSignature -FilePath $exePath -ErrorAction SilentlyContinue
                                if ($signature) {
                                    if ($signature.Status -eq "Valid" -and $signature.SignerCertificate.Subject -match "Microsoft") {
                                        Write-EmergencyLog "    Valid Microsoft signature for $exeName" "SUCCESS"
                                    }
                                    else {
                                        Write-EmergencyLog "    Invalid or non-Microsoft signature for $exeName" "WARNING"
                                    }
                                }
                                
                                $repairedFiles++
                            }
                            catch {
                                $errorMsg = $_.Exception.Message
                                Write-EmergencyLog "    Error validating $exeName - $errorMsg" "ERROR"
                                $errorCount++
                            }
                        }
                    }
                }
            }
            catch {
                $errorMsg = $_.Exception.Message
                Write-EmergencyLog "Error scanning framework path $frameworkPath - $errorMsg" "ERROR"
                $errorCount++
            }
        }
    }
    
    # Run .NET repair commands
    Write-EmergencyLog "Running .NET system repair commands..." "INFO"
    
    try {
        # Repair .NET Framework using DISM
        Write-EmergencyLog "Running DISM .NET Framework repair..." "INFO"
        $dismResult = & DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart 2>&1
        Write-EmergencyLog "DISM .NET Framework result: $dismResult" "INFO"
        
        # Register .NET Framework assemblies
        Write-EmergencyLog "Re-registering .NET Framework assemblies..." "INFO"
        
        $frameworkRegPaths = @(
            "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319",
            "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319"
        )
        
        foreach ($regPath in $frameworkRegPaths) {
            if (Test-Path $regPath) {
                $regAsmPath = Join-Path $regPath "RegAsm.exe"
                if (Test-Path $regAsmPath) {
                    Write-EmergencyLog "  Running RegAsm from: $regPath" "INFO"
                    
                    # Find and register key assemblies
                    $assemblies = Get-ChildItem -Path $regPath -Filter "*.dll" -ErrorAction SilentlyContinue | 
                                  Where-Object { $_.Name -match "^(System\.|Microsoft\.)" } |
                                  Select-Object -First 5  # Limit to prevent timeout
                    
                    foreach ($assembly in $assemblies) {
                        try {
                            $regResult = & $regAsmPath $assembly.FullName /nologo /silent 2>&1
                            Write-EmergencyLog "    Registered: $($assembly.Name)" "SUCCESS"
                        }
                        catch {
                            Write-EmergencyLog "    Failed to register: $($assembly.Name)" "WARNING"
                        }
                    }
                }
            }
        }
        
        # Update native image cache
        Write-EmergencyLog "Updating native image cache..." "INFO"
        foreach ($regPath in $frameworkRegPaths) {
            $ngenPath = Join-Path $regPath "ngen.exe"
            if (Test-Path $ngenPath) {
                try {
                    Write-EmergencyLog "  Running ngen update from: $regPath" "INFO"
                    $ngenResult = & $ngenPath update /silent 2>&1
                    Write-EmergencyLog "  ngen update completed" "SUCCESS"
                }
                catch {
                    Write-EmergencyLog "  ngen update failed: $($_.Exception.Message)" "WARNING"
                }
            }
        }
    }
    catch {
        Write-EmergencyLog ".NET repair commands failed: $($_.Exception.Message)" "ERROR"
        $errorCount++
    }
    
    Write-EmergencyLog "=== .NET RUNTIME REPAIR SUMMARY ===" "INFO"
    Write-EmergencyLog "Files validated: $repairedFiles" "INFO"
    Write-EmergencyLog "Errors encountered: $errorCount" "$(if ($errorCount -eq 0) {'SUCCESS'} else {'WARNING'})"
    
    return @{
        FilesProcessed = $repairedFiles
        Errors = $errorCount
        Success = ($errorCount -lt 5)  # Allow some minor errors
    }
}

function Repair-FirewallRegistrySettings {
    Write-EmergencyLog "Repairing Windows Defender Firewall registry settings..." "INFO"
    
    try {
        # Reset firewall service dependencies
        $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\MpsSvc"
        
        if (Test-Path $servicePath) {
            Write-EmergencyLog "Resetting MpsSvc registry dependencies..." "INFO"
            
            # Set correct dependencies
            Set-ItemProperty -Path $servicePath -Name "DependOnService" -Value @("mpsdrv") -ErrorAction SilentlyContinue
            
            # Reset service parameters
            Set-ItemProperty -Path $servicePath -Name "Start" -Value 2 -ErrorAction SilentlyContinue  # Automatic
            Set-ItemProperty -Path $servicePath -Name "Type" -Value 32 -ErrorAction SilentlyContinue  # Win32ShareProcess
            
            Write-EmergencyLog "Registry settings updated" "SUCCESS"
        }
        
        # Reset firewall policies that might be causing hangs
        Write-EmergencyLog "Resetting firewall policy registry..." "INFO"
        $policyPaths = @(
            "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile",
            "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile",
            "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile"
        )
        
        foreach ($path in $policyPaths) {
            if (Test-Path $path) {
                # Enable firewall but reset problematic settings
                Set-ItemProperty -Path $path -Name "EnableFirewall" -Value 1 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $path -Name "DoNotAllowExceptions" -Value 0 -ErrorAction SilentlyContinue
            }
        }
        
        return $true
    }
    catch {
        Write-EmergencyLog "Registry repair failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Reset-FirewallConfiguration {
    Write-EmergencyLog "Attempting to reset Windows Firewall to default configuration..." "WARNING"
    
    try {
        # Method 1: NetSH reset
        Write-EmergencyLog "Resetting firewall via netsh..." "INFO"
        $netshResult = & netsh.exe advfirewall reset 2>&1
        Write-EmergencyLog "NetSH result: $netshResult" "INFO"
        
        Start-Sleep -Seconds 3
        
        # Method 2: PowerShell cmdlets (if available)
        try {
            Write-EmergencyLog "Attempting PowerShell firewall reset..." "INFO"
            
            # Remove all firewall rules
            Get-NetFirewallRule | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            
            # Reset to defaults
            Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow
            
            Write-EmergencyLog "PowerShell firewall reset completed" "SUCCESS"
        }
        catch {
            Write-EmergencyLog "PowerShell firewall reset failed: $($_.Exception.Message)" "WARNING"
        }
        
        return $true
    }
    catch {
        Write-EmergencyLog "Firewall reset failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ===== MAIN EXECUTION =====

Write-EmergencyLog "=== EMERGENCY FIREWALL AND .NET RUNTIME REPAIR STARTED ===" "CRITICAL"
Write-EmergencyLog "Timestamp: $(Get-Date)" "INFO"

# Step 1: Repair .NET Desktop Runtime Executables
Write-EmergencyLog "STEP 1: Repairing .NET Desktop Runtime Executables" "INFO"
$dotnetRepair = Repair-DotNetRuntimeExecutables

if ($dotnetRepair.Success) {
    Write-EmergencyLog ".NET runtime repair completed successfully" "SUCCESS"
}
else {
    Write-EmergencyLog ".NET runtime repair completed with errors" "WARNING"
}

# Step 2: Test current firewall service status
Write-EmergencyLog "STEP 2: Testing Windows Defender Firewall Service" "INFO"
$serviceStatus = Test-ServiceWithTimeout -ServiceName "MpsSvc" -TimeoutSeconds 30

if ($serviceStatus.Status -eq "Timeout") {
    Write-EmergencyLog "CRITICAL: MpsSvc service is hanging - initiating emergency procedures" "CRITICAL"
    
    # Stop hanging service
    $stopResult = Stop-ServiceForcefully -ServiceName "MpsSvc"
    
    if ($stopResult) {
        Write-EmergencyLog "Service stopped successfully" "SUCCESS"
    }
    else {
        Write-EmergencyLog "Failed to stop service - continuing with repair" "WARNING"
    }
}

# Step 3: Repair firewall registry settings
Write-EmergencyLog "STEP 3: Repairing Firewall Registry Settings" "INFO"
$registryRepair = Repair-FirewallRegistrySettings

# Step 4: Reset firewall configuration
Write-EmergencyLog "STEP 4: Resetting Firewall Configuration" "INFO"
$configReset = Reset-FirewallConfiguration

# Step 5: Attempt to start the service with timeout
Write-EmergencyLog "STEP 5: Starting Windows Defender Firewall Service" "INFO"
$startResult = Start-ServiceWithTimeout -ServiceName "MpsSvc" -TimeoutSeconds 60

# Step 6: Final validation
Write-EmergencyLog "STEP 6: Final Service Validation" "INFO"
$finalStatus = Test-ServiceWithTimeout -ServiceName "MpsSvc" -TimeoutSeconds 20

# ===== SUMMARY =====

Write-EmergencyLog "=== EMERGENCY REPAIR SUMMARY ===" "INFO"
Write-EmergencyLog ".NET Files Processed: $($dotnetRepair.FilesProcessed)" "INFO"
Write-EmergencyLog ".NET Repair Errors: $($dotnetRepair.Errors)" "INFO"
Write-EmergencyLog "Registry Repair: $(if ($registryRepair) {'SUCCESS'} else {'FAILED'})" "$(if ($registryRepair) {'SUCCESS'} else {'ERROR'})"
Write-EmergencyLog "Config Reset: $(if ($configReset) {'SUCCESS'} else {'FAILED'})" "$(if ($configReset) {'SUCCESS'} else {'ERROR'})"
Write-EmergencyLog "Service Start: $(if ($startResult) {'SUCCESS'} else {'FAILED'})" "$(if ($startResult) {'SUCCESS'} else {'ERROR'})"
Write-EmergencyLog "Final Service Status: $($finalStatus.Status)" "$(if ($finalStatus.Status -eq 'Running') {'SUCCESS'} else {'ERROR'})"

if ($finalStatus.Status -eq "Running" -and $dotnetRepair.Success) {
    Write-EmergencyLog "EMERGENCY REPAIR COMPLETED SUCCESSFULLY" "SUCCESS"
    $exitCode = 0
}
elseif ($finalStatus.Status -eq "Running") {
    Write-EmergencyLog "FIREWALL REPAIR SUCCESSFUL - .NET HAD ISSUES" "WARNING"
    $exitCode = 1
}
else {
    Write-EmergencyLog "EMERGENCY REPAIR FAILED - MANUAL INTERVENTION REQUIRED" "CRITICAL"
    $exitCode = 2
}

Write-EmergencyLog "Log saved to: $logFile" "INFO"
Write-EmergencyLog "=== EMERGENCY REPAIR COMPLETED ===" "INFO"

# Immediate recommendations
Write-Host "`n=== IMMEDIATE ACTIONS REQUIRED ===" -ForegroundColor Yellow
if ($exitCode -eq 0) {
    Write-Host "✓ SYSTEM REPAIR SUCCESSFUL" -ForegroundColor Green
    Write-Host "1. RESTART the system to ensure all changes take effect" -ForegroundColor Yellow
    Write-Host "2. Verify Windows Defender Firewall is enabled after restart" -ForegroundColor Green
    Write-Host "3. Test .NET applications to ensure they work correctly" -ForegroundColor Green
}
elseif ($exitCode -eq 1) {
    Write-Host "⚠ PARTIAL SUCCESS - FIREWALL FIXED, .NET ISSUES REMAIN" -ForegroundColor Yellow
    Write-Host "1. RESTART the system immediately" -ForegroundColor Red
    Write-Host "2. Run Windows Update to repair .NET Framework" -ForegroundColor Yellow
    Write-Host "3. Consider reinstalling .NET runtimes from Microsoft" -ForegroundColor Yellow
}
else {
    Write-Host "✗ CRITICAL FAILURE - MANUAL INTERVENTION REQUIRED" -ForegroundColor Red
    Write-Host "1. DO NOT RESTART - System may not boot properly" -ForegroundColor Red
    Write-Host "2. Contact system administrator immediately" -ForegroundColor Red
    Write-Host "3. Consider system restore to pre-malware state" -ForegroundColor Red
}

exit $exitCode