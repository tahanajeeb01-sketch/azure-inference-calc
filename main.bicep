metadata description = 'Azure Inference Calculator Infrastructure'
param location string = 'eastus2'
param appName string = 'inference-calc'

resource staticSite 'Microsoft.Web/staticSites@2022-09-01' = {
  name: appName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    buildProperties: {
      appLocation: '/'
      outputLocation: '/'
    }
  }
}

output staticSiteUrl string = staticSite.properties.defaultHostname