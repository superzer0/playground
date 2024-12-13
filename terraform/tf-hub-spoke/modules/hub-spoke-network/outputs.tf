output "vnet_hub_id" {
  value = azurerm_virtual_network.vnet_hub.name
}

output "vnet_spoke_id" {
  value = azurerm_virtual_network.vnet_spoke.name
}

output "vnet_hub_workloads_subnet_id" {
  value = azurerm_subnet.vnet_hub_subnet_workloads.id
}

output "vnet_spoke_workloads_subnet_id" {
  value = azurerm_subnet.vnet_spoke_subnet_workloads.id
}
