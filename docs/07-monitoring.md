# Monitoring — AVD on Azure Local

## Architecture

```
Session Host (on-prem) → Azure Monitor Agent (AMA) → Log Analytics Workspace (Azure) → AVD Insights
```

The monitoring experience is identical for Azure Local session hosts and cloud-hosted session hosts. Same dashboards, same metrics, same queries.

## Setup

### 1. Install Azure Monitor Agent

AMA is installed as an Arc VM extension on each session host. Deploy via:
- Azure portal (Extensions blade on the Arc VM)
- Azure Policy (DeployIfNotExists)
- Bicep/ARM template

### 2. Configure Diagnostic Settings

On the AVD host pool, enable selective diagnostic categories:

| Category | Enable? | Notes |
|----------|---------|-------|
| Checkpoint | Yes | Core operational events |
| Connection | Yes | User connection events — essential |
| Error | Yes | Error tracking — essential |
| Management | Yes | Management operations |
| Feed | Yes | Feed subscription events |
| HostRegistration | Yes | Session host registration events |
| AgentHealthStatus | Yes | Agent health reporting |
| NetworkData | Optional | High volume — enable only when troubleshooting |
| SessionHostManagement | Optional | Session host lifecycle events |

**Do not enable everything.** Each category costs per GB ingested.

### 3. Configure Log Analytics Workspace

- Use **PerGB2018** pricing tier
- Set retention to **30 days** (default) — extend only if compliance requires it
- Consider **Basic Logs** tier for high-volume, low-query data

## AVD Insights

Navigate to: **Azure Virtual Desktop → Insights** or **Azure Monitor → Workbooks → AVD Insights**

Key tabs:
- **Overview**: Host pool health, session host count, active users
- **Connection Diagnostics**: Success/failure rates, round-trip time, bandwidth
- **Session Host Performance**: CPU, memory, disk utilization
- **User Experience**: Input delay, frames per second

## Key KQL Queries

See `../queries/` for ready-to-use queries:
- FSLogix profile load times
- Connection diagnostics
- Session host performance
- Cost analysis

## Cost Control

| Strategy | Impact |
|----------|--------|
| Enable only essential Diagnostic Settings categories | Reduces ingestion volume |
| Use Basic Logs tier for performance counters | Lower per-GB cost |
| Set 30-day retention (not 90) | Reduces storage cost |
| Use Azure Resource Graph for compliance (free) instead of Log Analytics | Eliminates query cost |
| Review Cost Management monthly | Catch unexpected spikes |

For 50 session hosts with full diagnostics: expect $200–500/month in Log Analytics ingestion. Be selective.
