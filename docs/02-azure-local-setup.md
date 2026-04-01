# Azure Local Setup

This document covers the steps required to prepare an Azure Local cluster to host Azure Virtual Desktop session hosts.

---

## 1. Verify Cluster Health

Before deploying AVD, confirm the cluster is healthy:

```powershell
# Connect to a cluster node
$session = New-PSSession -ComputerName "<cluster-node>" -Credential (Get-Credential)

# Check cluster health
Invoke-Command -Session $session -ScriptBlock {
    Get-ClusterNode | Select-Object Name, State
    Get-StorageSubSystem | Select-Object FriendlyName, HealthStatus, OperationalStatus
    Get-VirtualDisk  | Select-Object FriendlyName, HealthStatus, OperationalStatus
}
```

Alternatively, verify via the Azure portal under **Azure Local > Overview**.

---

## 2. Register the Cluster with Azure (if not already done)

```powershell
# Install required modules
Install-Module -Name Az.StackHCI -Force -AllowClobber

# Register
Register-AzStackHCI `
    -SubscriptionId "<subscription-id>" `
    -ResourceGroupName "rg-azurelocal-cluster" `
    -Region "eastus" `
    -ComputerName "<cluster-node>"
```

---

## 3. Deploy the Arc Resource Bridge

The Arc Resource Bridge (ARB) is required for deploying VMs on Azure Local via Azure APIs.

```powershell
# Verify Arc Resource Bridge status
Get-AzConnectedMachineExtension -ResourceGroupName "rg-azurelocal-cluster" -MachineName "<cluster-name>" |
    Where-Object { $_.Name -like '*ResourceBridge*' }
```

If the ARB is not deployed, follow the [Azure Local Arc Resource Bridge deployment guide](https://learn.microsoft.com/azure/azure-local/manage/azure-arc-vm-management-overview).

---

## 4. Create an Arc Logical Network

AVD session hosts require an Arc VM logical network that maps to a physical VM switch on the cluster.

### Via Azure Portal

1. Navigate to your Azure Local cluster resource
2. Select **Resources** → **Logical networks**
3. Click **+ Add** and complete the wizard:
   - Name: `lnet-avd-demo`
   - VM switch: select the switch connected to your AD/AVD subnet
   - IP address method: Static or DHCP (use DHCP for simplicity)
   - DNS servers: IP of your domain controller(s)

### Via CLI

```bash
az stack-hci-vm network lnet create \
  --resource-group "rg-azurelocal-cluster" \
  --custom-location "<arc-custom-location-id>" \
  --name "lnet-avd-demo" \
  --vm-switch-name "<vm-switch-name>" \
  --ip-allocation-method "Dynamic" \
  --dns-servers "<dns-ip>"
```

---

## 5. Download a VM Gallery Image

AVD session hosts are created from a gallery image stored on Azure Local.

```bash
# Download Windows 11 Enterprise multi-session from marketplace
az stack-hci-vm image create \
  --resource-group "rg-azurelocal-cluster" \
  --custom-location "<arc-custom-location-id>" \
  --name "img-win11-multisession" \
  --os-type "Windows" \
  --offer "WindowsDesktop" \
  --publisher "MicrosoftWindowsDesktop" \
  --sku "win11-24h2-avd" \
  --version "latest"
```

> Wait for the image download to complete (status: **Succeeded**) before proceeding.

---

## 6. Obtain the Custom Location Resource ID

The custom location ID is required by the Bicep templates.

```bash
az customlocation show \
  --resource-group "rg-azurelocal-cluster" \
  --name "<custom-location-name>" \
  --query id -o tsv
```

Save this value – you will need it in the parameter file.

---

## 7. Validate Arc VM Management

Test that you can create a VM through Arc before deploying AVD:

```bash
az stack-hci-vm show \
  --resource-group "rg-azurelocal-cluster" \
  --custom-location "<arc-custom-location-id>"
```

---

## Next Steps

Continue to [03-avd-deployment.md](03-avd-deployment.md) to deploy the AVD infrastructure.
