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
  }))
  default = {}
}

variable "vendor_vmseries" {
  description = "Optional Palo Alto Networks swfw-modules VM-Series instances keyed by logical name. Do not configure alongside virtual_machines."
  type        = map(any)
  default     = {}
}

variable "vendor_vmseries_passwords" {
  description = "Sensitive VM-Series admin passwords keyed by vendor_vmseries key. Use HCP sensitive variables or approved secret store injection."
  type        = map(string)
  sensitive   = true
  default     = {}
}
