param environmentName string
param logAnalyticsWorkspaceName string = 'logs-${environmentName}'
param appInsightsName string = 'appins-${environmentName}'
param location string = resourceGroup().location
param storageAccountName string = 'assets${uniqueString(resourceGroup().id)}' 
param containerName string = 'output'
param queueName string = 'requests'
param containerRegistryPath string = ''

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-${resourceGroup().name}'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/19'
      ]
    }
    subnets: [
      {
        name: 'gateway'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'jumpbox'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'apim'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
      {
        name: 'aca-control'
        properties: {
          addressPrefix: '10.0.8.0/21'
        }
      }
      {
        name: 'aca-apps'
        properties: {
          addressPrefix: '10.0.16.0/21'
        }
      }
    ]
  }
}

resource mediaStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
   name: storageAccountName
   location: location 
   sku: { 
     name: 'Standard_LRS' 
   } 
   kind: 'StorageV2' 
   properties: { 
     accessTier: 'Hot' 
   } 
}

resource outputContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${mediaStorageAccount.name}/default/${containerName}'
}

resource requestQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-08-01' = {
  name: '${mediaStorageAccount.name}/default/${queueName}'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: { 
    ApplicationId: appInsightsName
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'CustomDeployment'
  }
}

resource environment 'Microsoft.Web/kubeEnvironments@2021-03-01' = {
  name: environmentName
  location: location
  properties: {
    type: 'managed'
    internalLoadBalancerEnabled: false
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    containerAppsConfiguration: {
      daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
      controlPlaneSubnetResourceId : '${vnet.id}/subnets/aca-control'
      appSubnetResourceId: '${vnet.id}/subnets/aca-apps'
      internalOnly: false
    }
  }
}

resource containerApp 'Microsoft.Web/containerApps@2021-03-01' = {
  name: 'optimizer'
  kind: 'containerapp'
  location: location
  properties: {
    kubeEnvironmentId: environment.id
    configuration: {
      secrets: [
        {
          name: 'storage-key'
          value: '${listKeys(mediaStorageAccount.id, mediaStorageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'storage-connectionstring'
          value: 'DefaultEndpointsProtocol=https;AccountName=${mediaStorageAccount.name};EndpointSuffix=core.windows.net;AccountKey=${listKeys(mediaStorageAccount.id, mediaStorageAccount.apiVersion).keys[0].value}'
        }
      ]      
      ingress: {
        external: true
        targetPort: 6000
      }
    }
    template: {
      containers: [
        {
          image: '${containerRegistryPath}'
          name: 'optimizer'
          resources: {
            cpu: '2'
            memory: '4Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'queue-based-autoscaling'
            custom: {
              type: 'azure-queue'
              metadata: {
                queueName: queueName
                messageCount: '3'
              }
              auth: [
                {
                  secretRef: 'storage-connectionstring'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
      dapr: {
        enabled: true
        appPort: 6000
        appId: 'optimizer'
        components: [
          {
            name: 'bloboutput'
            type: 'bindings.azure.blobstorage'
            version: 'v1'
            metadata: [
              {
                name: 'storageAccount'
                value: storageAccountName
              }
              {
                name: 'storageAccessKey'
                secretRef: 'storage-key'
              }
              {
                name: 'container'
                value: containerName
              }            
              {
                name: 'decodeBase64'
                value: 'true'
              }
            ]
          }
          {
            name: 'queueinput'
            type: 'bindings.azure.storagequeues'
            version: 'v1'
            metadata: [
              {
                name: 'storageAccount'
                value: storageAccountName
              }
              {
                name: 'storageAccessKey'
                secretRef: 'storage-key'
              }
              {
                name: 'queue'
                value: queueName
              }  
              {
                name: 'ttlInSeconds'
                value: '60'
              }          
              {
                name: 'decodeBase64'
                value: 'true'
              }
            ]
          }
        ]
      }
    }
  }
}


output location string = location
output environmentId string = environment.id
