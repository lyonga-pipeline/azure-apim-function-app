variable "enabled" {
  description = "Master switch for the Palo Alto hub pattern."
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Hub resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tags" {
  description = "Enterprise tags applied to supported resources."
  type        = map(string)
  default     = {}
}

variable "marketplace_agreement" {
  description = "Optional Azure Marketplace agreement for Palo Alto VM-Series images. Import existing agreement ownership before enabling if terms were accepted outside Terraform."
  type = object({
    enabled   = optional(bool, false)
    publisher = optional(string, "paloaltonetworks")
    offer     = optional(string, "vmseries-flex")
    plan      = optional(string, "bundle2")
  })
  default = {}
}

variable "bootstrap_storage_account" {
  description = "Optional storage account used for Palo Alto bootstrap artifacts."
  type = object({
    name                            = string
    account_replication_type        = optional(string, "ZRS")
    public_network_access_enabled   = optional(bool, false)
    shared_access_key_enabled       = optional(bool, true)
    default_to_oauth_authentication = optional(bool, false)
    network_rules                   = optional(any)
    file_shares = optional(map(object({
      quota = optional(number, 5)
    })), {})
  })
  default = null
}

variable "public_ips" {
  description = "Public IPs keyed by logical name for untrust/egress interfaces or public load balancers."
  type = map(object({
    name                    = string
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    domain_name_label       = optional(string)
    idle_timeout_in_minutes = optional(number, 4)
    zones                   = optional(list(string), ["1", "2", "3"])
  }))
  default = {}
}

variable "network_interfaces" {
  description = "Palo Alto NICs keyed by logical name."
  type = map(object({
    name                           = string
    ip_forwarding_enabled          = optional(bool, true)
    accelerated_networking_enabled = optional(bool, true)
    dns_servers                    = optional(list(string))
    ip_configurations = map(object({
      subnet_id                     = string
      private_ip_address_allocation = optional(string, "Static")
      private_ip_address            = optional(string)
      primary                       = optional(bool, true)
      public_ip_key                 = optional(string)
    }))
  }))
  default = {}
}

variable "load_balancers" {
  description = "Internal or public load balancers for trust/untrust HA paths."
  type = map(object({
    name = string
    sku  = optional(string, "Standard")
    frontend_ip_configurations = map(object({
      subnet_id                     = optional(string)
      private_ip_address            = optional(string)
      private_ip_address_allocation = optional(string, "Static")
      public_ip_key                 = optional(string)
      zones                         = optional(list(string), ["1", "2", "3"])
    }))
    backend_address_pools = optional(map(object({})), {})
    probes = optional(map(object({
      protocol            = string
      port                = number
      request_path        = optional(string)
      interval_in_seconds = optional(number, 5)
      number_of_probes    = optional(number, 2)
    })), {})
    rules = optional(map(object({
      protocol                       = string
      frontend_port                  = number
      backend_port                   = number
      frontend_ip_configuration_name = string
      backend_address_pool_names     = list(string)
      probe_name                     = optional(string)
      load_distribution              = optional(string, "Default")
      disable_outbound_snat          = optional(bool, false)
      idle_timeout_in_minutes        = optional(number, 4)
      enable_floating_ip             = optional(bool, true)
    })), {})
  }))
  default = {}
}

variable "virtual_machines" {
  description = "Palo Alto VM-Series instances keyed by logical name."
  type = map(object({
    name                            = string
    size                            = string
    admin_username                  = string
    zone                            = optional(string)
    network_interface_keys          = list(string)
    disable_password_authentication = optional(bool, true)
    admin_password                  = optional(string)
    admin_ssh_keys = optional(list(object({
      username   = string
      public_key = string
    })), [])
    os_disk = optional(object({
      name                 = optional(string)
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
      disk_size_gb         = optional(number)
    }), {})
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
      }), {
      publisher = "paloaltonetworks"
      offer     = "vmseries-flex"
      sku       = "bundle2"
      version   = "latest"
    })
    plan = optional(object({
      name      = string
      publisher = string
      product   = string
      }), {
      name      = "bundle2"
      publisher = "paloaltonetworks"
      product   = "vmseries-flex"
    })
    boot_diagnostics_storage_account_uri = optional(string)

    # Managed identity for the firewall VM (used for bootstrap-from-blob,
    # Key Vault access, monitoring). SystemAssigned by default.
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })

    # PAN-OS bootstrap. `mode`:
    #   "none"              - no custom_data (default)
    #   "azure-file-share"  - classic Azure Files bootstrap.
    #                         * Own storage: leave storage_account_name/key unset
    #                           and set var.bootstrap_storage_account; the pattern
    #                           reads the key from a data source.
    #                         * External storage (e.g. a phase-1 bootstrap
    #                           workspace): set BOTH storage_account_name and
    #                           storage_account_key.
    #                         The key is rendered into custom_data and therefore
    #                         into Terraform state either way.
    #   "custom-data"       - supply the init-cfg / userdata text directly in
    #                         `custom_data` (or `init_cfg_content`); the pattern
    #                         base64-encodes it. No storage key in state.
    #                         Typical init-cfg: type=dhcp-client, hostname,
    #                         vm-auth-key, plugin-op-commands=set-cores:<n>,
    #                         panorama-server / tplname / dgname.
    bootstrap = optional(object({
      mode                 = optional(string, "none")
      storage_account_name = optional(string)
      storage_account_key  = optional(string)
      file_share_name      = optional(string, "bootstrap")
      share_directory      = optional(string, "None")
      custom_data          = optional(string)
      init_cfg_content     = optional(string)
    }), { mode = "none" })
  }))
  default = {}

  validation {
    condition = alltrue([
      for vm in values(var.virtual_machines) :
      contains(["none", "azure-file-share", "custom-data"], try(vm.bootstrap.mode, "none"))
    ])
    error_message = "virtual_machines[*].bootstrap.mode must be none, azure-file-share, or custom-data."
  }

  validation {
    # For an externally-owned bootstrap account, name + key are both required.
    # When the caller supplies neither, this pattern's own bootstrap storage is
    # used and the key is read from a data source (var.bootstrap_storage_account
    # must then be set - checked by a resource precondition).
    condition = alltrue([
      for vm in values(var.virtual_machines) :
      try(vm.bootstrap.mode, "none") != "azure-file-share" ? true :
      (try(vm.bootstrap.storage_account_name, null) == null && try(vm.bootstrap.storage_account_key, null) == null) ||
      (try(vm.bootstrap.storage_account_name, null) != null && try(vm.bootstrap.storage_account_key, null) != null)
    ])
    error_message = "bootstrap.mode = azure-file-share: supply BOTH storage_account_name and storage_account_key (external account), or NEITHER (use this pattern's bootstrap_storage_account)."
  }

  validation {
    condition = alltrue([
      for vm in values(var.virtual_machines) :
      try(vm.bootstrap.mode, "none") != "custom-data" ? true :
      (try(vm.bootstrap.custom_data, null) != null || try(vm.bootstrap.init_cfg_content, null) != null)
    ])
    error_message = "bootstrap.mode = custom-data requires bootstrap.custom_data or bootstrap.init_cfg_content."
  }
}

variable "bootstrap_share_layout" {
  description = <<-EOT
    Directory / file layout to lay down inside bootstrap file shares, keyed by
    share name (must also appear in bootstrap_storage_account.file_shares).
    Default creates the four PAN-OS bootstrap folders. Provide `files` to upload
    an init-cfg.txt / bootstrap.xml from a local path or inline content.
  EOT
  type = map(object({
    directories = optional(list(string), ["config", "content", "license", "software"])
    files = optional(map(object({
      path        = optional(string) # directory within the share, e.g. "config"
      source_path = optional(string) # local file to upload
      content     = optional(string) # inline content (mutually exclusive with source_path)
    })), {})
  }))
  default = {}
}


variable "bootstrap_key_vault" {
  description = <<-EOT
    Optional Key Vault for firewall cert authentication / Panorama secrets. The
    firewall VM managed identities are granted "Key Vault Certificates User" +
    "Key Vault Secrets User" automatically.

    Default network posture is PRIVATE. `network.mode = "selected"` opens
    public access to an IP / subnet allow-list (documented exception only - the
    keyvault module rejects an empty allow-list).
  EOT
  type = object({
    name                       = string
    tenant_id                  = string
    sku_name                   = optional(string, "premium")
    purge_protection_enabled   = optional(bool, true)
    soft_delete_retention_days = optional(number, 90)
    network = optional(object({
      mode               = optional(string, "private")
      allowed_ip_ranges  = optional(list(string), [])
      allowed_subnet_ids = optional(list(string), [])
    }), {})
    private_endpoint = optional(object({
      name                 = string
      subnet_id            = string
      private_dns_zone_ids = optional(list(string), [])
    }))
  })
  default = null

  validation {
    condition     = var.bootstrap_key_vault == null ? true : contains(["private", "selected"], try(var.bootstrap_key_vault.network.mode, "private"))
    error_message = "bootstrap_key_vault.network.mode must be private or selected."
  }
}
