param location string = resourceGroup().location
param projectName string

param imageTag string
param containerRegistryOwner string


module storage 'storage.bicep' = {
  name: 'container-app-storage'
  params: {
    storageAccountName: 'strg${resourceGroup().name}'
  }
}

module appqueueworkerdapr 'app-queue-worker-dapr.bicep' = {
  name: 'container-app-queue-worker-dapr'
  params: {
    containerRegistryPath: 'ghcr.io/${containerRegistryOwner}/container-apps/optimizer-dapr:${imageTag}'
    environmentName: '${projectName}'
    storageAccountName: storage.outputs.storageAccountName
    storageAccountKey: storage.outputs.storageAccountKey
  }
}

module appqueueworker 'app-queue-worker.bicep' = {
  name: 'container-app-queue-worker'
  params: {
    containerRegistryPath: 'ghcr.io/${containerRegistryOwner}/container-apps/optimizer:${imageTag}'
    environmentName: '${projectName}'
    storageAccountName: storage.outputs.storageAccountName
    storageAccountKey: storage.outputs.storageAccountKey
  }
}


// az deployment group create -g dzca15cgithub -f ./deploy/apps.bicep -p explorerImageTag=latest -p calculatorImageTag=latest  -p containerRegistryOwner=denniszielke
