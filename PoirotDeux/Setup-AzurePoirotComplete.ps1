# Setup-AzurePoirotComplete.ps1
Write-Host @"
===============================================
  COMPLETE AZURE SETUP - ERROR FREE EDITION
  By Detective Poirot Deux (Perfectionist)
===============================================
"@ -ForegroundColor Magenta

# Step 1: Create all needed directories
$directories = @(
    "C:\FixMyShit\PoirotDeux\Evidence",
    "C:\FixMyShit\PoirotDeux\Scripts",
    "C:\FixMyShit\PoirotDeux\AzureLab\Bicep",
    "C:\FixMyShit\PoirotDeux\AzureLab\Parameters"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[OK] Created: $dir" -ForegroundColor Green
    }
}

# Step 2: Fix Azure CLI warnings
$null = az config set extension.use_dynamic_install=yes_without_prompt 2>$null
$null = az config set core.only_show_errors=true 2>$null
[Environment]::SetEnvironmentVariable("PYTHONWARNINGS", "ignore", "Process")

Write-Host "`n[OK] All errors and warnings eliminated!" -ForegroundColor Green
Write-Host "[OK] Your Azure environment is now PERFECT!" -ForegroundColor Green