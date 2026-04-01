// =============================================================================
// demo.bicepparam
// Parameter values for the MMS MOA 2026 AVD on Azure Local demo deployment.
//
// Replace all values marked with TODO before running the deployment.
// NEVER commit real passwords or secrets to source control.
// =============================================================================

using '../main.bicep'

// Azure region for AVD control-plane resources
param location = 'eastus'

// ── AVD names ────────────────────────────────────────────────────────────────
param hostPoolName  = 'hp-mms-demo'
param appGroupName  = 'ag-mms-demo'
param workspaceName = 'ws-mms-demo'

// ── Azure Local references ───────────────────────────────────────────────────
// Run: az customlocation show --resource-group <rg> --name <name> --query id -o tsv
param customLocationId = '<arc-custom-location-resource-id>'      // TODO

// Run: az stack-hci-vm network lnet show --resource-group <rg> --name lnet-avd-demo --query id -o tsv
param logicalNetworkId = '<arc-logical-network-resource-id>'      // TODO

// Run: az stack-hci-vm image show --resource-group <rg> --name img-win11-multisession --query id -o tsv
param galleryImageId = '<arc-gallery-image-resource-id>'          // TODO

// ── Session hosts ────────────────────────────────────────────────────────────
param sessionHostCount      = 2
param sessionHostNamePrefix = 'vm-avd-demo'
param vmSize                = 'Standard_D4s_v3'
param localAdminUsername    = 'azureuser'
// localAdminPassword is injected securely at deploy time – do not store here.

// ── Active Directory ─────────────────────────────────────────────────────────
param domainName         = 'contoso.local'                        // TODO
param domainJoinUsername = 'CONTOSO\\avdjoin'                     // TODO
param domainJoinOuPath   = ''                                     // TODO (optional)
// domainJoinPassword is injected securely at deploy time – do not store here.

// ── Monitoring ───────────────────────────────────────────────────────────────
param logAnalyticsWorkspaceName = 'law-avd-demo'

// ── Tags ─────────────────────────────────────────────────────────────────────
param tags = {
  environment: 'demo'
  session: 'MMS-MOA-2026'
  technology: 'AVD-AzureLocal'
}
