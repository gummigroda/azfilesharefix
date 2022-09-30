param dnsServers array = []

// Get settings from general setttings file
var genSettings = json(loadTextContent('../_general.json'))

resource vNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: toLower('${genSettings.companyAbbreviation}-${genSettings.virtualNetwork.vNetName}-vnet')
  location: genSettings.region
  properties: {
    addressSpace: {
      addressPrefixes: genSettings.virtualNetwork.vNetAddressPrefixes
    }
    dhcpOptions: {
       dnsServers: dnsServers
    }
    //@batchSize(1)
    subnets: [for subnet in genSettings.virtualNetwork.subnets: {
      name: contains(['GatewaySubnet', 'AzureBastionSubnet'],subnet.sNetName) ? subnet.sNetName: toLower('${subnet.sNetName}-snet')
      properties: {
        addressPrefix: subnet.subnet
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        networkSecurityGroup: empty(subnet.nsg) ? null : {
          id: subnet.nsg
        }
        routeTable: empty(subnet.routeTable) ? null : {
          id: subnet.routeTable
        }
        delegations: subnet.delegations
        serviceEndpoints: subnet.serviceEndpoints
      }
    }]
  }
}
