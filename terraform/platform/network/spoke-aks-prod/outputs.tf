output "vnet_id" {
  value = module.spoke_aks_network.vnet_id
}

output "subnet_ids" {
  value = module.spoke_aks_network.subnet_ids
}
