# Image Pipeline — AVD on Azure Local

## Overview

AVD session host images on Azure Local can be sourced through 6 paths:

1. **Azure Marketplace** — Quick start / PoC
2. **Azure Compute Gallery** — Production with custom images (primary path)
3. **Storage Account** — Upload VHDX from blob storage
4. **Local Share / CSV** — Place VHDX directly on cluster shared volume
5. **Existing Arc VM capture** — Sysprep and capture a running VM
6. **Azure Managed Disk download** — Download from a managed disk

For production AVD, the **Compute Gallery with custom image templates** is the recommended path.

## Golden Image Checklist

- [ ] Start from Windows 11 Enterprise multi-session base
- [ ] **Do NOT install the AVD agent** — it is injected during host pool deployment
- [ ] Install FSLogix agent
- [ ] Install Microsoft 365 Apps (shared computer activation)
- [ ] Install LOB applications
- [ ] Disable Storage Sense
- [ ] Run Windows Update to latest cumulative update
- [ ] Apply RDP Shortpath and Teams optimization settings
- [ ] Sysprep with `/generalize /oobe /shutdown`

## Custom Image Template (Azure Image Builder)

The AVD portal provides an integrated image builder experience:

1. Select a base Marketplace image (Windows 11 multi-session)
2. Add built-in optimization scripts:
   - FSLogix configuration
   - Teams optimization (media redirection, WebRTC)
   - Language pack installation
   - Screen capture protection
   - Time zone redirection
3. Add custom scripts (URL to storage account or GitHub)
4. Build → outputs a new image version in Compute Gallery
5. Replicate to Azure Local custom location

## Replication to Azure Local

- Image versions in Compute Gallery can target Azure regions AND custom locations
- Replication to Azure Local depends on internet bandwidth
- For a ~30 GB Windows image: 30 minutes to several hours
- Plan replication into maintenance windows
- For air-gapped or low-bandwidth sites: build locally, place VHDX on CSV, register as image

## Image Versioning Strategy

- Use semantic versioning: `1.0.0`, `1.1.0`, `1.2.0`
- Each version is an immutable snapshot
- Keep at least 2 previous versions for rollback
- Delete old versions to reclaim storage on the cluster
