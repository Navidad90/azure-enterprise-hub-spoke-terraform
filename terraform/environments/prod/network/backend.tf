terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-enterprise-networking"
    storage_account_name = "sttfstateentnetprod"
    container_name       = "tfstate"
    key                  = "prod.network.tfstate"
  }
}
