# AVD Anywhere: Azure Virtual Desktop on Azure Local — Demo Guide

## Detailed Demo Documentation by Slide

This document maps every demo to its corresponding slide(s), provides step-by-step walkthrough instructions, talking points, fallback plans, and environment prerequisites.

---

## Demo Overview

| Demo | Block | Slide(s) | Duration | Portal Blade / Tool |
|------|-------|----------|----------|---------------------|
| 1. Image Build Pipeline | Block 3 | Slide 12–15 → live | ~4 min | Azure Compute Gallery, AVD Custom Image Templates |
| 2. Host Pool Deployment | Block 4 | Slide 16–19 → live | ~3 min | AVD Host Pools, Azure Local custom location |
| 3. FSLogix Configuration | Block 6 | Slide 24–27 → live | ~4 min | Session host registry, SMB share, profile VHDx |
| 4. GPU Verification | Block 7 | Slide 28–30 → live | ~2 min | PowerShell on cluster node, nvidia-smi in VM |
| 5. Monitoring Setup | Block 8 | Slide 31–34 → live | ~3 min | AVD Insights, Log Analytics, Cost Analysis |

**Total demo time: ~16–20 minutes**

---

## Demo 1: Image Build Pipeline (~4 min)

### Corresponding Slides
- **Slide 12**: "6 Ways to Get Images onto Azure Local" — visual overview of all image source paths, highlighting Marketplace + Custom Pipeline as the two primary AVD paths
- **Slide 13**: Custom image pipeline flow diagram (Build → Customize → Sysprep → Gallery or Local Share → Deploy)
- **Slide 14**: "What goes in the golden image" checklist
- **Slide 15**: Image versioning strategy

### Pre-Demo Slide Context
Slides 12–15 establish that there are 6 supported paths to get VM images onto Azure Local (Marketplace, Compute Gallery, Storage Account, Local Share/CSV, Existing Arc VM capture, and Azure Managed Disk download). For AVD, the two primary paths are Marketplace (quick start/PoC) and custom image pipelines (production with LOB apps). The golden image checklist (Slide 14) emphasizes: never include the AVD agent, install FSLogix, disable Storage Sense, run Windows Update. The demo shows the custom pipeline in action.

### Step-by-Step Walkthrough

**Step 1 — Show the Azure Compute Gallery with image definitions (60 sec)**
- Navigate to **Azure Compute Gallery** in the portal
- Open a gallery that contains AVD image definitions
- Show:
  - Image definition name (e.g., `win11-24h2-avd-m365-custom`)
  - OS type (Windows 11 Enterprise multi-session)
  - Multiple versions listed with dates
- Click into a specific image version and show:
  - **Replication targets**: Azure regions AND the Azure Local custom location
  - **Replication status**: Completed / In Progress
  - **Source**: Where the image was built (Azure VM, managed disk, etc.)
- Talking point: "This is your image catalog. Each definition represents a golden image template — OS + apps + configuration. Versions are immutable snapshots. When you update your image, you create a new version and replicate it. The key thing to notice here is the replication targets — see the custom location? That's our Azure Local cluster. The image is being replicated from Azure cloud down to our on-prem hardware."

**Step 2 — Walk through a custom image template in the AVD portal (90 sec)**
- Navigate to **Azure Virtual Desktop → Custom image templates** (or **Azure Compute Gallery → Image definitions → Create VM image version**)
- Open or create a custom image template
- Show the configuration:
  - **Source image**: Base Windows 11 multi-session from Marketplace
  - **Built-in scripts**: Point out the available script options:
    - FSLogix configuration script
    - Teams optimization script (media redirection, WebRTC)
    - Language pack installation
    - Screen capture protection
    - Time zone redirection
  - **Custom scripts**: Show where you add your own scripts (URL to a script in a storage account or GitHub)
  - **Build timeout**: Note the importance of allowing enough time
- Talking point: "This is Azure Image Builder integrated into AVD. You start with a base Marketplace image, layer on built-in optimization scripts — FSLogix, Teams, language packs — then add your own scripts for LOB apps. The output is a new image version in your Compute Gallery, ready for replication. No manual Sysprep, no RDP-into-a-VM-and-click-around. It's a pipeline."

**Step 3 — Show replication status and timing (30 sec)**
- Navigate back to the image version's replication tab
- Point out replication status to the custom location
- If in progress, show the percentage
- Talking point: "Replication to Azure Local depends on your internet bandwidth. For a 30GB Windows image, expect 30 minutes to several hours depending on your connection. Plan this into your maintenance windows. For air-gapped or low-bandwidth sites, you can skip this entirely — build the image locally, place the VHDX on a cluster shared volume, and register it as an image. No round-trip to Azure needed."

### Fallback Plan
- **If Compute Gallery is empty**: Have screenshots of a populated gallery with versions and replication status.
- **If custom image template blade isn't available**: This feature may be in preview. Show the Azure Image Builder resource directly or use screenshots.
- **If replication hasn't completed**: Point out the in-progress status as a teaching moment about bandwidth planning.

### Environment Prerequisites
- [ ] Azure Compute Gallery with at least one image definition containing multiple versions
- [ ] At least one image version replicated to the Azure Local custom location (completed or in progress)
- [ ] A custom image template created in the AVD portal (can be in draft/completed state)
- [ ] Built-in scripts visible in the template configuration

---

## Demo 2: Host Pool Deployment (~3 min)

### Corresponding Slides
- **Slide 16**: Host pool creation flow for Azure Local
- **Slide 17**: VM sizing — "it's your hardware, not a SKU picker"
- **Slide 18**: Common deployment failures and how to avoid them
- **Slide 19**: Deployment methods beyond the portal — Portal vs. ARM/Bicep vs. Terraform vs. Azure CLI vs. Nerdio

### Pre-Demo Slide Context
Slides 16–19 cover the host pool creation flow highlighting the key difference (selecting a custom location instead of an Azure region), VM sizing based on physical hardware rather than Azure SKU catalog, common deployment pitfalls, and the various IaC deployment options. The demo walks through the portal experience to show how similar (and different) it is from cloud AVD.

### Step-by-Step Walkthrough

**Step 1 — Walk through host pool creation in the portal (60 sec)**
- Navigate to **Azure Virtual Desktop → Host pools → Create**
- Walk through the wizard tabs:
  - **Basics**: Host pool name, host pool type (Pooled), load balancing (Breadth-first)
  - **Virtual machines → Location**: Select the **custom location** (not an Azure region)
  - Talking point: "This is the fork in the road. Instead of selecting 'East US' or 'West Europe', you select your custom location — that's your Azure Local cluster. From this point on, session hosts will be created as Arc-enabled VMs on your physical hardware."
  - **Virtual machines → Image**: Select from images replicated to the custom location
  - **Virtual machines → Size**: Show that you specify vCPU count and RAM directly — not an Azure SKU
  - Talking point: "No SKU picker. You're allocating from your physical hardware pool. If your node has 64 cores and 256 GB RAM, that's your ceiling. Plan accordingly — overcommitting vCPUs is common in VDI but you need to know your limits."
  - **Virtual machines → Network**: Select the logical network configured on Azure Local
  - **Virtual machines → Domain join**: Show AD domain join configuration

**Step 2 — Show deployed session hosts and their states (60 sec)**
- Navigate to an existing host pool that already has session hosts deployed
- Click **Session hosts**
- Show session hosts and their status progression:
  - Status values: **Upgrading** → **Available** (healthy) or **Unavailable** (problem) or **Needs Assistance**
  - Health check results: DomainJoinCheck, DomainTrustCheck, UrlsAccessibleCheck, etc.
- Talking point: "Once deployed, session hosts register with the AVD control plane. These health checks are your first diagnostic tool. If you see 'Unavailable', click into it — the health check details tell you exactly what failed. Domain join issues, connectivity issues, agent issues — it's all here."

**Step 3 — Show the registration key and expiration (30 sec)**
- In the host pool properties, show the registration key
- Point out the expiration date
- Talking point: "The registration key is how session hosts authenticate to this host pool during deployment. It expires. If you're automating deployments with Bicep or Terraform, make sure your pipeline generates a fresh key. And remember — if a session host stays powered off for more than 90 days, the internal token expires and it can't report state to the AVD backend. You'll see 'Unavailable' and need to re-register."

### Fallback Plan
- **If portal wizard is slow or errors**: Walk through the creation wizard up to the review step without actually deploying. Show the configuration selections.
- **If no session hosts exist yet**: Have screenshots of session hosts in various states (Available, Unavailable, Needs Assistance).
- **If health checks aren't populated**: Health checks can take a few minutes after deployment. Use screenshots of populated health check results.

### Environment Prerequisites
- [ ] Azure Local cluster with a custom location configured
- [ ] At least one image replicated to the custom location
- [ ] An existing host pool with deployed session hosts in "Available" status
- [ ] At least one logical network configured on Azure Local for session host networking
- [ ] Host pool registration key visible with its expiration date

---

## Demo 3: FSLogix Configuration (~4 min)

### Corresponding Slides
- **Slide 24**: "FSLogix is a storage project" — the mental model
- **Slide 25**: Storage sizing calculator example
- **Slide 26**: Must-have registry keys and GPO settings
- **Slide 27**: HA options comparison (SOFS vs. Cloud Cache vs. "don't do this" DFS-R)

### Pre-Demo Slide Context
Slides 24–27 reframe FSLogix as a storage problem rather than a profile problem. The sizing calculator (Slide 25) walks through login storm math (200 users x 50 IOPS = 10,000 IOPS peak). Slide 26 lists the critical registry keys. Slide 27 compares HA options and warns against DFS-R for live VHDx replication. The demo shows the actual configuration on a live session host and the resulting profile storage.

### Step-by-Step Walkthrough

**Step 1 — Show the registry keys on a session host (60 sec)**
- RDP or Bastion into a session host VM (or show via PowerShell remoting)
- Open Registry Editor or run PowerShell commands to show:
  ```
  HKLM\SOFTWARE\FSLogix\Profiles
  ```
  - `Enabled` = 1 (DWORD)
  - `VHDLocations` = `\\fileserver\profiles` (the UNC path to the SMB share)
  - `SizeInMBs` = configured max size (e.g., 15000 for ~15GB)
  - `IsDynamic` = 1
  - `DeleteLocalProfileWhenVHDShouldApply` = 1
- Talking point: "These are the keys that matter. `VHDLocations` points to your on-prem SMB share — this is where profiles live. `SizeInMBs` caps profile growth. `DeleteLocalProfileWhenVHDShouldApply` prevents local profile copies from piling up and eating disk space. In cloud AVD you'd point this at Azure Files. On Azure Local, it's your file server, your NAS, your SOFS cluster."

**Step 2 — Show a redirections.xml with exclusions (45 sec)**
- Show the redirections.xml file on the session host (typically in the FSLogix install directory or deployed via GPO)
- Point out exclusion entries:
  - Teams cache (`AppData\Local\Microsoft\Teams`)
  - Browser caches (`AppData\Local\Google\Chrome\User Data\Default\Cache`)
  - Windows temp files
  - OneDrive cache (if not needed in profile)
- Talking point: "Redirections.xml is your profile diet plan. Teams alone can dump gigabytes of cache data into a profile. Exclude it. Browser caches — exclude them. Temp files — exclude them. Every megabyte you keep out of the VHDx is IOPS you save during login and disk space you don't have to manage."

**Step 3 — Show the FSLogix profile folder on the SMB share (60 sec)**
- Open File Explorer (or PowerShell) and navigate to the SMB share path (e.g., `\\fileserver\profiles`)
- Show:
  - Per-user folders (named by SID or username)
  - VHDx files inside each folder
  - File sizes — point out variation between users
- Talking point: "Each user gets a folder with their VHDx file. Dynamic VHDx — it grows as they use it but doesn't automatically shrink. That 12GB file? Probably an Outlook OST that grew over months. This is why profile compaction matters."

**Step 4 — Show a profile compaction script or scheduled action (45 sec)**
- Show a PowerShell script using `Invoke-FslShrinkDisk` or a Nerdio scheduled action
- Point out:
  - Target path (the profile share)
  - Minimum whitespace threshold to trigger compaction
  - Scheduling (weekly/monthly during maintenance windows)
- Talking point: "VHDx files grow but don't shrink. `Invoke-FslShrinkDisk` reclaims the whitespace. Schedule this during maintenance windows. In a 200-user environment, regular compaction can reclaim hundreds of gigabytes."

**Step 5 (Optional) — Show Cloud Cache configuration (30 sec)**
- If configured, show the Cloud Cache registry keys:
  - `CCDLocations` instead of `VHDLocations`
  - Multiple targets (e.g., one on-prem, one Azure blob)
- Talking point: "Cloud Cache writes to a local cache first, then replicates asynchronously to multiple targets. Great for DR — if your on-prem file server goes down, there's a copy in Azure. More complex to configure and troubleshoot, but valuable for business continuity."

### Fallback Plan
- **If RDP to session host fails**: Have screenshots of the registry keys, redirections.xml, and profile share.
- **If the SMB share isn't accessible from the demo machine**: Show the path and structure via screenshots. Explain what you'd see.
- **If `Invoke-FslShrinkDisk` isn't available**: Show the script content and explain the scheduling approach.

### Environment Prerequisites
- [ ] At least one AVD session host with FSLogix configured (registry keys set)
- [ ] RDP or Bastion access to the session host for live demo
- [ ] SMB share with profile VHDx files from at least 3–5 users
- [ ] A redirections.xml deployed on the session host with Teams/browser cache exclusions
- [ ] A profile compaction script or Nerdio scheduled action configured (or at least the script ready to show)
- [ ] (Optional) Cloud Cache configured with dual targets

---

## Demo 4: GPU Verification (~2 min)

### Corresponding Slides
- **Slide 28**: DDA vs. GPU-P comparison table
- **Slide 29**: GPU-P setup flow (host driver → partition → attach → guest driver)
- **Slide 30**: RDP graphics policy settings

### Pre-Demo Slide Context
Slides 28–30 cover the two GPU options (DDA for dedicated passthrough, GPU-P for partitioned multi-session), the setup flow for GPU-P (install host driver, partition GPU, attach to VM, install guest driver, configure NVIDIA licensing), and the RDP graphics policies needed to enable hardware acceleration in AVD sessions. The demo proves the GPU is actually working inside an AVD session.

### Step-by-Step Walkthrough

**Step 1 — Show GPU partitioning on a cluster node (45 sec)**
- Open PowerShell on an Azure Local cluster node (or show via remote session)
- Run: `Get-VMHostPartitionableGpu`
- Show output:
  - GPU name/model
  - Partition count
  - Available partitions
- Talking point: "This shows the physical GPU on this cluster node, partitioned into segments. Each partition can be assigned to a different VM. For AVD multi-session, GPU-P is the recommended approach — it gives you density. One physical GPU serves multiple session hosts."

**Step 2 — Show nvidia-smi inside an AVD session host VM (45 sec)**
- RDP or connect to an AVD session host that has a GPU partition assigned
- Open Command Prompt or PowerShell
- Run: `nvidia-smi`
- Show output:
  - GPU model recognized
  - Driver version (must match host driver version)
  - GPU memory allocation
  - Current utilization (idle or active)
- Talking point: "nvidia-smi inside the VM confirms the GPU is visible and the driver is loaded. The driver version here must be compatible with the host driver version — mismatches will cause the vGPU to fail to load. This is the most common GPU troubleshooting issue."

**Step 3 — Show a GPU-accelerated application (30 sec)**
- Inside the AVD session, open a GPU-intensive application:
  - Options: a CAD viewer (AutoCAD, Blender), GPT4All, a 3D visualization, or even Task Manager showing GPU utilization
- Show GPU utilization climbing in Task Manager or nvidia-smi
- Talking point: "Real GPU acceleration in an AVD session, running on hardware in your datacenter. For users doing CAD work, AI inference, or video editing — this is the reason they need on-prem AVD instead of cloud."

### Fallback Plan
- **If no GPU hardware is available**: Use screenshots showing `Get-VMHostPartitionableGpu` output and `nvidia-smi` output inside a session. This demo is the most hardware-dependent and most likely to need fallback.
- **If GPU driver mismatch**: Acknowledge it as a common gotcha. Show the mismatched version numbers and explain the fix (reinstall matching guest driver).
- **If nvidia-smi not found**: The guest vGPU driver isn't installed or the GPU partition isn't attached. Use screenshots.

### Environment Prerequisites
- [ ] Azure Local cluster node with a supported NVIDIA GPU
- [ ] GPU partitioned via `Set-VMHostPartitionableGpu`
- [ ] At least one AVD session host VM with a GPU partition attached
- [ ] NVIDIA vGPU guest driver installed inside the VM (compatible version with host driver)
- [ ] NVIDIA licensing configured (CLS or DLS)
- [ ] A GPU-intensive application installed on the session host for visual proof
- [ ] RDP access to both the cluster node (for `Get-VMHostPartitionableGpu`) and the session host VM (for `nvidia-smi`)

---

## Demo 5: Monitoring Setup (~3 min)

### Corresponding Slides
- **Slide 31**: Monitoring data flow diagram
- **Slide 32**: "What to monitor" priority matrix
- **Slide 33**: Cost-conscious logging tier comparison
- **Slide 34**: Sample alert rules

### Pre-Demo Slide Context
Slides 31–34 establish the monitoring architecture (session host → AMA → Log Analytics → AVD Insights), what to prioritize monitoring (session host health, user experience metrics, FSLogix, GPU, infrastructure), the cost-conscious logging approach (be selective about Diagnostic Settings, use Basic Logs tier, set retention policies), and essential alert rules. The demo shows the real dashboards and costs.

### Step-by-Step Walkthrough

**Step 1 — Show AVD Insights workbook with Azure Local session hosts (60 sec)**
- Navigate to **Azure Virtual Desktop → Insights** (or **Azure Monitor → Workbooks → AVD Insights**)
- Show the workbook with data from Azure Local session hosts:
  - **Overview tab**: Host pool health, session host count, user sessions
  - **Connection diagnostics**: Connection success/failure rates, round-trip time
  - **Session host performance**: CPU, memory, disk utilization across hosts
- Talking point: "AVD Insights works the same for Azure Local session hosts as it does for cloud. Same dashboards, same metrics. The data flows from your on-prem session hosts through the Azure Monitor Agent to a Log Analytics workspace in Azure. The experience is identical — but the bill is not. We'll look at cost in a moment."

**Step 2 — Show Diagnostic Settings configuration (45 sec)**
- Navigate to the host pool → **Diagnostic settings**
- Show what's enabled and what's disabled:
  - **Enabled**: Checkpoint, Connection, Error, Management, Feed
  - **Disabled** (or reduced): High-frequency performance counters
- Talking point: "Don't enable everything. Each category you enable sends data to Log Analytics, and you pay per gigabyte ingested. Focus on what you'll actually alert on or query. Connection and Error logs are essential. Every-second CPU counters? Probably not — unless you're actively troubleshooting a performance issue."

**Step 3 — Show a Log Analytics query for FSLogix profile load times (45 sec)**
- Navigate to **Log Analytics workspace** → **Logs**
- Run a pre-saved query for FSLogix profile load times:
  ```
  FSLogixProfileEvent
  | where EventType == "ProfileAttach"
  | summarize avg(DurationMs), percentile(DurationMs, 95) by bin(TimeGenerated, 1h)
  | render timechart
  ```
  (or similar query)
- Show the chart: average and P95 profile load times over time
- Talking point: "This is how you know if FSLogix is healthy. If average attach time is under 5 seconds, you're fine. If P95 is spiking to 30+ seconds during login storms, your storage is the bottleneck. This is the login storm math from earlier — now you're seeing it in real data."

**Step 4 — Show cost analysis for monitoring data (30 sec)**
- Navigate to **Cost Management → Cost Analysis**
- Filter for Log Analytics / Azure Monitor charges
- Show the monthly cost for monitoring data ingestion
- Talking point: "Here's the bill. For 50 session hosts with full diagnostics enabled, you might see $200–500/month in Log Analytics ingestion alone. That's why we said 'be selective.' Use Basic Logs tier for high-volume data, set 30-day retention, and consider whether a third-party tool like Nerdio or ControlUp gives you what you need without the full Log Analytics commitment."

### Fallback Plan
- **If AVD Insights has no data**: Workbook requires AMA installed and Diagnostic Settings configured for at least 24 hours. Use screenshots of a populated workbook.
- **If Log Analytics query returns empty**: Have pre-captured query results and chart as screenshots.
- **If Cost Management isn't accessible**: Have a screenshot of monitoring cost breakdown.

### Environment Prerequisites
- [ ] Azure Monitor Agent (AMA) installed on AVD session hosts on Azure Local
- [ ] Log Analytics workspace configured as destination for AVD Diagnostic Settings
- [ ] AVD Insights workbook accessible with populated data (at least 24 hours of data)
- [ ] Diagnostic Settings configured on the host pool (selective categories enabled)
- [ ] A saved Log Analytics query for FSLogix profile load times
- [ ] Cost Management accessible with visible monitoring charges (or screenshots)

---

## Master Demo Preparation Checklist

### Environment Setup (Complete 48+ Hours Before Session)
- [ ] Azure Local cluster with AVD host pool deployed and session hosts in "Available" status
- [ ] Azure Compute Gallery with at least one image definition, multiple versions, and replication to custom location
- [ ] Custom image template created in AVD portal (draft or completed state)
- [ ] FSLogix configured on session hosts with registry keys, redirections.xml, and VHDx profiles on SMB share
- [ ] GPU partitioned on at least one cluster node with a session host VM attached (if covering GPU live)
- [ ] NVIDIA guest driver installed and nvidia-smi functional inside the GPU-equipped VM
- [ ] GPU-intensive application installed on the GPU session host
- [ ] Azure Monitor Agent installed on all demo session hosts
- [ ] Log Analytics workspace with AVD diagnostic data ingested (minimum 24 hours)
- [ ] AVD Insights workbook populated with data
- [ ] Saved Log Analytics queries (FSLogix profile load times, connection diagnostics)
- [ ] Cost Management blade accessible

### Fallback Materials (Complete 24+ Hours Before Session)
- [ ] Screenshots of every demo step saved as backup slides in a separate PowerPoint file
- [ ] Short screen recordings (30–60 sec each) of key demo moments as video fallback
- [ ] Screenshots of: Compute Gallery with versions, host pool with session hosts, FSLogix registry keys, nvidia-smi output, AVD Insights workbook, cost analysis
- [ ] A "broken" session host screenshot (Unavailable status with health check failures) for the Haunted Host Pool section

### Day-Of Checks (Complete 30 Minutes Before Session)
- [ ] Verify Azure portal loads and all blades are accessible
- [ ] Verify session hosts show "Available" status in the host pool
- [ ] Verify FSLogix profile share is accessible and has VHDx files
- [ ] Verify GPU session host responds to nvidia-smi (if demoing GPU live)
- [ ] Verify AVD Insights workbook loads with data
- [ ] Verify Log Analytics queries return results
- [ ] Clear browser tabs — bookmarks to each demo starting point
- [ ] Set browser zoom to 125–150% for audience visibility
- [ ] Disable browser notifications and OS notifications
- [ ] Test projector/screen share with portal and RDP session open

### Demo Flow Quick Reference

| Demo | Start Trigger | End Signal | Transition |
|------|--------------|------------|------------|
| 1. Image Pipeline | After Slide 15 | "Now we have images — let's deploy session hosts." | → Slides 16–19 (Deployment) |
| 2. Host Pool Deployment | After Slide 19 | "Hosts are running. Now let's tackle the #1 operational concern — user profiles and storage." | → Slides 20–23 (Identity/Networking slides) → Slides 24–27 (FSLogix) |
| 3. FSLogix Configuration | After Slide 27 | "Profiles are handled. For those of you with GPU workloads, let's see how that works on Azure Local." | → Slides 28–30 (GPU) |
| 4. GPU Verification | After Slide 30 | "Everything is running. Now — how do we keep an eye on it without blowing our Azure bill?" | → Slides 31–34 (Monitoring) |
| 5. Monitoring Setup | After Slide 34 | "That's the operational picture. Now let's talk about what goes wrong — the Haunted Host Pool." | → Slides 35–41 (Failures) |
