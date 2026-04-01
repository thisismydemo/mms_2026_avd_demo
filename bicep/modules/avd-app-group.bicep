// =============================================================================
// avd-app-group.bicep
// Deploys an AVD Desktop Application Group linked to a host pool.
// =============================================================================

param appGroupName string
param location string
param tags object

@description('Resource ID of the parent host pool.')
param hostPoolId string

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-01-16-preview' = {
  name: appGroupName
  location: location
  tags: tags
  properties: {
    applicationGroupType: 'Desktop'
    hostPoolArmPath: hostPoolId
    friendlyName: 'MMS 2026 Demo Desktop'
    description: 'Azure Virtual Desktop on Azure Local – MMS MOA 2026 demo desktop'
  }
}

output appGroupId string = appGroup.id
