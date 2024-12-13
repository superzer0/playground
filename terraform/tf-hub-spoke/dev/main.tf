module "naming_hub" {
  source  = "Azure/naming/azurerm"
  suffix  = ["hub-${var.environment}-${var.resource_location_code}"]
  version = "~>0.4"
}

module "naming_spoke" {
  source  = "Azure/naming/azurerm"
  suffix  = ["spoke-${var.environment}-${var.resource_location_code}"]
  version = "~>0.4"
}

resource "azurerm_resource_group" "rg_hub_spoke" {
  name     = module.naming_hub.resource_group.name
  location = var.resource_location
}

variable "pip_instance_set" {
  type    = set(string)
  default = ["dd", "dd", "ll"]
}

variable "pip_instance_list" {
  type = list(any)
  default = [{
    name = "l-1"
    tags = { "dd" = "d1", "ee" = "e1" }
    }, {
    name = "l-2"
    tags = { "dd" = "d2", "ee" = "e2" }
    }, {
    name = "l-3"
    tags = { "dd" = "d3", "ee" = "e3" }
  }]
}

variable "pip_instance_object_list" {
  type = list(object(
    {
      name = string
      tags = map(string)
    }
  ))
  default = [
    {
      name = "dd-1"
      tags = { "dd" = "dd", "ee" = "ee" }
    }
  ]
}

locals {
  pip_instance_object_map = { for pip in var.pip_instance_object_list : pip.name => pip.name if length(pip.tags) > 0 }
  pip_instance_from_splat_set = toset(var.pip_instance_object_list[*].name)
}

# resource "azurerm_public_ip" "pip_from_list" {
#   for_each            = local.pip_instance_from_splat_set
#   allocation_method   = "Static"
#   location            = var.resource_location
#   name                = "pip-${each.value}"
#   resource_group_name = azurerm_resource_group.rg_hub_spoke.name
#   sku                 = "Standard"
#   tags                = var.resource_tags
# }

# resource "azurerm_public_ip" "pip_from_map" {
#   for_each            = local.pip_instance_object_map
#   allocation_method   = "Static"
#   location            = var.resource_location
#   name                = "pip-${each.value}"
#   resource_group_name = azurerm_resource_group.rg_hub_spoke.name
#   sku                 = "Standard"
#   tags = merge(var.resource_tags, {
#     key   = each.key
#     value = each.value
#   })
# }

# output "pip_names_1" {
#   value = [for o in azurerm_public_ip.pip_from_list : o.id]
# }

# output "pip_names_2" {
#   value = [for o in azurerm_public_ip.pip_from_map : o.id]
# }

# module "mod_hub_spoke_vnet" {
#   source                 = "../modules/hub-spoke-network"
#   resource_group_name    = azurerm_resource_group.rg_hub_spoke.name
#   resource_location_code = var.resource_location_code
#   resource_location      = var.resource_location
#   tags                   = var.resource_tags
#   vnet_hub_name          = module.naming_hub.virtual_network.name
#   vnet_spoke_name        = module.naming_spoke.virtual_network.name
# }

# module "mod_vm_hub" {
#   source                 = "../modules/vm"
#   resource_location_code = var.resource_location_code
#   resource_location      = var.resource_location
#   tags                   = var.resource_tags
#   resource_group_name    = azurerm_resource_group.rg_hub_spoke.name

#   vnet_subnet_id              = module.mod_hub_spoke_vnet.vnet_hub_workloads_subnet_id
#   vm_name                     = module.naming_hub.virtual_machine.name
#   enable_turn_off_on_schedule = true
#   ssh_pub_key_path            = var.ssh_pub_key_path
# }

# module "mod_spoke_hub" {
#   count                  = 1
#   source                 = "../modules/vm"
#   resource_location_code = var.resource_location_code
#   resource_location      = var.resource_location
#   tags                   = var.resource_tags
#   resource_group_name    = azurerm_resource_group.rg_hub_spoke.name

#   vnet_subnet_id              = module.mod_hub_spoke_vnet.vnet_spoke_workloads_subnet_id
#   vm_name                     = module.naming_spoke.virtual_machine.name
#   enable_turn_off_on_schedule = true
#   ssh_pub_key_path            = var.ssh_pub_key_path

# }

