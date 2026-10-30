# PHASE2 EXISTING: v5 5.3/6.2/10.2 NET-39/NET-49/NET-22: central owner manages both peering directions. Partner gateway transit stays off; no NCUS-CUS hub peering for NET-38.
data "tfe_outputs" "platform_connectivity" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.platform_connectivity_workspace_name
}

data "tfe_outputs" "workload_spoke" {
  count        = var.use_tfe_outputs ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.workload_spoke_workspace_name
}

locals {
  platform_outputs             = try(data.tfe_outputs.platform_connectivity[0].nonsensitive_values, {})
  spoke_outputs                = try(data.tfe_outputs.workload_spoke[0].nonsensitive_values, {})
  upstream_attachment_contract = try(local.spoke_outputs.attachment_contract, local.spoke_outputs.spoke.attachment_contract, null)
  # Normalize HCP objects and typed manual inputs before combining maps/defaults.
  attachment_contract = {
    contract_version                 = try(var.spoke_attachment_contract.contract_version, local.upstream_attachment_contract.contract_version, null)
    owner                            = try(var.spoke_attachment_contract.owner, local.upstream_attachment_contract.owner, null)
    hub_virtual_network_id           = try(var.spoke_attachment_contract.hub_virtual_network_id, local.upstream_attachment_contract.hub_virtual_network_id, null)
    spoke_virtual_network_id         = try(var.spoke_attachment_contract.spoke_virtual_network_id, local.upstream_attachment_contract.spoke_virtual_network_id, null)
    spoke_virtual_network_name       = try(var.spoke_attachment_contract.spoke_virtual_network_name, local.upstream_attachment_contract.spoke_virtual_network_name, null)
    spoke_resource_group_name        = try(var.spoke_attachment_contract.spoke_resource_group_name, local.upstream_attachment_contract.spoke_resource_group_name, null)
    gateway_transit_enabled          = try(var.spoke_attachment_contract.gateway_transit_enabled, local.upstream_attachment_contract.gateway_transit_enabled, null)
    key_vault_private_dns_zone_id    = try(var.spoke_attachment_contract.key_vault_private_dns_zone_id, local.upstream_attachment_contract.key_vault_private_dns_zone_id, null)
    storage_blob_private_dns_zone_id = try(var.spoke_attachment_contract.storage_blob_private_dns_zone_id, local.upstream_attachment_contract.storage_blob_private_dns_zone_id, null)
    naming_context                   = try(var.spoke_attachment_contract.naming_context, local.upstream_attachment_contract.naming_context, null)
    peering_names                    = try(var.spoke_attachment_contract.peering_names, local.upstream_attachment_contract.peering_names, null)
    private_dns_zones                = try(var.spoke_attachment_contract.private_dns_zones, tomap(local.upstream_attachment_contract.private_dns_zones), {})
    tags                             = try(var.spoke_attachment_contract.tags, tomap(local.upstream_attachment_contract.tags), {})
  }

  hub_resource_group_name_candidates  = compact([var.hub_resource_group_name, var.use_spoke_attachment_contract ? try(split("/", local.attachment_contract.hub_virtual_network_id)[4], null) : null, try(local.platform_outputs.hub_resource_group_name, ""), try(local.platform_outputs.resource_group_name, "")])
  hub_virtual_network_name_candidates = compact([var.hub_virtual_network_name, var.use_spoke_attachment_contract ? try(split("/", local.attachment_contract.hub_virtual_network_id)[8], null) : null, try(local.platform_outputs.hub_virtual_network_name, "")])
  hub_virtual_network_id_candidates   = compact([var.hub_virtual_network_id, var.use_spoke_attachment_contract ? try(local.attachment_contract.hub_virtual_network_id, null) : null, try(local.platform_outputs.hub_virtual_network_id, "")])

  spoke_resource_group_name_candidates  = compact([var.spoke_resource_group_name, var.use_spoke_attachment_contract ? try(local.attachment_contract.spoke_resource_group_name, null) : null, try(local.spoke_outputs.spoke_resource_group_name, ""), try(local.spoke_outputs.resource_group_name, "")])
  spoke_virtual_network_name_candidates = compact([var.spoke_virtual_network_name, var.use_spoke_attachment_contract ? try(local.attachment_contract.spoke_virtual_network_name, null) : null, try(local.spoke_outputs.spoke_virtual_network_name, "")])
  spoke_virtual_network_id_candidates   = compact([var.spoke_virtual_network_id, var.use_spoke_attachment_contract ? try(local.attachment_contract.spoke_virtual_network_id, null) : null, try(local.spoke_outputs.spoke_virtual_network_id, "")])

  private_dns_zone_resource_group_name_candidates = compact([var.private_dns_zone_resource_group_name, try(local.platform_outputs.resource_group_name, ""), try(local.platform_outputs.hub_resource_group_name, "")])

  hub_resource_group_name  = try(local.hub_resource_group_name_candidates[0], null)
  hub_virtual_network_name = try(local.hub_virtual_network_name_candidates[0], null)
  hub_virtual_network_id   = try(local.hub_virtual_network_id_candidates[0], null)

  spoke_resource_group_name  = try(local.spoke_resource_group_name_candidates[0], null)
  spoke_virtual_network_name = try(local.spoke_virtual_network_name_candidates[0], null)
  spoke_virtual_network_id   = try(local.spoke_virtual_network_id_candidates[0], null)

  private_dns_zone_resource_group_name = try(local.private_dns_zone_resource_group_name_candidates[0], null)

  resolved_required_values = {
    hub_resource_group_name    = local.hub_resource_group_name
    hub_virtual_network_name   = local.hub_virtual_network_name
    hub_virtual_network_id     = local.hub_virtual_network_id
    spoke_resource_group_name  = local.spoke_resource_group_name
    spoke_virtual_network_name = local.spoke_virtual_network_name
    spoke_virtual_network_id   = local.spoke_virtual_network_id
  }

  dns_zone_inputs = var.use_spoke_attachment_contract ? try(local.attachment_contract.private_dns_zones, {}) : var.private_dns_zones
  peering_names = var.use_spoke_attachment_contract ? {
    for direction, key in { hub_to_spoke = "hub", spoke_to_hub = "spoke" } : direction => try(coalesce(
      var.peering_names[direction],
      try(local.attachment_contract.peering_names[direction], null),
      try(module.attachment_naming[0].vnet_peering_names[key], null)
    ), null)
  } : var.peering_names
  attachment_tags = var.use_spoke_attachment_contract ? merge(try(local.attachment_contract.tags, {}), var.tags) : var.tags
  required_dns_zone_ids = var.use_spoke_attachment_contract ? merge(
    try(local.attachment_contract.key_vault_private_dns_zone_id, null) == null ? {} : { key_vault = local.attachment_contract.key_vault_private_dns_zone_id },
    try(local.attachment_contract.storage_blob_private_dns_zone_id, null) == null ? {} : { storage_blob = local.attachment_contract.storage_blob_private_dns_zone_id }
  ) : {}

  private_dns_zone_links = {
    for key, zone in local.dns_zone_inputs : key => {
      name = coalesce(
        lookup(var.private_dns_link_names, key, null),
        try(zone.link_name, null),
        try(module.attachment_naming[0].private_dns_link_names[local.spoke_virtual_network_name], null),
        "lnk-${key}-${var.peering_name_prefix}-spoke"
      )
      resource_group_name   = try([for value in [try(zone.resource_group_name, null), local.private_dns_zone_resource_group_name] : value if value != null && value != ""][0], null)
      private_dns_zone_name = zone.name
      virtual_network_id    = local.spoke_virtual_network_id
      registration_enabled  = try(zone.registration_enabled, false)
      tags                  = local.attachment_tags
    }
    if try(zone.link_to_spoke_enabled, true)
  }
}

module "attachment_naming" {
  source = "../../modules/terraform-azurerm-compeer-naming"
  count = (
    var.use_spoke_attachment_contract && local.attachment_contract.contract_version == "2.0.0" &&
    local.attachment_contract.naming_context != null
  ) ? 1 : 0
  scope                  = "workload"
  region                 = local.attachment_contract.naming_context.region
  environment            = local.attachment_contract.naming_context.environment
  domain                 = local.attachment_contract.naming_context.domain
  appcode                = local.attachment_contract.naming_context.appcode
  private_dns_link_vnets = [local.spoke_virtual_network_name]
  vnet_peerings = {
    hub   = { local_vnet = local.hub_virtual_network_name, remote_vnet = local.spoke_virtual_network_name }
    spoke = { local_vnet = local.spoke_virtual_network_name, remote_vnet = local.hub_virtual_network_name }
  }
}

resource "terraform_data" "resolved_input_validation" {
  input = local.resolved_required_values

  lifecycle {
    precondition {
      condition = !var.use_spoke_attachment_contract || try(
        contains(["1.0.0", "2.0.0"], local.attachment_contract.contract_version) &&
        (local.attachment_contract.contract_version == "1.0.0" || (
          local.attachment_contract.naming_context != null && local.attachment_contract.peering_names == null &&
          alltrue([for zone in values(local.dns_zone_inputs) : try(zone.link_name, null) == null])
        )) &&
        local.attachment_contract.owner == "central-attachment-workspace" &&
        lower(local.attachment_contract.hub_virtual_network_id) == lower(local.hub_virtual_network_id) &&
        lower(local.attachment_contract.spoke_virtual_network_id) == lower(local.spoke_virtual_network_id) &&
        (var.use_tfe_outputs ? lower(local.platform_outputs.hub_virtual_network_id) == lower(local.hub_virtual_network_id) : true) &&
        alltrue([for name in values(local.peering_names) : name != null && try(length(trimspace(name)) > 0, false)]) &&
        local.attachment_contract.gateway_transit_enabled == var.hub_to_spoke.allow_gateway_transit &&
        local.attachment_contract.gateway_transit_enabled == var.spoke_to_hub.use_remote_gateways &&
        toset(keys(local.dns_zone_inputs)) == toset(keys(local.required_dns_zone_ids)) &&
        alltrue([for key, id in local.required_dns_zone_ids :
          can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/privateDnsZones/[^/]+$", id)) &&
          lower(split("/", id)[2]) == lower(coalesce(var.private_dns_subscription_id, var.hub_subscription_id)) &&
          lower(local.dns_zone_inputs[key].name) == lower(split("/", id)[8]) &&
          lower(local.dns_zone_inputs[key].name) == lookup({ key_vault = "privatelink.vaultcore.azure.net", storage_blob = "privatelink.blob.core.windows.net" }, key, "") &&
          lower(local.dns_zone_inputs[key].resource_group_name) == lower(split("/", id)[4]) &&
          !local.dns_zone_inputs[key].registration_enabled &&
          try(local.dns_zone_inputs[key].link_to_spoke_enabled, true) &&
          (local.attachment_contract.contract_version == "2.0.0" || try(length(trimspace(local.dns_zone_inputs[key].link_name)) > 0, false))
        ]), false
      )
      error_message = "Central attachment requires a central-owned v1/v2 contract, v2 naming context, matching hub/zone IDs and every required DNS link. Approve matching gateway flags here; do not attach a spoke whose blueprint still owns the connection."
    }
    precondition {
      condition = length(setsubtract(toset(keys(var.private_dns_link_names)), toset(keys(local.private_dns_zone_links)))) == 0 && alltrue([for value in values(local.resolved_required_values) : value != null && value != ""]) && alltrue([
        for link in values(local.private_dns_zone_links) : link.resource_group_name != null && link.resource_group_name != ""
      ])
      error_message = "network-peering requires resolved hub/spoke inputs and DNS name overrides matching actual linked zone keys. Confirm output-read access and successful producer applies, or set use_tfe_outputs=false and provide approved values manually."
    }
    precondition {
      condition = (
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", local.hub_virtual_network_id)) &&
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", local.spoke_virtual_network_id)) &&
        try(lower(local.hub_virtual_network_id) != lower(local.spoke_virtual_network_id), false) &&
        try(lower(split("/", local.hub_virtual_network_id)[2]) == lower(var.hub_subscription_id), false) &&
        try(lower(split("/", local.spoke_virtual_network_id)[2]) == lower(var.spoke_subscription_id), false) &&
        try(lower(split("/", local.hub_virtual_network_id)[4]) == lower(local.hub_resource_group_name), false) &&
        try(lower(split("/", local.hub_virtual_network_id)[8]) == lower(local.hub_virtual_network_name), false) &&
        try(lower(split("/", local.spoke_virtual_network_id)[4]) == lower(local.spoke_resource_group_name), false) &&
        try(lower(split("/", local.spoke_virtual_network_id)[8]) == lower(local.spoke_virtual_network_name), false)
      )
      error_message = "Peering requires two distinct full VNet IDs matching the explicitly resolved subscription, resource-group and VNet names."
    }
  }
}

module "attachment" {
  source                      = "../terraform-azurerm-compeer-hub-spoke-peering"
  providers                   = { azurerm.hub = azurerm.hub, azurerm.spoke = azurerm.spoke, azurerm.dns = azurerm.dns }
  hub_virtual_network_id      = local.hub_virtual_network_id
  spoke_virtual_network_id    = local.spoke_virtual_network_id
  hub_subscription_id         = var.hub_subscription_id
  spoke_subscription_id       = var.spoke_subscription_id
  private_dns_subscription_id = var.private_dns_subscription_id
  tenant_id                   = var.tenant_id
  peering_names               = local.peering_names
  peering_name_prefix         = var.peering_name_prefix
  hub_to_spoke                = var.hub_to_spoke
  spoke_to_hub                = var.spoke_to_hub
  private_dns_zones = { for key, link in local.private_dns_zone_links : key => {
    name      = link.private_dns_zone_name, resource_group_name = link.resource_group_name,
    link_name = link.name, registration_enabled = link.registration_enabled
  } }
  tags       = local.attachment_tags
  depends_on = [terraform_data.resolved_input_validation]
}
