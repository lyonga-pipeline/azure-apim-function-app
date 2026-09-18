output "region_short" {
  description = "Resolved region short code (e.g. centralus -> cus)."
  value       = local.region
}

output "all" {
  description = "Every computed name as a single map (nulls included). Prefer the individual outputs."
  value       = local.names
}

output "discriminator" {
  description = "Resolved root discriminator (component for platform, appcode|domain for workload)."
  value       = local.disc
}

output "stem" {
  description = "The <disc>-<region>-<env> stem used by the keyed rows."
  value       = local.stem
}

# ---- Keyed collections: <resource>_names = { <map key> => <name> } ---------

output "key_vault_names" {
  description = "Key Vault name per key_vault_keys entry. See README."
  value       = local.keyed.key_vault

  precondition {
    condition     = alltrue([for n in values(local.keyed.key_vault) : length(n) >= 3 && length(n) <= 24 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", n))])
    error_message = "Key Vault names must be 3-24 chars: ${jsonencode({ for k, n in local.keyed.key_vault : k => "${n} (${length(n)})" if length(n) > 24 || length(n) < 3 })}. Shorten the appcode/component abbreviation or the caller-controlled key."
  }
}

output "storage_account_names" {
  description = "Storage account name per storage_account_keys entry. See README."
  value       = local.keyed.storage_account

  precondition {
    condition     = alltrue([for n in values(local.keyed.storage_account) : length(n) >= 3 && length(n) <= 24 && can(regex("^[a-z0-9]+$", n))])
    error_message = "a storage account name is invalid (3-24 lowercase alphanumerics): ${jsonencode(local.keyed.storage_account)}. Shorten the component/appcode or the map key."
  }
}

output "user_assigned_identity_names" {
  description = "User-assigned identity name per user_assigned_identity_keys entry."
  value       = local.keyed.user_assigned_identity

  precondition {
    condition     = alltrue([for n in values(local.keyed.user_assigned_identity) : length(n) >= 3 && length(n) <= 128])
    error_message = "a user-assigned identity name is outside Azure's 3-128 character limit: ${jsonencode({ for k, n in local.keyed.user_assigned_identity : k => length(n) if length(n) < 3 || length(n) > 128 })}."
  }
}

output "function_app_names" {
  description = "Function App name per function_app_keys instance number. See README."
  value       = local.keyed.function_app

  precondition {
    condition = alltrue([
      for n in values(local.keyed.function_app) : length(n) >= 2 && length(n) <= 60 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", n))
    ])
    error_message = "a function app name is outside Azure's 2-60 character, alphanumeric-and-hyphen (no leading/trailing hyphen) limit: ${jsonencode({ for k, n in local.keyed.function_app : k => "${n} (${length(n)})" if length(n) < 2 || length(n) > 60 || !can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", n)) })}."
  }
}

output "nsg_names" {
  description = "NSG name per nsg_keys entry."
  value       = local.keyed.nsg
}

output "route_table_names" {
  description = "Route table name per route_table_keys entry."
  value       = local.keyed.route_table
}

output "network_interface_names" {
  description = "NIC name per network_interface_keys entry."
  value       = local.keyed.network_interface

  precondition {
    condition     = alltrue([for n in values(local.keyed.network_interface) : length(n) >= 1 && length(n) <= 80])
    error_message = "a network interface name exceeds Azure's 80-character limit: ${jsonencode({ for k, n in local.keyed.network_interface : k => length(n) if length(n) > 80 })}. Shorten the component/appcode or the map key."
  }
}

output "private_endpoint_names" {
  description = "Private endpoint name per private_endpoint_keys entry."
  value       = local.keyed.private_endpoint

  precondition {
    condition     = alltrue([for n in values(local.keyed.private_endpoint) : length(n) >= 1 && length(n) <= 80])
    error_message = "a private endpoint name exceeds Azure's 80-character limit: ${jsonencode({ for k, n in local.keyed.private_endpoint : k => length(n) if length(n) > 80 })}. Shorten the component/appcode or the map key."
  }
}

output "public_ip_names" {
  description = "Public IP name per public_ip_keys entry."
  value       = local.keyed.public_ip

  precondition {
    condition     = alltrue([for n in values(local.keyed.public_ip) : length(n) >= 1 && length(n) <= 80])
    error_message = "a public IP name exceeds Azure's 80-character limit: ${jsonencode({ for k, n in local.keyed.public_ip : k => length(n) if length(n) > 80 })}. Shorten the component/appcode or the map key."
  }
}

output "load_balancer_names" {
  description = "Load balancer name per load_balancer_keys entry."
  value       = local.keyed.load_balancer

  precondition {
    condition     = alltrue([for n in values(local.keyed.load_balancer) : length(n) >= 1 && length(n) <= 80])
    error_message = "a load balancer name exceeds Azure's 80-character limit: ${jsonencode({ for k, n in local.keyed.load_balancer : k => length(n) if length(n) > 80 })}. Shorten the stem (component/domain/appcode) or the map key."
  }
}

output "virtual_machine_names" {
  description = "VM name per virtual_machine_keys entry. See README."
  value       = local.keyed.virtual_machine

  precondition {
    condition     = alltrue([for n in values(local.keyed.virtual_machine) : length(n) >= 1 && length(n) <= 64])
    error_message = "a virtual machine name exceeds Azure's 64-character resource-name limit: ${jsonencode({ for k, n in local.keyed.virtual_machine : k => length(n) if length(n) > 64 })}. Shorten the stem (component/domain/appcode) or the map key."
  }
}

output "disk_names" {
  description = "Managed disk name per disk_keys entry."
  value       = local.keyed.disk
}

output "recovery_services_vault_names" {
  description = "Recovery Services vault name per recovery_services_vault_keys entry."
  value       = local.keyed.recovery_services_vault
}

output "subnet_names" {
  description = "Subnet name per subnet_keys entry (non-reserved subnets only)."
  value       = local.keyed.subnet
}

# ---- Management groups ----
output "mg_enterprise" {
  description = "Landing-zone root management group."
  value       = local.names.mg_enterprise
}
output "mg_platform" {
  description = "Platform management group."
  value       = local.names.mg_platform
}
output "mg_workloads" {
  description = "Workloads management group."
  value       = local.names.mg_workloads
}
output "mg_sandbox" {
  description = "Sandbox management group."
  value       = local.names.mg_sandbox
}
output "mg_decommissioned" {
  description = "Decommissioned management group."
  value       = local.names.mg_decommissioned
}
output "mg" {
  description = "Any <domain>-mg management group. Needs `domain`."
  value       = local.names.mg
}
output "mg_environment" {
  description = "Any <domain>-<env>-mg management group. Needs `domain`."
  value       = local.names.mg_environment
}
output "mg_workload_domain" {
  description = "Compatibility alias of `mg`. See README."
  value       = local.names.mg_workload_domain
}
output "mg_workload_domain_environment" {
  description = "Compatibility alias of `mg_environment`. See README."
  value       = local.names.mg_workload_domain_environment
}

# ---- Subscriptions ----
output "subscription_platform" {
  description = "Platform subscription."
  value       = local.names.subscription_platform
}
output "subscription_identity" {
  description = "Identity subscription."
  value       = local.names.subscription_identity
}
output "subscription_connectivity" {
  description = "Connectivity subscription."
  value       = local.names.subscription_connectivity
}
output "subscription_management" {
  description = "Management subscription."
  value       = local.names.subscription_management
}
output "subscription_workload" {
  description = "Workload subscription. Needs `name`."
  value       = local.names.subscription_workload
}
output "subscription_scoped" {
  description = "Generic scoped subscription. Needs `purpose`."
  value       = local.names.subscription_scoped
}

# ---- Networking ----
output "hub_vnet" {
  description = "Hub virtual network."
  value       = local.names.hub_vnet
}
output "shared_vnet" {
  description = "Shared-services virtual network."
  value       = local.names.shared_vnet
}
output "subnet" {
  description = "Compatibility single subnet. Needs `purpose`. Prefer subnet_keys."
  value       = local.names.subnet
}
output "nsg" {
  description = "Compatibility single NSG. Needs `purpose`. Prefer nsg_keys."
  value       = local.names.nsg
}
output "route_table" {
  description = "Compatibility single route table. Needs `destination`. Prefer route_table_keys."
  value       = local.names.route_table
}
output "public_ip" {
  description = "Compatibility single public IP. Needs `resource`. Prefer public_ip_keys."
  value       = local.names.public_ip

  precondition {
    condition     = local.names.public_ip == null ? true : length(local.names.public_ip) <= 80
    error_message = "public_ip name exceeds Azure's 80-character limit (${try(length(local.names.public_ip), 0)} chars). Shorten `resource`."
  }
}
output "workload_vnet" {
  description = "Workload spoke VNet. Needs `domain`."
  value       = local.names.workload_vnet
}
output "network_interface" {
  description = "Compatibility single NIC. Needs `resource`. Prefer network_interface_keys."
  value       = local.names.network_interface

  precondition {
    condition     = local.names.network_interface == null ? true : length(local.names.network_interface) <= 80
    error_message = "network_interface name exceeds Azure's 80-character limit (${try(length(local.names.network_interface), 0)} chars). Shorten `resource`."
  }
}
output "private_endpoint" {
  description = "Compatibility single private endpoint. Needs `resource`. Prefer private_endpoint_keys."
  value       = local.names.private_endpoint

  precondition {
    condition     = local.names.private_endpoint == null ? true : length(local.names.private_endpoint) <= 80
    error_message = "private_endpoint name exceeds Azure's 80-character limit (${try(length(local.names.private_endpoint), 0)} chars). Shorten `resource`."
  }
}
output "nat_gateway" {
  description = "Platform NAT gateway."
  value       = local.names.nat_gateway
}
output "route_server" {
  description = "Platform route server."
  value       = local.names.route_server
}
output "ddos_protection_plan" {
  description = "Platform DDoS protection plan."
  value       = local.names.ddos_protection_plan
}
output "private_dns_resolver" {
  description = "Platform private DNS resolver."
  value       = local.names.private_dns_resolver
}
output "bastion" {
  description = "Platform Bastion host."
  value       = local.names.bastion
}

# ---- Firewall / edge ----
output "firewall_vm" {
  description = "Palo Alto firewall VM. Uses `instance`."
  value       = local.names.firewall_vm
}
output "firewall_ilb" {
  description = "Firewall internal load balancer."
  value       = local.names.firewall_ilb
}
output "expressroute_gateway" {
  description = "ExpressRoute gateway."
  value       = local.names.expressroute_gateway
}
output "vpn_gateway" {
  description = "VPN gateway."
  value       = local.names.vpn_gateway
}
output "cloudflare_connector" {
  description = "Cloudflare Tunnel connector. Uses `instance`."
  value       = local.names.cloudflare_connector
}
output "expressroute_circuit" {
  description = "ExpressRoute circuit."
  value       = local.names.expressroute_circuit
}
output "expressroute_connection" {
  description = "ExpressRoute connection."
  value       = local.names.expressroute_connection
}
output "vpn_local_network_gateway" {
  description = "VPN local network gateway."
  value       = local.names.vpn_local_network_gateway
}
output "vpn_connection" {
  description = "VPN connection."
  value       = local.names.vpn_connection
}
output "domain_controller_vm" {
  description = "Domain controller VM. Uses `instance`. See README."
  value       = local.names.domain_controller_vm
}
output "load_balancer" {
  description = "Compatibility single internal load balancer. Needs `purpose`. Prefer load_balancer_keys."
  value       = local.names.load_balancer

  precondition {
    condition     = local.names.load_balancer == null ? true : length(local.names.load_balancer) <= 80
    error_message = "load_balancer name exceeds Azure's 80-character limit (${try(length(local.names.load_balancer), 0)} chars). Shorten `purpose`."
  }
}

# ---- Observability / recovery ----
output "log_analytics_workspace" {
  description = "Log Analytics workspace."
  value       = local.names.log_analytics_workspace

  precondition {
    condition     = length(local.names.log_analytics_workspace) >= 4 && length(local.names.log_analytics_workspace) <= 63
    error_message = "Log Analytics workspace name must be 4-63 characters."
  }
}
output "monitor_workspace" {
  description = "Azure Monitor workspace."
  value       = local.names.monitor_workspace
}
output "automation_account" {
  description = "Automation account."
  value       = local.names.automation_account

  precondition {
    condition     = length(local.names.automation_account) >= 6 && length(local.names.automation_account) <= 50 && can(regex("^[a-zA-Z]", local.names.automation_account))
    error_message = "Automation account name must be 6-50 chars and start with a letter."
  }
}
output "action_group" {
  description = "Monitor action group."
  value       = local.names.action_group
}
output "recovery_services_vault" {
  description = "Compatibility single Recovery Services vault. Prefer recovery_services_vault_keys."
  value       = local.names.recovery_services_vault

  precondition {
    condition     = length(local.names.recovery_services_vault) >= 2 && length(local.names.recovery_services_vault) <= 50 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", local.names.recovery_services_vault))
    error_message = "Recovery Services vault name must be 2-50 chars, start with a letter, alphanumerics and hyphens only."
  }
}

# ---- Key Vault / Resource Group ----
output "key_vault" {
  description = "Singular Key Vault name. See README for the pattern and `key_vault_name_token`."
  value       = local.names.key_vault

  precondition {
    condition = local.names.key_vault == null ? true : (
      length(local.names.key_vault) >= 3 &&
      length(local.names.key_vault) <= 24 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.names.key_vault)) &&
      !strcontains(local.names.key_vault, "--")
    )
    error_message = "Key Vault name must be 3-24 chars, start with a letter, end alphanumeric, hyphens allowed but not consecutive. Shorten `appcode`."
  }
}
output "platform_resource_group" {
  description = "Plain platform resource group (no component/purpose)."
  value       = local.names.platform_resource_group

  precondition {
    condition     = length(local.names.platform_resource_group) <= 90
    error_message = "platform_resource_group name exceeds Azure's 90-character limit (${length(local.names.platform_resource_group)} chars)."
  }
}
output "resource_group" {
  description = "Resource group for the current scope/component/purpose. See README."
  value       = local.names.resource_group

  precondition {
    condition     = length(local.names.resource_group) <= 90
    error_message = "resource_group name exceeds Azure's 90-character limit (${length(local.names.resource_group)} chars). Shorten `component`/`purpose` or (for workload scope) `domain`/`appcode`."
  }
}
output "workload_resource_group" {
  description = "Workload spoke resource group. Needs `domain`."
  value       = local.names.workload_resource_group

  precondition {
    condition     = local.names.workload_resource_group == null ? true : length(local.names.workload_resource_group) <= 90
    error_message = "workload_resource_group name exceeds Azure's 90-character limit (${try(length(local.names.workload_resource_group), 0)} chars). Shorten `domain`."
  }
}
output "storage_account" {
  description = "Compatibility single storage account. Needs `purpose`. Prefer storage_account_keys."
  value       = local.names.storage_account
}
output "user_assigned_identity" {
  description = "Compatibility single user-assigned identity. Needs `purpose`. Prefer user_assigned_identity_keys."
  value       = local.names.user_assigned_identity

  precondition {
    condition     = local.names.user_assigned_identity == null ? true : length(local.names.user_assigned_identity) >= 3 && length(local.names.user_assigned_identity) <= 128
    error_message = "user_assigned_identity name is outside Azure's 3-128 character limit (${try(length(local.names.user_assigned_identity), 0)} chars)."
  }
}

output "function_app" {
  description = "Compatibility single Function App. Needs `appcode`. Prefer function_app_keys."
  value       = local.names.function_app

  precondition {
    condition = local.names.function_app == null ? true : (
      length(local.names.function_app) >= 2 &&
      length(local.names.function_app) <= 60 &&
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", local.names.function_app))
    )
    error_message = "function_app name is outside Azure's 2-60 character, alphanumeric-and-hyphen limit (${try(length(local.names.function_app), 0)} chars). Shorten `appcode`."
  }
}

# ---- Policy ----
output "policy_initiative" {
  description = "Policy initiative name. Needs `domain` + `purpose`."
  value       = local.names.policy_initiative
}
output "policy_assignment" {
  description = "Policy assignment name. Needs `policy` + `policy_scope`. See README for the 24-char management-group caveat."
  value       = local.names.policy_assignment
}

# ---- Entra ID ----
output "entra_security_group" {
  description = "Entra ID security group name. Needs `entra_domain` + `entra_role`."
  value       = local.names.entra_security_group
}

# ---- Private DNS ----
output "private_dns_zone" {
  description = "Private DNS zone name. Needs `domain`."
  value       = local.names.private_dns_zone
}
