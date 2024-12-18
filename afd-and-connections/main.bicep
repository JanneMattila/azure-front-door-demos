param location string = resourceGroup().location
param username string
@secure()
param password string

param frontDoorName string

var frontendEndpoint1hostName = '${frontDoorName}.azurefd.net'
var healthProbe1Name = '${frontDoorName}-healthProbe1'
var frontendEndpoint1Name = '${frontDoorName}-frontendEndpoint1'
var backendPool1Name = '${frontDoorName}-backendPool1'
var loadBalancing1Name = '${frontDoorName}-loadBalancing1'
var routingRule1Name = '${frontDoorName}-routingRule1'

module network './network.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: location
    username: username
    password: password
  }
}

resource frontDoor 'Microsoft.Network/frontDoors@2021-06-01' = {
  name: frontDoorName
  location: 'global'
  properties: {
    friendlyName: frontDoorName
    enabledState: 'Enabled'

    frontendEndpoints: [
      {
        name: frontendEndpoint1Name
        properties: {
          hostName: frontendEndpoint1hostName
          sessionAffinityEnabledState: 'Disabled'
          webApplicationFirewallPolicyLink: {
            id: firewallPolicy.id
          }
        }
      }
    ]
    backendPoolsSettings: {
      enforceCertificateNameCheck: 'Enabled'
      sendRecvTimeoutSeconds: 30
    }
    backendPools: [
      {
        name: backendPool1Name
        properties: {
          backends: [
            {
              address: network.outputs.vm1PublicIP
              backendHostHeader: frontendEndpoint1hostName
              enabledState: 'Enabled'
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 50
            }
            {
              address: network.outputs.vm2PublicIP
              backendHostHeader: frontendEndpoint1hostName
              enabledState: 'Enabled'
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 50
            }
          ]
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, healthProbe1Name)
          }
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/LoadBalancingSettings', frontDoorName, loadBalancing1Name)
          }
        }
      }
    ]
    healthProbeSettings: [
      {
        name: healthProbe1Name
        properties: {
          healthProbeMethod: 'HEAD'
          intervalInSeconds: 5
          path: '/Probe.aspx'
          protocol: 'Http'
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: loadBalancing1Name
        properties: {
          additionalLatencyMilliseconds: 0
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    routingRules: [
      {
        name: routingRule1Name
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/FrontendEndpoints', frontDoorName, frontendEndpoint1Name)
            }
          ]
          acceptedProtocols: [
            'Http'
            'Https'
          ]
          patternsToMatch: [
            '/*'
          ]
          enabledState: 'Enabled'
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'HttpOnly'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/BackendPools', frontDoorName, backendPool1Name)
            }
            cacheConfiguration: {
              cacheDuration: 'PT5M' // 5 minutes
              dynamicCompression: 'Enabled'
              queryParameterStripDirective: 'StripNone'
            }
          }
        }
      }
    ]
  }
}

resource firewallPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2024-02-01' = {
  name: 'wafpolicy'
  location: 'global'
  properties: {
    policySettings: {
      requestBodyCheck: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '1.1'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

module monitoring './monitoring.bicep' = {
  name: 'monitoring'
  params: {
    parentName: frontDoor.name
    location: location
  }
}

output frontdoorId string = frontDoor.properties.frontdoorId

output vm1PublicIP string = network.outputs.vm1PublicIP
output vm1PrivateIP string = network.outputs.vm1PrivateIP

output vm2PublicIP string = network.outputs.vm2PublicIP
output vm2PrivateIP string = network.outputs.vm2PrivateIP
