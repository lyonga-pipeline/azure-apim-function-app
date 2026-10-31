# PHASE2 NEW: v5 6.1-6.4. CSP subscription must already be onboarded by governance.
resource "terraform_data" "approval" {
  count = var.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.existing_identity_owner_checked
      error_message = "Review the existing platform-directory-services external DC entries/state before enabling this separate forest owner; never deploy both for the same controllers."
    }
    precondition {
      condition     = var.environment == "prod" && var.hub_connection == null && length(var.management_locks) == 0
      error_message = "This production identity root delegates both peerings centrally and does not introduce management locks."
    }
    precondition {
      condition     = var.dc_backup == null ? false : length(setsubtract(toset(keys(var.domain_controllers)), toset(keys(var.dc_backup.protected_controllers)))) == 0
      error_message = "Both external domain controllers require approved backup enrolment before infrastructure deployment."
    }
    precondition {
      condition     = var.deployment_approved && var.identity_vnet != null && length(var.domain_controllers) == 2
      error_message = "External identity requires approval, a dedicated VNet and exactly two approved DC definitions."
    }
    precondition {
      condition     = alltrue([for dc in values(var.domain_controllers) : !try(dc.domain_join.enabled, false)])
      error_message = "Forest/trust/DNS design and DC promotion belong to the approved AD workflow, not a member-server join extension."
    }
    precondition {
      condition = var.identity_vnet == null ? false : alltrue([for key in keys(var.identity_vnet.subnets) :
        length([for association in values(local.nsg_associations) : association if association.subnet_key == key && contains(keys(var.network_security_groups), association.nsg_key)]) == 1 &&
        length([for association in values(local.route_associations) : association if association.subnet_key == key && contains(keys(var.route_tables), association.route_table_key)]) == 1
      ])
      error_message = "Every identity subnet requires exactly one real NSG and route-table association."
    }
    precondition {
      condition = length(var.inspection_address_prefixes) > 0 && var.inspection_next_hop_ip != null && alltrue([for table in values(var.route_tables) :
        table.bgp_route_propagation_enabled == false &&
        alltrue([for prefix in setunion(var.inspection_address_prefixes, toset(["0.0.0.0/0"])) :
          length([for route in values(table.routes) : route if route.address_prefix == prefix && route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == var.inspection_next_hop_ip]) == 1
        ]) && alltrue([for route in values(table.routes) : route.next_hop_type == "None" || (route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == var.inspection_next_hop_ip)])
      ])
      error_message = "Explicit hub/on-premises and default UDRs must target the approved firewall, with BGP propagation disabled and no inspection-bypass routes."
    }
    precondition {
      condition = alltrue([for dc in values(var.domain_controllers) :
        dc.source_image_id != null || try(dc.source_image_reference.version != "latest", false)
      ])
      error_message = "Production DCs require an immutable image version/ID; resolve and approve the exact image before enabling deployment."
    }
  }
}
module "external_identity" {
  source                          = "../../../../patterns/terraform-azurerm-compeer-directory-services"
  count                           = var.enabled ? 1 : 0
  subscription_id                 = var.subscription_id
  location                        = var.location
  environment                     = var.environment
  platform_tags                   = var.platform_tags
  resource_group                  = var.resource_group
  identity_vnet                   = var.identity_vnet
  hub_connection                  = null
  network_security_groups         = var.network_security_groups
  route_tables                    = var.route_tables
  subnet_nsg_associations         = var.subnet_nsg_associations
  subnet_route_table_associations = var.subnet_route_table_associations
  recovery_services_vaults        = var.recovery_services_vaults
  domain_controllers              = var.domain_controllers
  admin_passwords                 = var.admin_passwords
  domain_join_passwords           = var.domain_join_passwords
  role_assignments                = var.role_assignments
  management_locks                = {}
  additional_scopes               = var.additional_scopes
  operational_contracts           = var.operational_contracts
  dc_backup                       = var.dc_backup
  depends_on                      = [terraform_data.approval]
}
output "central_attachment_inputs" {
  description = "Compatibility metadata for existing callers. New batch attachments consume network_attachment_contract instead."
  value = var.enabled ? {
    spoke_virtual_network_id   = module.external_identity[0].identity_vnet_id
    spoke_virtual_network_name = var.identity_vnet.name
    spoke_resource_group_name  = module.external_identity[0].resource_group_name
    gateway_transit_enabled    = false
  } : null
}

# PHASE2 NEW: publish metadata only; both peering directions remain centrally owned.
data "azurerm_client_config" "attachment" {
  count = local.publish_attachment ? 1 : 0
}
resource "terraform_data" "attachment_context" {
  count = local.publish_attachment ? 1 : 0
  lifecycle {
    precondition {
      condition = (
        lower(data.azurerm_client_config.attachment[0].tenant_id) == lower(var.central_attachment.tenant_id) &&
        lower(data.azurerm_client_config.attachment[0].subscription_id) == lower(var.subscription_id)
      )
      error_message = "Attachment metadata must match the authenticated identity tenant and this VNet owner's subscription."
    }
  }
}
module "attachment_contract" {
  source                 = "../../../../patterns/terraform-azapi-compeer-network-attachments/producer"
  count                  = local.publish_attachment ? 1 : 0
  tenant_id              = var.central_attachment.tenant_id
  environment            = var.environment
  attachment_kind        = "platform"
  hub_virtual_network_id = var.central_attachment.hub_virtual_network_id
  virtual_network = {
    id            = module.external_identity[0].identity_vnet_id
    address_space = module.external_identity[0].identity_vnet_address_space
  }
  gateway_transit      = false
  private_dns_zone_ids = var.central_attachment.private_dns_zone_ids
  depends_on           = [terraform_data.attachment_context]
}
output "network_attachment_contract" {
  description = "Public v3 platform producer contract for the central batch attachment owner; null when disabled or not opted in."
  value       = try(module.attachment_contract[0].network_attachment_contract, null)
}

# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Optional VM-owner monitoring; include phase2_variables.tf with this root.
# =============================================================================

resource "terraform_data" "phase2_agent_contract" {
  count = length(var.phase2_agents) > 0 ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.enabled && var.phase2_log_analytics_workspace_id != null && var.phase2_agent_ownership_confirmed
      error_message = "External identity telemetry needs the enabled VM owner, approved central LAW and explicit agent/association ownership."
    }
    precondition {
      condition = alltrue([for key, agent in var.phase2_agents :
        contains(keys(var.domain_controllers), key) && agent.os_type == "Windows" &&
        try(contains(var.domain_controllers[key].identity.identity_ids, agent.managed_identity_id), false)
      ])
      error_message = "External identity agents can target only this root's Windows DCs with their declared UAMI assigned."
    }
  }
}
module "phase2_vm_observability" {
  source                     = "../../../../patterns/terraform-azurerm-compeer-platform-observability"
  count                      = var.enabled && length(var.phase2_agents) > 0 ? 1 : 0
  resource_group_name        = module.external_identity[0].resource_group_name
  location                   = var.location
  log_analytics_workspace_id = coalesce(var.phase2_log_analytics_workspace_id, "unset")
  agents = { for key, agent in var.phase2_agents : key => merge(agent, {
    virtual_machine_id = module.external_identity[0].domain_controller_ids[key]
  }) if contains(keys(var.domain_controllers), key) }
  tags       = module.external_identity[0].resource_tags
  depends_on = [terraform_data.phase2_agent_contract]
}
output "phase2_vm_observability" { value = try(module.phase2_vm_observability[0], null) }
