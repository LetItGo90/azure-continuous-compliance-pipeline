terraform {
  backend "azurerm" {
    resource_group_name  = "rg-bootstrap-azdevops"
    storage_account_name = "stbootstateunique99"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}


