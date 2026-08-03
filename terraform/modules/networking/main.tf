resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-security-group"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "lab"
  }
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-network"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "lab"
  }
}

resource "azurerm_subnet" "aks_subnet1" {
  name                 = "aks-subnet1"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "aks_subnet2" {
  name                 = "aks-subnet2"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "aks_subnet2_nsg" {
  subnet_id                 = azurerm_subnet.aks_subnet2.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}
