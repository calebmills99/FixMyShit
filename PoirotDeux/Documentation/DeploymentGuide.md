# Detective Agency Deployment Guide

## Architecture Overview

The Detective Agency solution utilizes a modern cloud architecture with:

- **Multi-region deployment** for high availability and disaster recovery
- **Zero-trust security model** with managed identities and proper RBAC
- **Serverless compute** for evidence processing and analysis
- **Advanced monitoring** for comprehensive visibility

## Deployment Prerequisites

1. Azure subscription with Owner or Contributor access
2. Azure CLI (latest version)
3. PowerShell 7.1 or higher
4. GitHub account (for CI/CD pipeline)

## Deployment Steps

### 1. Initial Setup

```powershell
# Clone the repository
git clone https://github.com/YourOrg/DetectiveAgency.git
cd DetectiveAgency

# Login to Azure
Connect-AzAccount
```

### 2. Infrastructure Deployment

For manual deployment (not recommended for production):

```powershell
./Scripts/Deploy-DetectiveInfrastructure.ps1 -Environment dev -Location eastus
```

For production, use the CI/CD pipeline by:

1. Setting up GitHub secrets:
   - AZURE_CREDENTIALS
   - KEY_VAULT_NAME

2. Triggering the workflow: