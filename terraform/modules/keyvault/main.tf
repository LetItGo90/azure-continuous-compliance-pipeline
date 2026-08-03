data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "keyvault" {
  name                        = "acrdevsecopslabkeyvault"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  rbac_authorization_enabled  = true
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"

  tags = {
    environment = "lab"
  }
}
