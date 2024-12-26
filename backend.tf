terraform {
  backend "azurerm" {
    resource_group_name  = "cloud-shell-storage-westeurope"
    storage_account_name = "csb1003200045814e8e"
    container_name       = "mycheapvnet"
    key                  = "terraform.tfstate"

  }
}