terraform {
  required_version = ">=1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
   null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }
  }
  
}
provider "azurerm" {
  features {}
  subscription_id = "96626c9a-69ae-435e-a0a5-f33230012f8d"
}
provider "null" {
  # Configuration options
}
