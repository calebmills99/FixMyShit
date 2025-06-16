# Real-time System Monitoring Script
# This script runs continuously to monitor for suspicious activity

param([string]$LogPath = "C:\FixMyShit\Monitoring\Logs\realtime_monitor.log")

function Write-MonitorLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogEntry
    if ($Level -eq "ALERT") {
        Write-EventLog -LogName Application -Source "FixMyShit-Monitor" -EntryType Warning -EventId 1001 -Message $Message
    }
}

# Register event source if it doesn't exist
try {
    if (-not (Get-EventLog -LogName Application -Source "FixMyShit-Monitor" -ErrorAction SilentlyContinue)) {
        New-EventLog -LogName Application -Source "FixMyShit-Monitor"
    }
} catch {}

Write-MonitorLog "Real-time monitoring started"

# Monitor for suspicious process creation
Register-WmiEvent -Query "SELECT * FROM Win32_ProcessStartTrace" -Action {
    $Process = $Event.SourceEventArgs.NewEvent
    $ProcessName = $Process.ProcessName
    
    # Check for suspicious process names
    $SuspiciousNames = @("backdoor", "trojan", "malware", "hack", "exploit")
    foreach ($Suspicious in $SuspiciousNames) {
        if ($ProcessName -like "*$Suspicious*") {
            Write-MonitorLog "SUSPICIOUS PROCESS DETECTED: $ProcessName (PID: $($Process.ProcessID))" "ALERT"
        }
    }
    
    # Monitor for processes starting from temp directories
    if ($Process.ExecutablePath -like "*\Temp\*" -or $Process.ExecutablePath -like "*\tmp\*") {
        Write-MonitorLog "Process started from temp directory: $ProcessName at $($Process.ExecutablePath)" "ALERT"
    }
}

Write-MonitorLog "Process monitoring registered"

# Monitor for changes to critical registry keys
$RegKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($RegKey in $RegKeys) {
    try {
        Register-ObjectEvent -InputObject (Get-Item $RegKey) -EventName "Changed" -Action {
            Write-MonitorLog "Registry change detected in: $($Event.SourceIdentifier)" "ALERT"
        }
    } catch {
        Write-MonitorLog "Could not monitor registry key: $RegKey"
    }
}

Write-MonitorLog "Registry monitoring registered"

# Keep the script running
while ($true) {
    Start-Sleep 300  # Check every 5 minutes
    
    # Monitor system resources
    $CPU = Get-Counter "\Processor(_Total)\% Processor Time" | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
    if ($CPU -gt 90) {
        Write-MonitorLog "High CPU usage detected: $([math]::Round($CPU, 2))%" "ALERT"
    }
    
    # Check for new startup items
    $StartupItems = Get-CimInstance -ClassName Win32_StartupCommand
    foreach ($Item in $StartupItems) {
        if ($Item.Caption -like "*backdoor*" -or $Item.Caption -like "*trojan*") {
            Write-MonitorLog "Suspicious startup item: $($Item.Caption) - $($Item.Command)" "ALERT"
        }
    }
}
