variable "resource_location" {
  description = "Specifies the resource location"
  type        = string
  nullable    = false
}

variable "resource_location_code" {
  description = "Specifies the resource location code"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.resource_location_code) > 0 && length(var.resource_location_code) < 5
    error_message = "Value cannot have than 1-5 characters"
  }
}

variable "resource_group_name" {
  description = "Specifies the name of the resource group"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Value cannot be empty"
  }
}

variable "vnet_hub_name" {
  description = "Specifies the name of the hub virtual network"
  type        = string
  nullable    = false
}

variable "vnet_spoke_name" {
  description = "Specifies the name of the spoke virtual network"
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Azure Tags"
  type        = map(string)
  nullable    = true
}

