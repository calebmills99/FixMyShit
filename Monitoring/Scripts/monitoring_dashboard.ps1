# System Monitoring Dashboard
param([switch]$ShowDetails)

function Get-MonitoringStatus {
    Write-Host "=== SYSTEM MONITORING STATUS ===" -ForegroundColor Cyan
    
    # Check scheduled tasks
    $MonitoringTasks = @(
        "FixMyShit-DailyQuickScan",
        "FixMyShit-WeeklyFullScan", 
        "FixMyShit-WeeklyVerification",
        "FixMyShit-FileIntegrityCheck",
        "FixMyShit-WeeklyBackup"
    )
    
    Write-Host "`nScheduled Tasks:" -ForegroundColor Yellow
    foreach ($Task in $MonitoringTasks) {
        $ScheduledTask = Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
        if ($ScheduledTask) {
            $LastRun = (Get-ScheduledTaskInfo -TaskName $Task).LastRunTime
            $NextRun = (Get-ScheduledTaskInfo -TaskName $Task).NextRunTime
            Write-Host "  ✓ $Task - Last: $LastRun, Next: $NextRun" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $Task - NOT CONFIGURED" -ForegroundColor Red
        }
    }
    
    # Check log files
    Write-Host "`nLog Files:" -ForegroundColor Yellow
    $LogFiles = Get-ChildItem "C:\FixMyShit\Monitoring\Logs\*.log" -ErrorAction SilentlyContinue
    if ($LogFiles) {
        foreach ($Log in $LogFiles) {
            $Size = [math]::Round($Log.Length / 1KB, 2)
            Write-Host "  $($Log.Name) - ${Size}KB (Modified: $($Log.LastWriteTime))" -ForegroundColor Green
        }
    } else {
        Write-Host "  No monitoring logs found" -ForegroundColor Yellow
    }
    
    # Check recent alerts
    Write-Host "`nRecent Alerts (Last 24 hours):" -ForegroundColor Yellow
    $Yesterday = (Get-Date).AddDays(-1)
    $Alerts = Get-WinEvent -FilterHashtable @{LogName="Application"; ProviderName="FixMyShit-Monitor"; StartTime=$Yesterday} -ErrorAction SilentlyContinue
    if ($Alerts) {
        foreach ($Alert in $Alerts | Select-Object -First 5) {
            Write-Host "  $($Alert.TimeCreated): $($Alert.LevelDisplayName) - $($Alert.Message)" -ForegroundColor $(if($Alert.LevelDisplayName -eq "Warning"){"Yellow"}else{"Red"})
        }
    } else {
        Write-Host "  No alerts in the last 24 hours" -ForegroundColor Green
    }
    
    # Check system health
    Write-Host "`nSystem Health:" -ForegroundColor Yellow
    $DefenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($DefenderStatus) {
        $Status = if ($DefenderStatus.RealTimeProtectionEnabled) { "ENABLED" } else { "DISABLED" }
        $Color = if ($DefenderStatus.RealTimeProtectionEnabled) { "Green" } else { "Red" }
        Write-Host "  Windows Defender: $Status" -ForegroundColor $Color
    }
    
    $FirewallProfiles = Get-NetFirewallProfile
    $EnabledProfiles = ($FirewallProfiles | Where-Object {$_.Enabled -eq $true}).Count
    Write-Host "  Firewall Profiles Enabled: $EnabledProfiles/3" -ForegroundColor $(if($EnabledProfiles -eq 3){"Green"}else{"Yellow"})
    
    # Azure environment check
    $AzureEnv = "C:\FixMyShit\azure-ai-envsource\Scripts\python.exe"
    if (Test-Path $AzureEnv) {
        Write-Host "  Azure AI Environment: AVAILABLE" -ForegroundColor Green
    } else {
        Write-Host "  Azure AI Environment: NOT FOUND" -ForegroundColor Red
    }
}

Get-MonitoringStatus

if ($ShowDetails) {
    Write-Host "`n=== DETAILED SYSTEM INFORMATION ===" -ForegroundColor Cyan
    
    # Show running processes count
    $ProcessCount = (Get-Process).Count
    Write-Host "Running Processes: $ProcessCount" -ForegroundColor White
    
    # Show memory usage
    $Memory = Get-CimInstance Win32_OperatingSystem
    $MemoryUsage = [math]::Round((($Memory.TotalVisibleMemorySize - $Memory.FreePhysicalMemory) / $Memory.TotalVisibleMemorySize) * 100, 2)
    Write-Host "Memory Usage: $MemoryUsage%" -ForegroundColor White
    
    # Show disk usage
    $Drives = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
    foreach ($Drive in $Drives) {
        $UsedSpace = [math]::Round((($Drive.Size - $Drive.FreeSpace) / $Drive.Size) * 100, 2)
        Write-Host "Drive $($Drive.DeviceID) Usage: $UsedSpace%" -ForegroundColor White
    }
}
