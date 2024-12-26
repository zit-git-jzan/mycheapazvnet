terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
  subscription_id = "f4021a7e-ec23-409d-8a54-36432dfa5afe"

  # Configuration options

}