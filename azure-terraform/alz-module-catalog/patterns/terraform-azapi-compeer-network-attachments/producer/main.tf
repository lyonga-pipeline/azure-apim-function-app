# Output-only adapter for an existing VNet owner. Creates no Azure resources or peerings.
terraform {
  required_version = ">= 1.11.4, < 2.0.0"
}

variable "tenant_id" {
  type        = string
  description = "Tenant of the existing VNet; the consumer independently checks its authenticated tenant."
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a UUID."
  }
}
variable "environment" {
  type        = string
  description = "Real approved VNet environment (including shared or custom names), not a relabeling to fit a consumer."
  validation {
    condition     = length(var.environment) <= 32 && can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)*$", var.environment))
    error_message = "Use an approved lowercase alphanumeric/hyphen environment label of at most 32 characters."
  }
}
variable "attachment_kind" {
  type        = string
  default     = "platform"
  description = "Platform or workload classification independently approved by the network inventory."
  validation {
    condition     = contains(["platform", "workload"], var.attachment_kind)
    error_message = "attachment_kind must be platform or workload."
  }
}
variable "hub_virtual_network_id" {
  type        = string
  description = "Expected central hub VNet; never establishes connectivity by itself."
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.hub_virtual_network_id))
    error_message = "Use a full hub VNet ARM ID."
  }
}
variable "virtual_network" {
  type        = object({ id = string, address_space = set(string) })
  description = "Actual outputs from the existing VNet owner module, not a manually claimed replacement VNet."
  validation {
    condition = (
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.virtual_network.id)) &&
      length(var.virtual_network.address_space) > 0 && alltrue([for cidr in var.virtual_network.address_space : can(cidrnetmask(cidr))])
    )
    error_message = "virtual_network requires its full ARM ID and nonempty IPv4 address spaces."
  }
}
variable "gateway_transit" {
  type        = bool
  default     = false
  description = "Requested intent only; central approval and gateway readiness are checked by the consumer."
}
variable "private_dns_zone_ids" {
  type        = map(string)
  default     = {}
  description = "Only the exact existing central zones this attached VNet should resolve. No DNS auto-registration."
  validation {
    condition     = alltrue([for id in values(var.private_dns_zone_ids) : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/privateDnsZones/[^/]+$", id))])
    error_message = "Use full existing private DNS zone ARM IDs."
  }
}

output "network_attachment_contract" {
  description = "Generic public v3 contract; no privileged credentials, resource creation or ownership transfer."
  value = {
    contract_version                 = "3.0.0"
    owner                            = "central-attachment-workspace"
    hub_virtual_network_id           = var.hub_virtual_network_id
    spoke_virtual_network_id         = var.virtual_network.id
    spoke_virtual_network_name       = try(split("/", var.virtual_network.id)[8], "")
    spoke_resource_group_name        = try(split("/", var.virtual_network.id)[4], "")
    address_space                    = var.virtual_network.address_space
    gateway_transit_enabled          = var.gateway_transit
    private_dns_zone_ids             = var.private_dns_zone_ids
    private_dns_registration_enabled = false
    context = {
      tenant_id       = var.tenant_id
      subscription_id = try(split("/", var.virtual_network.id)[2], "")
      environment     = var.environment
      attachment_kind = var.attachment_kind
    }
  }
  precondition {
    condition     = lower(var.hub_virtual_network_id) != lower(var.virtual_network.id)
    error_message = "A VNet cannot request peering to itself."
  }
}
