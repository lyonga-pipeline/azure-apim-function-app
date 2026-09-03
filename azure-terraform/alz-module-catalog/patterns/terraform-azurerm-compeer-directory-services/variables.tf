variable "subscription_id" {
  type        = string
  description = "Directory-services subscription ID."
}

variable "location" {
  type        = string
  description = "Azure region for directory-services resources."
}

variable "environment" {
  type        = string
  description = "Environment key, such as np or prod."
}

variable "platform_tags" {
  type = object({
    application           = optional(string)
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
    additional_tags       = optional(map(string), {})
  })
  default = {}
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "domain_controllers" {
  type = map(object({
    name                           = string
    nic_name                       = string
    subnet_id                      = string
    private_ip_address             = string
    private_ip_address_allocation  = optional(string, "Static")
    ip_configuration_name          = optional(string, "primary")
    dns_servers                    = optional(list(string))
    accelerated_networking_enabled = optional(bool, true)
    ip_forwarding_enabled          = optional(bool, false)
    vm_size                        = optional(string, "Standard_D2s_v5")
    admin_username                 = optional(string, "azureadmin")
    computer_name                  = optional(string)
    zone                           = optional(string)
    availability_set_id            = optional(string)
    source_image_id                = optional(string)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    plan                       = optional(any)
    license_type               = optional(string, "Windows_Server")
    timezone                   = optional(string, "UTC")
    provision_vm_agent         = optional(bool, true)
    allow_extension_operations = optional(bool, true)
    automatic_updates_enabled  = optional(bool)
    enable_automatic_updates   = optional(bool) # deprecated alias for automatic_updates_enabled
    patch_mode                 = optional(string, "AutomaticByPlatform")
    patch_assessment_mode      = optional(string, "AutomaticByPlatform")
    hotpatching_enabled        = optional(bool, false)
    secure_boot_enabled        = optional(bool, true)
    vtpm_enabled               = optional(bool, true)
    encryption_at_host_enabled = optional(bool, true)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    boot_diagnostics = optional(object({
      storage_account_uri = optional(string)
    }))
    additional_capabilities = optional(object({
      ultra_ssd_enabled = optional(bool, false)
    }))
    os_disk = optional(object({
      caching                   = string
      storage_account_type      = string
      disk_size_gb              = optional(number)
      name                      = optional(string)
      write_accelerator_enabled = optional(bool)
      disk_encryption_set_id    = optional(string)
    }))
    data_disks = optional(map(object({
      name                 = string
      lun                  = number
      disk_size_gb         = number
      storage_account_type = optional(string, "Premium_LRS")
      create_option        = optional(string, "Empty")
      caching              = optional(string, "ReadOnly")
      zone                 = optional(string)
    })), {})
    diagnostics = optional(object({
      enabled                        = optional(bool, false)
      name                           = optional(string)
      log_analytics_workspace_id     = optional(string)
      storage_account_id             = optional(string)
      eventhub_authorization_rule_id = optional(string)
      eventhub_name                  = optional(string)
      partner_solution_id            = optional(string)
      log_analytics_destination_type = optional(string)
      logs = optional(map(object({
        category       = optional(string)
        category_group = optional(string)
      })), {})
      metrics = optional(map(object({
        category = string
        enabled  = optional(bool, true)
      })), {})
    }), {})
    ad_ds_role_install = optional(object({
      enabled                  = optional(bool, false)
      name                     = optional(string, "install-ad-dns")
      features                 = optional(list(string), ["AD-Domain-Services", "DNS"])
      include_management_tools = optional(bool, true)
      script_version           = optional(string, "v1")
      type_handler_version     = optional(string, "1.10")
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    }), {})
    ad_ds_promotion = optional(object({
      enabled                      = optional(bool, false)
      name                         = optional(string, "promote-to-dc")
      domain_name                  = optional(string)
      domain_admin_username        = optional(string)
      domain_admin_password_key    = optional(string)
      safe_mode_admin_password_key = optional(string)
      site_name                    = optional(string)
      features                     = optional(list(string), ["AD-Domain-Services", "DNS"])
      include_management_tools     = optional(bool, true)
      install_dns                  = optional(bool, true)
      no_global_catalog            = optional(bool, false)
      critical_replication_only    = optional(bool, false)
      no_reboot_on_completion      = optional(bool, true)
      force                        = optional(bool, true)
      script_version               = optional(string, "v1")
      type_handler_version         = optional(string, "1.10")
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        read   = optional(string)
        delete = optional(string)
      }), {})
    }), {})
    domain_join = optional(object({
      enabled              = optional(bool, false)
      name                 = optional(string, "domain-join")
      domain_name          = string
      ou_path              = optional(string)
      domain_username      = string
      domain_password_key  = optional(string)
      restart              = optional(bool, true)
      join_options         = optional(number, 3)
      type_handler_version = optional(string, "1.3")
    }))
  }))
  default     = {}
  description = "Domain controller VM infrastructure with optional AD DS role-install and promotion extensions. AD promotion, DNS forwarders, and AD Sites configuration should remain outside Terraform unless explicitly approved by the AD/platform owners."
}

variable "admin_passwords" {
  type        = map(string)
  description = "Sensitive local administrator passwords keyed by domain controller key."
  sensitive   = true
  default     = {}
}

variable "domain_join_passwords" {
  type        = map(string)
  description = "Sensitive domain-join passwords keyed by domain controller key or domain_join.domain_password_key."
  sensitive   = true
  default     = {}
}

variable "ad_ds_promotion_passwords" {
  type        = map(string)
  description = "Sensitive AD DS promotion passwords keyed by domain controller key or ad_ds_promotion password keys. Used only when ad_ds_promotion.enabled is true."
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
  default     = {}
  description = "Optional RBAC assignments scoped to directory-services resources."

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      (
        (try(assignment.scope, null) != null || try(assignment.scope_key, null) != null) &&
        !(try(assignment.scope, null) != null && try(assignment.scope_key, null) != null)
      )
    ])
    error_message = "Each role assignment must set exactly one of scope or scope_key."
  }
}

variable "management_locks" {
  type = map(object({
    name       = string
    scope_key  = optional(string)
    scope      = optional(string)
    lock_level = string
    notes      = optional(string)
  }))
  default     = {}
  description = "Optional management locks for directory-services resources."

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
  type        = map(string)
  description = "Additional named scopes that can be referenced by locks or role assignments."
  default     = {}
}

variable "operational_contracts" {
  type        = any
  description = "No-resource operational controls, such as AD promotion, DNS cutover, and backup evidence contracts."
  default     = {}
}

variable "dc_backup" {
  description = <<-EOT
    Enrol domain-controller VMs into an existing recovery-services vault
    (backup policies are created by platform-management). `vault_name` +
    `vault_resource_group_name` identify the vault; `default_backup_policy_id`
    is used unless a controller overrides it. Keys of `protected_controllers`
    must match `domain_controllers` keys.
  EOT
  type = object({
    vault_name                = string
    vault_resource_group_name = string
    default_backup_policy_id  = string
    protected_controllers = map(object({
      backup_policy_id = optional(string)
    }))
  })
  default = null
}
