#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Explorer Shell Repair Script - EMERGENCY RESPONSE
.DESCRIPTION
    Re-registers Windows shell components, restarts Explorer with clean state,
    fixes file associations, and repairs Windows Search and indexing.
.NOTES
    Author: Kilo Code - Emergency Malware Response
    Version: 1.0
    Created: 2025-06-14
    CRITICAL: Run with Administrator privileges
    WARNING: This script modifies critical Windows shell components
#>

param(
    [string]$LogPath = ".\repair_shell_$(Get-Date -Format 'yyyyMMdd_HHmmss').log",
    [switch]$Force = $false,
    [switch]$SkipRestart = $false
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
$global:TotalTasks = 10
$global:CurrentTask = 0

function Update-Progress {
    param([string]$Activity, [string]$Status)
    $global:CurrentTask++
    $percentComplete = [math]::Round(($global:CurrentTask / $global:TotalTasks) * 100)
    Write-Progress -Activity "Explorer Shell Repair" -Status "$Activity - $Status" -PercentComplete $percentComplete
}

# Register DLL safely
function Register-DllSafe {
    param([string]$DllPath, [string]$Description)
    
    if (Test-Path $DllPath) {
        try {
            $process = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s", "`"$DllPath`"" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-LogMessage "Successfully registered: $Description ($DllPath)" "SUCCESS"
                return $true
            }
            else {
                Write-LogMessage "Failed to register: $Description ($DllPath) - Exit code: $($process.ExitCode)" "ERROR"
                return $false
            }
        }
        catch {
            Write-LogMessage "Error registering $Description : $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    else {
        Write-LogMessage "DLL not found: $DllPath" "WARNING"
        return $false
    }
}

# Unregister and re-register DLL
function Repair-DllRegistration {
    param([string]$DllPath, [string]$Description)
    
    if (Test-Path $DllPath) {
        try {
            # Unregister first
            $unregProcess = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/u", "/s", "`"$DllPath`"" -Wait -PassThru -NoNewWindow
            
            # Re-register
            $regProcess = Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s", "`"$DllPath`"" -Wait -PassThru -NoNewWindow
            
            if ($regProcess.ExitCode -eq 0) {
                Write-LogMessage "Successfully repaired registration: $Description" "SUCCESS"
                return $true
            }
            else {
                Write-LogMessage "Failed to repair registration: $Description - Exit code: $($regProcess.ExitCode)" "ERROR"
                return $false
            }
        }
        catch {
            Write-LogMessage "Error repairing $Description registration: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    else {
        Write-LogMessage "DLL not found for repair: $DllPath" "WARNING"
        return $false
    }
}

# Kill Explorer safely
function Stop-ExplorerSafe {
    try {
        $explorerProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($explorerProcesses) {
            Write-LogMessage "Stopping Explorer processes..." "INFO"
            $explorerProcesses | Stop-Process -Force
            Start-Sleep -Seconds 3
            
            # Verify Explorer is stopped
            $remainingProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
            if ($remainingProcesses) {
                Write-LogMessage "Some Explorer processes still running, forcing termination..." "WARNING"
                $remainingProcesses | Stop-Process -Force
                Start-Sleep -Seconds 2
            }
            
            Write-LogMessage "Explorer processes stopped successfully" "SUCCESS"
            return $true
        }
        else {
            Write-LogMessage "No Explorer processes found running" "INFO"
            return $true
        }
    }
    catch {
        Write-LogMessage "Error stopping Explorer: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Start Explorer safely
function Start-ExplorerSafe {
    try {
        # Check if Explorer is already running
        $existingProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($existingProcesses) {
            Write-LogMessage "Explorer already running with PID(s): $($existingProcesses.Id -join ', ')" "INFO"
            return $true
        }
        
        Write-LogMessage "Starting Explorer process..." "INFO"
        $process = Start-Process -FilePath "explorer.exe" -PassThru
        Start-Sleep -Seconds 5
        
        # Verify Explorer started successfully
        $newProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($newProcesses) {
            Write-LogMessage "Explorer started successfully with PID(s): $($newProcesses.Id -join ', ')" "SUCCESS"
            return $true
        }
        else {
            Write-LogMessage "Explorer failed to start" "ERROR"
            return $false
        }
    }
    catch {
        Write-LogMessage "Error starting Explorer: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

try {
    Write-LogMessage "=== EXPLORER SHELL REPAIR INITIATED ===" "WARNING"
    Write-LogMessage "Repair started at: $(Get-Date)"
    Write-LogMessage "Log file: $LogPath"

    # Task 1: Stop Explorer process
    Update-Progress "Explorer Control" "Stopping Explorer process"
    if (-not (Stop-ExplorerSafe)) {
        Write-LogMessage "Warning: Could not safely stop Explorer, continuing..." "WARNING"
    }

    # Task 2: Re-register core shell components
    Update-Progress "Shell Registration" "Re-registering core shell DLLs"
    
    $CoreShellDlls = @(
        @{ Path = "$env:WINDIR\System32\shell32.dll"; Description = "Windows Shell Common Dll" },
        @{ Path = "$env:WINDIR\System32\ole32.dll"; Description = "Microsoft OLE for Windows" },
        @{ Path = "$env:WINDIR\System32\oleaut32.dll"; Description = "OLE Automation" },
        @{ Path = "$env:WINDIR\System32\actxprxy.dll"; Description = "ActiveX Interface Marshaling Library" },
        @{ Path = "$env:WINDIR\System32\mshtml.dll"; Description = "Microsoft HTML Viewer" },
        @{ Path = "$env:WINDIR\System32\shdocvw.dll"; Description = "Shell Doc Object and Control Library" },
        @{ Path = "$env:WINDIR\System32\browseui.dll"; Description = "Shell Browser UI Library" },
        @{ Path = "$env:WINDIR\System32\jscript.dll"; Description = "Microsoft JScript" },
        @{ Path = "$env:WINDIR\System32\vbscript.dll"; Description = "Microsoft VBScript" },
        @{ Path = "$env:WINDIR\System32\scrrun.dll"; Description = "Microsoft Script Runtime" }
    )

    $successCount = 0
    foreach ($dll in $CoreShellDlls) {
        if (Repair-DllRegistration -DllPath $dll.Path -Description $dll.Description) {
            $successCount++
        }
    }
    
    Write-LogMessage "Shell DLL registration: $successCount/$($CoreShellDlls.Count) successful" "INFO"

    # Task 3: Re-register Explorer shell extensions
    Update-Progress "Shell Extensions" "Re-registering Explorer extensions"
    
    $ShellExtensions = @(
        @{ Path = "$env:WINDIR\System32\zipfldr.dll"; Description = "Compressed Folders" },
        @{ Path = "$env:WINDIR\System32\thumbcache.dll"; Description = "Thumbnail Cache" },
        @{ Path = "$env:WINDIR\System32\iedkcs32.dll"; Description = "Internet Explorer Development Kit" },
        @{ Path = "$env:WINDIR\System32\url.dll"; Description = "Internet Shortcut Shell Extension" },
        @{ Path = "$env:WINDIR\System32\urlmon.dll"; Description = "OLE32 Extensions for Win32" },
        @{ Path = "$env:WINDIR\System32\shlwapi.dll"; Description = "Shell Light-weight Utility Library" }
    )

    foreach ($extension in $ShellExtensions) {
        Register-DllSafe -DllPath $extension.Path -Description $extension.Description
    }

    # Task 4: Reset file associations for critical file types
    Update-Progress "File Associations" "Resetting critical file associations"
    
    $CriticalAssociations = @(
        @{ Extension = ".exe"; ProgId = "exefile" },
        @{ Extension = ".lnk"; ProgId = "lnkfile" },
        @{ Extension = ".txt"; ProgId = "txtfile" },
        @{ Extension = ".bat"; ProgId = "batfile" },
        @{ Extension = ".cmd"; ProgId = "cmdfile" }
    )

    foreach ($assoc in $CriticalAssociations) {
        try {
            $currentAssoc = cmd /c "assoc $($assoc.Extension)" 2>$null
            if ($currentAssoc -notmatch $assoc.ProgId) {
                cmd /c "assoc $($assoc.Extension)=$($assoc.ProgId)" 2>$null
                Write-LogMessage "Reset file association: $($assoc.Extension) -> $($assoc.ProgId)" "SUCCESS"
            }
            else {
                Write-LogMessage "File association correct: $($assoc.Extension) -> $($assoc.ProgId)" "INFO"
            }
        }
        catch {
            Write-LogMessage "Error setting file association $($assoc.Extension): $($_.Exception.Message)" "ERROR"
        }
    }

    # Task 5: Repair registry shell settings
    Update-Progress "Registry Repair" "Fixing shell registry entries"
    
    try {
        # Ensure Explorer shell is properly registered
        $explorerPath = "$env:WINDIR\explorer.exe"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "Shell" -Value $explorerPath -Force
        Write-LogMessage "Set Explorer as default shell in registry" "SUCCESS"
        
        # Reset taskbar settings
        $taskbarKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (Test-Path $taskbarKey) {
            Set-ItemProperty -Path $taskbarKey -Name "TaskbarGlomLevel" -Value 0 -Force -ErrorAction SilentlyContinue
            Write-LogMessage "Reset taskbar grouping settings" "SUCCESS"
        }
        
        # Reset Explorer folder options
        $folderKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (Test-Path $folderKey) {
            Set-ItemProperty -Path $folderKey -Name "Hidden" -Value 2 -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $folderKey -Name "HideFileExt" -Value 0 -Force -ErrorAction SilentlyContinue
            Write-LogMessage "Reset folder view options" "SUCCESS"
        }
    }
    catch {
        Write-LogMessage "Error repairing registry settings: $($_.Exception.Message)" "ERROR"
    }

    # Task 6: Clear icon cache
    Update-Progress "Cache Cleanup" "Clearing icon and thumbnail cache"
    
    try {
        $iconCachePath = "$env:LOCALAPPDATA\IconCache.db"
        if (Test-Path $iconCachePath) {
            Remove-Item -Path $iconCachePath -Force -ErrorAction SilentlyContinue
            Write-LogMessage "Cleared icon cache" "SUCCESS"
        }
        
        $thumbCachePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        if (Test-Path $thumbCachePath) {
            Get-ChildItem -Path $thumbCachePath -Filter "thumbcache*.db" -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-LogMessage "Cleared thumbnail cache" "SUCCESS"
        }
    }
    catch {
        Write-LogMessage "Error clearing cache: $($_.Exception.Message)" "ERROR"
    }

    # Task 7: Restart Windows Search service
    Update-Progress "Search Service" "Restarting Windows Search"
    
    try {
        $searchService = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
        if ($searchService) {
            if ($searchService.Status -eq "Running") {
                Stop-Service -Name "WSearch" -Force
                Write-LogMessage "Stopped Windows Search service" "INFO"
            }
            
            Start-Service -Name "WSearch"
            Write-LogMessage "Started Windows Search service" "SUCCESS"
        }
        else {
            Write-LogMessage "Windows Search service not found" "WARNING"
        }
    }
    catch {
        Write-LogMessage "Error restarting Windows Search: $($_.Exception.Message)" "ERROR"
    }

    # Task 8: Reset Windows indexing
    Update-Progress "Search Indexing" "Resetting search indexing"
    
    try {
        # Reset search indexer
        $indexerPath = "$env:PROGRAMDATA\Microsoft\Search\Data"
        if (Test-Path $indexerPath) {
            Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            Get-ChildItem -Path $indexerPath -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            
            Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
            Write-LogMessage "Reset search indexing database" "SUCCESS"
        }
    }
    catch {
        Write-LogMessage "Error resetting search indexing: $($_.Exception.Message)" "ERROR"
    }

    # Task 9: Rebuild Start Menu cache
    Update-Progress "Start Menu" "Rebuilding Start Menu cache"
    
    try {
        $startMenuCache = "$env:LOCALAPPDATA\Microsoft\Windows\Caches"
        if (Test-Path $startMenuCache) {
            Get-ChildItem -Path $startMenuCache -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-LogMessage "Cleared Start Menu cache" "SUCCESS"
        }
        
        # Reset Start Menu layout
        $startMenuKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (Test-Path $startMenuKey) {
            Remove-ItemProperty -Path $startMenuKey -Name "Start_TrackProgs" -Force -ErrorAction SilentlyContinue
            Write-LogMessage "Reset Start Menu tracking" "SUCCESS"
        }
    }
    catch {
        Write-LogMessage "Error rebuilding Start Menu: $($_.Exception.Message)" "ERROR"
    }

    # Task 10: Restart Explorer
    Update-Progress "Explorer Restart" "Starting Explorer with clean state"
    
    if (-not $SkipRestart) {
        if (Start-ExplorerSafe) {
            Write-LogMessage "Explorer restarted successfully with clean shell" "SUCCESS"
        }
        else {
            Write-LogMessage "Explorer failed to restart - manual intervention required" "ERROR"
        }
    }
    else {
        Write-LogMessage "Skipping Explorer restart as requested" "INFO"
    }

    # Final Summary
    Write-Progress -Activity "Explorer Shell Repair" -Completed
    Write-LogMessage "=== EXPLORER SHELL REPAIR COMPLETED ===" "SUCCESS"
    Write-LogMessage "Repair completed at: $(Get-Date)"
    
    # Display summary
    Write-Host "`n=== SHELL REPAIR SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Log file created: $LogPath" -ForegroundColor Green
    Write-Host "Core shell components re-registered" -ForegroundColor Green
    Write-Host "File associations reset for critical types" -ForegroundColor Green
    Write-Host "Icon and thumbnail cache cleared" -ForegroundColor Green
    Write-Host "Windows Search service restarted" -ForegroundColor Green
    
    if (-not $SkipRestart) {
        Write-Host "Explorer restarted with clean shell state" -ForegroundColor Green
        Write-Host "`nShell repair completed. Test Explorer functionality:" -ForegroundColor White
        Write-Host "- Check if file icons display correctly" -ForegroundColor White
        Write-Host "- Verify context menus work properly" -ForegroundColor White
        Write-Host "- Test file associations" -ForegroundColor White
        Write-Host "- Confirm Start Menu functionality" -ForegroundColor White
    }
    else {
        Write-Host "Explorer restart was skipped" -ForegroundColor Yellow
        Write-Host "Please restart Explorer manually or reboot system" -ForegroundColor Yellow
    }

}
catch {
    Write-LogMessage "CRITICAL ERROR during shell repair: $($_.Exception.Message)" "ERROR"
    Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    
    # Attempt emergency Explorer restart
    try {
        Write-LogMessage "Attempting emergency Explorer restart..." "WARNING"
        Start-ExplorerSafe
    }
    catch {
        Write-LogMessage "Emergency Explorer restart failed" "ERROR"
    }
    
    exit 1
}
finally {
    Write-Progress -Activity "Explorer Shell Repair" -Completed
}