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
param groupsOid string

//  storage account
resource stg 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: existingStorageAccount
}

// FILE SHARE RESOURCE
resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: '${stg.name}/default/${fileshareName}'
  properties: {
    accessTier: storageTier
    enabledProtocols: 'SMB'
    shareQuota: quotaInGB
  }
}

// Use a separate deployment via ARM to set the correct permissions
resource ResourceRoleAssignmentUsers 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'user-permissions'
  properties: {
    mode: 'Incremental'
    expressionEvaluationOptions: {
      scope: 'Outer'
    }
    template: json(loadTextContent('./genericRoleAssignment.json'))
    parameters: {
      scope: {
        value: replace(fileshare.id, '/shares/','/fileshares/')
      }
      name: {
        value: guid('${subscription().id},${resourceGroup().id},${stg.name},${fileshare.name},-users')
      }
      roleDefinitionId: {
        value: permissionRoleGuid
      }
      principalId: {
        value: groupsOid
      }
      principalType: {
        value: 'Group'
      }
    }
  }
}
