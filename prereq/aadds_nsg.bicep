// Get settings from general setttings file
var genSettings = json(loadTextContent('../_general.json'))

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: toLower('${genSettings.companyAbbreviation}-aadds-nsg')
  location: genSettings.region
  properties: {
    securityRules: [
      {
        name: 'AllowSyncWithAzureAD'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureActiveDirectoryDomainServices'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowRDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'CorpNetSaw'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowPSRemoting'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5986'
          sourceAddressPrefix: 'AzureActiveDirectoryDomainServices'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 301
          direction: 'Inbound'
        }
      }
    ]
  }
}

output nsgRecID string = nsg.id
