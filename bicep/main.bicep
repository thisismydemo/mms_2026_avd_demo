// =============================================================================
// main.bicep
// MMS MOA 2026 – Azure Virtual Desktop on Azure Local
// Entry point for the full demo deployment.
// =============================================================================

targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Azure region for the AVD control-plane resources.')
param location string = resourceGroup().location

@description('Name of the AVD host pool.')
param hostPoolName string = 'hp-avd-mms26-demo-eus-01'

@description('Name of the AVD application group.')
param appGroupName string = 'ag-avd-mms26-demo-eus-01'

@description('Name of the AVD workspace.')
param workspaceName string = 'ws-avd-mms26-demo-eus-01'

@description('Resource ID of the Arc custom location for the Azure Local cluster.')
param customLocationId string

@description('Resource ID of the Arc VM logical network.')
param logicalNetworkId string

@description('Resource ID of the Azure Local VM gallery image.')
param galleryImageId string

@description('Active Directory domain name (e.g. contoso.local).')
param domainName string

@description('UPN or sAMAccountName used for domain join.')
param domainJoinUsername string

@description('Password for the domain join account.')
@secure()
param domainJoinPassword string

@description('OU path for the session host computer objects (leave empty to use the default).')
param domainJoinOuPath string = ''

@description('Number of session host VMs to deploy.')
@minValue(1)
@maxValue(20)
param sessionHostCount int = 2

@description('Prefix for session host VM names.')
@maxLength(11)
param sessionHostNamePrefix string = 'vm-avd-mms26-demo-eus'

@description('Arc VM size for session hosts.')
param vmSize string = 'Standard_D4s_v3'

@description('Local administrator username for session host VMs.')
param localAdminUsername string = 'azureuser'

@description('Local administrator password for session host VMs.')
@secure()
param localAdminPassword string

@description('Name of the Log Analytics workspace for AVD Insights.')
param logAnalyticsWorkspaceName string = 'log-avd-mms26-demo-eus-01'

@description('Tags to apply to all resources. See STANDARDS.md for required tags.')
param tags object = {
  Demo:        'AVD Anywhere'
  Conference:  'MMSMOA 2026'
  Owner:       'Kristopher Turner'
  Environment: 'Demo'
  CostCenter:  'MMSMOA2026'
  ManagedBy:   'GitHub Copilot'
  Repository:  'https://github.com/thisismydemo/mms_2026_avd_demo'
}

// ---------------------------------------------------------------------------
// Log Analytics Workspace
// ---------------------------------------------------------------------------

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ---------------------------------------------------------------------------
// AVD Host Pool
// ---------------------------------------------------------------------------

module hostPool 'modules/avd-host-pool.bicep' = {
  name: 'deploy-host-pool'
  params: {
    hostPoolName: hostPoolName
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

// ---------------------------------------------------------------------------
// AVD Application Group
// ---------------------------------------------------------------------------

module appGroup 'modules/avd-app-group.bicep' = {
  name: 'deploy-app-group'
  params: {
    appGroupName: appGroupName
    location: location
    tags: tags
    hostPoolId: hostPool.outputs.hostPoolId
  }
}

// ---------------------------------------------------------------------------
// AVD Workspace
// ---------------------------------------------------------------------------

module workspace 'modules/avd-workspace.bicep' = {
  name: 'deploy-workspace'
  params: {
    workspaceName: workspaceName
    location: location
    tags: tags
    appGroupIds: [ appGroup.outputs.appGroupId ]
  }
}

// ---------------------------------------------------------------------------
// Session Hosts on Azure Local
// ---------------------------------------------------------------------------

module sessionHosts 'modules/avd-session-host.bicep' = {
  name: 'deploy-session-hosts'
  params: {
    sessionHostCount: sessionHostCount
    sessionHostNamePrefix: sessionHostNamePrefix
    vmSize: vmSize
    location: location
    customLocationId: customLocationId
    logicalNetworkId: logicalNetworkId
    galleryImageId: galleryImageId
    localAdminUsername: localAdminUsername
    localAdminPassword: localAdminPassword
    domainName: domainName
    domainJoinUsername: domainJoinUsername
    domainJoinPassword: domainJoinPassword
    domainJoinOuPath: domainJoinOuPath
    hostPoolRegistrationToken: hostPool.outputs.registrationToken
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output hostPoolId string = hostPool.outputs.hostPoolId
output appGroupId string = appGroup.outputs.appGroupId
output workspaceId string = workspace.outputs.workspaceId
output sessionHostNames array = sessionHosts.outputs.sessionHostNames
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
