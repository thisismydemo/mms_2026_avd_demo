# AVD Deployment Guide

This document covers deploying Azure Virtual Desktop (AVD) infrastructure on Azure Local using the Bicep templates in this repository.

---

## Architecture Overview

```
Azure (Cloud)                       Azure Local (On-Premises)
─────────────────────────────────   ─────────────────────────────────────
AVD Control Plane                   Arc Resource Bridge
 ├─ Workspace (ws-mms-demo)          └─ Custom Location
 ├─ Host Pool (hp-mms-demo)              └─ Arc VMs (session hosts)
 │   └─ Registration Token                   ├─ vm-avd-demo-01
 └─ App Group (ag-mms-demo)                  └─ vm-avd-demo-02
      └─ Desktop / RemoteApps
                │
                └─ Entra ID (Azure AD) / AD DS
```

The AVD control plane (workspace, host pool, app group) lives in Azure. The session host virtual machines are created **on Azure Local** via the Arc Resource Bridge and joined to Active Directory.

---

## 1. Update Parameter File

Open `bicep/parameters/demo.bicepparam` and fill in all values marked `// TODO`:

```bicep
// bicep/parameters/demo.bicepparam
using '../main.bicep'

param location = 'eastus'
param resourceGroupName = 'rg-avd-azurelocal-demo'
param hostPoolName = 'hp-mms-demo'
param workspaceName = 'ws-mms-demo'
param appGroupName = 'ag-mms-demo'
param customLocationId = '<arc-custom-location-resource-id>'   // TODO
param logicalNetworkId = '<arc-logical-network-resource-id>'   // TODO
param galleryImageId = '<arc-gallery-image-resource-id>'       // TODO
param domainName = 'contoso.local'                             // TODO
param domainJoinUsername = 'CONTOSO\\avdjoin'                  // TODO
param sessionHostCount = 2
param sessionHostNamePrefix = 'vm-avd-demo'
param vmSize = 'Standard_D4s_v3'
```

---

## 2. Deploy with PowerShell

```powershell
.\scripts\02-deploy-avd-infrastructure.ps1 `
    -SubscriptionId "<subscription-id>" `
    -ResourceGroupName "rg-avd-azurelocal-demo" `
    -Location "eastus" `
    -ParameterFile ".\bicep\parameters\demo.bicepparam"
```

The script will:
1. Create the resource group (if it does not exist)
2. Run `az deployment group what-if` and display a preview
3. Prompt for confirmation before deploying
4. Deploy the Bicep stack and stream output

---

## 3. Deploy with Azure CLI Directly

```bash
az group create \
  --name "rg-avd-azurelocal-demo" \
  --location "eastus"

az deployment group create \
  --resource-group "rg-avd-azurelocal-demo" \
  --template-file "bicep/main.bicep" \
  --parameters "bicep/parameters/demo.bicepparam" \
  --name "avd-demo-$(date +%Y%m%d%H%M%S)"
```

---

## 4. What Gets Deployed

| Resource | Type | Location |
|---|---|---|
| `hp-mms-demo` | AVD Host Pool | Azure (cloud) |
| `ag-mms-demo` | AVD Application Group (Desktop) | Azure (cloud) |
| `ws-mms-demo` | AVD Workspace | Azure (cloud) |
| `vm-avd-demo-01` … `vm-avd-demo-N` | Arc VMs (session hosts) | Azure Local |
| AVD Agent Extension | VM Extension on each session host | Azure Local |
| Domain Join Extension | VM Extension on each session host | Azure Local |
| Log Analytics Workspace | Diagnostics | Azure (cloud) |

---

## 5. Post-Deployment Configuration

### Assign Users to the App Group

```powershell
# Assign a user or group to the desktop app group
$objectId = (Get-AzADUser -UserPrincipalName "demo.user@contoso.com").Id

New-AzRoleAssignment `
    -ObjectId $objectId `
    -RoleDefinitionName "Desktop Virtualization User" `
    -Scope "/subscriptions/<sub-id>/resourceGroups/rg-avd-azurelocal-demo/providers/Microsoft.DesktopVirtualization/applicationGroups/ag-mms-demo"
```

### Enable AVD Insights (optional but recommended)

```powershell
.\scripts\03-configure-session-hosts.ps1 `
    -ResourceGroupName "rg-avd-azurelocal-demo" `
    -HostPoolName "hp-mms-demo" `
    -EnableInsights
```

---

## 6. Connect to AVD

1. Open [https://client.wvd.microsoft.com/arm/webclient](https://client.wvd.microsoft.com/arm/webclient)  
   *or* install the [Windows Desktop client](https://learn.microsoft.com/azure/virtual-desktop/users/connect-windows)
2. Sign in with the test user account
3. Click **Session Desktop** (from `ag-mms-demo`)
4. Confirm the session launches on a VM running on your Azure Local hardware

---

## Next Steps

Continue to [04-demo-walkthrough.md](04-demo-walkthrough.md) for the full conference demo script.
