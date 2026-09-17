# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

location                  = "centralus"
environment               = "prod"
tfe_organization          = "Compeer-Financial-Services"
management_workspace_name = "platform-management"

platform_tags = {
  application         = "alz-platform-connectivity"
  owner               = "Cloud Enablement"
  source_repo         = "ado://Compeer/landing-zone"
  created_on          = "2026-01-01"
  criticality_tier    = "tier-2"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  # optional / conditional - set where you have a value
  # application_component = "..."
  # modified_on           = "2026-01-01"
  # created_by            = "terraform"
  dr_tier = "standard"
  # expiration_date      = "2026-12-31"   # sandbox / temporary / POC only
  additional_tags = {
    created_by = "terraform"
  }
}

connectivity = {
  enabled        = true
  resource_group = {}
  hub_vnet = {
    # TENTATIVE re-address per Dan's 2026-09-17 Teams post ("New Landing Zone
    # Discussion" - Regional Allocation / Hub Subnets tables). Dan's own words:
    # "I will eventually send this to Compeer to get their approval" - NOT yet
    # approved. Still marked REPLACE-if-Compeer-changes-it, same as before.
    address_space = ["10.102.0.0/16"] # REPLACE if Compeer's approval changes this
    dns_servers   = []                # set to DC IPs only AFTER DC promotion + DNS health (runbook §7.6)
    # Every subnet a downstream workspace resolves by subnet_key must exist here
    # (runbook §4.1 - the hub pattern owns all subnets). route_table_key /
    # nsg_key wire the association from one place.
    subnets = {
      GatewaySubnet      = { address_prefixes = ["10.102.0.0/26"] }
      AzureBastionSubnet = { address_prefixes = ["10.102.0.64/26"] }
      # RouteServerSubnet removed - Route Server was dropped from this pattern
      # (network engineer confirmed removal earlier; also absent from Dan's
      # new table).

      prod-shared-subnet = { address_prefixes = ["10.102.1.0/24"] }
      prod-appgw-subnet0 = { address_prefixes = ["10.102.2.0/24"] }

      # Was one combined "domain_controllers" subnet; Dan's table splits it by
      # domain. Both share the domain_controllers NSG/route table for now
      # since no per-domain rules exist yet - split the nsg_key too if that
      # changes.
      prod-extdc-subnet    = { address_prefixes = ["10.102.3.0/27"], route_table_key = "to_firewall", nsg_key = "domain_controllers" }  # compeer.ext
      prod-intdc-subnet    = { address_prefixes = ["10.102.3.32/27"], route_table_key = "to_firewall", nsg_key = "domain_controllers" } # agstar.local
      prod-cftagent-subnet = { address_prefixes = ["10.102.3.64/26"], route_table_key = "to_firewall", nsg_key = "connectors" }

      # service_endpoints let the bootstrap storage account / Key Vault firewall
      # to this subnet without a public endpoint (see GUARDRAIL-EXCEPTIONS.md).
      prod-mgmt-subnet     = { address_prefixes = ["10.102.4.0/27"], nsg_key = "palo_mgmt", service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"] }
      prod-fw-trust-subnet = { address_prefixes = ["10.102.4.32/27"] }
      # Dan's table showed 10.10.4.64/27 and 10.10.4.96/27 for these two - read
      # as typos for 10.102.4.64/27 / 10.102.4.96/27 (consistent with the rest
      # of this /24 and the Central US 10.102.0.0/16 allocation). Confirm with
      # Dan before this goes to Compeer.
      prod-fw-untrust-subnet = { address_prefixes = ["10.102.4.64/27"] }
      prod-fw-partner-subnet = { address_prefixes = ["10.102.4.96/27"] } # was palo_alto_ha

      # Not in Dan's table - relocated into the new range rather than left
      # outside the VNet's address space. Confirm real prefixes once approved.
      private_endpoints = { address_prefixes = ["10.102.5.0/24"], route_table_key = "to_firewall" }
      app_integration   = { address_prefixes = ["10.102.6.0/24"], route_table_key = "to_firewall" }

      # dns_resolver_inbound / dns_resolver_outbound dropped: nothing in this
      # pattern creates a Private DNS Resolver (dc-forwarders mode below was
      # the confirmed approach), and they're absent from Dan's plan too.
    }
  }
  ddos_protection_plan = {
    enabled             = false
    enable_for_hub_vnet = true
  }
  # Network engineer confirmed: conditional forwarders on the existing domain
  # controllers, not Azure DNS Private Resolver - the resolver-based path
  # (private_dns_resolver variable/module) was removed from this pattern.
  dns_resolution = {
    enabled        = false
    mode           = "dc-forwarders"
    dns_server_ips = []
  }
  bastion = {
    enabled            = false
    subnet_key         = "AzureBastionSubnet"
    sku                = "Standard"
    tunneling_enabled  = true
    ip_connect_enabled = true
  }
  # names come from the naming module: <region>-<env>-<key>-nsg
  network_security_groups = {
    palo_mgmt          = { rules = {} }
    connectors         = { rules = {} }
    domain_controllers = { rules = {} }
  }
  subnet_nsg_associations = {} # derived from subnet.nsg_key above

  # UDR that forces spoke / connector / DC / PE / app-integration traffic to the
  # Palo Alto Trust ILB frontend (runbook §4.2, §5.5). Replace the appliance IP.
  # STALE: 10.0.1.132 was inside the old palo_alto_trusted subnet
  # (10.0.1.128/26). prod-fw-trust-subnet is now 10.102.4.32/27 - this next hop
  # must be updated to the Trust ILB's real frontend IP in that range before
  # this route table is ever applied. Not guessed here; get the real IP from
  # Dan/the Palo Alto build.
  route_tables = {
    to_firewall = {
      bgp_route_propagation_enabled = false
      routes = {
        default = { name = "to-firewall", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.1.132" }
      }
    }
  }
  subnet_route_table_associations = {} # derived from subnet.route_table_key above

  # Network engineer confirmed: a public IP is declared alongside the specific
  # resource that needs it (e.g. palo-alto-hub declares its own mgmt/untrust
  # public IPs; a load balancer frontend can still take a direct
  # public_ip_address_id) - the generic public_ips/route_server_public_ips
  # modules and the route_server module itself were removed from this pattern.

  load_balancers            = {}
  network_watchers          = {}
  network_watcher_flow_logs = {}

  # Canonical private-link DNS zones - list only the services the platform
  # onboards (runbook §7.4). See privatelink_zones.tf for the full key list.
  privatelink_zone_catalogue = [
    "blob", "file", "queue", "table", "dfs",
    "keyvault", "app_service", "app_config",
    "sql", "servicebus", "eventgrid", "acr", "monitor",
  ]

  # Confirmed: these zones already exist in the existing landing zone -
  # Terraform only links the new hub VNet to them, it never creates or
  # manages them. Every key below overrides the matching catalogue entry
  # (same key the catalogue generates internally:
  # replace(replace(name, "privatelink.", ""), ".", "_")) with existing = true.
  #
  # PLACEHOLDER - CONFIRM BEFORE APPLY: "net-ncus-plfc-rg" is an assumed name
  # for the existing landing zone's shared DNS resource group. Replace it
  # with the real, confirmed resource group name before the first apply.
  private_dns_zones = {
    blob_core_windows_net         = { name = "privatelink.blob.core.windows.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    file_core_windows_net         = { name = "privatelink.file.core.windows.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    queue_core_windows_net        = { name = "privatelink.queue.core.windows.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    table_core_windows_net        = { name = "privatelink.table.core.windows.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    dfs_core_windows_net          = { name = "privatelink.dfs.core.windows.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    vaultcore_azure_net           = { name = "privatelink.vaultcore.azure.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    azurewebsites_net             = { name = "privatelink.azurewebsites.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    azconfig_io                   = { name = "privatelink.azconfig.io", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    database_windows_net          = { name = "privatelink.database.windows.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    servicebus_windows_net        = { name = "privatelink.servicebus.windows.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    eventgrid_azure_net           = { name = "privatelink.eventgrid.azure.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    azurecr_io                    = { name = "privatelink.azurecr.io", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    monitor_azure_com             = { name = "privatelink.monitor.azure.com", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    oms_opinsights_azure_com      = { name = "privatelink.oms.opinsights.azure.com", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    ods_opinsights_azure_com      = { name = "privatelink.ods.opinsights.azure.com", existing = true, resource_group_name = "net-ncus-plfc-rg" }
    agentsvc_azure-automation_net = { name = "privatelink.agentsvc.azure-automation.net", existing = true, resource_group_name = "net-ncus-plfc-rg" }
  }
}
