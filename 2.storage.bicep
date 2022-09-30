param storageAccountName string
param location string = 'swedencentral'

// Create storage account
resource stg 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties:{
    azureFilesIdentityBasedAuthentication:{
      directoryServiceOptions: 'AADDS'
    }
  }
}

output stgRecId string = stg.id
