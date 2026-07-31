resource "azurerm_resource_group" "main_rg" {
  name     = "rg-bootstrap-azdevops"
  location = "Central US"
}

resource "azurerm_storage_account" "tfstate_storage_account" {
  name                     = "stbootstateunique99"
  resource_group_name      = azurerm_resource_group.main_rg.name
  location                 = azurerm_resource_group.main_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"


  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days                     = 7
      permanent_delete_enabled = false
    }
  }

}

resource "azurerm_storage_container" "state_file_container" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate_storage_account.id
  container_access_type = "private"
}
