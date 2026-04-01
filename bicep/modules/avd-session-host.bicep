// =============================================================================
// avd-session-host.bicep
// Deploys one or more Arc VMs on Azure Local as AVD session hosts.
// Each VM is domain-joined and the AVD Agent extension is installed.
// =============================================================================

param sessionHostCount int
param sessionHostNamePrefix string
param vmSize string
param location string
param customLocationId string
param logicalNetworkId string
param galleryImageId string
param localAdminUsername string
@secure()
param localAdminPassword string
param domainName string
param domainJoinUsername string
@secure()
param domainJoinPassword string
param domainJoinOuPath string
param hostPoolRegistrationToken string
param tags object

// ---------------------------------------------------------------------------
// Network interfaces (one per session host)
// ---------------------------------------------------------------------------

resource nic 'Microsoft.AzureStackHCI/networkInterfaces@2024-01-01' = [for i in range(0, sessionHostCount): {
  name: '${sessionHostNamePrefix}-${padLeft(i + 1, 2, '0')}-nic'
  location: location
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: logicalNetworkId
          }
        }
      }
    ]
  }
}]

// ---------------------------------------------------------------------------
// Session host virtual machines
// ---------------------------------------------------------------------------

resource vm 'Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01' = [for i in range(0, sessionHostCount): {
  name: 'default'
  scope: arcMachine[i]
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${sessionHostNamePrefix}-${padLeft(i + 1, 2, '0')}'
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        timeZone: 'UTC'
      }
    }
    storageProfile: {
      imageReference: {
        id: galleryImageId
      }
      osDisk: {
        osType: 'Windows'
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
  }
}]

// Arc machine placeholder resource (used to scope the VM instance resource)
resource arcMachine 'Microsoft.HybridCompute/machines@2024-05-20-preview' = [for i in range(0, sessionHostCount): {
  name: '${sessionHostNamePrefix}-${padLeft(i + 1, 2, '0')}'
  location: location
  tags: tags
  kind: 'HCI'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}]

// ---------------------------------------------------------------------------
// Domain join extension
// ---------------------------------------------------------------------------

resource domainJoinExtension 'Microsoft.HybridCompute/machines/extensions@2024-05-20-preview' = [for i in range(0, sessionHostCount): {
  parent: arcMachine[i]
  name: 'DomainJoin'
  location: location
  dependsOn: [ vm[i] ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      OUPath: domainJoinOuPath
      User: domainJoinUsername
      Restart: 'true'
      Options: '3'
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
}]

// ---------------------------------------------------------------------------
// AVD Agent extension
// ---------------------------------------------------------------------------

resource avdAgentExtension 'Microsoft.HybridCompute/machines/extensions@2024-05-20-preview' = [for i in range(0, sessionHostCount): {
  parent: arcMachine[i]
  name: 'AVDAgentInstall'
  location: location
  dependsOn: [ domainJoinExtension[i] ]
  properties: {
    publisher: 'Microsoft.Azure.VirtualDesktop'
    type: 'SessionHostConfigurationManagement'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      RegistrationToken: hostPoolRegistrationToken
    }
  }
}]

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output sessionHostNames array = [for i in range(0, sessionHostCount): '${sessionHostNamePrefix}-${padLeft(i + 1, 2, '0')}']
