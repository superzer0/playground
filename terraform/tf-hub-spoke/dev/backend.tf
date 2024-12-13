terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-dev-sdc"
    container_name       = "tfstate-local-playground"
    key                  = "terraform.tfstate"
    storage_account_name = "tfstatepaaqfweu"
    use_azuread_auth     = true
  }
}
