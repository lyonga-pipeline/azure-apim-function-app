variable "subscription_id" {
  type        = string
  description = "Connectivity subscription ID."
}

variable "location" {
  type        = string
  description = "Azure region for connector VMs."
}

variable "environment" {
  type        = string
  description = "Environment key, such as np or prod."
}

variable "platform_tags" {
  type = object({
    application           = optional(string)
    appcode               = optional(string)
    owner                 = optional(string)
    source_repo           = optional(string)
    created_on            = optional(string)
    criticality_tier      = optional(string)
    data_classification   = optional(string)
    lifecycle_state       = optional(string)
    cost_center           = optional(string)
    gl_category           = optional(string)
    application_component = optional(string)
    modified_on           = optional(string)
    created_by            = optional(string)
    dr_tier               = optional(string)
    expiration_date       = optional(string)
    time_bound_exception  = optional(bool, false)
    additional_tags       = optional(map(string), {})
  })
  default = {}
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "connectors" {
  type = map(object({
    os_type                        = optional(string, "Linux")
    name                           = string
    nic_name                       = string
    subnet_id                      = string
    private_ip_address             = optional(string)
    private_ip_address_allocation  = optional(string, "Dynamic")
    ip_configuration_name          = optional(string, "primary")
    dns_servers                    = optional(list(string))
    accelerated_networking_enabled = optional(bool, true)
    ip_forwarding_enabled          = optional(bool, false)
    vm_size                        = optional(string, "Standard_D2s_v5")
    zone                           = optional(string)
    computer_name                  = optional(string)
    license_type                   = optional(string)
    timezone                       = optional(string, "Central Standard Time")
    domain_join = optional(object({
      domain       = string
      username     = string
      password_key = string
      ou_path      = optional(string, "")
    }))
    admin_username                  = optional(string, "azureadmin")
    disable_password_authentication = optional(bool, true)
    admin_ssh_keys = optional(list(object({
      username   = string
      public_key = string
    })), [])
    source_image_id = optional(string)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    plan = optional(object({
      name      = string
      publisher = string
      product   = string
    }))
    patch_mode                 = optional(string, "ImageDefault")
    patch_assessment_mode      = optional(string, "ImageDefault")
    provision_vm_agent         = optional(bool, true)
    allow_extension_operations = optional(bool, true)
    encryption_at_host_enabled = optional(bool, true)
    secure_boot_enabled        = optional(bool, true)
    vtpm_enabled               = optional(bool, true)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    boot_diagnostics = optional(object({
      storage_account_uri = optional(string)
    }))
    os_disk = optional(object({
      caching                   = optional(string, "ReadWrite")
      storage_account_type      = optional(string, "Premium_LRS")
      disk_size_gb              = optional(number)
      name                      = optional(string)
      write_accelerator_enabled = optional(bool)
      disk_encryption_set_id    = optional(string)
    }), {})
    diagnostics = optional(object({
      enabled                        = optional(bool, false)
      name                           = optional(string)
      log_analytics_workspace_id     = optional(string)
      storage_account_id             = optional(string)
      eventhub_authorization_rule_id = optional(string)
      eventhub_name                  = optional(string)
      partner_solution_id            = optional(string)
      log_analytics_destination_type = optional(string)
      # Platform_Output_Contracts_IAC-10 management_diagnostic_profile - keep
      # in sync with modules/terraform-azurerm-compeer-diagnostic-profile's
      # defaults (allLogs / AllMetrics). Only applies when a connector VM has
      # diagnostics.enabled = true but leaves logs/metrics unset - an
      # explicit value here always wins.
      logs = optional(map(object({
        category       = optional(string)
        category_group = optional(string)
      })), { allLogs = { category_group = "allLogs" } })
      metrics = optional(map(object({
        category = string
        enabled  = optional(bool, true)
      })), { AllMetrics = { category = "AllMetrics" } })
    }), {})
    extensions = optional(map(object({
      name                       = optional(string)
      publisher                  = string
      type                       = string
      type_handler_version       = string
      auto_upgrade_minor_version = optional(bool, true)
      automatic_upgrade_enabled  = optional(bool)
      settings                   = optional(any, {})
      protected_settings_key     = optional(string)
      tags                       = optional(map(string), {})
    })), {})
  }))
  default     = {}
  description = "Cloudflare connector VM infrastructure. Connector runtime tokens should be injected through approved sensitive variables or external configuration management."

  validation {
    condition     = alltrue([for connector in values(var.connectors) : contains(["Linux", "Windows"], connector.os_type)])
    error_message = "Connector os_type must be Linux or Windows. Existing Linux keys retain their resource addresses; changing OS requires a reviewed migration."
  }
}

# PHASE 2: no runtime token is passed through Terraform. Only secret references.
variable "windows_bootstrap" {
  description = "Windows cloudflared installation keyed by connector key. Pin version/hash; grant the VM system identity secret-scoped Key Vault RBAC. Changing rollout_revision reruns that replica only."
  type = map(object({
    cloudflared_version = string
    binary_sha256       = string
    key_vault_id        = string
    key_vault_uri       = string
    token_secret_name   = string
    rollout_revision    = string
    protocol            = optional(string, "auto")
  }))
  default = {}

  validation {
    condition = alltrue([for item in values(var.windows_bootstrap) :
      can(regex("^20[0-9]{2}\\.[0-9]{1,2}\\.[0-9]+$", item.cloudflared_version)) &&
      can(regex("^[A-Fa-f0-9]{64}$", item.binary_sha256)) &&
      can(regex("^https://[a-zA-Z0-9-]+\\.vault\\.azure\\.net/?$", item.key_vault_uri)) &&
      can(regex("^[a-zA-Z0-9-]{1,127}$", item.token_secret_name)) &&
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.KeyVault/vaults/[^/]+$", item.key_vault_id)) &&
      length(trimspace(item.rollout_revision)) > 0 && contains(["auto", "quic", "http2"], item.protocol)
    ])
    error_message = "Bootstrap requires a pinned release/version, SHA256, Azure public-cloud vault URI/ID, secret name, non-empty rollout revision and valid transport protocol."
  }
}

variable "require_windows_runtime" {
  type        = bool
  default     = false
  description = "Enforce Windows and a bootstrap entry for every connector. Enable for the Compeer production rollout; false retains legacy infrastructure-only consumers."
}

variable "admin_passwords" {
  type        = map(string)
  description = "Sensitive local administrator passwords keyed by connector key. Required only when password authentication is enabled."
  sensitive   = true
  default     = {}
}

variable "domain_join_passwords" {
  type        = map(string)
  sensitive   = true
  default     = {}
  description = "Domain-join credential map referenced by connector.domain_join.password_key. Scope the account to the approved OU; never commit passwords."
}

variable "custom_data_by_key" {
  type        = map(string)
  description = "Sensitive base64-encoded cloud-init custom data keyed by connector key."
  sensitive   = true
  default     = {}
}

variable "extension_protected_settings" {
  type        = map(string)
  description = "Sensitive JSON protected settings keyed by connector:extension key or extensions[*].protected_settings_key."
  sensitive   = true
  default     = {}
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string)
    scope_key                              = optional(string)
    scope                                  = optional(string)
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}
}

variable "management_locks" {
  type = map(object({
    name       = string
    scope_key  = optional(string)
    scope      = optional(string)
    lock_level = optional(string, "CanNotDelete")
    notes      = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for item in values(var.management_locks) :
      (
        (try(item.scope, null) != null || try(item.scope_key, null) != null) &&
        !(try(item.scope, null) != null && try(item.scope_key, null) != null)
      )
    ])
    error_message = "Each management lock must set exactly one of scope or scope_key."
  }
}

variable "additional_scopes" {
  type    = map(string)
  default = {}
}

variable "operational_contracts" {
  type        = any
  description = "No-resource operational controls, such as connector egress, Palo Alto policy, and tunnel health evidence."
  default     = {}
}
