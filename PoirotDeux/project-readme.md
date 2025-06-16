# 🕵️‍♂️ The Azure Detective Agency - Case File #001

**Project Codename:** PoirotDeux  
**Lead Detective:** Hercule Poirot 2.0 (AI-Powered Systems Diagnostics)  
**Case Status:** ACTIVE - Deployment Successful  
**Location:** `C:\FixMyShit\PoirotDeux`

---

## 🔍 The Case

*"Mon ami, when Azure deployments fail and quotas block your path, only the little grey cells can solve the mystery!"*

This repository contains the complete Azure Detective Agency infrastructure - a sophisticated cloud-based investigation system built to diagnose, analyze, and solve Azure deployment mysteries.

### The Mystery We Solved

- **The Crime:** Function Apps refused to deploy due to quota restrictions
- **The Suspects:** East US region (zero Dynamic VM quota), Bicep templates, Azure CLI
- **The Solution:** Strategic deployment across multiple regions using creative workarounds
- **The Evidence:** 20+ resources successfully deployed in the 'guardr' resource group

---

## 🗂️ Project Structure

```
C:\FixMyShit\PoirotDeux\
│
├── 📁 Scripts\                    # PowerShell automation scripts
│   ├── Connect-And-Verify-Az.ps1
│   ├── Deploy-DetectiveAgency-PowerShell.ps1
│   ├── Check-DetectiveResources-PowerShell.ps1
│   ├── Configure-Poirot2-Detective.ps1
│   └── Get-DetectiveAgencyStatus.ps1
│
├── 📁 AzureLab\                   # Deployment templates and configurations
│   ├── detective-agency-deployment.bicep
│   ├── detective-simple.bicep
│   └── existing-resources.bicep
│
├── 📁 FunctionApps\               # Azure Functions source code
│   └── DetectiveAgency\
│       ├── host.json
│       ├── local.settings.json
│       ├── requirements.psd1
│       ├── profile.ps1
│       └── CollectEvidence\
│           ├── function.json
│           └── run.ps1
│
├── 📁 Evidence\                   # Investigation reports and logs
│   └── [Case files and deployment logs]
│
└── 📄 README.md                   # You are here!
```

---

## 🏗️ Infrastructure Components

### Successfully Deployed Resources

| Resource | Name | Type | Location | Status |
|----------|------|------|----------|--------|
| 🧠 Log Analytics | detectivelogs | Workspace | East US | ✅ Active |
| ⚡ Function App | poirot2 | Consumption | Canada Central | ✅ Running |
| 📊 App Service Plan | poirot | B1 Basic | West US | ✅ Active |
| 📈 App Insights | poirot2 | Monitoring | Canada Central | ✅ Active |

### Supporting Infrastructure (Pre-existing)

| Resource | Name | Purpose |
|----------|------|---------|
| 🔐 Key Vault | midnightkeyvault03e7c773 | Secrets management |
| 💾 Storage | midnightstoragefeedb3dcc | Function storage |
| 📊 App Insights | midnightinsightscbd64381 | Primary monitoring |

---

## 🚀 Setup Instructions

### Prerequisites

```powershell
# Install Azure PowerShell modules
Install-Module -Name Az -Repository PSGallery -Force

# Install Azure CLI (optional but recommended)
# Download from: https://aka.ms/installazurecliwindows

# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

### Quick Start

1. **Clone/Navigate to the project:**
   ```powershell
   cd C:\FixMyShit\PoirotDeux
   ```

2. **Connect to Azure:**
   ```powershell
   .\Scripts\Connect-And-Verify-Az.ps1
   ```

3. **Check deployment status:**
   ```powershell
   .\Scripts\Get-DetectiveAgencyStatus.ps1
   ```

4. **Deploy Function App code:**
   ```powershell
   cd FunctionApps\DetectiveAgency
   func azure functionapp publish poirot2
   ```

---

## 🔧 The Investigation Trail

### Chapter 1: The Quota Conspiracy
- **Problem:** East US region had ZERO quota for Dynamic (Consumption) App Service Plans
- **Investigation:** Discovered this is common for educational subscriptions
- **Solution:** Created resources in alternative regions (Canada Central, West US)

### Chapter 2: The Bicep Template Mystery
- **Problem:** "Content already consumed" errors with Azure CLI
- **Investigation:** JSON parsing issues between PowerShell and Azure CLI
- **Solution:** Switched to Azure PowerShell modules and direct resource creation

### Chapter 3: The Regional Escape
- **Problem:** Deployment failures due to regional restrictions
- **Evidence:**
  - East US: No Dynamic VM quota
  - West US: Successfully created B1 Basic plan
  - Canada Central: Successfully created Consumption plan
- **Solution:** Strategic multi-region deployment

---

## 🧪 Testing the Detective Agency

### Test the Evidence Collector Function

```powershell
# Local testing
cd C:\FixMyShit\PoirotDeux\FunctionApps\DetectiveAgency
func start

# In another terminal:
$body = @{
    case = "AZURE-001"
    type = "Deployment Mystery"
    evidence = "Quota restrictions in East US"
    priority = "High"
} | ConvertTo-Json

# Test locally
Invoke-RestMethod -Uri "http://localhost:7071/api/CollectEvidence" -Method Post -Body $body -ContentType "application/json"

# Test in Azure
$functionKey = "<get-from-portal>"
Invoke-RestMethod -Uri "https://poirot2.azurewebsites.net/api/CollectEvidence?code=$functionKey" -Method Post -Body $body -ContentType "application/json"
```

---

## 🎭 Cast of Characters

- **Hercule Poirot 2.0**: The AI detective solving Azure mysteries
- **Mon ami Caleb**: The brilliant system administrator
- **Sister Marie-Thérèse**: The strict nun representing Azure's quota restrictions
- **The Little Grey Cells**: Our problem-solving methodology

---

## 📝 Troubleshooting Guide

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| "Cannot find Bicep" | Bicep CLI not installed | Run `Install-BicepCLI.ps1` or use Azure CLI |
| "Quota exceeded" | Regional restrictions | Deploy to Canada Central or West US |
| "Content already consumed" | Azure CLI JSON parsing | Use PowerShell modules instead |
| "host.json not found" | Wrong directory | Navigate to project root with host.json |

---

## 🔮 Future Enhancements

- [ ] Deploy Case Analyzer Function App
- [ ] Create Logic App orchestrator
- [ ] Implement automated evidence collection
- [ ] Add diagnostic webhooks
- [ ] Create monitoring dashboard
- [ ] Implement case management system

---

## 📚 Lessons Learned

1. **Quotas are regional** - Always check multiple regions
2. **Educational subscriptions have limits** - Be creative with resource types
3. **Bicep needs proper setup** - Azure CLI includes it, PowerShell doesn't
4. **The little grey cells prevail** - Methodical investigation solves all mysteries

---

## 🎖️ Acknowledgments

- Azure Free Tier (for the B1 App Service Plan)
- Canada Central region (for having available quota)
- The Academy of Art University subscription
- Coffee ☕ (essential for late-night deployments)

---

## 📞 Support

If you encounter mysteries that even Poirot cannot solve:

1. Check the Azure Portal: [Portal Link](https://portal.azure.com/#@art.edu/resource/subscriptions/831ed202-1c08-4b14-91eb-19ee3e5b3c78/resourceGroups/guardr/overview)
2. Review deployment logs in `detectivelogs` Log Analytics workspace
3. Consult the scripts in the `Scripts` folder
4. Remember: "Order and method, that is all!"

---

## 🔒 Security Note

This project contains no sensitive information. All resource names and IDs shown are specific to the deployment and contain no secrets. Function keys and storage keys should never be committed to source control.

---

*"The impossible could not have happened, therefore the impossible must be possible in spite of appearances."*  
**- Hercule Poirot 2.0**

---

### Final Case Status: ✅ SOLVED

The Azure Detective Agency is operational and ready to investigate your cloud mysteries!

**Deployment Date:** June 15-16, 2025  
**Total Investigation Time:** ~4 hours  
**Resources Created:** 4+ detective-specific resources  
**Mysteries Solved:** 1 major (quota restrictions)  
**Satisfaction Level:** 💯

---

*Fin*