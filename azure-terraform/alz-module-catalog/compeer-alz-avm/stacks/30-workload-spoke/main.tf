locals {
  base = "${var.prefix}-${var.environment}-cus-${var.workload}"
  tags = merge({ Environment = var.environment, Workload = var.workload, ManagedBy = "Terraform", IaCSource = "AVM+CompeerHCP" }, var.tags)

  workload_key_vault_role_assignments = var.enable_workload_key_vault ? merge(
    var.enable_workload_identity ? {
      workload_identity_secrets_user = {
        scope                = module.workload_key_vault[0].id
        role_definition_name = "Key Vault Secrets User"
        principal_id         = module.workload_identity[0].principal_id
        principal_type       = "ServicePrincipal"
      }
    } : {},
    {
      for key, assignment in var.workload_key_vault_additional_role_assignments : key => merge(assignment, {
        scope = module.workload_key_vault[0].id
      })
    }
  ) : {}
}

module "rg" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "0.4.0"
  name             = "${local.base}-rg"
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "nsg" {
  for_each = var.subnets
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version  = "0.5.1"

  name                = "${local.base}-${each.key}-nsg"
  location            = var.location
  resource_group_name = module.rg.name
  security_rules = {
    deny_internet_inbound = {
      name              = "Deny-Internet-Inbound", priority = 4096, direction = "Inbound", access = "Deny", protocol = "*"
      source_port_range = "*", destination_port_range = "*", source_address_prefix = "Internet", destination_address_prefix = "*"
    }
  }
  diagnostic_settings = { law = { workspace_resource_id = var.log_analytics_workspace_id } }
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry
}

module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  name                          = "${local.base}-rt"
  location                      = var.location
  resource_group_name           = module.rg.name
  bgp_route_propagation_enabled = true
  routes = {
    default = {
      name                   = "default-to-ngfw"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_next_hop_ip
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name          = "${local.base}-vnet"
  location      = var.location
  parent_id     = module.rg.resource_id
  address_space = var.address_space
  ipam_pools = length(var.ipam_pools) == 0 ? [
    {
      id            = "/subscriptions/${var.subscription_id}/resourceGroups/${module.rg.name}/providers/Microsoft.Network/networkManagers/${var.prefix}-${var.environment}-cus-networkmanager/ipamPools/${var.workload}-vnet-pool"
      prefix_length = var.ipam_prefix_length
    }
  ] : var.ipam_pools
  subnets = {
    for name, cfg in var.subnets : name => {
      name                              = name
      address_prefixes                  = cfg.address_prefixes
      service_endpoints                 = cfg.service_endpoints
      network_security_group            = { resource_id = module.nsg[name].resource_id }
      route_table                       = { resource_id = module.route_table.resource_id }
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = "Disabled"
    }
  }
  peerings = {
    hub = {
      name                                 = "${local.base}-to-hub"
      remote_virtual_network_resource_id   = var.hub_vnet_id
      allow_virtual_network_access         = true
      allow_forwarded_traffic              = true
      allow_gateway_transit                = false
      use_remote_gateways                  = true
      create_reverse_peering               = true
      reverse_name                         = "hub-to-${local.base}"
      reverse_allow_virtual_network_access = true
      reverse_allow_forwarded_traffic      = true
    }
  }
  diagnostic_settings = { law = { workspace_resource_id = var.log_analytics_workspace_id } }
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry
}

module "workload_identity" {
  count   = var.enable_workload_identity ? 1 : 0
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.2"

  name                = coalesce(var.workload_identity_name, "${local.base}-uami")
  location            = var.location
  resource_group_name = module.rg.name
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry
}

module "workload_key_vault" {
  count   = var.enable_workload_key_vault ? 1 : 0
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-keyvault/azurerm"
  version = "1.0.6"

  name                = coalesce(var.workload_key_vault_name, substr(replace("${local.base}-kv", "-", ""), 0, 24))
  location            = var.location
  resource_group_name = module.rg.name
  sku_name            = "premium"

  public_network_access_enabled   = false
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90
  rbac_authorization_enabled      = true
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = false
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  tags = local.tags
}

module "workload_key_vault_rbac" {
  count   = var.enable_workload_key_vault ? 1 : 0
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-role-assignments/azurerm"
  version = "1.0.0"

  assignments = local.workload_key_vault_role_assignments
}

module "workload_key_vault_diagnostics" {
  count   = var.enable_workload_key_vault ? 1 : 0
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "${local.base}-kv-law"
  target_resource_id         = module.workload_key_vault[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs = {
    all = { category_group = "allLogs" }
  }
  metrics = {
    all = { category = "AllMetrics" }
  }
}

module "workload_key_vault_private_endpoint" {
  count   = var.enable_workload_key_vault && var.workload_key_vault_private_endpoint_subnet_key != null ? 1 : 0
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-private-endpoint/azurerm"
  version = "1.0.5"

  name                          = "${local.base}-kv-pe"
  custom_network_interface_name = "${local.base}-kv-pe-nic"
  resource_group_name           = module.rg.name
  location                      = var.location
  subnet_id                     = module.vnet.subnets[var.workload_key_vault_private_endpoint_subnet_key].resource_id
  private_service_connections = [
    {
      name                           = "${local.base}-kv-psc"
      is_manual_connection           = false
      private_connection_resource_id = module.workload_key_vault[0].id
      subresource_names              = ["vault"]
    }
  ]
  private_dns_zone_group = length(var.workload_key_vault_private_dns_zone_ids) == 0 ? [] : [
    {
      name                 = "default"
      private_dns_zone_ids = var.workload_key_vault_private_dns_zone_ids
    }
  ]
  tags = local.tags
}
