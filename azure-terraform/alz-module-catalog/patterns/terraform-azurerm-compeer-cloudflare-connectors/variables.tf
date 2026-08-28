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
    application         = string
    business_owner      = string
    source_repo         = string
    terraform_workspace = string
    recovery_tier       = string
    cost_center         = string
    data_classification = string
    compliance_boundary = string
    additional_tags     = optional(map(string), {})
  })
}

variable "resource_group" {
  type = object({
    name = string
  })
}

variable "connectors" {
  type = map(object({
    name                            = string
    nic_name                        = string
    subnet_id                       = string
    private_ip_address              = optional(string)
    private_ip_address_allocation   = optional(string, "Dynamic")
    ip_configuration_name           = optional(string, "primary")
    dns_servers                     = optional(list(string))
    accelerated_networking_enabled  = optional(bool, true)
    ip_forwarding_enabled           = optional(bool, false)
    vm_size                         = optional(string, "Standard_D2s_v5")
    zone                            = optional(string)
    computer_name                   = optional(string)
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
      logs = optional(map(object({
        category       = optional(string)
        category_group = optional(string)
      })), {})
      metrics = optional(map(object({
        category = string
        enabled  = optional(bool, true)
      })), {})
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
}

variable "admin_passwords" {
  type        = map(string)
  description = "Sensitive local administrator passwords keyed by connector key. Required only when password authentication is enabled."
  sensitive   = true
  default     = {}
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
    lock_level = string
    notes      = optional(string)
  }))
  default = {}
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
