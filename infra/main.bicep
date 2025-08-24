targetScope = 'subscription'

@description('Azure region for all resources (e.g., eastus, westeurope).')
param location string = 'eastus'

@description('Resource group name to create.')
param rgName string = 'rg-web-kv-demo'

@description('App Service plan name.')
param planName string = 'plan-web-kv-demo'

@description('Web App name (must be globally unique).')
param appName string = 'app-web-kv-demo-001'

@description('Key Vault name (must be globally unique).')
param kvName string = 'kv-web-kv-demo-001'

@description('App Service SKU (e.g., B1, S1).')
param sku string = 'B1'

@description('Key Vault secret name to create.')
param secretName string = 'app-message'

@secure()
@description('Initial value for the Key Vault secret.')
param secretValue string = 'Hello from Key Vault via Bicep!'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

module rgResources 'rg.bicep' = {
  name: 'rg-resources'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    planName: planName
    appName: appName
    kvName: kvName
    sku: sku
    secretName: secretName
    secretValue: secretValue
  }
}

output resourceGroupName string = rg.name
output webAppName string = appName
output keyVaultName string = kvName
