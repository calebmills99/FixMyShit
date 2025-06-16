#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Tests shell extensions to identify problematic ones
.DESCRIPTION
    This script systematically tests shell extensions to find which ones
    might be causing shell malfunctions in normal mode.
#>

$logFile = ".\shell_extension_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-TestLog {
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

Write-TestLog "=== SHELL EXTENSION TEST STARTED ===" "INFO"
Write-TestLog "This script will help identify shell extensions that might be causing problems" "INFO"

# Test 1: Shell Context Menu Handlers
Write-TestLog "Testing Shell Context Menu Handlers..." "INFO"

$contextMenuKeys = @(
    "HKLM:\SOFTWARE\Classes\*\shellex\ContextMenuHandlers",
    "HKLM:\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers",
    "HKLM:\SOFTWARE\Classes\Folder\shellex\ContextMenuHandlers",
    "HKLM:\SOFTWARE\Classes\Drive\shellex\ContextMenuHandlers",
    "HKLM:\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers"
)

foreach ($key in $contextMenuKeys) {
    Write-TestLog "Testing registry key: $key" "INFO"
    
    $job = Start-Job -ScriptBlock {
        param($registryPath)
        if (Test-Path $registryPath) {
            $handlers = @{}
            Get-ChildItem -Path $registryPath -ErrorAction SilentlyContinue | ForEach-Object {
                $name = $_.PSChildName
                $clsid = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).'(Default)'
                $handlers[$name] = $clsid
            }
            return $handlers
        } else {
            return @{Error = "Registry path not found"}
        }
    } -ArgumentList $key
    
    $result = Wait-Job $job -Timeout 10
    
    if ($result) {
        $handlers = Receive-Job $job
        if ($handlers -and $handlers.Count -gt 0 -and -not $handlers.ContainsKey("Error")) {
            foreach ($handler in $handlers.GetEnumerator()) {
                Write-TestLog "  Handler: $($handler.Key) - CLSID: $($handler.Value)" "INFO"
                
                # Look up CLSID information
                $clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$($handler.Value)"
                try {
                    if (Test-Path $clsidPath) {
                        $clsidInfo = Get-ItemProperty -Path $clsidPath -ErrorAction SilentlyContinue
                        if ($clsidInfo) {
                            $defaultValue = $clsidInfo.'(Default)'
                            Write-TestLog "    Name: $defaultValue" "SUCCESS"
                            
                            # Check InprocServer32
                            $serverPath = Join-Path $clsidPath "InprocServer32"
                            if (Test-Path $serverPath) {
                                $serverInfo = Get-ItemProperty -Path $serverPath -ErrorAction SilentlyContinue
                                if ($serverInfo -and $serverInfo.'(Default)') {
                                    $dllPath = $serverInfo.'(Default)'
                                    Write-TestLog "    DLL: $dllPath" "INFO"
                                    
                                    # Check if the DLL exists
                                    if (Test-Path $dllPath) {
                                        Write-TestLog "    DLL exists: Yes" "SUCCESS"
                                    } else {
                                        Write-TestLog "    DLL exists: No (POTENTIAL PROBLEM)" "ERROR"
                                    }
                                }
                            }
                        }
                    } else {
                        Write-TestLog "    CLSID not found in registry (POTENTIAL PROBLEM)" "ERROR"
                    }
                } catch {
                    Write-TestLog "    Error checking CLSID: $($_.Exception.Message)" "ERROR"
                }
            }
        } elseif ($handlers -and $handlers.ContainsKey("Error")) {
            Write-TestLog "  Error: $($handlers.Error)" "ERROR"
        } else {
            Write-TestLog "  No handlers found or path doesn't exist" "WARNING"
        }
    } else {
        Write-TestLog "  TIMEOUT accessing registry key! This is likely corrupted." "ERROR"
        Write-TestLog "  This key is a strong candidate for causing shell problems." "ERROR"
    }
    
    Remove-Job $job -Force
}

# Test 2: Shell Icon Overlay Handlers
Write-TestLog "Testing Shell Icon Overlay Handlers..." "INFO"
$overlayKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers"

if (Test-Path $overlayKey) {
    try {
        $overlays = Get-ChildItem -Path $overlayKey -ErrorAction SilentlyContinue
        foreach ($overlay in $overlays) {
            $name = $overlay.PSChildName
            $clsid = (Get-ItemProperty -Path $overlay.PSPath -ErrorAction SilentlyContinue).'(Default)'
            Write-TestLog "  Overlay: $name - CLSID: $clsid" "INFO"
            
            # Check CLSID
            if ($clsid) {
                $clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$clsid"
                if (Test-Path $clsidPath) {
                    $serverPath = Join-Path $clsidPath "InprocServer32"
                    if (Test-Path $serverPath) {
                        $dllPath = (Get-ItemProperty -Path $serverPath -ErrorAction SilentlyContinue).'(Default)'
                        if (Test-Path $dllPath) {
                            Write-TestLog "    DLL: $dllPath (OK)" "SUCCESS"
                        } else {
                            Write-TestLog "    DLL: $dllPath (NOT FOUND - PROBLEM)" "ERROR"
                        }
                    }
                } else {
                    Write-TestLog "    CLSID not found (PROBLEM)" "ERROR"
                }
            }
        }
    } catch {
        Write-TestLog "Error checking overlay handlers: $($_.Exception.Message)" "ERROR"
    }
} else {
    Write-TestLog "ShellIconOverlayIdentifiers key not found" "WARNING"
}

# Test 3: Property Sheet Handlers
Write-TestLog "Testing Property Sheet Handlers..." "INFO"
$propertySheetKeys = @(
    "HKLM:\SOFTWARE\Classes\*\shellex\PropertySheetHandlers",
    "HKLM:\SOFTWARE\Classes\Directory\shellex\PropertySheetHandlers",
    "HKLM:\SOFTWARE\Classes\Drive\shellex\PropertySheetHandlers"
)

foreach ($key in $propertySheetKeys) {
    if (Test-Path $key) {
        Write-TestLog "Checking key: $key" "INFO"
        try {
            Get-ChildItem -Path $key -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $handlerName = $_.PSChildName
                $clsid = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).'(Default)'
                Write-TestLog "  Handler: $handlerName - CLSID: $clsid" "INFO"
                
                if ($clsid) {
                    $clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$clsid"
                    if (Test-Path $clsidPath) {
                        $serverPath = Join-Path $clsidPath "InprocServer32"
                        if (Test-Path $serverPath) {
                            $dllPath = (Get-ItemProperty -Path $serverPath -ErrorAction SilentlyContinue).'(Default)'
                            if (Test-Path $dllPath) {
                                Write-TestLog "    DLL: $dllPath (OK)" "SUCCESS"
                            } else {
                                Write-TestLog "    DLL: $dllPath (NOT FOUND - PROBLEM)" "ERROR"
                            }
                        }
                    } else {
                        Write-TestLog "    CLSID not found (PROBLEM)" "ERROR"
                    }
                }
            }
        } catch {
            Write-TestLog "Error checking property sheet handlers: $($_.Exception.Message)" "ERROR"
        }
    }
}

# Test 4: Namespace Extensions
Write-TestLog "Testing Namespace Extensions..." "INFO"
$namespaceKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace"

if (Test-Path $namespaceKey) {
    try {
        $job = Start-Job -ScriptBlock {
            param($regKey)
            if (Test-Path $regKey) {
                $results = @()
                Get-ChildItem -Path $regKey -ErrorAction SilentlyContinue | ForEach-Object {
                    $clsid = $_.PSChildName
                    $name = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).'(Default)'
                    $results += @{
                        CLSID = $clsid
                        Name = $name
                    }
                }
                return $results
            }
        } -ArgumentList $namespaceKey
        
        $result = Wait-Job $job -Timeout 10
        if ($result) {
            $namespaces = Receive-Job $job
            Write-TestLog "Found $($namespaces.Count) namespace extensions" "INFO"
            
            # Critical namespace CLSIDs
            $criticalNamespaces = @{
                "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" = "My Computer"
                "{450D8FBA-AD25-11D0-98A8-0800361B1103}" = "My Documents"
                "{208D2C60-3AEA-1069-A2D7-08002B30309D}" = "Network Places"
            }
            
            $foundCritical = @{}
            foreach ($ns in $namespaces) {
                Write-TestLog "  Namespace: $($ns.CLSID) - $($ns.Name)" "INFO"
                
                # Check if this is a critical namespace
                if ($criticalNamespaces.ContainsKey($ns.CLSID)) {
                    Write-TestLog "    Critical namespace found: $($criticalNamespaces[$ns.CLSID])" "SUCCESS"
                    $foundCritical[$ns.CLSID] = $true
                }
                
                # Check CLSID
                $clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$($ns.CLSID)"
                if (Test-Path $clsidPath) {
                    $serverPath = Join-Path $clsidPath "InprocServer32"
                    if (Test-Path $serverPath) {
                        $dllPath = (Get-ItemProperty -Path $serverPath -ErrorAction SilentlyContinue).'(Default)'
                        if ($dllPath -and (Test-Path $dllPath)) {
                            Write-TestLog "    DLL: $dllPath (OK)" "SUCCESS"
                        } else {
                            Write-TestLog "    DLL: $dllPath (NOT FOUND - PROBLEM)" "ERROR"
                        }
                    }
                } else {
                    Write-TestLog "    CLSID registration not found (PROBLEM)" "ERROR"
                }
            }
            
            # Check for missing critical namespaces
            foreach ($critical in $criticalNamespaces.GetEnumerator()) {
                if (-not $foundCritical.ContainsKey($critical.Key)) {
                    Write-TestLog "  MISSING critical namespace: $($critical.Value) ($($critical.Key))" "ERROR"
                    Write-TestLog "  This is likely causing shell navigation problems" "ERROR"
                }
            }
        } else {
            Write-TestLog "TIMEOUT accessing namespace registry! This key may be corrupted." "ERROR"
        }
        Remove-Job $job -Force
    } catch {
        Write-TestLog "Error checking namespace extensions: $($_.Exception.Message)" "ERROR"
    }
} else {
    Write-TestLog "Namespace extensions key not found (SERIOUS PROBLEM)" "ERROR"
}

# Summary and recommendations
Write-TestLog "=== TEST COMPLETED ===" "INFO"
Write-TestLog "Shell extension test completed. Look for ERROR entries above to identify problematic extensions." "INFO"
Write-TestLog "Log saved to: $logFile" "INFO"
Write-TestLog "RECOMMENDATIONS:" "INFO"
Write-TestLog "1. For any ERROR entries above, consider fixing or removing the problematic extensions" "INFO"
Write-TestLog "2. For registry timeouts, you may need to manually delete those keys and let Windows recreate them" "INFO"
Write-TestLog "3. For missing DLLs, try re-registering them using: regsvr32 [path-to-dll]" "INFO"
Write-TestLog "4. For missing namespace entries, run emergency_shell_repair.ps1 script" "INFO"

Write-Host "`n==== NEXT STEPS ====" -ForegroundColor Yellow
Write-Host "1. Look for ERROR entries in the log above" -ForegroundColor Cyan
Write-Host "2. Run compare_startup.ps1 to identify startup differences between safe and normal mode" -ForegroundColor Cyan
Write-Host "3. Run clean_boot_test.ps1 to test if the issue is related to third-party services" -ForegroundColor Cyan