# --- Built in policies ---
data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

# --- Custom: deny any public IP resource outright ---
resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny creation of Public IP addresses"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Network/publicIPAddresses"
    }
    then = {
      effect = "deny"
    }
  })
}

# --- Custom: require HTTPS-only on storage accounts ---
resource "azurerm_policy_definition" "require_https_storage" {
  name         = "require-https-storage"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require HTTPS-only on Storage Accounts"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Storage/storageAccounts" },
        { field = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly", notEquals = "true" }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

# --- Bundle all four into one Initiative ---
resource "azurerm_policy_set_definition" "lab_governance_initiative" {
  name         = "lab-governance-initiative"
  policy_type  = "Custom"
  display_name = "DevSecOps Lab Governance Baseline"

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.require_tag.id
    reference_id         = "requireTag"
    parameter_values = jsonencode({
      tagName = { value = "environment" }
    })
  }

  policy_definition_reference {
    policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
    reference_id         = "allowedLocations"
    parameter_values = jsonencode({
      listOfAllowedLocations = { value = ["centralus"] }
    })
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_public_ip.id
    reference_id         = "denyPublicIp"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.require_https_storage.id
    reference_id         = "requireHttpsStorage"
  }
}

# --- Assign the Initiative to the Resource Group ---
resource "azurerm_resource_group_policy_assignment" "lab_governance_assignment" {
  name                 = "lab-governance-assignment"
  resource_group_id    = azurerm_resource_group.workload_rg.id
  policy_definition_id = azurerm_policy_set_definition.lab_governance_initiative.id
}
