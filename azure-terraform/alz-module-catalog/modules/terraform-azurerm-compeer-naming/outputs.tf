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
output "mg" {
  description = "Any <name>-mg management group (needs `domain` as the node token: security, identity, internal-apps, ...). Pattern: <domain>-mg."
  value       = local.names.mg
}
output "mg_environment" {
  description = "Any <name>-<env>-mg management group (needs `domain`). Pattern: <domain>-<env>-mg."
  value       = local.names.mg_environment
}
output "mg_workload_domain" {
  description = "Alias of `mg` kept for older callers. Pattern: <domain>-mg."
  value       = local.names.mg_workload_domain
}
output "mg_workload_domain_environment" {
  description = "Alias of `mg_environment` kept for older callers. Pattern: <domain>-<env>-mg."
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
output "subscription_scoped" {
  description = "ADAPTED (closest: the platform subscription rows). Generic scoped subscription (needs `purpose`: security, sandbox-ops, decommissioned, ...). Pattern: sub-<purpose>-<env>-<region>."
  value       = local.names.subscription_scoped
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
output "workload_vnet" {
  description = "ADAPTED (closest: shared_vnet / hub_vnet). Workload spoke VNet (needs `domain`). Pattern: <domain>-<region>-<env>-vnet."
  value       = local.names.workload_vnet
}
output "network_interface" {
  description = "ADAPTED (closest: public_ip). NIC (needs `resource`). Pattern: <region>-<env>-<resource>-nic."
  value       = local.names.network_interface
}
output "private_endpoint" {
  description = "ADAPTED (closest: public_ip). Private endpoint (needs `resource`). Pattern: <region>-<env>-<resource>-pe."
  value       = local.names.private_endpoint
}
output "nat_gateway" {
  description = "ADAPTED (closest: monitor_workspace). Pattern: platform-<region>-<env>-natgw."
  value       = local.names.nat_gateway
}
output "route_server" {
  description = "ADAPTED (closest: monitor_workspace). Pattern: platform-<region>-<env>-rtsrv."
  value       = local.names.route_server
}
output "ddos_protection_plan" {
  description = "ADAPTED (closest: monitor_workspace). Pattern: platform-<region>-<env>-ddos."
  value       = local.names.ddos_protection_plan
}
output "private_dns_resolver" {
  description = "ADAPTED (closest: monitor_workspace). Pattern: platform-<region>-<env>-dnspr."
  value       = local.names.private_dns_resolver
}
output "bastion" {
  description = "ADAPTED (closest: monitor_workspace). Pattern: platform-<region>-<env>-bas."
  value       = local.names.bastion
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
output "expressroute_circuit" {
  description = "ADAPTED (closest: expressroute_gateway). Pattern: platform-<region>-<env>-erc."
  value       = local.names.expressroute_circuit
}
output "expressroute_connection" {
  description = "ADAPTED (closest: expressroute_gateway). Pattern: platform-<region>-<env>-erconn."
  value       = local.names.expressroute_connection
}
output "vpn_local_network_gateway" {
  description = "ADAPTED (closest: vpn_gateway). Pattern: platform-<region>-<env>-lng."
  value       = local.names.vpn_local_network_gateway
}
output "vpn_connection" {
  description = "ADAPTED (closest: vpn_gateway). Pattern: platform-<region>-<env>-vpnconn."
  value       = local.names.vpn_connection
}
output "domain_controller_vm" {
  description = "ADAPTED (closest: firewall_vm). Domain controller VM. Pattern: platform-<region>-<env>-dc-0<n> (from `instance`)."
  value       = local.names.domain_controller_vm
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
output "automation_account" {
  description = "ADAPTED (closest: monitor_workspace / recovery_services_vault). Pattern: platform-<region>-<env>-aa."
  value       = local.names.automation_account
}
output "action_group" {
  description = "ADAPTED (closest: monitor_workspace). Pattern: platform-<region>-<env>-ag."
  value       = local.names.action_group
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
  description = "Platform resource group (no capability). Pattern: platform-<region>-<env>-rg."
  value       = local.names.platform_resource_group
}
output "resource_group" {
  description = "ADAPTED (F has one platform RG row). Per-capability platform RG when `purpose` is set, else the plain platform RG. Pattern: platform-<region>-<env>[-<purpose>]-rg."
  value       = local.names.resource_group
}
output "workload_resource_group" {
  description = "ADAPTED (closest: mg_environment). Workload spoke RG (needs `domain`). Pattern: <domain>-<env>-rg."
  value       = local.names.workload_resource_group
}
output "storage_account" {
  description = "ADAPTED (no-separator resource). Needs `purpose`. Pattern: st<purpose><region><env>, lower-cased, truncated to 24. Not guaranteed globally unique - caller adds a suffix if needed."
  value       = local.names.storage_account
}
output "user_assigned_identity" {
  description = "ADAPTED (closest: key_vault). Needs `purpose`. Pattern: <purpose>-<region>-<env>-id."
  value       = local.names.user_assigned_identity
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
