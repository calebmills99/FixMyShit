# System Baseline Configuration Script
param([string]$BaselinePath = "C:\FixMyShit\Monitoring\Baselines")

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BaselineFile = "$BaselinePath\SystemBaseline_$Timestamp.json"

Write-Host "Creating system baseline: $BaselineFile"

$Baseline = @{
    Timestamp = (Get-Date).ToString()
    ComputerInfo = @{
        Name = $env:COMPUTERNAME
        OS = (Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber)
        CPU = (Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors)
        Memory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    }
    
    Services = (Get-Service -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq "Running"} | Select-Object Name, DisplayName, StartType)
}

$Baseline | ConvertTo-Json -Depth 4 | Set-Content -Path $BaselineFile
Write-Host "System baseline created successfully"

# Keep only last 5 baselines
$OldBaselines = Get-ChildItem $BaselinePath -File | Where-Object {$_.Name -like "SystemBaseline_*.json"} | Sort-Object CreationTime -Descending | Select-Object -Skip 5
foreach ($OldBaseline in $OldBaselines) {
    Remove-Item -Path $OldBaseline.FullName -Force
    Write-Host "Removed old baseline: $($OldBaseline.Name)"
}