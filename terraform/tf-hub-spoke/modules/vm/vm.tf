
resource "azurerm_public_ip" "pip_vm" {
  allocation_method   = "Static"
  location            = var.resource_location
  name                = "pip-${var.vm_name}"
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags = var.tags
}

resource "azurerm_network_interface" "nic_vm" {
  location            = var.resource_location
  name                = "nic-${var.vm_name}"
  resource_group_name = var.resource_group_name
  tags = var.tags
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_vm.id
    subnet_id                     = var.vnet_subnet_id
  }
  depends_on = [
    azurerm_public_ip.pip_vm,
  ]
}

resource "azurerm_linux_virtual_machine" "vm" {
  admin_username = "azureuser"
  tags = var.tags
  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_pub_key_path)
  }
  disable_password_authentication = true
  location                        = var.resource_location
  name                            = var.vm_name
  network_interface_ids           = [azurerm_network_interface.nic_vm.id]
  patch_mode                      = "AutomaticByPlatform"
  reboot_setting                  = "IfRequired"
  resource_group_name             = var.resource_group_name
  secure_boot_enabled             = true
  size                            = var.vm_size
  vtpm_enabled                    = true
  allow_extension_operations      = true
  additional_capabilities {
  }
  boot_diagnostics {
   storage_account_uri = null  # Passing a null value will utilize a Managed Storage Account to store Boot Diagnostics
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    offer     = "0001-com-ubuntu-server-jammy"
    publisher = "canonical"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.nic_vm,
  ]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm-schedule" {
  count                 = var.enable_turn_off_on_schedule ? 1 : 0
  tags = var.tags
  daily_recurrence_time = "1900"
  location              = var.resource_location
  timezone              = "UTC"
  virtual_machine_id    = azurerm_linux_virtual_machine.vm.id
  notification_settings {
    enabled = false
  }
  depends_on = [
    azurerm_linux_virtual_machine.vm,
  ]
}
