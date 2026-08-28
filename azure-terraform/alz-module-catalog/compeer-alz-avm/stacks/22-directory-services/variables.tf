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

variable "domain_controllers" {
  description = "Central US AD DS/DNS servers."
  type = map(object({
    name                           = string
    computer_name                  = optional(string)
    network_interface_name         = string
    subnet_id                      = string
    private_ip_address_allocation  = optional(string, "Static")
    private_ip_address             = optional(string)
    dns_servers                    = optional(list(string))
    accelerated_networking_enabled = optional(bool, true)
    vm_size                        = optional(string, "Standard_D2s_v5")
    admin_username                 = optional(string, "azureadmin")
    zone                           = optional(string)
    availability_set_id            = optional(string)
    source_image_id                = optional(string)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    license_type               = optional(string, "Windows_Server")
    timezone                   = optional(string, "UTC")
    patch_mode                 = optional(string, "AutomaticByPlatform")
    patch_assessment_mode      = optional(string, "AutomaticByPlatform")
    secure_boot_enabled        = optional(bool, true)
    vtpm_enabled               = optional(bool, true)
    encryption_at_host_enabled = optional(bool, true)
    boot_diagnostics = optional(object({
      storage_account_uri = optional(string)
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
      caching              = optional(string, "ReadOnly")
    })), {})
    domain_join = optional(object({
      name            = optional(string, "domain-join")
      domain_name     = string
      ou_path         = optional(string)
      domain_username = string
      restart         = optional(bool, true)
      join_options    = optional(number, 3)
    }))
  }))
  default = {}
}

variable "admin_passwords" {
  description = "Per-domain-controller local admin passwords."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "domain_join_passwords" {
  description = "Per-domain-controller domain join passwords when domain_join is configured."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "operational_contracts" {
  description = "AD DS promotion, DNS forwarder, and replication validation controls."
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
