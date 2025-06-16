# Alternative Deployment Method - Via Azure Portal
Write-Host "AZURE PORTAL DEPLOYMENT METHOD" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Since Azure CLI is being difficult, let's use the Portal!" -ForegroundColor Yellow
Write-Host ""

# Generate the portal deployment URL
$subscriptionId = "831ed202-1c08-4b14-91eb-19ee3e5b3c78"
$resourceGroup = "guardr"
$templatePath = "C:\FixMyShit\PoirotDeux\AzureLab\detective-agency-deployment.bicep"

# First, let's try a different CLI approach
Write-Host "[METHOD 1] Try deployment with --no-wait flag:" -ForegroundColor Green
Write-Host ""
Write-Host "az deployment group create --resource-group guardr --template-file detective-agency-deployment.bicep --name detective-$(Get-Random) --no-wait" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""

Write-Host "[METHOD 2] Deploy via Azure Portal Custom Deployment:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Open this URL in your browser:" -ForegroundColor Yellow
Write-Host "   https://portal.azure.com/#create/Microsoft.Template/uri/" -ForegroundColor White
Write-Host ""
Write-Host "2. In the portal:" -ForegroundColor Yellow
Write-Host "   - Select Subscription: Azure subscription 1" -ForegroundColor White
Write-Host "   - Select Resource Group: guardr" -ForegroundColor White
Write-Host "   - Click 'Build your own template in the editor'" -ForegroundColor White
Write-Host "   - Copy and paste the Bicep template content" -ForegroundColor White
Write-Host "   - Click Save, then Review + Create" -ForegroundColor White
Write-Host ""

Write-Host "[METHOD 3] Try with Azure PowerShell module instead:" -ForegroundColor Green
Write-Host ""
Write-Host "# Install Azure PowerShell if needed:" -ForegroundColor Yellow
Write-Host "Install-Module -Name Az -Repository PSGallery -Force" -ForegroundColor White
Write-Host ""
Write-Host "# Login and deploy:" -ForegroundColor Yellow
Write-Host "Connect-AzAccount" -ForegroundColor White
Write-Host "Set-AzContext -SubscriptionId '$subscriptionId'" -ForegroundColor White
Write-Host "New-AzResourceGroupDeployment -ResourceGroupName '$resourceGroup' -TemplateFile '$templatePath'" -ForegroundColor White
Write-Host ""

Write-Host "[QUICK CHECK] See if anything was created:" -ForegroundColor Magenta
Write-Host "az resource list --resource-group guardr --query `"[?contains(name, 'detective')]`" --output table" -ForegroundColor White -BackgroundColor DarkBlue