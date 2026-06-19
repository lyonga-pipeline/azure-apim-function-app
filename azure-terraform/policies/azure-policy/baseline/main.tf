locals {
  effect_parameter = jsonencode({
    effect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
      metadata = {
        displayName = "Effect"
        description = "Policy effect for this control."
      }
    }
  })

  required_tag_parameters = jsonencode({
    tagName = {
      type = "String"
      metadata = {
        displayName = "Tag name"
        description = "Name of the required tag."
      }
    }
    effect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = "Audit"
      metadata = {
        displayName = "Effect"
        description = "Policy effect for this control."
      }
    }
  })
}

resource "azurerm_policy_definition" "allowed_locations" {
  name                = "${var.organization_prefix}-allowed-locations"
  management_group_id = var.definition_management_group_id
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Allow approved Azure regions"
  description         = "Audits or denies deployments outside approved Azure regions."
  parameters          = local.effect_parameter

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "location"
          notIn = var.allowed_locations
        },
        {
          field     = "location"
          notEquals = "global"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_definition" "required_tag" {
  name                = "${var.organization_prefix}-required-tag"
  management_group_id = var.definition_management_group_id
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require enterprise tag"
  description         = "Audits or denies resources missing a required enterprise tag."
  parameters          = local.required_tag_parameters

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field     = "type"
          notEquals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          field  = "[concat('tags[', parameters('tagName'), ']')]"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_definition" "deny_public_ip" {
  name                = "${var.organization_prefix}-deny-public-ip"
  management_group_id = var.definition_management_group_id
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Restrict public IP creation"
  description         = "Audits or denies public IP address resources."
  parameters          = local.effect_parameter

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Network/publicIPAddresses"
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_definition" "storage_public_network" {
  name                = "${var.organization_prefix}-storage-private-network"
  management_group_id = var.definition_management_group_id
  policy_type         = "Custom"
  mode                = "Indexed"
  display_name        = "Require private storage network posture"
  description         = "Audits or denies storage accounts that allow public network access."
  parameters          = local.effect_parameter

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Storage/storageAccounts"
        },
        {
          field     = "Microsoft.Storage/storageAccounts/publicNetworkAccess"
          notEquals = "Disabled"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_definition" "key_vault_public_network" {
  name                = "${var.organization_prefix}-keyvault-private-network"
  management_group_id = var.definition_management_group_id
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Require private Key Vault network posture"
  description         = "Audits or denies Key Vaults that allow public network access."
  parameters          = local.effect_parameter

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.KeyVault/vaults"
        },
        {
          field     = "Microsoft.KeyVault/vaults/publicNetworkAccess"
          notEquals = "Disabled"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_definition" "sql_public_network" {
  name                = "${var.organization_prefix}-sql-private-network"
  management_group_id = var.definition_management_group_id
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Require private SQL network posture"
  description         = "Audits or denies Azure SQL servers that allow public network access."
  parameters          = local.effect_parameter

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Sql/servers"
        },
        {
          field     = "Microsoft.Sql/servers/publicNetworkAccess"
          notEquals = "Disabled"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_definition" "app_service_public_network" {
  name                = "${var.organization_prefix}-appservice-private-network"
  management_group_id = var.definition_management_group_id
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "Require private App Service network posture"
  description         = "Audits or denies App Service and Function App resources that allow public network access."
  parameters          = local.effect_parameter

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Web/sites"
        },
        {
          field     = "Microsoft.Web/sites/publicNetworkAccess"
          notEquals = "Disabled"
        }
      ]
    }
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_policy_set_definition" "landing_zone_baseline" {
  name                = "${var.organization_prefix}-landing-zone-baseline"
  display_name        = "Compeer Landing Zone Baseline"
  policy_type         = "Custom"
  management_group_id = var.definition_management_group_id

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.allowed_locations.id
    reference_id         = "allowedLocations"
    parameter_values = jsonencode({
      effect = {
        value = var.policy_effects.allowed_locations
      }
    })
  }

  dynamic "policy_definition_reference" {
    for_each = toset(var.required_tags)

    content {
      policy_definition_id = azurerm_policy_definition.required_tag.id
      reference_id         = "requiredTag-${replace(policy_definition_reference.value, "_", "-")}"
      parameter_values = jsonencode({
        tagName = {
          value = policy_definition_reference.value
        }
        effect = {
          value = var.policy_effects.required_tag
        }
      })
    }
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_public_ip.id
    reference_id         = "denyPublicIp"
    parameter_values = jsonencode({
      effect = {
        value = var.policy_effects.deny_public_ip
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.storage_public_network.id
    reference_id         = "storagePublicNetwork"
    parameter_values = jsonencode({
      effect = {
        value = var.policy_effects.storage_public_network
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.key_vault_public_network.id
    reference_id         = "keyVaultPublicNetwork"
    parameter_values = jsonencode({
      effect = {
        value = var.policy_effects.key_vault_public_network
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.sql_public_network.id
    reference_id         = "sqlPublicNetwork"
    parameter_values = jsonencode({
      effect = {
        value = var.policy_effects.sql_public_network
      }
    })
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.app_service_public_network.id
    reference_id         = "appServicePublicNetwork"
    parameter_values = jsonencode({
      effect = {
        value = var.policy_effects.app_service_public_network
      }
    })
  }
}

resource "azurerm_management_group_policy_assignment" "landing_zone_baseline" {
  for_each = var.assignment_management_group_ids

  name                 = substr("${var.organization_prefix}-${each.key}-lz-baseline", 0, 24)
  display_name         = "Compeer ${each.key} Landing Zone Baseline"
  management_group_id  = each.value
  policy_definition_id = azurerm_policy_set_definition.landing_zone_baseline.id
  location             = var.assignment_location

  identity {
    type = "SystemAssigned"
  }
}

