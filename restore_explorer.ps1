# Restore Explorer Functionality Script

# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "This script must be run as an administrator. Exiting..."
    exit
}

# Ensure PowerShell is available
$powerShellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path $powerShellPath)) {
    Write-Output "PowerShell executable not found at $powerShellPath. Please ensure PowerShell is installed and accessible."
    exit
}

# 1. Check and clean startup locations
Write-Output "Checking startup locations..."
$startupFolders = @(
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:AppData\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($folder in $startupFolders) {
    Get-ChildItem -Path $folder -Force | ForEach-Object {
        if ($_.Name -like "*.lnk" -or $_.Name -like "*.exe") {
            Write-Output "Suspicious file found: $($_.FullName)"
            try {
                Remove-Item -Path $_.FullName -Force
            } catch {
                Write-Output "Failed to remove file: $($_.FullName). Error: $($_.Exception.Message). Please check permissions or run as administrator."
            }
        }
    }
}

# 2. Verify and clean registry startup entries
Write-Output "Checking registry startup entries..."
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($path in $registryPaths) {
    Get-ItemProperty -Path $path | ForEach-Object {
        Write-Output "Suspicious registry entry found: $($_.PSChildName)"
        try {
            Remove-ItemProperty -Path $path -Name $_.PSChildName -Force
        } catch {
            Write-Output "Failed to remove registry entry: $($_.PSChildName). Error: $($_.Exception.Message). Please check permissions or run as administrator."
        }
    }
}

# 3. Re-register shell components
Write-Output "Re-registering shell components..."
$components = @(
    "explorer.exe",
    "shell32.dll",
    "ole32.dll",
    "oleaut32.dll",
    "actxprxy.dll",
    "shdocvw.dll",
    "browseui.dll",
    "mshtml.dll"
)
foreach ($component in $components) {
    Write-Output "Re-registering $component..."
    Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s $component" -NoNewWindow -Wait
}

# 4. Restart Explorer
Write-Output "Restarting Explorer..."
Stop-Process -Name explorer -Force
Start-Process -FilePath "explorer.exe"
Write-Output "Explorer restored successfully."
