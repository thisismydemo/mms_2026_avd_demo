# Slide-to-Demo Map — AVD on Azure Local

## Demo 1: Image Build Pipeline

| Slide | Title | Purpose |
|-------|-------|---------|
| 12 | 6 Ways to Get Images onto Azure Local | Visual overview of image source paths |
| 13 | Custom image pipeline flow | Build → Customize → Sysprep → Gallery → Deploy |
| 14 | What goes in the golden image | Checklist: no AVD agent, install FSLogix, disable Storage Sense |
| 15 | Image versioning strategy | Version numbering, replication targets |
| **→ DEMO** | Live in Azure portal | Compute Gallery, custom image template, replication status |

## Demo 2: Host Pool Deployment

| Slide | Title | Purpose |
|-------|-------|---------|
| 16 | Host pool creation flow | Portal wizard with custom location selection |
| 17 | VM sizing | Physical hardware allocation, not SKU picker |
| 18 | Common deployment failures | DNS, domain join, registration key expiry |
| 19 | Deployment methods | Portal vs. Bicep vs. Terraform vs. CLI vs. Nerdio |
| **→ DEMO** | Live in Azure portal | Host pool creation wizard, session host states, health checks |

## Demo 3: FSLogix Configuration

| Slide | Title | Purpose |
|-------|-------|---------|
| 24 | FSLogix is a storage project | Mental model reframe |
| 25 | Storage sizing calculator | Login storm math (users × IOPS) |
| 26 | Must-have registry keys | VHDLocations, SizeInMBs, IsDynamic, etc. |
| 27 | HA options comparison | SOFS vs. Cloud Cache vs. DFS-R (don't) |
| **→ DEMO** | Live on session host + file share | Registry keys, redirections.xml, VHDx files, compaction |

## Demo 4: GPU Verification

| Slide | Title | Purpose |
|-------|-------|---------|
| 28 | DDA vs. GPU-P comparison | Dedicated passthrough vs. partitioned |
| 29 | GPU-P setup flow | Host driver → partition → attach → guest driver |
| 30 | RDP graphics policies | Hardware acceleration settings |
| **→ DEMO** | Live on cluster node + session host | Get-VMHostPartitionableGpu, nvidia-smi, GPU app |

## Demo 5: Monitoring Setup

| Slide | Title | Purpose |
|-------|-------|---------|
| 31 | Monitoring data flow | Session host → AMA → Log Analytics → Insights |
| 32 | What to monitor | Priority matrix |
| 33 | Cost-conscious logging | Basic Logs tier, selective Diagnostic Settings |
| 34 | Sample alert rules | Critical alerts for AVD operations |
| **→ DEMO** | Live in Azure portal | AVD Insights, Diagnostic Settings, KQL query, Cost Analysis |
