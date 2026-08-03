resource "azurerm_resource_group" "workload_rg" {
  name     = var.resource_group_name
  location = var.location
}


module "networking" {
  source              = "../../modules/networking"
  location            = var.location
  resource_group_name = azurerm_resource_group.workload_rg.name
}

module "acr" {
  source              = "../../modules/acr"
  location            = var.location
  resource_group_name = azurerm_resource_group.workload_rg.name
}

module "aks" {
  source              = "../../modules/aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.workload_rg.name
  subnet_id           = module.networking.subnet_id
  acr_id              = module.acr.acr_id
}

module "keyvault" {
  source              = "../../modules/keyvault"
  location            = var.location
  resource_group_name = azurerm_resource_group.workload_rg.name
}