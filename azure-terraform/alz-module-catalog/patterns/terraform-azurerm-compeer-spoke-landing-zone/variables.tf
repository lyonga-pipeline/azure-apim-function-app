variable "subscription_id" {
  description = "Target workload subscription UUID; existing subscriptions are not created or moved by this blueprint."
  type        = string
}

variable "tenant_id" {
  description = "Common Entra tenant for the workload, hub and private DNS subscriptions."
  type        = string
}

variable "location" {
  description = "Azure deployment region. Resource names use the naming module's abbreviation."
  type        = string
  default     = "centralus"
}

variable "environment" {
  description = "Production or approved non-production environment; the same security baseline applies to both."
  type        = string
  validation {
    condition     = contains(["prod", "dev", "test", "uat", "np1", "np2", "np3"], var.environment)
    error_message = "Use prod, dev, test, uat, np1, np2 or np3; nonprod is a workspace label, not an approved environment token."
  }
}

variable "appcode" {
  description = "Approved application code; names and tags use the same value."
  type        = string
}

variable "domain" {
  description = "Approved workload domain."
  type        = string
  default     = "internal-apps"
}

variable "workload_tags" {
  description = "Mandatory business metadata. created_on must be stable and supplied by the root lifecycle boundary."
  type = object({
    application         = string
    owner               = string
    source_repo         = string
    created_on          = string
    criticality_tier    = string
    data_classification = string
    lifecycle_state     = string
    cost_center         = string
    gl_category         = string
    dr_tier             = string
    additional_tags     = optional(map(string), {})
  })
}

variable "platform" {
  description = "Public output contracts from management and connectivity, or explicitly approved equivalent inputs. Secrets/full state are not inputs."
  type = object({
    management_contract_version      = string
    connectivity_contract_version    = string
    log_analytics_workspace_id       = string
    hub_virtual_network_id           = string
    hub_address_space                = list(string)
    key_vault_private_dns_zone_id    = string
    storage_blob_private_dns_zone_id = optional(string)
    dns_server_ips                   = optional(list(string), [])
    ddos_protection_plan_id          = optional(string)
  })
}

variable "address_space" {
  description = "IPAM-approved IPv4 VNet prefixes. Never allocate ranges automatically."
  type        = list(string)
  validation {
    condition     = length(var.address_space) > 0 && alltrue([for cidr in var.address_space : can(cidrnetmask(cidr))])
    error_message = "Provide at least one valid, approved IPv4 VNet CIDR. IPv6 requires a separately reviewed dual-stack design."
  }
}

variable "reserved_address_spaces" {
  description = "Other spoke/on-prem ranges supplied by IPAM; hub ranges are checked automatically. This is not a global IPAM discovery service."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.reserved_address_spaces : can(cidrnetmask(cidr))])
    error_message = "reserved_address_spaces must contain valid IPv4 CIDRs."
  }
}

variable "subnets" {
  description = "Stable logical keys. Every subnet gets an NSG and route table; private_endpoints is required and must not be delegated."
  type = map(object({
    address_prefixes              = list(string)
    service_endpoints             = optional(list(string), [])
    bgp_route_propagation_enabled = optional(bool, true)
    delegations = optional(map(object({
      name    = string
      actions = optional(list(string), [])
    })), {})
    rules = optional(map(object({
      description                  = optional(string)
      protocol                     = string
      source_port_range            = optional(string, "*")
      destination_port_range       = string
      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(set(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(set(string))
      access                       = string
      priority                     = number
      direction                    = string
    })), {})
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
  validation {
    condition = (
      contains(keys(var.subnets), "private_endpoints") && length(var.subnets) >= 2 &&
      alltrue([for subnet in values(var.subnets) : length(subnet.address_prefixes) > 0 && alltrue([for cidr in subnet.address_prefixes : can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) <= 29, false)])])
    )
    error_message = "Provide application subnet(s) and a private_endpoints subnet, each with approved IPv4 prefixes of /29 or larger."
  }
  validation {
    condition     = try(length(var.subnets.private_endpoints.delegations) == 0 && length(var.subnets.private_endpoints.service_endpoints) == 0, false)
    error_message = "The private_endpoints subnet must not be delegated or configured with service endpoints."
  }
  validation {
    condition = alltrue(flatten([for subnet in values(var.subnets) : [for rule in values(subnet.rules) :
      rule.priority >= 300 && rule.priority <= 4000 && floor(rule.priority) == rule.priority &&
      contains(["Allow", "Deny"], rule.access) && contains(["Inbound", "Outbound"], rule.direction) &&
      (rule.source_address_prefix != null) != (rule.source_address_prefixes != null) &&
      (rule.destination_address_prefix != null) != (rule.destination_address_prefixes != null) &&
      !(rule.direction == "Inbound" && rule.access == "Allow" &&
      anytrue([for prefix in concat(rule.source_address_prefix == null ? [] : [rule.source_address_prefix], rule.source_address_prefixes == null ? [] : tolist(rule.source_address_prefixes)) : contains(["*", "Internet", "0.0.0.0/0"], prefix)]))
    ]]))
    error_message = "Custom rules use priorities 300-4000, valid directions/actions, one source and destination form, and may not open Internet-wide inbound access."
  }
  validation {
    condition = alltrue([for subnet in values(var.subnets) :
      length(distinct([for rule in values(subnet.rules) : "${rule.direction}:${rule.priority}"])) == length(subnet.rules) &&
      alltrue([for name in keys(subnet.rules) : !startswith(name, "baseline-")]) &&
      !contains(keys(subnet.routes), "default-egress") &&
      alltrue([for route in values(subnet.routes) : route.next_hop_type != "Internet" && route.address_prefix != "0.0.0.0/0"])
    ])
    error_message = "Rule priorities must be unique per direction; baseline- rule names are reserved; custom routes cannot override default-egress or bypass the hub with Internet routes."
  }
}

variable "egress_next_hop_ip" {
  description = "Approved hub firewall/NVA frontend IPv4 address. Do not guess it from a subnet or Route Server address."
  type        = string
  validation {
    condition     = can(cidrnetmask("${var.egress_next_hop_ip}/32"))
    error_message = "egress_next_hop_ip must be an approved IPv4 address."
  }
}

variable "allow_azure_provided_dns" {
  description = "Explicit opt-in when architecture approves Azure-provided DNS instead of central hybrid DNS."
  type        = bool
  default     = false
}

variable "manage_hub_attachment" {
  description = "True: this state owns BOTH peerings and the vault-zone link. False: a central attachment state owns all three; never split or double-own them."
  type        = bool
  default     = true
}

variable "gateway_transit_enabled" {
  description = "Enable paired hub gateway-transit/spoke remote-gateway flags only after network approval and gateway readiness."
  type        = bool
  default     = false
}

variable "private_endpoint_client_cidrs" {
  description = "Additional approved source CIDRs needing HTTPS to private endpoints, e.g. a private deployment-agent subnet. Spoke CIDRs are included."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.private_endpoint_client_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "Private endpoint clients must be specific approved IPv4 CIDRs, not the entire Internet."
  }
}

variable "key_vault" {
  description = "Dedicated vault is mandatory. Reader identities use vault-scoped Secrets User; operator access is explicit. No secrets enter Terraform state."
  type = object({
    name     = optional(string)
    sku_name = optional(string, "standard")
    secret_readers = optional(map(object({
      principal_id   = string
      principal_type = optional(string, "ServicePrincipal")
    })), {})
    secret_officer_group_ids = optional(map(string), {})
  })
  default = {}
  validation {
    condition     = !contains(keys(var.key_vault.secret_readers), "workload")
    error_message = "The workload reader key is reserved for the blueprint-created managed identity."
  }
}

variable "workload_access_group_ids" {
  description = "Approved group object IDs receiving resource-group Reader or Contributor access; platform policy/PIM ownership stays outside this blueprint."
  type = map(object({
    principal_id = string
    role         = string
  }))
  default = {}
  validation {
    condition     = alltrue([for assignment in values(var.workload_access_group_ids) : contains(["Reader", "Contributor"], assignment.role)])
    error_message = "Workload access supports Reader or Contributor only; privileged roles remain with the authorization/PIM owner."
  }
}
