// =============================================================================
// avd-workspace.bicep
// Deploys an AVD workspace and associates one or more application groups.
// =============================================================================

param workspaceName string
param location string
param tags object

@description('List of application group resource IDs to associate with the workspace.')
param appGroupIds array

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-01-16-preview' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    friendlyName: 'MMS MOA 2026 – AVD on Azure Local'
    description: 'Demo workspace for the MMS MOA 2026 Azure Virtual Desktop on Azure Local session'
    applicationGroupReferences: appGroupIds
  }
}

output workspaceId string = workspace.id
