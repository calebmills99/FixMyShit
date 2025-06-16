#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Checks shell overlay handlers and shell loading components
.DESCRIPTION
    This script examines shell icons, overlay handlers, and other shell components
    that might be causing shell malfunctions in normal mode but not in safe mode.
#>

$logFile = ".\shell_overlays_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-OverlayLog {
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

Write-OverlayLog "=== SHELL OVERLAY HANDLERS CHECK STARTED ===" "INFO"
Write-OverlayLog "This script will examine shell components that often cause problems" "INFO"

# Function to check registry key with timeout protection
function Test-RegistryKeyWithTimeout {
    param(
        [string]$Key,
        [int]$TimeoutSeconds = 10
    )
    
    Write-OverlayLog "Checking registry key: $Key (with timeout protection)" "INFO"
    
    $job = Start-Job -ScriptBlock {
        param($regKey)
        try {
            if (Test-Path $regKey) {
                $items = Get-ChildItem -Path $regKey -ErrorAction Stop
                return @{
                    Success = $true
                    Items = $items
                    Count = $items.Count
                }
            } else {
                return @{
                    Success = $false
                    Error = "Registry path not found"
                    Count = 0
                }
            }
        } catch {
            return @{
                Success = $false
                Error = $_.Exception.Message
                Count = 0
            }
        }
    } -ArgumentList $Key
    
    $result = Wait-Job $job -Timeout $TimeoutSeconds
    
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job -Force
        return $output
    } else {
        Remove-Job $job -Force
        return @{
            Success = $false
            Error = "TIMEOUT - Registry key may be corrupted"
            Count = 0
            Timeout = $true
        }
    }
}

# Section 1: Shell Icon Overlays
Write-OverlayLog "Testing Shell Icon Overlay Handlers..." "INFO"

$overlayKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers"
$overlayResult = Test-RegistryKeyWithTimeout -Key $overlayKey

if ($overlayResult.Success) {
    Write-OverlayLog "Found $($overlayResult.Count) icon overlay handlers" "INFO"
    
    foreach ($overlay in $overlayResult.Items) {
        $name = $overlay.PSChildName
        try {
            $clsid = (Get-ItemProperty -Path $overlay.PSPath -ErrorAction SilentlyContinue).'(Default)'
            Write-OverlayLog "  Overlay: $name - CLSID: $clsid" "INFO"
            
            # Check CLSID registration
            $clsidPath = "HKLM:\SOFTWARE\Classes\CLSID\$clsid"
            if (Test-Path $clsidPath) {
                $clsidInfo = Get-ItemProperty -Path $clsidPath -ErrorAction SilentlyContinue
                Write-OverlayLog "    CLSID registered as: $($clsidInfo.'(Default)')" "SUCCESS"
                
                # Check InprocServer32
                $serverPath = Join-Path $clsidPath "InprocServer32"
                if (Test-Path $serverPath) {
                    $serverInfo = Get-ItemProperty -Path $serverPath -ErrorAction SilentlyContinue
                    $dllPath = $serverInfo.'(Default)'
                    Write-OverlayLog "    DLL path: $dllPath" "INFO"
                    
                    # Check if DLL exists and is valid
                    if (Test-Path $dllPath) {
                        try {
                            $fileInfo = Get-Item -Path $dllPath -ErrorAction SilentlyContinue
                            $fileSigned = Get-AuthenticodeSignature -FilePath $dllPath -ErrorAction SilentlyContinue
                            
                            if ($fileSigned.Status -eq "Valid") {
                                Write-OverlayLog "    DLL signature: Valid ($($fileSigned.SignerCertificate.Subject))" "SUCCESS"
                            } else {
                                Write-OverlayLog "    DLL signature: $($fileSigned.Status) (POTENTIAL ISSUE)" "WARNING"
                            }
                        } catch {
                            Write-OverlayLog "    Error checking DLL: $($_.Exception.Message)" "ERROR"
                        }
                    } else {
                        Write-OverlayLog "    DLL does not exist: $dllPath (PROBLEM)" "ERROR"
                    }
                } else {
                    Write-OverlayLog "    InprocServer32 key missing (PROBLEM)" "ERROR"
                }
            } else {
                Write-OverlayLog "    CLSID not registered in registry (PROBLEM)" "ERROR"
            }
        } catch {
            Write-OverlayLog "    Error processing overlay: $($_.Exception.Message)" "ERROR"
        }
    }
} elseif ($overlayResult.Timeout) {
    Write-OverlayLog "TIMEOUT accessing overlay handlers registry key - likely corrupted" "ERROR"
    Write-OverlayLog "This is a common cause of shell problems" "ERROR"
} else {
    Write-OverlayLog "Error accessing overlay handlers: $($overlayResult.Error)" "ERROR"
}

# Section 2: Context Menu Handlers (problematic ones)
Write-OverlayLog "Testing Context Menu Handlers (most common problem area)..." "INFO"

$contextMenuKeys = @(
    "HKLM:\SOFTWARE\Classes\*\shellex\ContextMenuHandlers",
    "HKLM:\SOFTWARE\Classes\Directory\shellex\ContextMenuHandlers",
    "HKLM:\SOFTWARE\Classes\Folder\shellex\ContextMenuHandlers"
)

foreach ($key in $contextMenuKeys) {
    $keyResult = Test-RegistryKeyWithTimeout -Key $key
    
    if ($keyResult.Success) {
        Write-OverlayLog "Context menu key: $key - $($keyResult.Count) handlers" "SUCCESS"
        
        # We don't need to list all handlers here as that's done in test_shell_extensions.ps1
    } elseif ($keyResult.Timeout) {
        Write-OverlayLog "TIMEOUT on context menu key: $key (HIGH PROBABILITY ISSUE)" "ERROR"
        Write-OverlayLog "This registry key is likely corrupted and needs to be fixed" "ERROR"
        
        # Export the problematic key name to a file for easy reference
        $keyName = $key.Split('\')[-1]
        "Corrupted shell key: $key" | Out-File -FilePath ".\corrupted_shell_key.txt" -Append
    } else {
        Write-OverlayLog "Error accessing context menu key: $($keyResult.Error)" "ERROR"
    }
}

# Section 3: Critical Shell Explorer Components
Write-OverlayLog "Testing Critical Shell Explorer Components..." "INFO"

# Check if explorer.exe is present
$explorerPath = "$env:windir\explorer.exe"
if (Test-Path $explorerPath) {
    $explorerInfo = Get-Item $explorerPath -ErrorAction SilentlyContinue
    Write-OverlayLog "Explorer.exe found: $explorerPath (Size: $($explorerInfo.Length) bytes)" "SUCCESS"
    
    # Check if it's properly signed
    $signature = Get-AuthenticodeSignature -FilePath $explorerPath -ErrorAction SilentlyContinue
    if ($signature.Status -eq "Valid") {
        Write-OverlayLog "Explorer.exe signature: Valid" "SUCCESS"
    } else {
        Write-OverlayLog "Explorer.exe signature: $($signature.Status) (SERIOUS ISSUE)" "ERROR"
    }
} else {
    Write-OverlayLog "Explorer.exe NOT FOUND at expected location: $explorerPath (CRITICAL)" "ERROR"
}

# Check critical explorer registry keys
$explorerKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellExecuteHooks",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects"
)

foreach ($key in $explorerKeys) {
    $keyResult = Test-RegistryKeyWithTimeout -Key $key
    
    if ($keyResult.Success) {
        Write-OverlayLog "Explorer key: $key - $($keyResult.Count) items" "SUCCESS"
    } elseif ($keyResult.Timeout) {
        Write-OverlayLog "TIMEOUT on explorer key: $key (HIGH PROBABILITY ISSUE)" "ERROR"
    } else {
        Write-OverlayLog "Error accessing explorer key: $($keyResult.Error)" "ERROR"
    }
}

# Section 4: Critical Namespace Components
Write-OverlayLog "Testing Critical Namespace Components..." "INFO"

$criticalNamespaces = @(
    @{CLSID="{20D04FE0-3AEA-1069-A2D8-08002B30309D}"; Name="My Computer"},
    @{CLSID="{450D8FBA-AD25-11D0-98A8-0800361B1103}"; Name="My Documents"},
    @{CLSID="{208D2C60-3AEA-1069-A2D7-08002B30309D}"; Name="Network Places"}
)

$namespaceKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace"
$nsResult = Test-RegistryKeyWithTimeout -Key $namespaceKey

if ($nsResult.Success) {
    # Check for each critical namespace
    foreach ($ns in $criticalNamespaces) {
        $nsPath = "$namespaceKey\$($ns.CLSID)"
        if (Test-Path $nsPath) {
            Write-OverlayLog "Critical namespace found: $($ns.Name) ($($ns.CLSID))" "SUCCESS"
        } else {
            Write-OverlayLog "MISSING critical namespace: $($ns.Name) ($($ns.CLSID))" "ERROR"
            
            # Add to repair list
            "Missing namespace: $($ns.Name) ($($ns.CLSID))" | Out-File -FilePath ".\missing_namespaces.txt" -Append
        }
    }
} elseif ($nsResult.Timeout) {
    Write-OverlayLog "TIMEOUT accessing namespace key (CRITICAL ISSUE)" "ERROR"
} else {
    Write-OverlayLog "Error accessing namespace key: $($nsResult.Error)" "ERROR"
}

# Section 5: File Associations
Write-OverlayLog "Testing Critical File Associations..." "INFO"

$criticalExtensions = @(
    ".exe", ".dll", ".txt", ".ps1", ".bat", ".cmd", ".reg"
)

foreach ($ext in $criticalExtensions) {
    try {
        $assocResult = (cmd /c "assoc $ext" 2>&1)
        if ($assocResult -like "$ext=*") {
            Write-OverlayLog "File association ${ext}: $assocResult" "SUCCESS"
        } else {
            Write-OverlayLog "Missing file association for $ext" "WARNING"
            "Missing file association: $ext" | Out-File -FilePath ".\missing_file_associations.txt" -Append
        }
    } catch {
        Write-OverlayLog "Error checking file association for ${ext}: $($_.Exception.Message)" "ERROR"
    }
}

# Section 6: Check Shell Loading Performance
Write-OverlayLog "Testing Shell Loading Performance..." "INFO"

try {
    $shellStartTime = Get-Date
    $shell = New-Object -ComObject Shell.Application
    $shellEndTime = Get-Date
    $timeToLoadShell = ($shellEndTime - $shellStartTime).TotalMilliseconds
    
    Write-OverlayLog "Shell.Application load time: $timeToLoadShell ms" $(if ($timeToLoadShell -lt 500) {"SUCCESS"} else {"WARNING"})
    
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
} catch {
    Write-OverlayLog "Error loading Shell.Application COM object: $($_.Exception.Message)" "ERROR"
}

# Summary and recommendations
Write-OverlayLog "=== SHELL OVERLAY CHECK COMPLETED ===" "INFO"
Write-OverlayLog "Log saved to: $logFile" "INFO"

# Check if we found any serious issues
$foundIssues = $false
$issueTypes = @()

if (Test-Path ".\corrupted_shell_key.txt") {
    $foundIssues = $true
    $issueTypes += "Corrupted shell registry keys"
}

if (Test-Path ".\missing_namespaces.txt") {
    $foundIssues = $true
    $issueTypes += "Missing critical namespace components"
}

if (Test-Path ".\missing_file_associations.txt") {
    $foundIssues = $true
    $issueTypes += "Missing file associations"
}

if (-not (Test-Path "$env:windir\explorer.exe")) {
    $foundIssues = $true
    $issueTypes += "Missing explorer.exe"
}

# Display appropriate recommendations based on findings
Write-OverlayLog "RECOMMENDATIONS:" "INFO"

if ($foundIssues) {
    Write-OverlayLog "The following issues were detected:" "WARNING"
    foreach ($issue in $issueTypes) {
        Write-OverlayLog "- $issue" "WARNING"
    }
    
    Write-OverlayLog "1. Run emergency_shell_repair.ps1 with the -ForceRepair parameter" "INFO"
    Write-OverlayLog "2. If repair script doesn't fix the issue, consider renaming/deleting corrupted registry keys" "INFO"
    Write-OverlayLog "3. For missing namespaces, run: reg import default_namespaces.reg (after creating it)" "INFO"
} else {
    Write-OverlayLog "No critical shell overlay issues detected." "SUCCESS"
    Write-OverlayLog "Continue with other diagnostic steps:" "INFO"
    Write-OverlayLog "1. Run compare_startup.ps1 to identify startup differences" "INFO"
    Write-OverlayLog "2. Run clean_boot_test.ps1 to test with minimal services" "INFO"
}

# Display final instructions
Write-Host "`n==== NEXT STEPS ====" -ForegroundColor Yellow

if ($foundIssues) {
    Write-Host "Critical shell issues detected! Follow these steps:" -ForegroundColor Red
    Write-Host "1. Run the emergency_shell_repair.ps1 script with -ForceRepair parameter:" -ForegroundColor Cyan
    Write-Host "   .\emergency_shell_repair.ps1 -ForceRepair" -ForegroundColor White
    Write-Host "2. Restart your computer" -ForegroundColor Cyan
    Write-Host "3. If issues persist, consider manual repair of corrupted registry keys" -ForegroundColor Cyan
} else {
    Write-Host "No critical shell overlay issues detected. Continue with:" -ForegroundColor Green
    Write-Host "1. Run test_shell_extensions.ps1 for a more detailed shell extension analysis" -ForegroundColor Cyan
    Write-Host "2. Run compare_startup.ps1 in both safe and normal mode to identify differences" -ForegroundColor Cyan
    Write-Host "3. Run clean_boot_test.ps1 to test with minimal services" -ForegroundColor Cyan
}