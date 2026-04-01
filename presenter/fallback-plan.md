# Fallback Plan — AVD on Azure Local

Every demo has a fallback. Screenshots and recordings live in `../assets/`.

## Demo 1: Image Build Pipeline

| Failure | Fallback |
|---------|----------|
| Compute Gallery empty | Screenshot: `assets/screenshots/demo1-gallery-versions.png` |
| Custom image template blade unavailable | Screenshot: `assets/screenshots/demo1-image-template.png` |
| Replication not completed | Use in-progress status as teaching moment about bandwidth planning |

## Demo 2: Host Pool Deployment

| Failure | Fallback |
|---------|----------|
| Portal wizard slow or errors | Walk through wizard to review step without deploying |
| No session hosts exist | Screenshot: `assets/screenshots/demo2-session-hosts.png` |
| Health checks not populated | Screenshot: `assets/screenshots/demo2-health-checks.png` |

## Demo 3: FSLogix Configuration

| Failure | Fallback |
|---------|----------|
| RDP to session host fails | Screenshot: `assets/screenshots/demo3-registry-keys.png` |
| SMB share inaccessible | Screenshot: `assets/screenshots/demo3-profile-share.png` |
| Invoke-FslShrinkDisk unavailable | Show script content from `scripts/` |

## Demo 4: GPU Verification

| Failure | Fallback |
|---------|----------|
| No GPU hardware | Screenshot: `assets/screenshots/demo4-gpu-partition.png` + `demo4-nvidia-smi.png` |
| GPU driver mismatch | Acknowledge as common gotcha, show version numbers |
| nvidia-smi not found | Screenshot: `assets/screenshots/demo4-nvidia-smi.png` |

**This is the most hardware-dependent demo and the most likely to need fallback.**

## Demo 5: Monitoring Setup

| Failure | Fallback |
|---------|----------|
| AVD Insights has no data | Screenshot: `assets/screenshots/demo5-avd-insights.png` |
| Log Analytics query returns empty | Screenshot: `assets/screenshots/demo5-kql-results.png` |
| Cost Management inaccessible | Screenshot: `assets/screenshots/demo5-cost-analysis.png` |

## General Fallback Rules

1. Never apologize for switching to screenshots — say "Let me show you what this looks like" and move on.
2. If the portal is completely down, switch to the backup PowerPoint with embedded screenshots.
3. Keep fallback screenshots in `assets/screenshots/` with naming that matches the demo number.
4. Record 30–60 second video clips of each demo as a last-resort fallback in `assets/recordings/`.
