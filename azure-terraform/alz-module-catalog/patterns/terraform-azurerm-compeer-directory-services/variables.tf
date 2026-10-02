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

# ADR (23 Sep 2026, deploy-runbook.tf / resource-placement sheet): domain
# controllers move off the hub VNet into a dedicated identity VNet
# (platform-<region>-<env>-identity-vnet), peered to the hub, isolating the
# Tier 0 identity plane from the connectivity subscription. This reverses
# the earlier hub-hosted DC placement. null keeps the legacy shape (a
# caller-supplied subnet_id, e.g. still on the hub) for anyone not yet
# migrated; set this to create and own the identity VNet here instead.
variable "identity_vnet" {
  description = "Dedicated identity virtual network for domain controllers and DNS, peered to the hub. null = do not create one (domain_controllers must then supply an external subnet_id directly, e.g. a hub subnet)."
  type = object({
    name          = string
    address_space = list(string)
    dns_servers   = optional(list(string))
    subnets = optional(map(object({
      address_prefixes = list(string)
      route_table_key  = optional(string)
      nsg_key          = optional(string)
    })), {})
  })
  default = null
}

# Mirrors workload-spoke's hub_connection shape exactly - the identity VNet is
# architecturally a peered spoke of the hub, even though it is platform-tier.
variable "hub_connection" {
  description = "Peers identity_vnet to the hub. null = no peering (leaves identity_vnet isolated - only useful for a smoke test)."
  type = object({
    hub_virtual_network_id  = string
    allow_forwarded_traffic = optional(bool, true)
    allow_gateway_transit   = optional(bool, false)
    use_remote_gateways     = optional(bool, false)
  })
  default = null
}

variable "network_security_groups" {
  type = map(object({
    name = string
    rules = optional(map(object({
      protocol                                   = string
      access                                     = string
      priority                                   = number
      direction                                  = string
      description                                = optional(string)
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
    })), {})
  }))
  default     = {}
  description = "Network security groups for identity_vnet's subnets, referenced by subnet.nsg_key."
}

variable "route_tables" {
  type = map(object({
    name                          = string
    bgp_route_propagation_enabled = optional(bool)
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  }))
  default     = {}
  description = "Route tables for identity_vnet's subnets, referenced by subnet.route_table_key - typically routing DC traffic through the hub firewall."
}

variable "subnet_nsg_associations" {
  type = map(object({
    subnet_key = string
    nsg_key    = string
  }))
  default     = {}
  description = "Explicit subnet-to-NSG associations beyond the inline identity_vnet.subnets[*].nsg_key hints."
}

variable "subnet_route_table_associations" {
  type = map(object({
    subnet_key      = string
    route_table_key = string
  }))
  default     = {}
  description = "Explicit subnet-to-route-table associations beyond the inline identity_vnet.subnets[*].route_table_key hints."
}

variable "recovery_services_vaults" {
  type = map(object({
    name                               = optional(string)
    sku                                = optional(string, "Standard")
    storage_mode_type                  = optional(string, "GeoRedundant")
    public_network_access_enabled      = optional(bool)
    immutability                       = optional(string)
    cross_region_restore_enabled       = optional(bool)
    classic_vmware_replication_enabled = optional(bool)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    encryption = optional(object({
      key_id                            = string
      infrastructure_encryption_enabled = optional(bool)
      use_system_assigned_identity      = optional(bool)
      user_assigned_identity_id         = optional(string)
    }))
    monitoring = optional(object({
      alerts_for_all_job_failures_enabled            = optional(bool)
      alerts_for_all_failover_issues_enabled         = optional(bool)
      alerts_for_all_replication_issues_enabled      = optional(bool)
      alerts_for_critical_operation_failures_enabled = optional(bool)
      email_notifications_for_site_recovery_enabled  = optional(bool)
    }))
    backup_policy_vm         = optional(any, {})
    backup_policy_file_share = optional(any, {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  description = "Recovery Services vault(s) this pattern creates and owns directly - e.g. platform-cus-prod-identity-rsv for DC backups, kept in the identity subscription rather than shared with platform-management's vault. Distinct from dc_backup below, which enrols VMs against a vault (this one or an external one)."
  default     = {}
}

variable "domain_controllers" {
  type = map(object({
    name                           = string
    nic_name                       = string
    subnet_id                      = optional(string)
    subnet_key                     = optional(string)
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
      # Platform_Output_Contracts_IAC-10 management_diagnostic_profile - keep
      # in sync with modules/terraform-azurerm-compeer-diagnostic-profile's
      # defaults (allLogs / AllMetrics). Only applies when a domain
      # controller has diagnostics.enabled = true but leaves logs/metrics
      # unset - an explicit value here always wins.
      logs = optional(map(object({
        category       = optional(string)
        category_group = optional(string)
      })), { allLogs = { category_group = "allLogs" } })
      metrics = optional(map(object({
        category = string
        enabled  = optional(bool, true)
      })), { AllMetrics = { category = "AllMetrics" } })
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
  description = "Domain controller VM infrastructure (VM/NIC/disks/domain-join). AD DS role installation, domain-controller promotion, DNS forwarders, and AD Sites configuration are not Terraform-owned - handled manually or via the approved Ansible/DSC pipeline once the VM has joined the domain."
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
    lock_level = optional(string, "CanNotDelete")
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
    Enrol domain-controller VMs into a recovery-services vault. `vault_name` /
    `vault_resource_group_name` default to this pattern's own
    recovery_services_vaults["identity"] (if set) - the dedicated identity-
    subscription vault, per the 23 Sep 2026 placement decision. Set them
    explicitly only to point at a different, externally-managed vault during
    migration/import. `backup_policy_key` resolves a VM backup policy created
    in recovery_services_vaults["identity"]; `default_backup_policy_id` is for
    external policies. Per-controller `backup_policy_id` wins over either
    default. Keys of `protected_controllers` must match `domain_controllers`
    keys.
  EOT
  type = object({
    vault_name                = optional(string)
    vault_resource_group_name = optional(string)
    backup_policy_key         = optional(string)
    default_backup_policy_id  = optional(string)
    protected_controllers = map(object({
      backup_policy_id = optional(string)
    }))
  })
  default = null
}
