output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
}

output "kv_identity_client_id" {
  value = azurerm_user_assigned_identity.kv_secrets.client_id
}
