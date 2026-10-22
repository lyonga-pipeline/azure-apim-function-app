variable "resource_group_name" {
  description = "Existing workload resource group; this pattern does not create or move resource groups."
  type        = string
}

variable "location" {
  description = "Azure deployment region; naming resolves the approved short code."
  type        = string
}

variable "tenant_id" {
  description = "Entra tenant containing the vault and its principals."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.tenant_id)) && var.tenant_id != "00000000-0000-0000-0000-000000000000"
    error_message = "tenant_id must be a real Entra tenant UUID."
  }
}

variable "environment" {
  description = "Approved workload environment."
  type        = string
}

variable "appcode" {
  description = "Approved application code, shared with the spoke naming and tags."
  type        = string
}

variable "domain" {
  description = "Workload domain used by the naming module."
  type        = string
  default     = "internal-apps"
}

variable "name" {
  description = "Optional approved globally unique vault name; null uses the naming module."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "Standard unless a documented HSM-backed key requirement justifies premium."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "private_endpoint_subnet_id" {
  description = "Default endpoint subnet; alternatively configure private_endpoints. Existing callers retain the default endpoint."
  type        = string
  default     = null
  validation {
    condition     = var.private_endpoint_subnet_id == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.private_endpoint_subnet_id))
    error_message = "private_endpoint_subnet_id must be a full Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  description = "Existing centrally owned privatelink.vaultcore.azure.net zone; never create a duplicate zone here."
  type        = string
  default     = null
  validation {
    condition     = var.private_dns_zone_id == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/privatelink\\.vaultcore\\.azure\\.net$", var.private_dns_zone_id))
    error_message = "private_dns_zone_id must identify the approved privatelink.vaultcore.azure.net zone."
  }
}

variable "log_analytics_workspace_id" {
  description = "Central platform LAW resource ID, not the workspace GUID."
  type        = string
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "log_analytics_workspace_id must be a full workspace resource ID."
  }
}

variable "diagnostics" {
  description = "Create audit diagnostics by default, or reference an externally owned compliant setting without importing or updating it. Disabling creation requires an existing setting."
  type = object({
    enabled                        = optional(bool, true)
    name                           = optional(string)
    log_analytics_destination_type = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    existing_setting = optional(object({
      id                = string
      workspace_id      = string
      log_categories    = optional(set(string), [])
      metric_categories = optional(set(string), [])
    }))
  })
  default = {}
  validation {
    condition = (
      (var.diagnostics.log_analytics_destination_type == null ? true : contains(["Dedicated", "AzureDiagnostics"], var.diagnostics.log_analytics_destination_type)) &&
      (var.diagnostics.eventhub_name == null || var.diagnostics.eventhub_authorization_rule_id != null) &&
      (var.diagnostics.storage_account_id == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Storage/storageAccounts/[^/]+$", var.diagnostics.storage_account_id))) &&
      (var.diagnostics.eventhub_authorization_rule_id == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.EventHub/namespaces/[^/]+/authorizationRules/[^/]+$", var.diagnostics.eventhub_authorization_rule_id))) &&
      (var.diagnostics.existing_setting == null || (var.diagnostics.storage_account_id == null && var.diagnostics.eventhub_authorization_rule_id == null))
    )
    error_message = "Use a valid LAW table mode and Event Hub authorization rule. External diagnostic reuse cannot request locally managed extra destinations."
  }
  validation {
    condition = var.diagnostics.existing_setting == null ? var.diagnostics.enabled : (
      try(length(regexall("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.KeyVault/vaults/[^/]+/providers/Microsoft\\.Insights/diagnosticSettings/[^/]+$", var.diagnostics.existing_setting.id)) > 0, false) &&
      contains(var.diagnostics.existing_setting.log_categories, "AuditEvent") && contains(var.diagnostics.existing_setting.metric_categories, "AllMetrics")
    )
    error_message = "Vault auditing cannot be disabled: create it or supply an existing vault diagnosticSettings ARM ID with AuditEvent/AllMetrics."
  }
}

variable "secret_readers" {
  description = "Stable logical keys mapped to approved workload identity/group object IDs. Vault-scoped Secrets User only."
  type = map(object({
    principal_id   = string
    principal_type = optional(string, "ServicePrincipal")
  }))
  default = {}
  validation {
    condition = alltrue([for reader in values(var.secret_readers) :
      can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", reader.principal_id)) &&
      reader.principal_id != "00000000-0000-0000-0000-000000000000" &&
      contains(["ServicePrincipal", "Group"], reader.principal_type)
    ])
    error_message = "Readers must use real Entra object IDs and ServicePrincipal or Group principal types, not application/client IDs or individual users."
  }
}

variable "secret_officer_group_ids" {
  description = "Explicitly approved security/operator group object IDs. No deployment identity is granted secret access automatically."
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([for id in values(var.secret_officer_group_ids) :
      can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", id)) && id != "00000000-0000-0000-0000-000000000000"
    ])
    error_message = "Secret officers must be approved groups with real Entra object IDs."
  }
}

variable "tags" {
  description = "Output of the shared tags module, including the root-owned stable created_on date."
  type        = map(string)
  validation {
    condition = alltrue([for key in ["environment", "application", "appcode", "owner", "source_repo", "created_on", "criticality_tier", "data_classification", "lifecycle_state", "cost_center", "gl_category", "created_by"] :
      try(length(trimspace(var.tags[key])) > 0, false)
    ])
    error_message = "Use the shared tags module to supply all mandatory ownership, classification, cost and creation tags."
  }
}

variable "private_endpoints" {
  description = "Optional endpoint map. null preserves the original default endpoint inputs; {} is permitted only with approved restricted-public access. Existing zones/VNet links remain platform-owned."
  type = map(object({
    subnet_id                     = string
    private_dns_zone_id           = string
    name                          = optional(string)
    resource_group_name           = optional(string)
    location                      = optional(string)
    custom_network_interface_name = optional(string)
    private_ip_address            = optional(string)
    manual_connection             = optional(bool, false)
    request_message               = optional(string)
  }))
  default = null
  validation {
    condition = var.private_endpoints == null ? true : alltrue([for key, endpoint in var.private_endpoints :
      can(regex("^[a-z][a-z0-9-]{0,30}$", key)) &&
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", endpoint.subnet_id)) &&
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/privatelink\\.vaultcore\\.azure\\.net$", endpoint.private_dns_zone_id)) &&
      (endpoint.private_ip_address == null ? true : can(cidrnetmask("${endpoint.private_ip_address}/32"))) &&
      (endpoint.request_message == null || endpoint.manual_connection)
    ])
    error_message = "Endpoints require stable keys, subnet/Key Vault zone ARM IDs, valid optional IPv4 and manual_connection=true when a request message is supplied."
  }
}

variable "network_access" {
  description = "Private-only by default. restricted_public is an explicit security exception for approved service endpoints/static egress IPs; unrestricted public access is never offered."
  type = object({
    mode                       = optional(string, "private")
    exception_reference        = optional(string)
    ip_rules                   = optional(set(string), [])
    virtual_network_subnet_ids = optional(set(string), [])
    trusted_services_bypass    = optional(bool, false)
  })
  default = {}
  validation {
    condition = (
      contains(["private", "restricted_public"], var.network_access.mode) &&
      ((var.network_access.mode == "restricted_public" || var.network_access.trusted_services_bypass) ? try(length(trimspace(var.network_access.exception_reference)) > 0, false) : true) &&
      (var.network_access.mode == "private" ? length(var.network_access.ip_rules) + length(var.network_access.virtual_network_subnet_ids) == 0 : length(var.network_access.ip_rules) + length(var.network_access.virtual_network_subnet_ids) > 0) &&
      alltrue([for cidr in var.network_access.ip_rules : can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) >= 24, false)]) &&
      alltrue([for id in var.network_access.virtual_network_subnet_ids : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", id))])
    )
    error_message = "Use private mode without firewall allowlists, or an approved restricted_public exception with explicit subnet/public IPv4 CIDR rules (/24 or narrower). Trusted-services bypass also needs an exception reference."
  }
}

variable "data_access" {
  description = "Additional vault-scoped built-in data-plane roles for approved groups/managed identities. No custom/Owner/Contributor/Administrator grants or individual users."
  type = map(object({
    principal_id         = string
    principal_type       = optional(string, "ServicePrincipal")
    role_definition_name = string
  }))
  default = {}
  validation {
    condition = alltrue([for grant in values(var.data_access) :
      can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", grant.principal_id)) && grant.principal_id != "00000000-0000-0000-0000-000000000000" &&
      contains(["ServicePrincipal", "Group"], grant.principal_type) &&
      contains(["Key Vault Secrets User", "Key Vault Secrets Officer", "Key Vault Crypto User", "Key Vault Crypto Service Encryption User", "Key Vault Crypto Officer", "Key Vault Certificate User", "Key Vault Certificates Officer", "Key Vault Reader"], grant.role_definition_name)
    ])
    error_message = "data_access must use real group/service-principal object IDs and an explicitly supported least-privilege Key Vault data role."
  }
}

variable "keys" {
  description = "Optional service-generated keys; no imported key material or secrets. Keys require initial expiration, automatic rotation and an already-authorized network-connected deployment identity."
  type = map(object({
    key_type        = optional(string, "RSA")
    key_size        = optional(number)
    curve           = optional(string)
    key_opts        = list(string)
    not_before_date = optional(string)
    expiration_date = string
    tags            = optional(map(string), {})
    rotation_policy = object({
      expire_after         = string
      notify_before_expiry = optional(string, "P30D")
      automatic = object({
        time_after_creation = optional(string)
        time_before_expiry  = optional(string)
      })
    })
  }))
  default = {}
  validation {
    condition = alltrue([for name, key in var.keys :
      can(regex("^[a-zA-Z0-9-]{1,127}$", name)) &&
      contains(["RSA", "RSA-HSM", "EC", "EC-HSM"], key.key_type) &&
      (startswith(key.key_type, "RSA") ? (key.curve == null && contains([2048, 3072, 4096], coalesce(key.key_size, 3072))) : (key.key_size == null && contains(["P-256", "P-384", "P-521"], coalesce(key.curve, "P-256")))) &&
      length(key.key_opts) > 0 && alltrue([for operation in key.key_opts : contains(startswith(key.key_type, "RSA") ? ["encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"] : ["sign", "verify"], operation)]) &&
      can(formatdate("YYYY-MM-DD", key.expiration_date)) &&
      (key.not_before_date == null ? true : try(timecmp(key.not_before_date, key.expiration_date) < 0, false)) &&
      can(regex("^P[1-9][0-9]*D$", key.rotation_policy.expire_after)) &&
      try(tonumber(trimsuffix(trimprefix(key.rotation_policy.expire_after, "P"), "D")) <= 730, false) &&
      can(regex("^P[1-9][0-9]*D$", key.rotation_policy.notify_before_expiry)) &&
      ((key.rotation_policy.automatic.time_after_creation == null) != (key.rotation_policy.automatic.time_before_expiry == null)) &&
      try(tonumber(trimsuffix(trimprefix(coalesce(key.rotation_policy.automatic.time_after_creation, key.rotation_policy.automatic.time_before_expiry, "invalid"), "P"), "D")) >= 7, false) &&
      can(regex("^P[1-9][0-9]*D$", coalesce(key.rotation_policy.automatic.time_after_creation, key.rotation_policy.automatic.time_before_expiry, "invalid"))) &&
      try(tonumber(trimsuffix(trimprefix(key.rotation_policy.expire_after, "P"), "D")) >= tonumber(trimsuffix(trimprefix(coalesce(key.rotation_policy.automatic.time_after_creation, key.rotation_policy.automatic.time_before_expiry, "invalid"), "P"), "D")) + 7, false) &&
      try(tonumber(trimsuffix(trimprefix(key.rotation_policy.notify_before_expiry, "P"), "D")) < tonumber(trimsuffix(trimprefix(key.rotation_policy.expire_after, "P"), "D")), false)
    ])
    error_message = "Keys require supported RSA/EC parameters/operations, valid expiration and exactly one automatic rotation trigger. Use ISO day durations (P90D), a rotation interval >=7 days, lifetime <=730 days, at least 7 days of lifetime margin and notification before expiration."
  }
}

variable "monitoring" {
  description = "Optional operational metric alerts using existing action groups; no duplicate contacts/groups are created. Security log alerts remain with the central SOC."
  type = object({
    enabled                = optional(bool, false)
    action_group_ids       = optional(set(string), [])
    availability_threshold = optional(number, 99.9)
    latency_threshold_ms   = optional(number, 1000)
    saturation_threshold   = optional(number, 80)
    severity               = optional(number, 2)
    frequency              = optional(string, "PT1M")
    window_size            = optional(string, "PT5M")
  })
  default = {}
  validation {
    condition = (
      (!var.monitoring.enabled || length(var.monitoring.action_group_ids) > 0) &&
      alltrue([for id in var.monitoring.action_group_ids : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Insights/actionGroups/[^/]+$", id))]) &&
      var.monitoring.availability_threshold > 0 && var.monitoring.availability_threshold <= 100 &&
      var.monitoring.saturation_threshold > 0 && var.monitoring.saturation_threshold <= 100 && var.monitoring.latency_threshold_ms > 0 &&
      contains([0, 1, 2, 3, 4], var.monitoring.severity) &&
      contains(["PT1M", "PT5M", "PT15M", "PT30M", "PT1H"], var.monitoring.frequency) &&
      contains(["PT1M", "PT5M", "PT15M", "PT30M", "PT1H", "PT6H", "PT12H", "P1D"], var.monitoring.window_size)
    )
    error_message = "Enabled alerts need approved action-group ARM IDs and valid severity, thresholds, evaluation frequency and window."
  }
}

variable "timeouts" {
  description = "Vault control-plane operation timeouts; private data-plane operations still require network access."
  type        = object({ create = optional(string), read = optional(string), update = optional(string), delete = optional(string) })
  default     = {}
}
