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
    condition     = contains(["prod", "dev", "test", "uat", "np1", "np2", "np3", "sandbox"], var.environment)
    error_message = "Use prod, dev, test, uat, np1, np2, np3 or sandbox; nonprod is a workspace label, not an approved environment token."
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
    application           = string
    owner                 = string
    source_repo           = string
    created_on            = string
    criticality_tier      = string
    data_classification   = string
    lifecycle_state       = string
    cost_center           = string
    gl_category           = string
    dr_tier               = string
    application_component = optional(string)
    modified_on           = optional(string)
    # PHASE2 NEW: v5 10.1/10.3 (WKL-08/GOV-14). Existing callers retain null/false defaults.
    expiration_date      = optional(string)
    time_bound_exception = optional(bool, false)
    additional_tags      = optional(map(string), {})
  })
  validation {
    condition = var.environment != "sandbox" || try(
      var.workload_tags.expiration_date != null &&
      formatdate("YYYY-MM-DD", "${var.workload_tags.expiration_date}T00:00:00Z") == var.workload_tags.expiration_date &&
      timecmp("${var.workload_tags.expiration_date}T00:00:00Z", "${var.workload_tags.created_on}T00:00:00Z") > 0,
      false
    )
    error_message = "Sandbox workloads require a real expiration_date (YYYY-MM-DD) after their stable created_on date."
  }
}

variable "platform" {
  description = "Public output contracts from management and connectivity, or explicitly approved equivalent inputs. Secrets/full state are not inputs."
  type = object({
    management_contract_version      = string
    connectivity_contract_version    = string
    log_analytics_workspace_id       = string
    hub_virtual_network_id           = string
    hub_address_space                = list(string)
    key_vault_private_dns_zone_id    = optional(string)
    storage_blob_private_dns_zone_id = optional(string)
    dns_server_ips                   = optional(list(string), [])
    ddos_protection_plan_id          = optional(string)
    mandatory_tag_keys               = optional(set(string))
    action_group_ids                 = optional(map(string), {})
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

variable "inspection_address_prefixes" {
  description = "Approved on-prem/other-spoke/identity prefixes routed through the hub NVA. Hub and Sunstream ranges are automatic; Sunstream remains NSG-denied. Supply exact remote prefixes, not the encompassing regional allocation."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.inspection_address_prefixes : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "Inspection prefixes must be explicit approved IPv4 CIDRs; the default route is managed by the blueprint."
  }
}

variable "subnets" {
  description = "Stable logical keys. Every subnet gets an NSG and route table; private_endpoints is required and must not be delegated."
  type = map(object({
    address_prefixes              = list(string)
    service_endpoints             = optional(list(string), [])
    bgp_route_propagation_enabled = optional(bool, false)
    delegations = optional(map(object({
      name    = string
      actions = optional(list(string), [])
    })), {})
    rules = optional(map(object({
      description                                = optional(string)
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(set(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(set(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(set(string))
      source_application_security_group_ids      = optional(set(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(set(string))
      destination_application_security_group_ids = optional(set(string))
      access                                     = string
      priority                                   = number
      direction                                  = string
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
      !(rule.source_port_range != null && rule.source_port_ranges != null) &&
      (rule.destination_port_range != null) != (rule.destination_port_ranges != null) &&
      length(compact([rule.source_address_prefix, rule.source_address_prefixes == null ? null : "prefixes", rule.source_application_security_group_ids == null ? null : "asgs"])) == 1 &&
      length(compact([rule.destination_address_prefix, rule.destination_address_prefixes == null ? null : "prefixes", rule.destination_application_security_group_ids == null ? null : "asgs"])) == 1 &&
      alltrue([for items in [rule.source_port_ranges, rule.destination_port_ranges, rule.source_address_prefixes, rule.destination_address_prefixes, rule.source_application_security_group_ids, rule.destination_application_security_group_ids] : items == null ? true : length(items) > 0 && alltrue([for item in items : length(trimspace(item)) > 0])]) &&
      alltrue([for port in [rule.source_port_range, rule.destination_port_range] : port == null ? true : length(trimspace(port)) > 0]) &&
      !(rule.direction == "Inbound" && rule.access == "Allow" &&
      anytrue([for prefix in concat(rule.source_address_prefix == null ? [] : [rule.source_address_prefix], rule.source_address_prefixes == null ? [] : tolist(rule.source_address_prefixes)) : contains(["*", "internet", "0.0.0.0/0", "::/0"], lower(trimspace(prefix)))]))
    ]]))
    error_message = "Custom rules use priorities 300-4000, valid directions/actions, one non-empty address/ASG form per side, at most one source-port form and exactly one destination-port form. Internet-wide inbound access is not allowed."
  }
  validation {
    condition = alltrue(flatten([for subnet in values(var.subnets) : [for rule in values(subnet.rules) : [for id in concat(
      rule.source_application_security_group_ids == null ? [] : tolist(rule.source_application_security_group_ids),
      rule.destination_application_security_group_ids == null ? [] : tolist(rule.destination_application_security_group_ids)
      ) : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/applicationSecurityGroups/[^/]+$", id))
    ]]]))
    error_message = "ASG rules require applicationSecurityGroups ARM IDs. The application owner must ensure ASG NIC membership belongs to this VNet."
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
  description = "Deprecated compatibility guard. Must be false: central attachment owns both peerings and VNet-to-zone links. Migrate existing state before adopting this version."
  type        = bool
  default     = false
  validation {
    condition     = !var.manage_hub_attachment
    error_message = "Spoke-owned attachment has been removed. Hand off existing peerings/DNS links without deleting Azure resources, then set manage_hub_attachment=false and use the central attachment workspace."
  }
}

variable "gateway_transit_enabled" {
  description = "Requested gateway-transit intent published to the central owner; not applied by the spoke. Central approval and gateway readiness are required."
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
  description = "Dedicated private vault by default. Set enabled=false only for a workload that needs no vault; never share a platform secrets vault as a substitute. No secrets enter state."
  type = object({
    enabled  = optional(bool, true)
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

variable "diagnostics" {
  description = "Required audit coverage. enabled controls creation, not whether auditing is required. Existing settings stay externally owned; keys are key_vault, storage.<account-key>.account and storage.<account-key>.blob."
  type = object({
    enabled = optional(bool, true)
    existing_settings = optional(map(object({
      id                = string
      workspace_id      = string
      log_categories    = optional(set(string), [])
      metric_categories = optional(set(string), [])
    })), {})
  })
  default = {}
  validation {
    condition = alltrue([for setting in values(var.diagnostics.existing_settings) :
      try(length(regexall("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/[^/]+/.+/providers/Microsoft\\.Insights/diagnosticSettings/[^/]+$", setting.id)) > 0, false)
    ])
    error_message = "Reused diagnostics require canonical ARM diagnosticSettings IDs, not Terraform pipe-delimited IDs. The external owner must verify the live configuration."
  }
}

variable "workload_access_group_ids" {
  description = "Approved group object IDs receiving Reader/Contributor. Optional resource_group_keys narrows a grant; omission preserves access to all blueprint RGs. Privileged roles/PIM remain outside this blueprint."
  type = map(object({
    principal_id        = string
    role                = string
    resource_group_keys = optional(set(string))
  }))
  default = {}
  validation {
    condition     = alltrue([for assignment in values(var.workload_access_group_ids) : contains(["Reader", "Contributor"], assignment.role)])
    error_message = "Workload access supports Reader or Contributor only; privileged roles remain with the authorization/PIM owner."
  }
}

variable "operations" {
  description = "Reuse approved platform action-group keys or explicit IDs. A new application action group requires create_action_group=true and recipients. Budgets are outside this Phase 1 package."
  type = object({
    create_action_group        = optional(bool, false)
    platform_action_group_keys = optional(set(string), [])
    notification_emails        = optional(set(string), [])
    action_group_ids           = optional(set(string), [])
  })
  default = {}
  validation {
    condition = (
      (var.operations.create_action_group ? length(var.operations.notification_emails) > 0 : length(var.operations.notification_emails) == 0) &&
      alltrue([for email in var.operations.notification_emails : can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", email)) && !strcontains(lower(email), "replace")]) &&
      alltrue([for id in var.operations.action_group_ids : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Insights/actionGroups/[^/]+$", id))])
    )
    error_message = "Reuse approved action-group keys/IDs, or explicitly enable create_action_group with real recipients. Emails alone never authorize creation; enabled alerts require a route."
  }
}

variable "monitoring" {
  description = "Optional application telemetry: explicitly create a component or reuse an approved existing component/LAW pair. Reused resources remain externally owned; role assignment on them requires explicit opt-in."
  type = object({
    enabled                     = optional(bool, false)
    create_application_insights = optional(bool, false)
    existing_application_insights = optional(object({
      id           = string
      workspace_id = string
    }))
    manage_existing_telemetry_access = optional(bool, false)
    alerts_enabled                   = optional(bool, false)
    create_failed_requests_alert     = optional(bool, true)
    existing_failed_requests_alert = optional(object({
      id                      = string
      application_insights_id = string
      action_group_ids        = set(string)
    }))
    sampling_percentage        = optional(number)
    failed_request_threshold   = optional(number)
    internet_ingestion_enabled = optional(bool, true)
    internet_query_enabled     = optional(bool, true)
    private_link_ready         = optional(bool, false)
  })
  default = {}
  validation {
    condition = (
      !(var.monitoring.create_application_insights && var.monitoring.existing_application_insights != null) &&
      (!var.monitoring.enabled || var.monitoring.create_application_insights || var.monitoring.existing_application_insights != null) &&
      (!var.monitoring.manage_existing_telemetry_access || (var.monitoring.enabled && var.monitoring.existing_application_insights != null)) &&
      (!var.monitoring.alerts_enabled || var.monitoring.enabled) &&
      (!var.monitoring.alerts_enabled || (var.monitoring.create_failed_requests_alert != (var.monitoring.existing_failed_requests_alert != null))) &&
      (var.monitoring.sampling_percentage == null ? true : var.monitoring.sampling_percentage > 0 && var.monitoring.sampling_percentage <= 100) &&
      (var.monitoring.failed_request_threshold == null ? true : var.monitoring.failed_request_threshold > 0) &&
      (!var.monitoring.enabled || !var.monitoring.create_application_insights || (var.monitoring.internet_ingestion_enabled && var.monitoring.internet_query_enabled) || var.monitoring.private_link_ready)
    )
    error_message = "Enabled telemetry requires either explicit creation or an existing component, never both. Alerts require telemetry; existing-role management requires reuse. Created private-only telemetry needs an approved AMPLS/DNS path and valid sampling/thresholds."
  }
  validation {
    condition     = var.monitoring.existing_application_insights == null ? true : length(regexall("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Insights/components/[^/]+$", var.monitoring.existing_application_insights.id)) > 0
    error_message = "Existing Application Insights requires its actual component ARM ID; a LAW ID is not an Application Insights component."
  }
  validation {
    condition = var.monitoring.existing_failed_requests_alert == null ? true : (
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Insights/metricAlerts/[^/]+$", var.monitoring.existing_failed_requests_alert.id)) &&
      length(var.monitoring.existing_failed_requests_alert.action_group_ids) > 0 &&
      alltrue([for id in var.monitoring.existing_failed_requests_alert.action_group_ids : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Insights/actionGroups/[^/]+$", id))])
    )
    error_message = "Reused failed-request alerts need a metric-alert ARM ID, their actual Application Insights scope and non-empty existing action-group IDs. Set create_failed_requests_alert=false to reuse."
  }
}

variable "storage_accounts" {
  description = "Optional, actually consumed private Blob stores. No unused account is deployed by default. Azure Files/queues/ADLS need separate service-specific extensions."
  type = map(object({
    enabled                    = optional(bool, true)
    name                       = optional(string)
    replication_type           = optional(string)
    delete_retention_days      = optional(number)
    grant_workload_blob_access = optional(bool, false)
  }))
  default = {}
  validation {
    condition = alltrue([for account in values(var.storage_accounts) : !account.enabled || (
      (account.replication_type == null ? true : contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], account.replication_type)) &&
      (account.delete_retention_days == null ? true : account.delete_retention_days >= 7 && account.delete_retention_days <= 365 && floor(account.delete_retention_days) == account.delete_retention_days)
    )])
    error_message = "Storage uses approved replication types and 7-365 whole days of delete retention; production applies stronger additional checks."
  }
}

variable "backup" {
  description = "Optional VM backup registration into an existing workload-subscription vault/policy. Compute and the vault/policy lifecycle remain with their approved owners."
  type = object({
    enabled           = optional(bool, true)
    recovery_vault_id = string
    backup_policy_id  = string
    virtual_machines  = map(string)
  })
  default = null
  validation {
    condition = var.backup == null ? true : !var.backup.enabled || (
      length(var.backup.virtual_machines) > 0 &&
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.RecoveryServices/vaults/[^/]+$", var.backup.recovery_vault_id)) &&
      startswith(lower(var.backup.backup_policy_id), "${lower(var.backup.recovery_vault_id)}/backuppolicies/") &&
      alltrue([for id in values(var.backup.virtual_machines) : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Compute/virtualMachines/[^/]+$", id))])
    )
    error_message = "Backup requires existing VM IDs, a Recovery Services vault ID and an approved policy belonging to that vault. Empty/unattached vaults are not deployed."
  }
}
