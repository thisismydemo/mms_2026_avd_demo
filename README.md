# MMS MOA 2026 – Azure Virtual Desktop on Azure Local

> **Session Demo Repository**  
> Midwest Management Summit (MMS) MOA 2026  
> Topic: *Azure Virtual Desktop on Azure Local*

---

## Overview

This repository contains all the demo materials, Infrastructure-as-Code (IaC) templates, and PowerShell scripts used during the MMS MOA 2026 session on **Azure Virtual Desktop (AVD) running on Azure Local** (formerly Azure Stack HCI).

Azure Local lets you deploy AVD session hosts on your own on-premises hardware while still leveraging Azure cloud services for identity, brokering, monitoring, and management. This demo walks through a complete end-to-end deployment.

---

## Repository Structure

```
mms_2026_avd_demo/
├── README.md                            # This file
├── Demo-Guide-AVD-Azure-Local.md        # Detailed demo guide mapped to slides
├── .gitignore
├── presenter/                           # Session delivery materials
│   ├── run-of-show.md                   # Timing, flow, transition lines
│   ├── slide-map.md                     # Slide-to-demo mapping
│   ├── fallback-plan.md                 # Fallback strategy per demo
│   └── day-of-checklist.md              # 30-minute pre-session checklist
├── docs/                                # Technical documentation
│   ├── 01-prerequisites.md              # Environment prerequisites
│   ├── 02-azure-local-setup.md          # Prepare the Azure Local cluster
│   ├── 03-image-pipeline.md             # Image build and replication
│   ├── 04-avd-deployment.md             # Deploy AVD infrastructure
│   ├── 05-fslogix.md                    # FSLogix configuration and storage
│   ├── 06-gpu-setup.md                  # GPU-P / DDA setup and verification
│   ├── 07-monitoring.md                 # AVD Insights, Log Analytics, cost
│   └── 08-troubleshooting.md            # Common issues and fixes
├── scripts/
│   ├── 01-prepare-azure-local.ps1       # Register and prepare Azure Local
│   ├── 02-deploy-avd-infrastructure.ps1 # Deploy AVD via Bicep
│   ├── 03-configure-session-hosts.ps1   # Post-deploy session host config
│   ├── 04-validate-deployment.ps1       # Validate the full deployment
│   ├── 05-collect-demo-artifacts.ps1    # Gather resource info for fallback
│   └── 06-cleanup-demo.ps1             # Tear down demo resources
├── bicep/
│   ├── main.bicep                       # Main deployment entry point
│   ├── modules/
│   │   ├── avd-host-pool.bicep          # AVD host pool
│   │   ├── avd-app-group.bicep          # AVD application group
│   │   ├── avd-workspace.bicep          # AVD workspace
│   │   └── avd-session-host.bicep       # AVD session hosts on Azure Local
│   └── parameters/
│       └── demo.bicepparam              # Demo parameter values
├── queries/                             # KQL queries for demos
│   └── log-analytics/
│       ├── fslogix-profile-load-times.kql
│       ├── connection-diagnostics.kql
│       ├── session-host-performance.kql
│       └── active-sessions.kql
├── assets/                              # Fallback screenshots, diagrams, recordings
│   ├── diagrams/
│   ├── screenshots/
│   └── recordings/
└── .github/
    └── workflows/
        └── validate.yml                 # Bicep linting / what-if validation
```

---

## Key Technologies

| Technology | Purpose |
|---|---|
| **Azure Local** (Azure Stack HCI) | On-premises infrastructure platform |
| **Azure Virtual Desktop** | Cloud-brokered virtual desktop service |
| **Azure Arc** | Connects Azure Local to Azure control plane |
| **Bicep** | Infrastructure-as-Code for Azure resources |
| **PowerShell** | Automation and configuration scripts |
| **Entra ID (Azure AD)** | Identity and access management |
| **Azure Monitor / Insights** | Monitoring and diagnostics |

---

## Quick Start

### Prerequisites

See [docs/01-prerequisites.md](docs/01-prerequisites.md) for the full list. At a minimum you need:

- An Azure Local (HCI) cluster running version **23H2** or later, registered with Azure
- An active Azure subscription with Contributor access
- Azure CLI ≥ 2.60 or Azure PowerShell ≥ 12.0
- Bicep CLI ≥ 0.27

### 1 – Clone the repository

```bash
git clone https://github.com/thisismydemo/mms_2026_avd_demo.git
cd mms_2026_avd_demo
```

### 2 – Prepare Azure Local

```powershell
.\scripts\01-prepare-azure-local.ps1 `
    -SubscriptionId "<your-subscription-id>" `
    -ResourceGroupName "rg-avd-azurelocal-demo" `
    -ClusterName "<your-hci-cluster-name>" `
    -Location "eastus"
```

### 3 – Deploy AVD Infrastructure

```powershell
.\scripts\02-deploy-avd-infrastructure.ps1 `
    -SubscriptionId "<your-subscription-id>" `
    -ResourceGroupName "rg-avd-azurelocal-demo" `
    -Location "eastus"
```

### 4 – Configure Session Hosts

```powershell
.\scripts\03-configure-session-hosts.ps1 `
    -ResourceGroupName "rg-avd-azurelocal-demo" `
    -HostPoolName "hp-mms-demo"
```

### 5 – Validate Deployment

```powershell
.\scripts\04-validate-deployment.ps1 `
    -ResourceGroupName "rg-avd-azurelocal-demo"
```

---

## Demo Scenarios

| # | Scenario | Description |
|---|---|---|
| 1 | **Provision & Connect** | Deploy a personal host pool and connect via AVD client |
| 2 | **Pooled Desktop** | Deploy a pooled host pool with depth-first load balancing |
| 3 | **RemoteApp** | Publish individual applications from a session host |
| 4 | **Monitoring** | Review Azure Monitor Insights for AVD and Azure Local |
| 5 | **Image Management** | Update session host image using Azure Local VM image |

---

## Documentation

- [Prerequisites](docs/01-prerequisites.md)
- [Azure Local Setup](docs/02-azure-local-setup.md)
- [Image Pipeline](docs/03-image-pipeline.md)
- [AVD Deployment Guide](docs/04-avd-deployment.md)
- [FSLogix Configuration](docs/05-fslogix.md)
- [GPU Setup](docs/06-gpu-setup.md)
- [Monitoring](docs/07-monitoring.md)
- [Troubleshooting](docs/08-troubleshooting.md)

---

## Presenter Materials

- [Run of Show](presenter/run-of-show.md)
- [Slide-to-Demo Map](presenter/slide-map.md)
- [Fallback Plan](presenter/fallback-plan.md)
- [Day-Of Checklist](presenter/day-of-checklist.md)
- [Detailed Demo Guide](Demo-Guide-AVD-Azure-Local.md)

---

## Contributing

This repository is maintained by the MMS 2026 session presenters. Pull requests and issues are welcome.

---

## License

[MIT License](LICENSE)

---

*MMS MOA 2026 · Azure Virtual Desktop on Azure Local*
