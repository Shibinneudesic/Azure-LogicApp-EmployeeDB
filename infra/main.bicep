// Azure Logic App Standard Infrastructure
// This template creates the required resources for the UpsertEmployee Logic App
// in the existing AIS_Training_Shibin resource group with proper policy compliance

@description('The location for all resources')
param location string = 'Canada Central'

@description('Logic App name')
param logicAppName string = 'upsert-employee'

@description('Storage account name for Logic App')
param storageAccountName string = 'stshibinupsert01'

@description('App Service Plan name')
param appServicePlanName string = 'asp-shibin-upsert-dev'

@description('Environment tag')
param environment string = 'dev'

// Required tags for policy compliance
var commonTags = {
  Owner: 'shibin.sam@neudesic.com'
  Environment: environment
  Project: 'AIS-Training'
  Application: 'UpsertEmployee'
}

// Storage Account for Logic App runtime
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// App Service Plan for Logic App
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: commonTags
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  properties: {
    targetWorkerCount: 1
    targetWorkerSizeId: 0
  }
}

// Logic App (Standard)
resource logicApp 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: location
  tags: commonTags
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower('${logicAppName}-content')
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'AzureWebJobsFeatureFlags'
          value: 'EnableWorkerIndexing'
        }
        {
          name: 'APP_KIND'
          value: 'workflowapp'
        }
        {
          name: 'AZURE_SQL_CONNECTION_STRING'
          value: 'Server=tcp:aistrainingserver.database.windows.net,1433;Initial Catalog=empdb;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication="Active Directory Default";'
        }
      ]
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v6.0'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'https://ms.portal.azure.com'
        ]
      }
    }
  }
}

// Outputs
output logicAppName string = logicApp.name
output logicAppUrl string = 'https://${logicApp.properties.defaultHostName}'
output storageAccountName string = storageAccount.name
output appServicePlanName string = appServicePlan.name
output resourceGroupName string = resourceGroup().name