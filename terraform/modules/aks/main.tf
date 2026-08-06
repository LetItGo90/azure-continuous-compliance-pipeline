data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "devsecops-aks-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "dnsprefix1"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = var.subnet_id

    upgrade_settings {
      max_surge = "10%"
    }
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

# User-assigned managed identity for workload identity
resource "azurerm_user_assigned_identity" "kv_secrets" {
  name                = "aks-kv-secrets-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Grant it Key Vault Secrets User role
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.kv_secrets.principal_id
}

# Federated credential linking K8s ServiceAccount to this identity
resource "azurerm_federated_identity_credential" "kv_secrets" {
  name                      = "aks-kv-federated-cred"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  subject                   = "system:serviceaccount:default:sampleapp-sa"
  user_assigned_identity_id = azurerm_user_assigned_identity.kv_secrets.id
}
