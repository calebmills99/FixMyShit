# Automated System Configuration Backup Script
param([string]$BackupPath = "C:\FixMyShit\Monitoring\Backups")

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir = "$BackupPath\Backup_$Timestamp"

if (-not (Test-Path $BackupDir)) {
    New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
}

Write-Host "Creating system configuration backup in $BackupDir..."

try {
    # Backup registry keys
    $RegKeys = @(
        @{Key="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; File="HKLM_Run.reg"},
        @{Key="HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; File="HKCU_Run.reg"},
        @{Key="HKLM\SYSTEM\CurrentControlSet\Services"; File="Services.reg"}
    )
    
    foreach ($RegKey in $RegKeys) {
        $RegFile = "$BackupDir\$($RegKey.File)"
        reg export $RegKey.Key $RegFile /y 2>$null
        if (Test-Path $RegFile) {
            Write-Host "Exported: $($RegKey.Key)"
        }
    }
    
    # Backup security policies
    secedit /export /cfg "$BackupDir\SecurityPolicy.inf" 2>$null
    
    # Backup firewall configuration
    netsh advfirewall export "$BackupDir\FirewallConfig.wfw" 2>$null
    
    # Backup scheduled tasks
    schtasks /query /fo CSV > "$BackupDir\ScheduledTasks.csv"
    
    # Backup event log configuration
    wevtutil el | ForEach-Object {
        $LogName = $_
        $LogInfo = wevtutil gl "$LogName" 2>$null
        if ($LogInfo) {
            Add-Content -Path "$BackupDir\EventLogConfig.txt" -Value "=== $LogName ==="
            Add-Content -Path "$BackupDir\EventLogConfig.txt" -Value $LogInfo
        }
    }
    
    # Create backup manifest
    $Manifest = @{
        BackupDate = (Get-Date).ToString()
        ComputerName = $env:COMPUTERNAME
        WindowsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
        Files = (Get-ChildItem $BackupDir | Select-Object Name, Length, LastWriteTime)
    }
    
    $Manifest | ConvertTo-Json -Depth 3 | Set-Content -Path "$BackupDir\manifest.json"
    
    Write-Host "Backup completed successfully: $BackupDir"
    
    # Clean up old backups (keep last 10)
    $OldBackups = Get-ChildItem $BackupPath -Directory | Where-Object {$_.Name -like "Backup_*"} | Sort-Object CreationTime -Descending | Select-Object -Skip 10
    foreach ($OldBackup in $OldBackups) {
        Remove-Item -Path $OldBackup.FullName -Recurse -Force
        Write-Host "Removed old backup: $($OldBackup.Name)"
    }
    
} catch {
    Write-Host "Error during backup: $($_.Exception.Message)" -ForegroundColor Red
}
