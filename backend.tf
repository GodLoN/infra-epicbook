terraform {
  backend "azurerm" {
    resource_group_name  = "rg-epicbook-tfstate"
    storage_account_name = "stepicbooktfstate01"
    container_name       = "tfstate"
    key                  = "infra-epicbook.tfstate"
  }
}
