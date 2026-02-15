module "hub_network" {
  source = "../../../modules/network"

  vnet_name           = "vnet-hub-prod-gwc"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    shared = {
      name           = "subnet-shared-services"
      address_prefix = "10.0.0.0/24"
    }

    firewall = {
      name           = "AzureFirewallSubnet"
      address_prefix = "10.0.1.0/26"
    }
  }
}
