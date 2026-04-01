# Troubleshooting — AVD on Azure Local

## Session Host Issues

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Session host shows **Unavailable** | AVD agent not registered or unhealthy | Check agent extension on the Arc VM; re-register if token expired |
| Session host shows **Needs Assistance** | Health check failure | Click into health check details for specific failure |
| **DomainJoinCheck** failed | Wrong credentials, DNS, or OU path | Verify DNS resolution from cluster nodes; check domain join credentials |
| **DomainTrustCheck** failed | Broken trust relationship | Rejoin the domain or reset the computer account |
| **UrlsAccessibleCheck** failed | Firewall blocking AVD service URLs | Ensure outbound 443/TCP to AVD gateway and broker URLs |
| Session host powered off > 90 days | Internal registration token expired | Re-register with a fresh host pool registration key |

## Connection Issues

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| RDP connection fails | Firewall or networking | Verify outbound access to AVD gateway URLs |
| High latency / poor experience | Network path or session host load | Check round-trip time in AVD Insights; check CPU/memory on host |
| Black screen after connect | Profile load failure | Check FSLogix logs on the session host |
| Disconnected sessions pile up | Session limits not configured | Configure idle/disconnected session limits in host pool properties |

## FSLogix Issues

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Profile not loading | VHDLocations registry key wrong | Verify UNC path and share permissions |
| Slow login | Storage IOPS bottleneck | Check storage performance; review login storm math |
| Profile VHDx growing unbounded | No redirections.xml | Deploy redirections.xml with cache exclusions |
| Profile locked / in use | Previous session didn't detach | Check for orphaned sessions; force-dismount the VHDx |
| Local profile created instead | FSLogix not enabled or misconfigured | Verify `Enabled = 1` in registry |

## GPU Issues

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| nvidia-smi not found | Guest driver not installed | Install NVIDIA vGPU guest driver |
| nvidia-smi shows no GPU | Partition not attached to VM | Verify GPU partition assignment |
| GPU driver error in VM | Host/guest driver version mismatch | Match driver versions exactly |
| Poor rendering in RDP session | RDP graphics policies not applied | Apply hardware encoding GPO settings |

## Azure Local / Infrastructure Issues

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Arc Resource Bridge down | Appliance VM issue | Restart ARB appliance; check cluster health |
| Image download stuck | Connectivity from cluster to Azure | Verify outbound internet from cluster nodes |
| VM provisioning fails | No available capacity | Check cluster node resources; remove stale VMs |
| Arc VMs not showing in portal | ARB not syncing | Restart Arc Resource Bridge |

## Useful Diagnostic Commands

```powershell
# Check AVD agent status on session host
Get-Service -Name "RDAgentBootLoader", "RDAgent" | Format-Table Name, Status

# Check FSLogix status
Get-Service -Name "frxsvc" | Format-Table Name, Status

# Check FSLogix logs
Get-WinEvent -LogName "Microsoft-FSLogix-Apps/Operational" -MaxEvents 20

# Check GPU partition on cluster node
Get-VMHostPartitionableGpu

# Check GPU inside session host VM
nvidia-smi

# Check Arc agent status
azcmagent show
```
