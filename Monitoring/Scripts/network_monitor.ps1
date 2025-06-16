# Network Connection Monitoring Script
param([string]$LogPath = "C:\FixMyShit\Monitoring\Logs\network_monitor.log")

function Write-NetworkLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogEntry
    if ($Level -eq "ALERT") {
        Write-EventLog -LogName Application -Source "FixMyShit-Monitor" -EntryType Warning -EventId 1003 -Message $Message
    }
}

Write-NetworkLog "Network monitoring started"

while ($true) {
    try {
        # Get current network connections
        $Connections = Get-NetTCPConnection | Where-Object {$_.State -eq "Established"}
        
        foreach ($Conn in $Connections) {
            # Check for suspicious ports
            $SuspiciousPorts = @(1234, 4444, 5555, 6666, 8080, 9999)
            if ($Conn.RemotePort -in $SuspiciousPorts) {
                Write-NetworkLog "Suspicious connection detected: $($Conn.LocalAddress):$($Conn.LocalPort) -> $($Conn.RemoteAddress):$($Conn.RemotePort)" "ALERT"
            }
            
            # Check for connections to known malicious IP ranges (example)
            $RemoteIP = $Conn.RemoteAddress
            if ($RemoteIP -like "10.0.0.*" -and $Conn.RemotePort -gt 8000) {
                Write-NetworkLog "Potentially suspicious internal connection: $RemoteIP:$($Conn.RemotePort)" "ALERT"
            }
        }
        
        # Monitor DNS queries for suspicious domains
        $DNSCache = Get-DnsClientCache | Where-Object {$_.TimeToLive -lt 60}
        foreach ($Entry in $DNSCache) {
            $SuspiciousDomains = @("malware", "backdoor", "trojan", "hack")
            foreach ($Suspicious in $SuspiciousDomains) {
                if ($Entry.Name -like "*$Suspicious*") {
                    Write-NetworkLog "Suspicious DNS query: $($Entry.Name)" "ALERT"
                }
            }
        }
        
    } catch {
        Write-NetworkLog "Error in network monitoring: $($_.Exception.Message)" "ERROR"
    }
    
    Start-Sleep 60  # Check every minute
}
