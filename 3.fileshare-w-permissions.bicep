param existingStorageAccount string
param fileshareName string
@allowed([
  'Cool'
  'Hot'
  'TransactionOptimized'
  'Premium'
])
param storageTier string = 'Hot'
param quotaInGB int = 10
param permissionRoleGuid string
param groupsOid array

// Existing storage
resource stg 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: existingStorageAccount
}

// FILE SHARE RESOURCE
resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: toLower('${stg.name}/default/${fileshareName}')
  properties: {
    accessTier: storageTier
    enabledProtocols: 'SMB'
    shareQuota: quotaInGB
  }
}

// GET AZ ROLE DEFINITION
resource roleDef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: permissionRoleGuid
}

// SET PERMISSIONS
resource perms 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = [for group in groupsOid: {
  name: guid(subscription().id, resourceGroup().id, stg.name, fileshareName, group)
  //scope: replace(fileshare.id,'/shares/','/fileshares/')
  scope: fileshare
  properties: {
    roleDefinitionId: roleDef.id
    principalId: group
  }
}]

output shareRecId string = fileshare.id
