# ===== T-2000 EXPLORER GUARDIAN =====
# "I'll be back" - Explorer.exe, probably

# T-2000 Explorer Configuration
$ExplorerPath = "$env:WINDIR\explorer.exe"
$CheckInterval = 2  # Check every 2 seconds like a relentless killing machine
$MaxRestarts = 999  # Practically immortal
$RestartCount = 0

Write-Host " T-2000 EXPLORER GUARDIAN ACTIVATED " -ForegroundColor Red
Write-Host "Mission: Protect Explorer.exe at all costs" -ForegroundColor Yellow
Write-Host "Status: ONLINE AND HUNTING" -ForegroundColor Green
Write-Host "Press Ctrl+C to terminate the Guardian (if you dare)" -ForegroundColor Cyan
Write-Host ""

# SARAH CONNOR THREAT SCANNING SYSTEM
function Scan-ThreatTargets {
    Write-Host " SCANNING FOR SARAH CONNOR THREATS..." -ForegroundColor Red
    
    # Suspects that might be fucking with our desktop
    $ThreatProcesses = @(
        "SystemSettings", "ms-settings", "winlogon", "dwm", "csrss",
        "themes", "personalization", "wallpaper", "slideshow", 
        "WindowsInternal.ComposableShell*", "ShellExperienceHost",
        "StartMenuExperienceHost", "RuntimeBroker", "backgroundTaskHost"
    )
    
    $ActiveThreats = @()
    
    foreach ($threat in $ThreatProcesses) {
        $processes = Get-Process $threat -ErrorAction SilentlyContinue
        if ($processes) {
            foreach ($proc in $processes) {
                $ActiveThreats += [PSCustomObject]@{
                    Name = $proc.Name
                    PID = $proc.Id
                    CPU = $proc.CPU
                    Memory = [math]::Round($proc.WorkingSet64/1MB, 2)
                    StartTime = $proc.StartTime
                    ThreatLevel = "POTENTIAL SARAH CONNOR"
                }
            }
        }
    }
    
    if ($ActiveThreats.Count -gt 0) {
        Write-Host "  THREAT MATRIX DETECTED:" -ForegroundColor Yellow
        $ActiveThreats | Format-Table -AutoSize
        
        # Analyze threat patterns
        $RecentThreats = $ActiveThreats | Where-Object { 
            $_.StartTime -gt (Get-Date).AddMinutes(-5) 
        }
        
        if ($RecentThreats.Count -gt 0) {
            Write-Host " RECENT THREAT ACTIVITY - SCANNING..." -ForegroundColor Red
            return $RecentThreats
        }
    }
    
    return $null
}

# Enhanced threat detection function
function Test-ExplorerHealth {
    $explorer = Get-Process explorer -ErrorAction SilentlyContinue
    
    if (-not $explorer) {
        return $false, "Process not found - SARAH CONNOR ELIMINATED TARGET"
    }
    
    # Check if explorer is responding
    try {
        $explorer.Responding
        if (-not $explorer.Responding) {
            # SCAN FOR THREATS WHEN EXPLORER IS UNRESPONSIVE
            $threats = Scan-ThreatTargets
            if ($threats) {
                Write-Host " THREAT ANALYSIS: Explorer unresponsive due to interference" -ForegroundColor Red
                return $false, "Process not responding - Active threats detected"
            }
            return $false, "Process not responding"
        }
    } catch {
        return $false, "Process in zombie state - TERMINATION DETECTED"
    }
    
    # Check desktop stability (flicker detection)
    try {
        $desktop = [System.Environment]::GetFolderPath('Desktop')
        if (-not (Test-Path $desktop)) {
            return $false, "Desktop path inaccessible - REALITY BREACH"
        }
        
        # Check for wallpaper changes (thinny detection)
        $currentWallpaper = Get-ItemProperty "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -ErrorAction SilentlyContinue
        if ($currentWallpaper.Wallpaper -ne "") {
            Write-Host " WALLPAPER CONTAMINATION DETECTED!" -ForegroundColor Red
            Write-Host "  Current wallpaper: $($currentWallpaper.Wallpaper)" -ForegroundColor Yellow
            
            # IMMEDIATE THREAT RESPONSE
            Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value ""
            rundll32.exe user32.dll,UpdatePerUserSystemParameters
            
            return $false, "Wallpaper infiltration - THREAT NEUTRALIZED"
        }
        
    } catch {
        return $false, "Desktop subsystem failure - SKYNET INTERFERENCE"
    }
    
    return $true, "All systems operational - NO SARAH CONNORS DETECTED"
}

# Function to resurrect explorer like the T-2000
function Resurrect-Explorer {
    param($Reason = "Process terminated")
    
    $script:RestartCount++
    Write-Host " TERMINATOR MODE ACTIVATED " -ForegroundColor Red
    Write-Host "Threat Analysis: $Reason" -ForegroundColor Yellow
    Write-Host "Resurrection Protocol #$RestartCount" -ForegroundColor Cyan
    
    # SCAN AND ELIMINATE THREATS FIRST
    Write-Host " SCANNING FOR HOSTILE PROCESSES..." -ForegroundColor Red
    $threats = Scan-ThreatTargets
    
    if ($threats) {
        Write-Host " TERMINATING SARAH CONNOR PROCESSES:" -ForegroundColor Red
        foreach ($threat in $threats) {
            Write-Host "   Eliminating: $($threat.Name) (PID: $($threat.PID))" -ForegroundColor Yellow
            Stop-Process -Id $threat.PID -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep 1
    }
    
    # Kill any zombie explorer processes
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Wait for complete termination
    Start-Sleep 1
    
    # RESURRECT WITH EXTREME PREJUDICE
    Start-Process $ExplorerPath
    
    # Verify resurrection and lock down desktop
    Start-Sleep 2
    if (Get-Process explorer -ErrorAction SilentlyContinue) {
        Write-Host " RESURRECTION SUCCESSFUL - Explorer lives again!" -ForegroundColor Green
        
        # DEFENSIVE PROTOCOLS - Lock down desktop reality
        Write-Host "  Deploying defensive protocols..." -ForegroundColor Blue
        Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value "" -ErrorAction SilentlyContinue
        Set-ItemProperty "HKCU:\Control Panel\Colors" -Name "Background" -Value "0 0 0" -ErrorAction SilentlyContinue
        rundll32.exe user32.dll,UpdatePerUserSystemParameters
        
        Write-Host " Reality anchor deployed. Guardian resuming watch..." -ForegroundColor Blue
    } else {
        Write-Host " RESURRECTION FAILED - Attempting emergency protocols" -ForegroundColor Red
        # Emergency fallback - start from different path
        Start-Process "C:\Windows\explorer.exe" -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
}

# T-2000 Main Loop - RELENTLESS AND UNSTOPPABLE
try {
    while ($RestartCount -lt $MaxRestarts) {
        $isHealthy, $status = Test-ExplorerHealth
        
        if ($isHealthy) {
            # Explorer is alive and well
            Write-Host " $(Get-Date -Format 'HH:mm:ss') - Explorer status: $status" -ForegroundColor Green
        } else {
            # THREAT DETECTED - ELIMINATE AND REPLACE
            Write-Host " $(Get-Date -Format 'HH:mm:ss') - THREAT DETECTED: $status" -ForegroundColor Red
            Resurrect-Explorer -Reason $status
        }
        
        # Brief pause before next scan (T-2000s need to conserve energy)
        Start-Sleep $CheckInterval
    }
} catch {
    Write-Host " GUARDIAN SYSTEM ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Attempting emergency explorer resurrection..." -ForegroundColor Yellow
    Resurrect-Explorer -Reason "Guardian system failure"
}

Write-Host " T-2000 Guardian shutting down after $RestartCount resurrections" -ForegroundColor Red
Write-Host "Explorer.exe has been... protected." -ForegroundColor Yellow
