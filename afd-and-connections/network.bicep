param username string
@secure()
param password string
param location string

resource networkSecurityGroupVM 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-vm'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          description: 'Allow  HTTP traffic'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
          priority: 110
          description: 'Allow HTTPS traffic'
        }
      }
      {
        name: 'Allow-HTTPS-8000'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '8000'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
          priority: 120
          description: 'Allow HTTPS over port 8000 traffic'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: 'vnet-afd'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: [
      {
        name: 'snet-vm'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroupVM.id
          }
        }
      }
    ]
  }
}

module vm1 'vm.bicep' = {
  name: 'vm1-deployment'
  params: {
    name: 'vm1'
    location: location
    username: username
    password: password
    subnetId: virtualNetwork.properties.subnets[0].id
  }
}

module vm2 'vm.bicep' = {
  name: 'vm2-deployment'
  params: {
    name: 'vm2'
    location: location
    username: username
    password: password
    subnetId: virtualNetwork.properties.subnets[0].id
  }
}

output subnets object[] = virtualNetwork.properties.subnets

output vm1PublicIP string = vm1.outputs.vmPublicIP
output vm1PrivateIP string = vm1.outputs.vmPrivateIP

output vm2PublicIP string = vm2.outputs.vmPublicIP
output vm2PrivateIP string = vm2.outputs.vmPrivateIP
