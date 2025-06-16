# File Integrity Monitoring Script
param([string]$BaselinePath = "C:\FixMyShit\Monitoring\Baselines")

function Get-FileHash {
    param([string]$FilePath)
    try {
        return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    } catch {
        return $null
    }
}

function Create-Baseline {
    param([string]$Directory, [string]$BaselineName)
    
    Write-Host "Creating baseline for $Directory..."
    $Files = Get-ChildItem -Path $Directory -Recurse -File -ErrorAction SilentlyContinue
    $Baseline = @{}
    
    foreach ($File in $Files) {
        $Hash = Get-FileHash -FilePath $File.FullName
        if ($Hash) {
            $Baseline[$File.FullName] = @{
                Hash = $Hash
                Size = $File.Length
                LastModified = $File.LastWriteTime
            }
        }
    }
    
    $BaselineFile = "$BaselinePath\$BaselineName.json"
    $Baseline | ConvertTo-Json -Depth 3 | Set-Content -Path $BaselineFile
    Write-Host "Baseline saved to $BaselineFile"
}

function Check-Integrity {
    param([string]$Directory, [string]$BaselineName)
    
    $BaselineFile = "$BaselinePath\$BaselineName.json"
    if (-not (Test-Path $BaselineFile)) {
        Write-Host "Baseline not found: $BaselineFile" -ForegroundColor Red
        return
    }
    
    $Baseline = Get-Content -Path $BaselineFile | ConvertFrom-Json
    $CurrentFiles = Get-ChildItem -Path $Directory -Recurse -File -ErrorAction SilentlyContinue
    
    Write-Host "Checking integrity for $Directory..."
    $Changes = @()
    
    foreach ($File in $CurrentFiles) {
        $CurrentHash = Get-FileHash -FilePath $File.FullName
        if ($CurrentHash -and $Baseline.($File.FullName)) {
            $BaselineInfo = $Baseline.($File.FullName)
            if ($CurrentHash -ne $BaselineInfo.Hash) {
                $Changes += "MODIFIED: $($File.FullName)"
            }
        } elseif ($CurrentHash) {
            $Changes += "NEW: $($File.FullName)"
        }
    }
    
    # Check for deleted files
    foreach ($BaselineFile in $Baseline.PSObject.Properties.Name) {
        if (-not (Test-Path $BaselineFile)) {
            $Changes += "DELETED: $BaselineFile"
        }
    }
    
    if ($Changes.Count -gt 0) {
        Write-Host "Changes detected:" -ForegroundColor Yellow
        foreach ($Change in $Changes) {
            Write-Host "  $Change" -ForegroundColor Yellow
        }
        
        # Log to event log
        $ChangeText = $Changes -join "`n"
        Write-EventLog -LogName Application -Source "FixMyShit-Monitor" -EntryType Warning -EventId 1002 -Message "File integrity changes detected:`n$ChangeText"
    } else {
        Write-Host "No changes detected" -ForegroundColor Green
    }
}

# Critical directories to monitor
$CriticalDirs = @(
    @{Path="C:\Windows\System32"; Name="System32"},
    @{Path="C:\Windows\SysWOW64"; Name="SysWOW64"},
    @{Path="C:\FixMyShit"; Name="FixMyShit"}
)

# Create baselines if they don't exist
foreach ($Dir in $CriticalDirs) {
    if (Test-Path $Dir.Path) {
        $BaselineFile = "$BaselinePath\$($Dir.Name).json"
        if (-not (Test-Path $BaselineFile)) {
            Create-Baseline -Directory $Dir.Path -BaselineName $Dir.Name
        } else {
            Check-Integrity -Directory $Dir.Path -BaselineName $Dir.Name
        }
    }
}
