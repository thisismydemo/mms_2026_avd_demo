// =============================================================================
// avd-host-pool.bicep
// Deploys an AVD host pool (pooled, depth-first) with a registration token.
// =============================================================================

param hostPoolName string
param location string
param tags object
param logAnalyticsWorkspaceId string

// Registration token expiry time – fixed at 24 hours (PT24H)
var tokenExpirationTime = dateTimeAdd(utcNow('u'), 'PT24H')

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-01-16-preview' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'DepthFirst'
    maxSessionLimit: 10
    validationEnvironment: false
    preferredAppGroupType: 'Desktop'
    startVMOnConnect: false
    registrationInfo: {
      expirationTime: tokenExpirationTime
      registrationTokenOperation: 'Update'
    }
    agentUpdate: {
      useSessionHostLocalTime: false
      maintenanceWindowTimeZone: 'UTC'
      type: 'Scheduled'
      maintenanceWindows: [
        {
          hour: 2
          dayOfWeek: 'Sunday'
        }
      ]
    }
  }
}

// Diagnostic settings for AVD Insights
resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: hostPool
  name: 'avd-insights'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      { category: 'Checkpoint'; enabled: true }
      { category: 'Error'; enabled: true }
      { category: 'Management'; enabled: true }
      { category: 'Connection'; enabled: true }
      { category: 'HostRegistration'; enabled: true }
      { category: 'AgentHealthStatus'; enabled: true }
    ]
  }
}

output hostPoolId string = hostPool.id
output registrationToken string = hostPool.properties.registrationInfo.token
