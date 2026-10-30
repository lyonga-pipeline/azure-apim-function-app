locals {
  allowed_environments = var.allowed_environments == null ? toset([var.environment]) : var.allowed_environments
  # Inventory declares the real environment; producer outputs only cross-check it.
  attachment_environments = { for key, attachment in var.attachments : key => coalesce(
    attachment.environment, try(attachment.naming_context.environment, null), var.environment
  ) }
  active        = length(var.attachments) > 0
  hub_outputs   = try(data.tfe_outputs.hub[0].nonsensitive_values, {})
  spoke_outputs = { for key, producer in data.tfe_outputs.spoke : key => producer.nonsensitive_values }
  contracts = { for key, attachment in var.attachments : key => attachment.producer.contract_version == "3.0.0" ? try(local.spoke_outputs[key].network_attachment_contract, null) : try(
    local.spoke_outputs[key].attachment_contract,
    local.spoke_outputs[key].spoke.attachment_contract,
    null
  ) }
  contexts    = { for key, attachment in var.attachments : key => attachment.producer.contract_version == "3.0.0" ? try(local.contracts[key].context, null) : try(local.spoke_outputs[key].context, local.spoke_outputs[key].spoke.context, null) }
  hub_name    = try(split("/", var.hub.virtual_network_id)[8], "invalid")
  spoke_names = { for key, attachment in var.attachments : key => try(split("/", attachment.spoke_virtual_network_id)[8], "invalid") }
  peering_names = { for key, attachment in var.attachments : key => {
    hub_to_spoke = attachment.peering_names == null ? module.naming[key].vnet_peering_names.hub : attachment.peering_names.hub_to_spoke
    spoke_to_hub = attachment.peering_names == null ? module.naming[key].vnet_peering_names.spoke : attachment.peering_names.spoke_to_hub
  } }
  dns_links = merge({}, [for key, attachment in var.attachments : {
    for zone_key, zone_id in attachment.private_dns_zone_ids : "${key}/${zone_key}" => {
      attachment_key     = key
      zone_id            = zone_id
      virtual_network_id = attachment.spoke_virtual_network_id
      name               = lookup(attachment.private_dns_link_names, zone_key, module.naming[key].private_dns_link_names[local.spoke_names[key]])
      tags               = attachment.tags
    }
  }]...)
  contract_zone_ids = { for key, contract in local.contracts : key => var.attachments[key].producer.contract_version == "3.0.0" ? try(contract.private_dns_zone_ids, {}) : merge(
    try(contract.key_vault_private_dns_zone_id, null) == null ? {} : { key_vault = contract.key_vault_private_dns_zone_id },
    try(contract.storage_blob_private_dns_zone_id, null) == null ? {} : { storage_blob = contract.storage_blob_private_dns_zone_id }
  ) }
  # IPv4 integer intervals detect partial overlap, not just equal CIDR strings.
  cidrs = toset(concat(tolist(var.hub.address_space), tolist(var.reserved_address_spaces), flatten([for attachment in values(var.attachments) : tolist(attachment.address_space)])))
  ranges = { for cidr in local.cidrs : cidr => {
    first = try(sum([for i, octet in split(".", cidrhost(cidr, 0)) : parseint(octet, 10) * pow(256, 3 - i)]), 0)
    last  = try(sum([for i, octet in split(".", cidrhost(cidr, -1)) : parseint(octet, 10) * pow(256, 3 - i)]), 0)
  } }
  spoke_cidrs = flatten([for key, attachment in var.attachments : [for cidr in attachment.address_space : { key = key, cidr = cidr }]])
  producer_checks = { for key, attachment in var.attachments : key => {
    version        = try(local.contracts[key].contract_version == attachment.producer.contract_version, false)
    owner          = try(local.contracts[key].owner == "central-attachment-workspace", false)
    hub_id         = try(lower(local.contracts[key].hub_virtual_network_id) == lower(var.hub.virtual_network_id), false)
    spoke_id       = try(lower(local.contracts[key].spoke_virtual_network_id) == lower(attachment.spoke_virtual_network_id), false)
    spoke_name     = try(lower(local.contracts[key].spoke_virtual_network_name) == lower(split("/", attachment.spoke_virtual_network_id)[8]), false)
    resource_group = try(lower(local.contracts[key].spoke_resource_group_name) == lower(split("/", attachment.spoke_virtual_network_id)[4]), false)
    naming         = attachment.producer.contract_version == "3.0.0" || try(alltrue([for field, value in attachment.naming_context : local.contracts[key].naming_context[field] == value]), false)
    kind           = attachment.producer.contract_version == "3.0.0" ? try(local.contexts[key].attachment_kind == attachment.attachment_kind, false) : attachment.attachment_kind == "workload"
    gateway        = try(local.contracts[key].gateway_transit_enabled == attachment.gateway_transit, false)
    tenant         = try(lower(local.contexts[key].tenant_id) == lower(var.tenant_id), false)
    subscription   = try(lower(local.contexts[key].subscription_id) == lower(split("/", attachment.spoke_virtual_network_id)[2]), false)
    environment    = try(contains(local.allowed_environments, local.attachment_environments[key]) && local.contexts[key].environment == local.attachment_environments[key], false)
    live_cidrs     = try(toset(data.azapi_resource.spoke[key].output.properties.addressSpace.addressPrefixes) == attachment.address_space, false)
    producer_cidrs = attachment.producer.contract_version != "3.0.0" || try(toset(local.contracts[key].address_space) == attachment.address_space, false)
    central_names  = try(local.contracts[key].peering_names, null) == null
    zone_keys = try(
      (attachment.producer.contract_version == "3.0.0" || try(length(local.contracts[key].private_dns_zones) == length(attachment.private_dns_zone_ids), false)) &&
      length(local.contract_zone_ids[key]) == length(attachment.private_dns_zone_ids) &&
      alltrue([for zone_key in keys(attachment.private_dns_zone_ids) : contains(keys(local.contract_zone_ids[key]), zone_key)]),
      false
    )
    zone_intent = try(alltrue([for zone_key, id in attachment.private_dns_zone_ids :
      lower(local.contract_zone_ids[key][zone_key]) == lower(id) &&
      (attachment.producer.contract_version == "3.0.0" ? try(!local.contracts[key].private_dns_registration_enabled, true) : (
        lower(local.contracts[key].private_dns_zones[zone_key].name) == lower(split("/", id)[8]) &&
        lower(local.contracts[key].private_dns_zones[zone_key].resource_group_name) == lower(split("/", id)[4]) &&
        lower(split("/", id)[8]) == lookup({ key_vault = "privatelink.vaultcore.azure.net", storage_blob = "privatelink.blob.core.windows.net" }, zone_key, "") &&
        !local.contracts[key].private_dns_zones[zone_key].registration_enabled &&
        try(local.contracts[key].private_dns_zones[zone_key].link_to_spoke_enabled, true) &&
        try(local.contracts[key].private_dns_zones[zone_key].link_name, null) == null
      ))
    ]), false)
  } }
}
