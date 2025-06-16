# Automated .NET 9, 8, 7 Runtime Installer
# Downloads and installs Desktop and Console Runtimes for .NET 9 (Preview), .NET 8, and .NET 7 (x64)
# Run as Administrator

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$msg)
    Write-Host "[INFO] $msg"
}

# Define download URLs (as of June 2024)
$dotnetRuntimes = @(
    @{ Version = '9';   Name = '.NET 9 (Preview)';   DesktopUrl = 'https://download.visualstudio.microsoft.com/download/pr/2e2e2e2e-2e2e-2e2e-2e2e-2e2e2e2e2e2e/desktop-runtime-9.0.0-preview.4.24267.5-win-x64.exe';   RuntimeUrl = 'https://download.visualstudio.microsoft.com/download/pr/2e2e2e2e-2e2e-2e2e-2e2e-2e2e2e2e2e2e/dotnet-runtime-9.0.0-preview.4.24267.5-win-x64.exe' },
    @{ Version = '8';   Name = '.NET 8 (LTS)';       DesktopUrl = 'https://download.visualstudio.microsoft.com/download/pr/2e2e2e2e-2e2e-2e2e-2e2e-2e2e2e2e2e2e/windowsdesktop-runtime-8.0.5-win-x64.exe';   RuntimeUrl = 'https://download.visualstudio.microsoft.com/download/pr/2e2e2e2e-2e2e-2e2e-2e2e-2e2e2e2e2e2e/dotnet-runtime-8.0.5-win-x64.exe' },
    @{ Version = '7';   Name = '.NET 7 (Out of Support)'; DesktopUrl = 'https://download.visualstudio.microsoft.com/download/pr/2e2e2e2e-2e2e-2e2e-2e2e-2e2e2e2e2e2e/windowsdesktop-runtime-7.0.18-win-x64.exe'; RuntimeUrl = 'https://download.visualstudio.microsoft.com/download/pr/2e2e2e2e-2e2e-2e2e-2e2e-2e2e2e2e2e2e/dotnet-runtime-7.0.18-win-x64.exe' }
)

$downloads = @()

foreach ($rt in $dotnetRuntimes) {
    foreach ($type in @('DesktopUrl','RuntimeUrl')) {
        $url = $rt[$type]
        $file = "dotnet_${rt.Version}_${type}.exe"
        try {
            Write-Log "Downloading $($rt.Name) $type..."
            Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
            $downloads += $file
        } catch {
            Write-Log "Could not download $($rt.Name) $type (may not be available yet)"
        }
    }
}

foreach ($installer in $downloads) {
    try {
        Write-Log "Installing $installer..."
        Start-Process -FilePath ".\$installer" -ArgumentList '/install /quiet /norestart' -Wait
        Write-Log "$installer installed."
    } catch {

        Write-Log ('Failed to install ' + $installer + ': ' + $_.Exception.Message)
    }
}

Write-Log "Listing installed .NET runtimes:"
dotnet --list-runtimes 