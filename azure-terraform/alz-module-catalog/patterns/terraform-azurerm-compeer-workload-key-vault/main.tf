data "azurerm_client_config" "current" {}

resource "terraform_data" "tag_contract" {
  lifecycle {
    precondition {
      condition     = lower(var.tenant_id) == lower(data.azurerm_client_config.current.tenant_id)
      error_message = "The vault tenant must match the authenticated provider tenant."
    }
    precondition {
      condition     = (var.network_access.mode != "private" || length(local.private_endpoints) > 0) && alltrue([for endpoint in values(local.private_endpoints) : endpoint.subnet_id != null && endpoint.private_dns_zone_id != null])
      error_message = "Private mode requires at least one endpoint with an existing subnet and central Key Vault DNS zone."
    }
    precondition {
      condition     = alltrue([for endpoint in values(local.private_endpoints) : try(lower(split("/", endpoint.subnet_id)[2]) == lower(data.azurerm_client_config.current.subscription_id), false)])
      error_message = "Endpoint subnets must be in the workload provider subscription; use separately authorized endpoint states for cross-subscription endpoints."
    }
    precondition {
      condition     = alltrue([for range in values(local.firewall_ranges) : alltrue([for reserved in local.reserved_ranges : range.last < reserved.first || range.first > reserved.last])])
      error_message = "Key Vault IP rules must identify public egress addresses, not private, loopback, link-local, CGNAT or multicast/reserved ranges."
    }
    precondition {
      condition     = var.sku_name == "premium" || alltrue([for key in values(var.keys) : !endswith(key.key_type, "-HSM")])
      error_message = "RSA-HSM and EC-HSM keys require sku_name=premium."
    }
    precondition {
      condition     = length([for endpoint in values(local.private_endpoints) : endpoint if endpoint.private_ip_address != null]) == length(toset([for endpoint in values(local.private_endpoints) : "${lower(endpoint.subnet_id)}:${endpoint.private_ip_address}" if endpoint.private_ip_address != null]))
      error_message = "Multiple endpoints cannot reserve the same static IP in the same subnet."
    }
    precondition {
      condition     = length(local.role_assignment_identities) == length(toset(local.role_assignment_identities))
      error_message = "The same principal/role pair cannot be declared more than once across the convenience and data_access inputs."
    }
    precondition {
      condition     = lookup(local.evaluation_minutes, var.monitoring.frequency, 0) <= lookup(local.evaluation_minutes, var.monitoring.window_size, 0)
      error_message = "The metric alert evaluation frequency cannot exceed its aggregation window."
    }
    precondition {
      condition     = var.diagnostics.existing_setting == null ? true : lower(var.diagnostics.existing_setting.workspace_id) == lower(var.log_analytics_workspace_id)
      error_message = "Reused vault diagnostics must declare the approved central LAW as their destination."
    }
    precondition {
      condition     = try(var.tags.environment == var.environment && var.tags.appcode == lower(var.appcode), false)
      error_message = "Vault environment/appcode tags must match the naming inputs; do not mislabel non-production vaults as production."
    }
  }
}

module "naming" {
  source                = "../../modules/terraform-azurerm-compeer-naming"
  scope                 = "workload"
  region                = var.location
  environment           = var.environment
  domain                = var.domain
  appcode               = var.appcode
  private_endpoint_keys = [for key in keys(local.private_endpoints) : key == "default" ? "vault" : "vault-${key}"]
}

module "vault" {
  source                          = "../../modules/terraform-azurerm-compeer-key-vault"
  name                            = coalesce(var.name, module.naming.key_vault)
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name
  rbac_authorization_enabled      = true
  public_network_access_enabled   = var.network_access.mode == "restricted_public"
  soft_delete_retention_days      = 90
  purge_protection_enabled        = true
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  network_acls = {
    bypass                     = var.network_access.trusted_services_bypass ? "AzureServices" : "None"
    default_action             = "Deny"
    ip_rules                   = var.network_access.ip_rules
    virtual_network_subnet_ids = var.network_access.virtual_network_subnet_ids
  }
  timeouts   = var.timeouts
  tags       = var.tags
  depends_on = [terraform_data.tag_contract]
}

module "private_endpoint" {
  for_each                      = local.private_endpoints
  source                        = "../../modules/terraform-azurerm-compeer-private-endpoint"
  name                          = coalesce(each.value.name, module.naming.private_endpoint_names[each.key == "default" ? "vault" : "vault-${each.key}"])
  resource_group_name           = coalesce(each.value.resource_group_name, var.resource_group_name)
  location                      = coalesce(each.value.location, var.location)
  subnet_id                     = each.value.subnet_id
  custom_network_interface_name = each.value.custom_network_interface_name
  private_service_connections = [{
    name                           = coalesce(each.value.name, module.naming.private_endpoint_names[each.key == "default" ? "vault" : "vault-${each.key}"])
    is_manual_connection           = each.value.manual_connection
    request_message                = each.value.request_message
    private_connection_resource_id = module.vault.id
    subresource_names              = ["vault"]
  }]
  private_dns_zone_group = [{ name = "default", private_dns_zone_ids = [each.value.private_dns_zone_id] }]
  ip_configurations = each.value.private_ip_address == null ? [] : [{
    name               = "vault"
    private_ip_address = each.value.private_ip_address
    subresource_name   = "vault"
    member_name        = "default"
  }]
  tags = var.tags
}

module "roles" {
  source      = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = local.role_assignments
}

module "diagnostics" {
  count                          = var.diagnostics.enabled && var.diagnostics.existing_setting == null ? 1 : 0
  source                         = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  name                           = coalesce(var.diagnostics.name, "diag-${module.vault.name}-law")
  target_resource_id             = module.vault.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.diagnostics.log_analytics_destination_type
  storage_account_id             = var.diagnostics.storage_account_id
  eventhub_authorization_rule_id = var.diagnostics.eventhub_authorization_rule_id
  eventhub_name                  = var.diagnostics.eventhub_name
  logs                           = { audit = { category = "AuditEvent" } }
  metrics                        = { all = { category = "AllMetrics" } }
}

resource "terraform_data" "diagnostic_reuse_contract" {
  lifecycle {
    precondition {
      condition = var.diagnostics.existing_setting == null ? true : (
        lower(join("/", slice(split("/", var.diagnostics.existing_setting.id), 0, length(split("/", var.diagnostics.existing_setting.id)) - 4))) == lower(module.vault.id)
      )
      error_message = "The existing diagnostic setting must belong to this exact workload vault. Reuse does not adopt or change the external setting."
    }
  }
}

module "keys" {
  source       = "../../modules/terraform-azurerm-compeer-key-vault-key"
  key_vault_id = module.vault.id
  keys         = local.keys
  tags         = var.tags
  depends_on   = [module.roles, module.private_endpoint]
}

module "metric_alerts" {
  for_each            = var.monitoring.enabled ? local.metric_alerts : {}
  source              = "../../modules/terraform-azurerm-compeer-monitor-metric-alert"
  name                = "${module.vault.name}-${each.key}"
  resource_group_name = var.resource_group_name
  scopes              = [module.vault.id]
  description         = each.value.description
  severity            = var.monitoring.severity
  frequency           = var.monitoring.frequency
  window_size         = var.monitoring.window_size
  criteria = { vault = {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = each.value.metric_name
    aggregation      = "Average"
    operator         = each.value.operator
    threshold        = each.value.threshold
  } }
  actions = { for id in var.monitoring.action_group_ids : id => { action_group_id = id } }
  tags    = var.tags
}
