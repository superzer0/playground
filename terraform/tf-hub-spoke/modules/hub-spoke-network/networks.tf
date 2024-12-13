
resource "azurerm_virtual_network" "vnet_hub" {
  name                = var.vnet_hub_name
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  tags                = var.tags

}

resource "azurerm_subnet" "vnet_hub_subnet_workloads" {
  name                 = "workloads"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on           = [azurerm_virtual_network.vnet_hub]

}

resource "azurerm_virtual_network" "vnet_spoke" {
  name                = var.vnet_spoke_name
  address_space       = ["10.1.0.0/16"]
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "vnet_spoke_subnet_workloads" {
  name                 = "workloads"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_spoke.name
  address_prefixes     = ["10.1.0.0/24"]
  depends_on           = [azurerm_virtual_network.vnet_spoke]
}

resource "azurerm_subnet_network_security_group_association" "hub_to_default_nsg" {
  subnet_id                 = azurerm_subnet.vnet_hub_subnet_workloads.id
  network_security_group_id = azurerm_network_security_group.nsg_default.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_to_default_nsg" {
  subnet_id                 = azurerm_subnet.vnet_spoke_subnet_workloads.id
  network_security_group_id = azurerm_network_security_group.nsg_default.id
}

resource "azurerm_virtual_network_peering" "peer_hub_to_spoke" {
  name                         = "${var.vnet_hub_name}_to_${var.vnet_spoke_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.vnet_hub_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_spoke.id
  allow_virtual_network_access = true
  allow_gateway_transit        = true
  allow_forwarded_traffic      = false
}

resource "azurerm_virtual_network_peering" "peer_spoke_to_hub" {
  name                         = "${var.vnet_spoke_name}_to_${var.vnet_hub_name}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = var.vnet_spoke_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_hub.id
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  allow_forwarded_traffic      = true
}
