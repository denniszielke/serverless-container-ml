param location string = resourceGroup().location
param environmentName string = 'env-${resourceGroup().name}'
param containerRegistryPath string = ''

// // container app environment
module environment 'environment.bicep' = {
  name: 'container-app-environment'
  params: {
    environmentName: environmentName
    containerRegistryPath: containerRegistryPath
  }
}
