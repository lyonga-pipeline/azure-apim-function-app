variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "resource_group_name" {
  type = string
}

variable "bootstrap_storage_name" {
  description = "Compeer HCP storage account used for Palo Alto bootstrap artifacts."
  type        = string
}

variable "bootstrap_storage_replication_type" {
  type    = string
  default = "ZRS"
}

variable "bootstrap_storage_public_network_access_enabled" {
  type    = bool
  default = false
}

variable "bootstrap_storage_shared_access_key_enabled" {
  type    = bool
  default = false
}

variable "bootstrap_storage_network_rules" {
  type = object({
    default_action             = string
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "bootstrap_file_share" {
  description = "Optional Palo bootstrap file share. Bootstrap file contents are supplied outside this root."
  type = object({
    name             = string
    quota_gb         = optional(number, 50)
    enabled_protocol = optional(string, "SMB")
    metadata         = optional(map(string), {})
  })
  default = null
}

variable "bootstrap_storage_private_endpoint" {
  description = "Optional private endpoint for the bootstrap storage account."
  type = object({
    subnet_id            = string
    subresource_name     = optional(string, "file")
    private_dns_zone_ids = optional(list(string), [])
  })
  default = null
}

variable "bootstrap_storage_role_assignments" {
  description = "Optional role assignments scoped to the bootstrap storage account."
  type = map(object({
    scope                = string
    role_definition_id   = optional(string)
    role_definition_name = optional(string)
    principal_id         = string
    principal_type       = optional(string)
  }))
  default = {}
}

variable "marketplace_agreements" {
  description = "Optional marketplace agreements for Palo Alto VM-Series plans."
  type = map(object({
    publisher = string
    offer     = string
    plan      = string
  }))
  default = {}
}

variable "appliances" {
  description = "Palo Alto VM-Series appliances keyed by logical instance."
  type = map(object({
    name                            = string
    vm_size                         = string
    zone                            = optional(string)
    admin_username                  = optional(string, "azureadmin")
    disable_password_authentication = optional(bool, false)
    admin_ssh_keys = optional(list(object({
      username   = string
      public_key = string
    })), [])
    interface_order             = list(string)
    custom_data                 = optional(string)
    provision_vm_agent          = optional(bool, true)
    allow_extension_operations  = optional(bool, true)
    encryption_at_host_enabled  = optional(bool, true)
    secure_boot_enabled         = optional(bool, false)
    vtpm_enabled                = optional(bool, false)
    patch_mode                  = optional(string, "ImageDefault")
    diagnostic_settings_enabled = optional(bool, true)
    source_image_id             = optional(string)
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
    interfaces = map(object({
      name                           = string
      subnet_id                      = string
      ip_configuration_name          = optional(string, "primary")
      private_ip_address_allocation  = optional(string, "Static")
      private_ip_address             = optional(string)
      dns_servers                    = optional(list(string))
      accelerated_networking_enabled = optional(bool, true)
      ip_forwarding_enabled          = optional(bool, true)
      load_balancer_backend_pool_id  = optional(string)
      public_ip = optional(object({
        name                    = string
        allocation_method       = optional(string, "Static")
        sku                     = optional(string, "Standard")
        sku_tier                = optional(string, "Regional")
        ip_version              = optional(string, "IPv4")
        domain_name_label       = optional(string)
        idle_timeout_in_minutes = optional(number, 4)
        public_ip_prefix_id     = optional(string)
        reverse_fqdn            = optional(string)
        zones                   = optional(list(string), ["1", "2", "3"])
      }))
    }))
  }))
  default = {}
}

variable "admin_passwords" {
  description = "Per-appliance local admin passwords. Required for appliances with password authentication enabled."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "operational_contracts" {
  description = "Firewall policies and Panorama controls that remain outside Azure resource deployment."
  type = map(object({
    phase                = optional(string, "Phase 1")
    owner                = optional(string)
    enabled              = optional(bool, false)
    cost_disabled        = optional(bool, true)
    implementation_state = optional(string, "contract-only")
    required_controls    = optional(list(string), [])
    evidence_locations   = optional(list(string), [])
    notes                = optional(string)
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
