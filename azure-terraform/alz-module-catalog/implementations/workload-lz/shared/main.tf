locals {
  enabled = try(var.configuration.enabled, false)
}

data "tfe_outputs" "management" {
  count        = local.enabled && var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}
data "tfe_outputs" "connectivity" {
  count        = local.enabled && var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

data "tfe_outputs" "governance" {
  count        = local.enabled && var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

resource "time_static" "deployment_created" {
  count = local.enabled ? 1 : 0
}

locals {
  management              = try(data.tfe_outputs.management[0].nonsensitive_values, {})
  connectivity            = try(data.tfe_outputs.connectivity[0].nonsensitive_values, {})
  governance              = try(data.tfe_outputs.governance[0].nonsensitive_values, {})
  private_dns_ids_by_name = { for key, id in try(local.connectivity.private_dns_zone_ids, {}) : lower(try(local.connectivity.private_dns_zone_names[key], split("/", id)[8])) => id }
  platform = {
    management_contract_version      = try(var.platform_inputs.management_contract_version, local.management.contract_version, "unset")
    connectivity_contract_version    = try(var.platform_inputs.connectivity_contract_version, local.connectivity.contract_version, "unset")
    log_analytics_workspace_id       = try(var.platform_inputs.log_analytics_workspace_id, local.management.log_analytics_workspace_id, "unset")
    hub_virtual_network_id           = try(var.platform_inputs.hub_virtual_network_id, local.connectivity.hub_virtual_network_id, "unset")
    hub_address_space                = try(var.platform_inputs.hub_address_space, local.connectivity.hub_virtual_network_address_space, [])
    key_vault_private_dns_zone_id    = coalesce(try(var.platform_inputs.key_vault_private_dns_zone_id, null), try(local.connectivity.key_vault_private_dns_zone_id, null), try(local.connectivity.private_dns_zone_ids.key_vault, null), lookup(local.private_dns_ids_by_name, "privatelink.vaultcore.azure.net", null), "unset")
    storage_blob_private_dns_zone_id = try(coalesce(try(var.platform_inputs.storage_blob_private_dns_zone_id, null), try(local.connectivity.storage_blob_private_dns_zone_id, null), try(local.connectivity.private_dns_zone_ids.storage_blob, null), lookup(local.private_dns_ids_by_name, "privatelink.blob.core.windows.net", null)), null)
    dns_server_ips                   = try(var.platform_inputs.dns_server_ips, local.connectivity.dns_server_ips, [])
    ddos_protection_plan_id          = try(var.platform_inputs.ddos_protection_plan_id, local.connectivity.ddos_protection_plan_id, null)
    mandatory_tag_keys               = try(var.platform_inputs.mandatory_tag_keys, local.governance.mandatory_tag_keys, [])
  }
}

resource "terraform_data" "deployment_contract" {
  count = local.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition = alltrue([for id in [var.subscription_id, var.tenant_id] :
        can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", id)) && id != "00000000-0000-0000-0000-000000000000"
      ])
      error_message = "Set real workload subscription_id and tenant_id in HCP before enabling deployment."
    }
    precondition {
      condition     = !var.use_tfe_outputs || (var.tfe_organization != null && length(local.management) > 0 && length(local.connectivity) > 0 && length(local.governance) > 0)
      error_message = "Public platform outputs are unreadable. Confirm exact HCP workspace names and scoped output-read access, or explicitly use approved platform_inputs with use_tfe_outputs=false."
    }
    precondition {
      condition     = length(local.platform.mandatory_tag_keys) > 0
      error_message = "The governance contract must publish non-empty mandatory_tag_keys, or provide their explicitly approved equivalent in platform_inputs."
    }
  }
}

module "blueprint" {
  source = "../../../patterns/terraform-azurerm-compeer-spoke-landing-zone"
  count  = local.enabled ? 1 : 0
  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
    azurerm.dns          = azurerm.dns
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  environment     = var.environment
  location        = try(var.configuration.location, "centralus")
  appcode         = try(var.configuration.appcode, "replace")
  domain          = try(var.configuration.domain, "internal-apps")
  workload_tags = merge(try(var.configuration.workload_tags, {}), {
    created_on = try(formatdate("YYYY-MM-DD", time_static.deployment_created[0].rfc3339), "2000-01-01")
  })
  platform                      = local.platform
  address_space                 = try(var.configuration.address_space, [])
  reserved_address_spaces       = try(var.configuration.reserved_address_spaces, [])
  inspection_address_prefixes   = try(var.configuration.inspection_address_prefixes, [])
  subnets                       = try(var.configuration.subnets, {})
  egress_next_hop_ip            = try(var.configuration.egress_next_hop_ip, "unset")
  allow_azure_provided_dns      = try(var.configuration.allow_azure_provided_dns, false)
  manage_hub_attachment         = try(var.configuration.manage_hub_attachment, true)
  gateway_transit_enabled       = try(var.configuration.gateway_transit_enabled, false)
  private_endpoint_client_cidrs = try(var.configuration.private_endpoint_client_cidrs, [])
  key_vault                     = try(var.configuration.key_vault, {})
  workload_access_group_ids     = try(var.configuration.workload_access_group_ids, {})
  operations = {
    notification_emails = try(var.configuration.operations.notification_emails, [])
    action_group_ids    = try(var.configuration.operations.action_group_ids, [])
    budget = {
      enabled    = try(var.configuration.operations.budget.enabled, false)
      amount     = try(var.configuration.operations.budget.amount, 0)
      start_date = try(coalesce(try(var.configuration.operations.budget.start_date, null), formatdate("YYYY-MM-01'T'00:00:00'Z'", time_static.deployment_created[0].rfc3339)), "2000-01-01T00:00:00Z")
    }
  }
  monitoring       = try(var.configuration.monitoring, {})
  storage_accounts = try(var.configuration.storage_accounts, {})
  backup           = try(var.configuration.backup, null)
  depends_on       = [terraform_data.deployment_contract]
}
