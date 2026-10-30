resource "terraform_data" "inventory_contract" {
  input = keys(var.attachments)
  lifecycle {
    precondition {
      condition = !local.active || try(
        lower(data.azapi_client_config.current[0].tenant_id) == lower(var.tenant_id) &&
        length(distinct([for attachment in values(var.attachments) : lower(attachment.spoke_virtual_network_id)])) == length(var.attachments) &&
        alltrue([for attachment in values(var.attachments) :
          lower(attachment.spoke_virtual_network_id) != lower(var.hub.virtual_network_id) &&
          (attachment.producer.contract_version == "3.0.0" || try(attachment.naming_context.environment == var.environment, false)) &&
          (!attachment.gateway_transit || var.hub.gateway_ready)
        ]) &&
        length(distinct([for names in values(local.peering_names) : lower(names.hub_to_spoke)])) == length(var.attachments) &&
        length(distinct([for link in values(local.dns_links) : lower("${link.zone_id}/${link.name}")])) == length(local.dns_links),
        false
      )
      error_message = "Inventory must stay in the approved tenant/environment, contain unique spoke pairs/names/links and require explicit hub gateway readiness for transit."
    }
  }
}

resource "terraform_data" "producer_contract" {
  input = keys(var.attachments)
  lifecycle {
    precondition {
      condition = !local.active || try(
        local.hub_outputs.contract_version == var.hub.contract_version &&
        lower(local.hub_outputs.hub_virtual_network_id) == lower(var.hub.virtual_network_id) &&
        toset(local.hub_outputs.hub_virtual_network_address_space) == var.hub.address_space &&
        toset(data.azapi_resource.hub[0].output.properties.addressSpace.addressPrefixes) == var.hub.address_space,
        false
      )
      error_message = "Approved hub ID/CIDRs/version must match its public producer outputs and live Azure VNet."
    }
    precondition {
      condition     = alltrue(flatten([for checks in values(local.producer_checks) : values(checks)]))
      error_message = "Producer/inventory mismatch (attachment => failed fields): ${jsonencode({ for key, checks in local.producer_checks : key => [for field, passed in checks : field if !passed] if !alltrue(values(checks)) })}. Outputs never authorize inventory changes."
    }
  }
}

resource "terraform_data" "ipam_contract" {
  input = local.spoke_cidrs
  lifecycle {
    precondition {
      condition = alltrue(flatten([for index, prefix in local.spoke_cidrs : [
        for other_index, other in local.spoke_cidrs :
        index == other_index || local.ranges[prefix.cidr].last < local.ranges[other.cidr].first || local.ranges[other.cidr].last < local.ranges[prefix.cidr].first
        ]])) && alltrue(flatten([for prefix in local.spoke_cidrs : [
        for cidr in setunion(var.hub.address_space, var.reserved_address_spaces) :
        local.ranges[prefix.cidr].last < local.ranges[cidr].first || local.ranges[cidr].last < local.ranges[prefix.cidr].first
      ]]))
      error_message = "Spoke address spaces must not overlap each other, the hub or approved external IPAM ranges."
    }
  }
}
