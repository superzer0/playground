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

variable "vm_name" {
  description = "Specifies the name of the resource"
  type = string
  nullable = false
}

variable "vnet_subnet_id" {
  description = "Specifies subnet where the VM should be deployed to"
  type = string
  nullable = false
}

variable "enable_turn_off_on_schedule" {
  description = "Turn off VMs daily"
  type = bool
  nullable = false
}

variable "vm_size" {
  description = "VM size"
  type = string
  nullable = false
  default = "Standard_B2s"
}

variable "tags" {
  description = "Azure Tags"
  type = map(string)
  nullable = true
}

variable "ssh_pub_key_path" {
  description = "SSH Public Key file path on local disk"
  type = string
  nullable = false
}
