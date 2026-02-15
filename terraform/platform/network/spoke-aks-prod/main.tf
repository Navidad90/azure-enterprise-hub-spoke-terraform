module "spoke_aks_network" {
  source = "../../../modules/network"

  vnet_name           = "vnet-spoke-aks-prod-gwc"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
  address_space       = ["10.1.0.0/16"]

  subnets = {
    aks_nodes = {
      name           = "subnet-aks-nodes"
      address_prefix = "10.1.0.0/22"
    }
  }
}
