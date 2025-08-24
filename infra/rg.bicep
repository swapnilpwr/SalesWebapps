@description('Azure region for all resources (e.g., eastus, westeurope).')
param location string

@description('App Service plan name.')
param planName string

@description('Web App name (must be globally unique).')
param appName string

@description('Key Vault name (must be globally unique).')
param kvName string

@description('App Service SKU (e.g., B1, S1).')
param sku string = 'B1'

@description('Key Vault secret name to create.')
param secretName string = 'app-message'

@secure()
@description('Initial value for the Key Vault secret.')
param secretValue string = 'Hello from Key Vault via Bicep!'

var nodeFx = 'NODE|18-lts'

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: sku
    tier: contains(toLower(sku), 'b') ? 'Basic' : (contains(toLower(sku), 's') ? 'Standard' : 'Basic')
    capacity: 1
  }
  properties: {
    reserved: true // Linux
  }
}

resource site 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: nodeFx
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'KEYVAULT_URI'
          value: 'https://${kv.name}.vault.azure.net/'
        }
        {
          name: 'SECRET_NAME'
          value: secretName
        }
      ]
    }
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    publicNetworkAccess: 'Enabled' // Public endpoint ON
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow' // Allow from internet (for demo/public access). Tighten for production.
    }
    softDeleteRetentionInDays: 90
    enablePurgeProtection: false
    accessPolicies: [
      // Grant the Web App's system-assigned identity access to read secrets
      {
        tenantId: tenant().tenantId
        objectId: site.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Create an initial secret value for the demo
resource demoSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${kv.name}/${secretName}'
  properties: {
    value: secretValue
  }
  dependsOn: [
    kv
  ]
}

output webAppPrincipalId string = site.identity.principalId
