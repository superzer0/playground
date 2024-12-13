resource "azurerm_network_security_group" "nsg_default" {
  location            = var.resource_location
  name                = "nsg-default"
  resource_group_name = var.resource_group_name
}
resource "azurerm_network_security_rule" "nsg_ssh_rule" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "SSH"
  network_security_group_name = azurerm_network_security_group.nsg_default.name
  priority                    = 300
  protocol                    = "Tcp"
  resource_group_name         = azurerm_network_security_group.nsg_default.resource_group_name
  source_address_prefix       = "*"
  source_port_range           = "*"
  depends_on = [
    azurerm_network_security_group.nsg_default,
  ]
}
