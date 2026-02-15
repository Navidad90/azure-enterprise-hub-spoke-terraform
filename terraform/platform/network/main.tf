module "hub" {
  source = "./hub"
}

module "spoke_aks_prod" {
  source = "./spoke-aks-prod"
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke-aks-prod"
  resource_group_name       = "rg-network-prod"
  virtual_network_name      = "vnet-hub-prod-gwc"
  remote_virtual_network_id = module.spoke_aks_prod.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-aks-prod-to-hub"
  resource_group_name       = "rg-network-prod"
  virtual_network_name      = "vnet-spoke-aks-prod-gwc"
  remote_virtual_network_id = module.hub.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# -------------------------
# HUB NSG
# -------------------------

resource "azurerm_network_security_group" "hub_nsg" {
  name                = "nsg-hub-prod-gwc"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
}

resource "azurerm_network_security_rule" "hub_allow_spoke" {
  name                        = "allow-spoke-to-hub"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.1.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = "rg-network-prod"
  network_security_group_name = azurerm_network_security_group.hub_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "hub_nsg_assoc" {
  subnet_id                 = module.hub.subnet_ids["shared"]
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
}

# -------------------------
# SPOKE NSG
# -------------------------

resource "azurerm_network_security_group" "spoke_nsg" {
  name                = "nsg-spoke-aks-prod-gwc"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
}

resource "azurerm_network_security_rule" "spoke_allow_hub" {
  name                        = "allow-hub-to-spoke"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = "rg-network-prod"
  network_security_group_name = azurerm_network_security_group.spoke_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "spoke_nsg_assoc" {
  subnet_id                 = module.spoke_aks_prod.subnet_ids["aks_nodes"]
  network_security_group_id = azurerm_network_security_group.spoke_nsg.id
}

# -------------------------
# ROUTE TABLE FOR SPOKE EGRESS
# -------------------------

resource "azurerm_route_table" "spoke_rt" {
  name                = "rt-spoke-egress-prod-gwc"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
}

resource "azurerm_route" "spoke_default_route" {
  name                   = "default-to-hub-firewall"
  resource_group_name    = "rg-network-prod"
  route_table_name       = azurerm_route_table.spoke_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.1.4"
}

resource "azurerm_subnet_route_table_association" "spoke_rt_assoc" {
  subnet_id      = module.spoke_aks_prod.subnet_ids["aks_nodes"]
  route_table_id = azurerm_route_table.spoke_rt.id
}
# -------------------------
# LOG ANALYTICS WORKSPACE
# -------------------------

resource "azurerm_log_analytics_workspace" "network_law" {
  name                = "law-network-prod-gwc"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# -------------------------
# VNET DIAGNOSTICS
# -------------------------

resource "azurerm_monitor_diagnostic_setting" "hub_vnet_diag" {
  name                       = "diag-hub-vnet"
  target_resource_id         = module.hub.vnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.network_law.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "spoke_vnet_diag" {
  name                       = "diag-spoke-vnet"
  target_resource_id         = module.spoke_aks_prod.vnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.network_law.id

  metric {
    category = "AllMetrics"
  }
}

# -------------------------
# PRIVATE DNS ZONE
# -------------------------

resource "azurerm_private_dns_zone" "sql_private_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = "rg-network-prod"
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_dns_link" {
  name                  = "hub-dns-link"
  resource_group_name   = "rg-network-prod"
  private_dns_zone_name = azurerm_private_dns_zone.sql_private_dns.name
  virtual_network_id    = module.hub.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_dns_link" {
  name                  = "spoke-dns-link"
  resource_group_name   = "rg-network-prod"
  private_dns_zone_name = azurerm_private_dns_zone.sql_private_dns.name
  virtual_network_id    = module.spoke_aks_prod.vnet_id
}

# -------------------------
# STORAGE ACCOUNT FOR FLOW LOGS
# -------------------------

resource "azurerm_storage_account" "flowlogs_sa" {
  name                     = "stflowlogsprodgwc"
  resource_group_name      = "rg-network-prod"
  location                 = "germanywestcentral"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# -------------------------
# NETWORK WATCHER (REQUIRED)
# -------------------------

resource "azurerm_network_watcher" "network_watcher" {
  name                = "NetworkWatcher_germanywestcentral"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
}

# -------------------------
# NSG FLOW LOGS
# -------------------------

resource "azurerm_network_watcher_flow_log" "hub_flowlog" {
  network_watcher_name = azurerm_network_watcher.network_watcher.name
  resource_group_name  = "rg-network-prod"
  name                 = "hub-nsg-flowlog"

  network_security_group_id = azurerm_network_security_group.hub_nsg.id
  storage_account_id        = azurerm_storage_account.flowlogs_sa.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 30
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.network_law.workspace_id
    workspace_region      = "germanywestcentral"
    workspace_resource_id = azurerm_log_analytics_workspace.network_law.id
  }
}

resource "azurerm_network_watcher_flow_log" "spoke_flowlog" {
  network_watcher_name = azurerm_network_watcher.network_watcher.name
  resource_group_name  = "rg-network-prod"
  name                 = "spoke-nsg-flowlog"

  network_security_group_id = azurerm_network_security_group.spoke_nsg.id
  storage_account_id        = azurerm_storage_account.flowlogs_sa.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 30
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.network_law.workspace_id
    workspace_region      = "germanywestcentral"
    workspace_resource_id = azurerm_log_analytics_workspace.network_law.id
  }
}

# -------------------------
# DDoS PROTECTION PLAN
# -------------------------

resource "azurerm_network_ddos_protection_plan" "ddos_plan" {
  name                = "ddos-plan-prod-gwc"
  location            = "germanywestcentral"
  resource_group_name = "rg-network-prod"
}
