param SubNetResourceId string

// Get settings from general setttings file
var genSettings = json(loadTextContent('../_general.json'))

resource aadds 'Microsoft.AAD/domainServices@2021-05-01' = {
  name: toLower(genSettings.AADDSDomainName)
  location: genSettings.region
  properties: {
    domainConfigurationType: 'FullySynced'
    domainName: genSettings.AADDSDomainName
    domainSecuritySettings: {
      kerberosArmoring: 'Enabled'
      kerberosRc4Encryption: 'Disabled'
      ntlmV1: 'Disabled'
      syncKerberosPasswords: 'Enabled'
      syncNtlmPasswords: 'Disabled'
      syncOnPremPasswords: 'Disabled'
      tlsV1: 'Disabled'
    }
    filteredSync: 'Disabled'
    notificationSettings: {
      additionalRecipients: genSettings.Notifications
      notifyDcAdmins: 'Disabled'
      notifyGlobalAdmins: 'Disabled'
    }
    replicaSets: [
      {
        location: genSettings.region
        subnetId: SubNetResourceId
      }
    ]
    sku: 'standard'
  }
}
