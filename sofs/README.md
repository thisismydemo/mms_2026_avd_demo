# SOFS — Supporting Infrastructure

> **Type:** Supporting Infrastructure (pre-deployed before the session)
> **Repo:** [AzureLocal/azurelocal-sofs-fslogix](https://github.com/AzureLocal/azurelocal-sofs-fslogix)
> **Deployment method:** PowerShell (tested path)

---

## What This Is

This directory contains the configuration needed to deploy a **Scale-Out File Server (SOFS)** cluster on Azure Local that provides FSLogix profile storage for the AVD Anywhere demo.

The SOFS cluster is **not part of the live demo**. It must be deployed and validated **before the session starts**. Attendees will see the result (fast profile load times, seamless roaming) but not the deployment itself.

### Cluster summary

| Property | Value |
|---|---|
| Cluster name | `sofs-mms26-01` |
| Access point | `sofsap-mms26-01` |
| Share UNC path | `\\sofsap-mms26-01\profiles` |
| Node VMs | `vm-mms26-sofs-01`, `vm-mms26-sofs-02`, `vm-mms26-sofs-03` |
| Resource group | `rg-sofs-mms26-azl-eus-01` |
| Subscription | `demo-labs-lz-azurelocal-001` (`2caa0b8a-...`) |
| Azure Local cluster | `tplabs-clus01` |
| Domain | `azrl.mgmt` |
| Cloud witness | `stwitmms26sofs01` |

> **Shared cluster:** This same SOFS cluster is also referenced by `mms_2026_hybrid_demo` for the hotpatch/WS2025 update management demo. Deploy it once — both sessions use it.

---

## Files in This Directory

| File | Purpose |
|---|---|
| `variables.yml` | Deployment config (gitignored — fill in PLACEHOLDERs before use) |
| `deploy-sofs.ps1` | Orchestration script — clones the SOFS repo and runs deployment |
| `README.md` | This file |

---

## Prerequisites

Before running `deploy-sofs.ps1`, resolve all `PLACEHOLDER` values in `variables.yml`:

| Placeholder | What to fill in | How to find it |
|---|---|---|
| `gallery_image_name` | WS2025 Datacenter Core Gen2 image name on `tplabs-clus01` | `Get-AzStackHCIVMImage -ClusterName tplabs-clus01` |
| `storage_path_ids."01/02/03"` | Azure Local storage container resource IDs | Portal → tplabs-clus01 → Storage → Volumes |
| `vm.ips."01/02/03"` | Three static IPs from VLAN 717 | IPAM / network team |
| `sofs.cluster_ip` | Static cluster IP from VLAN 717 | IPAM / network team |
| `sofs.access_point_ip` | Static access point IP from VLAN 717 | IPAM / network team |
| `keyvault.name` | Key Vault containing deployment secrets | Azure Portal |
| `keyvault.resource_group` | Resource group of the Key Vault | Azure Portal |
| `vm.admin_password` (KV ref) | Secret name in Key Vault | Create: `sofs-admin-password` |
| `domain.join_password` (KV ref) | Secret name in Key Vault | Create: `domain-join-password` |

---

## Deployment

```powershell
# From repo root
.\sofs\deploy-sofs.ps1
```

The script will:
1. Check for/clone `AzureLocal/azurelocal-sofs-fslogix` into a temp directory
2. Copy `sofs/variables.yml` to `config/variables/variables.yml` in the cloned repo
3. Run `Invoke-SOFSDeployment.ps1` (orchestrates `Deploy-SOFS-Azure.ps1` + `Configure-SOFS-Cluster.ps1`)

Expected deployment time: ~45–60 minutes.

---

## Validation

After deployment, verify:

```powershell
# Check SOFS cluster is online
Invoke-Command -ComputerName sofsap-mms26-01 -ScriptBlock { Get-ClusterNode }

# Verify share is accessible
Test-Path "\\sofsap-mms26-01\profiles"

# Check S2D volume
Invoke-Command -ComputerName vm-mms26-sofs-01 -ScriptBlock { Get-Volume -FriendlyName FSLogixData }
```

---

## Relationship to Demo Content

```
Supporting Infrastructure (deploy BEFORE session)
├── sofs/         ← This directory
│   └── SOFS cluster providing \\sofsap-mms26-01\profiles
│
Demo Content (live during session)
├── bicep/        ← AVD host pool, session hosts, app groups
├── scripts/      ← 01-prepare through 06-cleanup
└── docs/         ← Technical walk-through per demo step
```
