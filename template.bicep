//PARAMETERS
@description('Azure Region where the resources will be deployed. Default Value:  the resource group region')
param resourceLocation string = resourceGroup().location

@minLength(3)
@maxLength(6)
@description('Deployment Prefix - all resources names created by this template will start with this prefix')
param deploymentPrefix string

@description('Tags to be applied to resources that are deployed in this template')
param resourceTags object = {
  'project': 'gnocchi'
}

@description('SKU for the App Service Plan')
param appServicePlanSKU object = {
  name: 'Y1'
  tier: 'Dynamic'
  size: 'Y1'
  family: 'Y'
  capacity: 0
}

//VARIABLES
var importStorageAccountName = '${deploymentPrefix}saimp'
var exportStorageAccountName = '${deploymentPrefix}saexp'
var functionsStorageAccountName = '${deploymentPrefix}safun'
var healthDataServicesName = '${deploymentPrefix}hdsws'
var dataFactoryName = '${deploymentPrefix}dafa'
var appServicePlanName = '${deploymentPrefix}asp'

var importStorageContainerList = [ 'landing', 'error', 'processed' ]
var exportStorageContainerList = [ 'export' ]

var fhirServiceConfig = {
  name: 'fhirtrn'
  url: 'https://${healthDataServicesName}-fhirtrn.fhir.azurehealthcareapis.com'
  kind: 'fhir-R4'
  version: 'R4'
  systemIdentity: 'SystemAssigned'
}

var fhirIngestionAppConfig = {
  name: '${deploymentPrefix}faing'
  url: 'https://${deploymentPrefix}faing.azurewebsites.net'
  repoUrl: 'https://github.com/alberto-vico/azure-fhir-ingestion'
  repoBranch: 'main'
}

//RESOURCES
resource importStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: importStorageAccountName
  kind: 'StorageV2'
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    isHnsEnabled: true
    isNfsV3Enabled: false
    minimumTlsVersion: 'TLS1_2'
  }
  tags: resourceTags
}

resource importStorageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: importStorageAccount
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource importStorageAccountContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [for container in importStorageContainerList: {
  name: container
  parent: importStorageAccountBlob
}]

resource exportStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: exportStorageAccountName
  kind: 'StorageV2'
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    isHnsEnabled: true
    isNfsV3Enabled: false
    minimumTlsVersion: 'TLS1_2'
  }
  tags: resourceTags
}

resource exportStorageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: exportStorageAccount
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource exportStorageAccountContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [for container in exportStorageContainerList: {
  name: container
  parent: exportStorageAccountBlob
}]

resource functionsStorageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: functionsStorageAccountName
  kind: 'StorageV2'
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    isHnsEnabled: false
    isNfsV3Enabled: false
    minimumTlsVersion: 'TLS1_2'
  }
  tags: resourceTags
}

resource functionsStorageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: functionsStorageAccount
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource healthDataServicesWorkspace 'Microsoft.HealthcareApis/workspaces@2022-05-15' = {
  name: healthDataServicesName
  location: resourceLocation
  properties: {
    publicNetworkAccess: 'Enabled'
  }
  tags: resourceTags
}

resource fhirService 'Microsoft.HealthcareApis/workspaces/fhirservices@2022-05-15' = {
  name: fhirServiceConfig.name
  location: resourceLocation
  identity: {
    type: fhirServiceConfig.systemIdentity
  }
  kind: fhirServiceConfig.kind
  properties: {
    exportConfiguration: {
      storageAccountName: exportStorageAccountName
    }
    authenticationConfiguration: {
      audience: 'https://${healthDataServicesName}-${fhirServiceConfig.name}.fhir.azurehealthcareapis.com'
      authority: uri(environment().authentication.loginEndpoint, subscription().tenantId)
    }
  }
  tags: resourceTags
  parent: healthDataServicesWorkspace
  dependsOn: [
    exportStorageAccount
  ]
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: resourceLocation
  tags: resourceTags
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: resourceLocation
  sku: appServicePlanSKU
  kind: 'elastic'
  tags: resourceTags
}



resource fhirIngestionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: fhirIngestionAppConfig.name
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  kind:'functionapp'
  properties:{
    enabled: true
    httpsOnly: true
    clientAffinityEnabled: false
    serverFarmId: appServicePlan.id
    siteConfig:{
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      appSettings:[
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionsStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionsStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }        
      ]
    }
  }
  tags: resourceTags
}

resource fhirIngestionAppSource 'Microsoft.Web/sites/sourcecontrols@2021-03-01' = {
  name: 'web'
  parent: fhirIngestionApp
  properties: {
    repoUrl: fhirIngestionAppConfig.repoUrl
    branch: fhirIngestionAppConfig.repoBranch
    isManualIntegration: true
  }
}

