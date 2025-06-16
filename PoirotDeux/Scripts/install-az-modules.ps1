# Install Required Azure PowerShell Modules
# By Hercule Poirot 2.0

Write-Host "INSTALLING REQUIRED AZURE POWERSHELL MODULES" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "[WARNING] Not running as Administrator!" -ForegroundColor Yellow
    Write-Host "Some modules may require admin rights to install." -ForegroundColor Yellow
    Write-Host ""
}

# List of required modules
$requiredModules = @(
    @{Name = "Az.Accounts"; Description = "Core authentication module"},
    @{Name = "Az.Resources"; Description = "Resource management"},
    @{Name = "Az.KeyVault"; Description = "Key Vault operations"},
    @{Name = "Az.ApplicationInsights"; Description = "Application Insights"},
    @{Name = "Az.Storage"; Description = "Storage Account operations"},
    @{Name = "Az.Websites"; Description = "App Service and Function Apps"},
    @{Name = "Az.OperationalInsights"; Description = "Log Analytics"},
    @{Name = "Az.LogicApp"; Description = "Logic Apps"},
    @{Name = "Az.Monitor"; Description = "Azure Monitor"}
)

Write-Host "Checking and installing required modules..." -ForegroundColor Yellow
Write-Host ""

foreach ($module in $requiredModules) {
    Write-Host "Checking $($module.Name) - $($module.Description)..." -ForegroundColor White
    
    $installed = Get-Module -Name $module.Name -ListAvailable
    
    if ($installed) {
        Write-Host "  [INSTALLED] Version: $($installed.Version)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name $module.Name -Repository PSGallery -Force -AllowClobber -Scope CurrentUser
            Write-Host "  [SUCCESS] Installed $($module.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Failed to install $($module.Name): $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Importing all Az modules..." -ForegroundColor Yellow
try {
    Import-Module Az -Force
    Write-Host "[SUCCESS] All Az modules imported" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Some modules may not have imported correctly" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "MODULE INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed modules:" -ForegroundColor Cyan
Get-Module -Name Az* -ListAvailable | Select-Object Name, Version | Format-Table

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run .\Connect-And-Verify-Az.ps1 again" -ForegroundColor White
Write-Host "2. If any modules failed to install, run PowerShell as Administrator" -ForegroundColor White
Write-Host ""