# =============================================================================
# One flat output per Appendix F row. A name whose required tokens were not
# supplied is `null` - reference it and Terraform stops, which is the intended
# behaviour (you asked for a name you did not give the inputs for).
#
# `region_short` and `all` are conveniences; everything else is a finished name.
# =============================================================================

output "region_short" {
  description = "Resolved region short code (e.g. centralus -> cus)."
  value       = local.region
}

output "all" {
  description = "Every computed name as a single map (nulls included). Prefer the individual outputs."
  value       = local.names
}

# ---- Management groups ----
output "mg_enterprise" {
  description = "Landing-zone root management group. Pattern: compeer-enterprise-mg."
  value       = local.names.mg_enterprise
}
output "mg_platform" {
  description = "Platform management group. Pattern: platform-mg."
  value       = local.names.mg_platform
}
output "mg_workloads" {
  description = "Workloads management group. Pattern: workloads-mg."
  value       = local.names.mg_workloads
}
output "mg_sandbox" {
  description = "Sandbox management group. Pattern: sandbox-mg."
  value       = local.names.mg_sandbox
}
output "mg_decommissioned" {
  description = "Decommissioned management group. Pattern: decommissioned-mg."
  value       = local.names.mg_decommissioned
}
output "mg_workload_domain" {
  description = "Workload-domain management group (needs `domain`). Pattern: <domain>-mg."
  value       = local.names.mg_workload_domain
}
output "mg_workload_domain_environment" {
  description = "Domain+environment management group (needs `domain`). Pattern: <domain>-<env>-mg."
  value       = local.names.mg_workload_domain_environment
}

# ---- Subscriptions ----
output "subscription_platform" {
  description = "Platform subscription. Pattern: sub-platform-<env>-<region>."
  value       = local.names.subscription_platform
}
output "subscription_identity" {
  description = "Identity subscription. Pattern: sub-identity-<env>-<region>."
  value       = local.names.subscription_identity
}
output "subscription_connectivity" {
  description = "Connectivity subscription. Pattern: sub-connectivity-<env>-<region>."
  value       = local.names.subscription_connectivity
}
output "subscription_management" {
  description = "Management subscription. Pattern: sub-management-<env>-<region>."
  value       = local.names.subscription_management
}
output "subscription_workload" {
  description = "Workload subscription (needs `name`). Pattern: sub-workload-<name>-<env>-<region>."
  value       = local.names.subscription_workload
}

# ---- Networking ----
output "hub_vnet" {
  description = "Hub virtual network. Pattern: platform-<region>-<env>-hub-vnet."
  value       = local.names.hub_vnet
}
output "shared_vnet" {
  description = "Shared-services virtual network. Pattern: platform-<region>-<env>-shared-vnet."
  value       = local.names.shared_vnet
}
output "subnet" {
  description = "Subnet (needs `purpose`). Pattern: <env>-<purpose>-subnet."
  value       = local.names.subnet
}
output "nsg" {
  description = "Network security group (needs `purpose`). Pattern: <region>-<env>-<purpose>-nsg."
  value       = local.names.nsg
}
output "route_table" {
  description = "Route table (needs `destination`). Pattern: <region>-<env>-<destination>-rt."
  value       = local.names.route_table
}
output "public_ip" {
  description = "Public IP (needs `resource`). Pattern: <region>-<env>-<resource>-pip."
  value       = local.names.public_ip
}

# ---- Firewall / edge ----
output "firewall_vm" {
  description = "Palo Alto firewall VM. Pattern: platform-<region>-<env>-fw-0<n> (from `instance`)."
  value       = local.names.firewall_vm
}
output "firewall_ilb" {
  description = "Firewall internal load balancer. Pattern: platform-<region>-<env>-fw-ilb."
  value       = local.names.firewall_ilb
}
output "expressroute_gateway" {
  description = "ExpressRoute gateway. Pattern: platform-<region>-<env>-ergw."
  value       = local.names.expressroute_gateway
}
output "vpn_gateway" {
  description = "VPN gateway. Pattern: platform-<region>-<env>-vpngw."
  value       = local.names.vpn_gateway
}
output "cloudflare_connector" {
  description = "Cloudflare Tunnel connector. Pattern: platform-<region>-<env>-cf-connector-0<n> (from `instance`)."
  value       = local.names.cloudflare_connector
}

# ---- Observability / recovery ----
output "log_analytics_workspace" {
  description = "Log Analytics workspace. Pattern: <region>-<env>-loganalytics-workspace."
  value       = local.names.log_analytics_workspace

  precondition {
    condition     = length(local.names.log_analytics_workspace) >= 4 && length(local.names.log_analytics_workspace) <= 63
    error_message = "Log Analytics workspace name must be 4-63 characters."
  }
}
output "monitor_workspace" {
  description = "Azure Monitor workspace. Pattern: platform-<region>-<env>-monitor."
  value       = local.names.monitor_workspace
}
output "recovery_services_vault" {
  description = "Recovery Services vault. Pattern: platform-<region>-<env>-rsv."
  value       = local.names.recovery_services_vault

  precondition {
    condition     = length(local.names.recovery_services_vault) >= 2 && length(local.names.recovery_services_vault) <= 50 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", local.names.recovery_services_vault))
    error_message = "Recovery Services vault name must be 2-50 chars, start with a letter, alphanumerics and hyphens only."
  }
}

# ---- Key Vault / Resource Group ----
output "key_vault" {
  description = "Key Vault (needs `appcode`). Pattern: <appcode>-<region>-<env>-vault. Enforced 3-24 chars."
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
  description = "Platform resource group. Pattern: platform-<region>-<env>-rg."
  value       = local.names.platform_resource_group
}

# ---- Policy ----
output "policy_initiative" {
  description = "Policy initiative (needs `domain` + `purpose`). Pattern: initiative-<domain>-<purpose>."
  value       = local.names.policy_initiative
}
output "policy_assignment" {
  description = "Policy assignment (needs `policy` + `scope`). Pattern: assign-<policy>-<scope>."
  value       = local.names.policy_assignment
}

# ---- Entra ID ----
output "entra_security_group" {
  description = "Entra ID security group (needs `entra_domain` + `entra_role`). Pattern: AZ-<DOMAIN>-<Role> (domain upper, role case preserved)."
  value       = local.names.entra_security_group
}

# ---- Private DNS ----
output "private_dns_zone" {
  description = "Private DNS zone (needs `domain`). Pattern: <domain>-pdns."
  value       = local.names.private_dns_zone
}
