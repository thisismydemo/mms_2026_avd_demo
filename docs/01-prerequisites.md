# Prerequisites

This document lists everything you need before running the MMS 2026 AVD on Azure Local demo.

---

## 1. Azure Local Cluster

| Requirement | Detail |
|---|---|
| **OS version** | Azure Local 23H2 (or later) |
| **Cluster nodes** | Minimum 1 node (2+ recommended for HA) |
| **Memory per node** | 256 GB RAM recommended |
| **Storage** | Storage Spaces Direct (NVMe or SSD recommended) |
| **Network** | Management + compute + storage network separation |
| **Azure registration** | Cluster must be registered with Azure Arc |
| **HCI Arc resource bridge** | Must be deployed and healthy |

> **Tip:** Use the Azure Local 23H2 deployment wizard from Windows Admin Center or the Azure portal to deploy and register the cluster.

---

## 2. Azure Subscription

- An active Azure subscription
- **Contributor** role (or higher) on the target resource group
- The following resource providers registered:

```powershell
$providers = @(
    'Microsoft.DesktopVirtualization',
    'Microsoft.HybridCompute',
    'Microsoft.AzureStackHCI',
    'Microsoft.Compute',
    'Microsoft.Network',
    'Microsoft.Storage',
    'Microsoft.KeyVault',
    'Microsoft.Insights'
)

foreach ($provider in $providers) {
    Register-AzResourceProvider -ProviderNamespace $provider
}
```

---

## 3. Tooling

| Tool | Minimum Version | Install |
|---|---|---|
| **Azure CLI** | 2.60.0 | `winget install Microsoft.AzureCLI` |
| **Bicep CLI** | 0.27.1 | `az bicep install` |
| **Azure PowerShell** | 12.0.0 | `Install-Module -Name Az -Scope CurrentUser` |
| **PowerShell** | 7.4 | [Download](https://github.com/PowerShell/PowerShell/releases) |
| **Git** | 2.40+ | `winget install Git.Git` |

---

## 4. Identity

- **Microsoft Entra ID (Azure AD)** tenant linked to the subscription
- A **Domain Controller** or **Microsoft Entra Domain Services** (AADDS) instance reachable from the Azure Local nodes
- A service principal (or managed identity) with the following permissions:
  - `Desktop Virtualization Contributor` on the subscription or resource group
  - `Virtual Machine Contributor` on the Azure Local custom location resource group

---

## 5. Networking

| Requirement | Detail |
|---|---|
| **DNS** | Azure Local VMs must resolve internal AD DNS and Azure endpoints |
| **Internet access** | Nodes need outbound access to Azure endpoints (or Azure ExpressRoute/VPN) |
| **AVD URLs** | Whitelist required [AVD URLs](https://learn.microsoft.com/azure/virtual-desktop/safe-url-list) |
| **Logical Network** | An Arc VM logical network defined on the Azure Local cluster |

---

## 6. VM Image

A generalized Windows 11 or Windows Server 2022/2025 image stored in the Azure Local cluster's Azure Local image gallery.

Recommended: download a marketplace image via the Azure Local portal blade or using:

```powershell
# List available marketplace images
Get-AzStackHciMarketplaceGalleryImage -ResourceGroupName "<cluster-rg>" -ClusterName "<cluster-name>"
```

---

## Next Steps

Continue to [02-azure-local-setup.md](02-azure-local-setup.md) to prepare the Azure Local cluster for AVD.
