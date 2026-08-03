data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "devsecops-aks-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "dnsprefix1"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  azure_policy_enabled = true
  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
  }
  node_provisioning_profile {
    mode = "Manual"
  }

  tags = {
    Environment = "lab"
  }
}

resource "azurerm_role_assignment" "aks_role" {
  principal_id                     = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
