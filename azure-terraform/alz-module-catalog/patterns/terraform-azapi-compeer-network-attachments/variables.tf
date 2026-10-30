variable "tenant_id" {
  description = "Single approved Entra tenant. Cross-tenant attachment is deliberately unsupported."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a UUID."
  }
}

variable "environment" {
  description = "Fixed approved environment/boundary label of this state, including shared platform or custom environments; never a runtime selector."
  type        = string
  validation {
    condition     = length(var.environment) <= 32 && can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)*$", var.environment))
    error_message = "environment must be an approved lowercase alphanumeric/hyphen label, starting with a letter, at most 32 characters."
  }
}

variable "hub" {
  description = "Network-approved hub and versioned public producer contract, not values selected by an application."
  type = object({
    virtual_network_id = string
    address_space      = set(string)
    organization       = string
    workspace          = string
    contract_version   = optional(string, "0.1.0")
    gateway_ready      = optional(bool, false)
  })
  validation {
    condition = (
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", var.hub.virtual_network_id)) &&
      length(var.hub.address_space) > 0 && alltrue([for cidr in var.hub.address_space : can(cidrnetmask(cidr))]) &&
      var.hub.contract_version == "0.1.0" && length(trimspace(var.hub.organization)) > 0 && length(trimspace(var.hub.workspace)) > 0
    )
    error_message = "hub needs a VNet ARM ID, approved IPv4 CIDRs, public producer location and supported contract 0.1.0."
  }
}

variable "reserved_address_spaces" {
  description = "Approved IPAM inventory outside this batch/hub (on-premises, partners and other environments). Exclude this batch's own ranges."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.reserved_address_spaces : can(cidrnetmask(cidr))])
    error_message = "reserved_address_spaces must contain IPv4 CIDRs."
  }
}

variable "attachments" {
  description = "Network-reviewed inventory keyed by immutable attachment identity. Remove a key only through an approved teardown. Empty creates nothing."
  type = map(object({
    attachment_kind          = optional(string, "workload")
    spoke_virtual_network_id = string
    address_space            = set(string)
    producer = object({
      organization     = string
      workspace        = string
      contract_version = optional(string, "2.0.0")
    })
    # Legacy workload-v2 metadata only. Generic v3 derives names from existing VNets.
    naming_context     = optional(object({ region = string, environment = string, domain = string, appcode = string }))
    approval_reference = string
    ipam_reference     = string
    gateway_transit    = optional(bool, false)
    # NVA forwarding is explicit and paired, not confused with gateway transit.
    allow_forwarded_traffic = optional(bool, true)
    private_dns_zone_ids    = optional(map(string), {})
    peering_names           = optional(object({ hub_to_spoke = string, spoke_to_hub = string }))
    private_dns_link_names  = optional(map(string), {})
    tags                    = optional(map(string), {})
  }))
  default = {}
  validation {
    condition = alltrue([for key, attachment in var.attachments :
      can(regex("^[a-z][a-z0-9_-]*$", key)) &&
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$", attachment.spoke_virtual_network_id)) &&
      length(attachment.address_space) > 0 && alltrue([for cidr in attachment.address_space : can(cidrnetmask(cidr))]) &&
      contains(["workload", "platform"], attachment.attachment_kind) &&
      (attachment.producer.contract_version == "2.0.0" ? (
        attachment.attachment_kind == "workload" && attachment.naming_context != null
      ) : attachment.producer.contract_version == "3.0.0" && attachment.naming_context == null) &&
      alltrue([for value in [attachment.approval_reference, attachment.ipam_reference, attachment.producer.organization, attachment.producer.workspace] : length(trimspace(value)) > 0]) &&
      alltrue([for id in values(attachment.private_dns_zone_ids) : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Network/privateDnsZones/[^/]+$", id))]) &&
      length(setsubtract(toset(keys(attachment.private_dns_link_names)), toset(keys(attachment.private_dns_zone_ids)))) == 0 &&
      alltrue([for name in concat(attachment.peering_names == null ? [] : values(attachment.peering_names), values(attachment.private_dns_link_names)) : can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,78}[a-zA-Z0-9_]$", name))])
    ])
    error_message = "Attachments need approved IDs/CIDRs/references and valid names; use workload v2 with naming_context or generic v3 (workload/platform) without it."
  }
}
