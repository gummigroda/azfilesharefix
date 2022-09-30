// Get settings from general setttings file
var genSettings = json(loadTextContent('../_general.json'))

resource aadds 'Microsoft.AAD/domainServices@2021-05-01' existing = {
  name: toLower(genSettings.AADDSDomainName)
}

module vNet 'vnet.bicep' = {
  name: 'Update-DNS-on-vnet'
  params: {
    // asuming one replica set only 
    dnsServers: first(aadds.properties.replicaSets).domainControllerIpAddress
  }
}

// asuming one replica set only
output ad array = first(aadds.properties.replicaSets).domainControllerIpAddress
