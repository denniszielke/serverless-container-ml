param environmentName string
param location string = resourceGroup().location
param containerRegistryPath string
param storageAccountName string
param storageAccountKey string

resource optmsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'opt-msi'
  location: location
}

resource containerApp 'Microsoft.App/containerapps@2022-11-01-preview'  = {
  name: 'optimizer'
  kind: 'containerapp'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${optmsi.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', environmentName)
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 6000
        allowInsecure: false    
        transport: 'Auto'
      }
      secrets: [
        {
          name: 'storage-connectionstring'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=core.windows.net;AccountKey=${storageAccountKey}'
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerRegistryPath
          name: 'optimizer'
          resources: {
            cpu: '2'
            memory: '4Gi'
          }
          probes: [
            {
              type: 'liveness'
              httpGet: {
                path: '/ping'
                port: 6000
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/ping'
                port: 6000
              }
              initialDelaySeconds: 5
              periodSeconds: 3
            }
          ]
          env:[
            {
              name: 'STORAGE_ACCOUNT'
              value: storageAccountName
            }
            {
              name: 'STORAGE_ACCOUNT_CONNECTIONSTRING'
              secretRef: 'storage-connectionstring'
            }
          ]
        }
      ]
    }
  }
}
