# Demo Walkthrough – MMS MOA 2026

This document is the presenter's guide for the live demo during the MMS MOA 2026 session on **Azure Virtual Desktop on Azure Local**.

---

## Pre-Demo Checklist

Before presenting, verify the following:

- [ ] Azure Local cluster is healthy (portal shows **Online**)
- [ ] Arc Resource Bridge is in **Running** state
- [ ] Logical network `lnet-avd-demo` exists and is **Succeeded**
- [ ] Gallery image `img-win11-multisession` download is **Succeeded**
- [ ] Resource group `rg-avd-azurelocal-demo` is deployed
- [ ] At least 2 session host VMs are **Available** in the host pool
- [ ] Test user is assigned to `ag-mms-demo` app group
- [ ] AVD Web Client tab is open and signed in as the test user
- [ ] Azure Portal tabs are open: Azure Local cluster, Host Pool, Session Hosts

---

## Demo 1 – Show the Architecture

**Talking points:**

1. Open the Azure portal and navigate to the **Azure Local** cluster.
2. Show the **Overview** blade – highlight the nodes, storage, and status.
3. Explain how the **Arc Resource Bridge** bridges on-prem VMs to Azure APIs.
4. Navigate to the **Resources → Virtual machines** blade and show the session host VMs (`vm-avd-demo-01`, `vm-avd-demo-02`).

> *"These virtual machines are physically running on the hardware in this room (or in our data center), but they are managed entirely through the Azure portal."*

---

## Demo 2 – AVD Control Plane in Azure

1. In the Azure portal, navigate to **Azure Virtual Desktop**.
2. Open the **Host Pool** `hp-mms-demo`.
   - Show **Properties**: type = *Pooled*, load balancing = *Depth-first*
   - Show **Session Hosts** tab – both VMs show status **Available**
3. Open the **Application Group** `ag-mms-demo`.
   - Show **Desktop Application Group** with the default desktop published
   - Show the **Role Assignments** tab – the demo user is assigned `Desktop Virtualization User`
4. Open the **Workspace** `ws-mms-demo`.
   - Show the associated application groups

> *"The AVD control plane – host pool, workspace, and app groups – lives in Azure. Authentication and brokering happen in Azure. But the compute is entirely on-premises."*

---

## Demo 3 – End-User Connection

1. Open the [AVD Web Client](https://client.wvd.microsoft.com/arm/webclient) in a browser.
2. Sign in as `demo.user@contoso.com`.
3. Click **Session Desktop**.
4. While the session is loading, explain what is happening:
   - Entra ID issues a token
   - AVD broker selects a session host using depth-first balancing
   - The RDP connection is established through the AVD gateway to the on-prem VM
5. The desktop opens – show that it is a **Windows 11 Enterprise** desktop.
6. Open **Task Manager → Performance** to show the VM resources.
7. Open `\\<cluster-node>\c$` (or similar) to visually show it is on-prem.

> *"The user experience is identical to cloud-only AVD, but all the compute and data never leaves your data center."*

---

## Demo 4 – Azure Monitor / AVD Insights

1. In the Azure portal, navigate to the **Host Pool → Insights**.
2. Show:
   - Connection diagnostics (latency, round-trip time)
   - Session count over time
   - Session host utilization (CPU / memory)
3. Navigate to **Log Analytics Workspace** and run a quick KQL query:

```kusto
WVDConnections
| where TimeGenerated > ago(1h)
| summarize Sessions = count() by UserName, SessionHostName
| order by Sessions desc
```

> *"All telemetry flows to Azure Monitor regardless of where the session hosts are running. One pane of glass for hybrid AVD."*

---

## Demo 5 – Image Update (Optional / Time Permitting)

Show how to update the session host image on Azure Local:

1. In the Azure portal, navigate to the Azure Local cluster → **Resources → VM images**.
2. Show the existing `img-win11-multisession` image.
3. Describe the process of sysprep → capture → update host pool → drain & replace VMs.

---

## Cleanup After Demo

```powershell
# Remove all demo resources
Remove-AzResourceGroup -Name "rg-avd-azurelocal-demo" -Force
```

> **Do not delete the Azure Local cluster resource group** – it is shared infrastructure.

---

## Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| Session host shows *Unavailable* | AVD agent not registered | Check agent extension status on the Arc VM |
| Domain join failed | Wrong credentials or DNS | Verify DNS resolves the AD domain from cluster nodes |
| RDP connection fails | Firewall blocking 443/TCP | Ensure outbound access to AVD gateway URLs |
| Image download stuck | Connectivity issue | Check cluster outbound internet access |
| Arc VMs not showing in portal | ARB issue | Restart Arc Resource Bridge appliance |

---

## Resources

- [AVD on Azure Local documentation](https://learn.microsoft.com/azure/virtual-desktop/azure-local-overview)
- [Azure Local 23H2 docs](https://learn.microsoft.com/azure/azure-local/)
- [AVD client downloads](https://learn.microsoft.com/azure/virtual-desktop/users/connect-windows)
- [Required URLs for AVD](https://learn.microsoft.com/azure/virtual-desktop/safe-url-list)
- [AVD Insights](https://learn.microsoft.com/azure/virtual-desktop/insights)
