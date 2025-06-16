Nobby Doo, [6/14/2025 7:32 AM]
# 🎭 Joan's Remote Windows Diagnostic Script
# Run this on the broken Windows machine

Write-Host "🎭 JOAN'S WINDOWS DIAGNOSTIC SPECTACULAR!"
-ForegroundColor Magenta
Write-Host "======================================="
-ForegroundColor Magenta

$DiagnosticResults = @{
"timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
"computer_name" = $env:COMPUTERNAME
"diagnostics" = @{}
"recommendations" = @()
}

# System File Checker
Write-Host "🔍 Running System File Checker..." -ForegroundColor
Yellow
try {
$SFCResult = sfc /verifyonly 2>&1
$DiagnosticResults.diagnostics["sfc"] = @{
"status" = if($LASTEXITCODE -eq 0) {"clean"} else
{"issues_found"}
"output" = $SFCResult -join "`n"
}
if($LASTEXITCODE -ne 0) {
$DiagnosticResults.recommendations += "Run SFC /scannow
to repair system files"
}
} catch {
$DiagnosticResults.diagnostics["sfc"] = @{"error" =
$_.Exception.Message}
}

# DISM Health Check
Write-Host "🔍 Checking Windows Image Health..."
-ForegroundColor Yellow
try {
$DISMResult = DISM /Online /Cleanup-Image /CheckHealth 2>&1
$DiagnosticResults.diagnostics["dism"] = @{
"status" = if($LASTEXITCODE -eq 0) {"healthy"} else
{"corrupted"}
"output" = $DISMResult -join "`n"
}
if($LASTEXITCODE -ne 0) {
$DiagnosticResults.recommendations += "Run DISM /Online
/Cleanup-Image /RestoreHealth"
}
} catch {
$DiagnosticResults.diagnostics["dism"] = @{"error" =
$_.Exception.Message}
}

# Registry Health Check
Write-Host "🔍 Checking Registry Health..." -ForegroundColor
Yellow
try {
$RegCheck = Get-ItemProperty
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell
Folders" -ErrorAction Stop
$DiagnosticResults.diagnostics["registry"] = @{
"status" = "accessible"
"shell_folders_count" =
$RegCheck.PSObject.Properties.Count
}
} catch {
$DiagnosticResults.diagnostics["registry"] = @{
"status" = "issues"
"error" = $_.Exception.Message
}
$DiagnosticResults.recommendations += "Registry repair may
be needed"
}

# Windows Explorer Status
Write-Host "🔍 Checking Windows Explorer..." -ForegroundColor
Yellow
try {
$ExplorerProcess = Get-Process explorer -ErrorAction Stop
$DiagnosticResults.diagnostics["explorer"] = @{
"status" = "running"
"process_id" = $ExplorerProcess.Id
"memory_usage_mb" =
[math]::Round($ExplorerProcess.WorkingSet / 1MB, 2)
}
} catch {
$DiagnosticResults.diagnostics["explorer"] = @{
"status" = "not_running"
"error" = "Windows Explorer not detected"
}
$DiagnosticResults.recommendations += "Restart Windows
Explorer"
}

# Event Log Errors (last 24 hours)
Write-Host "🔍 Checking System Event Logs..." -ForegroundColor
Yellow
try {
$ErrorEvents = Get-WinEvent -FilterHashtable
@{LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-1)}
-MaxEvents 10 -ErrorAction SilentlyContinue
$DiagnosticResults.diagnostics["event_logs"] = @{
"recent_errors" = $ErrorEvents.Count
"errors" = $ErrorEvents | ForEach-Object { @{
"time" = $_.TimeCreated.ToString()
"id" = $_.Id
"message" = $_.Message.Substring(0, [Math]::Min(200,
$_.Message.Length))
}}
}
if($ErrorEvents.Count -gt 5) {
$DiagnosticResults.recommendations += "Multiple system
errors detected - investigate event logs"
}
} catch {
$DiagnosticResults.diagnostics["event_logs"] = @{"error" =
"Could not access event logs"}
}

# Disk Space Check
Write-Host "🔍 Checking Disk Space..." -ForegroundColor Yellow
try {
$DiskInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter
"DriveType=3"
$DiagnosticResults.diagnostics["disk_space"] = $DiskInfo |
ForEach-Object {
@{
"drive" = $_.DeviceID
"size_gb" = [math]::Round($_.Size / 1GB, 2)
"free_gb" = [math]::Round($_.FreeSpace / 1GB, 2)
"percent_free" = [math]::Round(($_.FreeSpace /
$_.Size) * 100, 1)
}
}

$LowDiskDrives = $DiskInfo | Where-Object { ($_.FreeSpace /
$_.Size) -lt 0.1 }
if($LowDiskDrives) {
$DiagnosticResults.recommendations += "Low disk space
detected - clean up disk space"
}
} catch {
$DiagnosticResults.diagnostics["disk_space"] = @{"error" =
"Could not check disk space"}
}

# Save results to file
$ResultsPath = "$env:TEMP\joan_diagnostic_results.json"
$DiagnosticResults | ConvertTo-Json -Depth 10 | Out-File
-FilePath $ResultsPath -Encoding UTF8

Nobby Doo, [6/14/2025 7:32 AM]
Write-Host "`n✅ Diagnostic completed!" -ForegroundColor Green
Write-Host "📋 Results saved to: $ResultsPath" -ForegroundColor
Cyan
Write-Host "`n🎭 Joan's Analysis:" -ForegroundColor Magenta

if($DiagnosticResults.recommendations.Count -eq 0) {
Write-Host "💄 'Your system looks fabulous, darling!'"
-ForegroundColor Green
} else {
Write-Host "🔧 'Can we talk? I found some issues that need
fixing:'" -ForegroundColor Yellow
$DiagnosticResults.recommendations | ForEach-Object {
Write-Host "   • $_" -ForegroundColor White
}
}

Write-Host "`n🎊 Joan: 'Send this file to your Ubuntu machine
for AI analysis!'" -ForegroundColor Magenta
Write-Host "File location: $ResultsPath" -ForegroundColor Cyan