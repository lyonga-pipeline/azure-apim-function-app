locals {
  is_production               = var.environment == "prod"
  notification_required       = var.monitoring.alerts_enabled || var.operations.budget.enabled
  create_action_group         = local.notification_required && var.operations.create_action_group
  create_application_insights = var.monitoring.enabled && var.monitoring.create_application_insights
  operations_enabled          = local.create_application_insights || local.create_action_group || var.monitoring.alerts_enabled
  mandatory_tag_keys          = var.platform.mandatory_tag_keys == null ? toset(module.tags.mandatory_keys) : var.platform.mandatory_tag_keys
  resource_group_keys         = concat(["network", "security", "application"], local.operations_enabled ? ["operations"] : [], length(var.storage_accounts) > 0 ? ["data"] : [])
  # Preserve consumer keys while matching the refined placement sheet's app-rg purpose.
  resource_group_purposes = { for key in local.resource_group_keys : key => key == "application" ? "app" : key }
  environment_profile = {
    tier                          = local.is_production ? "production" : "non-production"
    storage_replication_type      = local.is_production ? "ZRS" : "LRS"
    blob_delete_retention_days    = local.is_production ? 30 : 7
    telemetry_sampling_percentage = coalesce(var.monitoring.sampling_percentage, local.is_production ? 100 : 20)
    alert_severity                = local.is_production ? 1 : 3
    alert_frequency               = local.is_production ? "PT1M" : "PT5M"
    failed_request_threshold      = coalesce(var.monitoring.failed_request_threshold, local.is_production ? 5 : 20)
    recovery_ownership            = "application-team-approved-backup-policy"
  }
  storage_replication = { for key, account in var.storage_accounts : key => coalesce(account.replication_type, local.environment_profile.storage_replication_type) }
  storage_retention   = { for key, account in var.storage_accounts : key => coalesce(account.delete_retention_days, local.environment_profile.blob_delete_retention_days) }

  # cidrhost parses IPv4; integer ranges allow complete containment/overlap checks, including differently sized prefixes.
  inspection_address_prefixes = sort(distinct(concat(var.platform.hub_address_space, ["10.169.0.0/16"], var.inspection_address_prefixes)))
  cidrs                       = distinct(concat(var.address_space, local.inspection_address_prefixes, var.reserved_address_spaces, flatten([for subnet in values(var.subnets) : subnet.address_prefixes])))
  cidr_ranges = { for cidr in local.cidrs : cidr => {
    first = try(sum([for i, octet in split(".", cidrhost(cidr, 0)) : parseint(octet, 10) * pow(256, 3 - i)]), 0)
    last  = try(sum([for i, octet in split(".", cidrhost(cidr, -1)) : parseint(octet, 10) * pow(256, 3 - i)]), 0)
  } }
  subnet_prefixes  = flatten([for key, subnet in var.subnets : [for cidr in subnet.address_prefixes : { key = key, cidr = cidr }]])
  egress_ip_number = try(sum([for i, octet in split(".", var.egress_next_hop_ip) : parseint(octet, 10) * pow(256, 3 - i)]), -1)

  subnet_ids = { for key in keys(var.subnets) : key => module.network.subnet_ids[module.naming.subnet_names[key]] }
  baseline_rules = { for key, subnet in var.subnets : key => merge(
    {
      baseline-deny-sunstream-inbound = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "10.169.0.0/16", destination_address_prefix = "*",
        access   = "Deny", priority = 100, direction = "Inbound"
      }
      baseline-deny-sunstream-outbound = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "10.169.0.0/16",
        access   = "Deny", priority = 100, direction = "Outbound"
      }
      baseline-deny-inbound = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
        access   = "Deny", priority = 4096, direction = "Inbound"
      }
      baseline-deny-outbound = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
        access   = "Deny", priority = 4096, direction = "Outbound"
      }
    },
    { for rule_name, rule in {
      baseline-private-https = {
        protocol                = "Tcp", source_port_range = "*", destination_port_range = "443",
        source_address_prefixes = distinct(concat(var.address_space, var.private_endpoint_client_cidrs)), destination_address_prefix = "*",
        access                  = "Allow", priority = 110, direction = "Inbound"
      }
      } : rule_name => rule if key == "private_endpoints"
    },
    { for rule_name, rule in {
      baseline-health-probe = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "AzureLoadBalancer", destination_address_prefix = "*",
        access   = "Allow", priority = 110, direction = "Inbound"
      }
      baseline-dns-udp = {
        protocol                     = "Udp", source_port_range = "*", destination_port_range = "53", source_address_prefix = "*",
        destination_address_prefix   = length(var.platform.dns_server_ips) == 0 ? "AzurePlatformDNS" : null,
        destination_address_prefixes = length(var.platform.dns_server_ips) > 0 ? toset(var.platform.dns_server_ips) : null,
        access                       = "Allow", priority = 110, direction = "Outbound"
      }
      baseline-dns-tcp = {
        protocol                     = "Tcp", source_port_range = "*", destination_port_range = "53", source_address_prefix = "*",
        destination_address_prefix   = length(var.platform.dns_server_ips) == 0 ? "AzurePlatformDNS" : null,
        destination_address_prefixes = length(var.platform.dns_server_ips) > 0 ? toset(var.platform.dns_server_ips) : null,
        access                       = "Allow", priority = 111, direction = "Outbound"
      }
      baseline-private-https = {
        protocol                     = "Tcp", source_port_range = "*", destination_port_range = "443", source_address_prefix = "*",
        destination_address_prefixes = toset(try(var.subnets.private_endpoints.address_prefixes, [])),
        access                       = "Allow", priority = 120, direction = "Outbound"
      }
      baseline-egress-https = {
        protocol = "Tcp", source_port_range = "*", destination_port_range = "443", source_address_prefix = "*", destination_address_prefix = "Internet",
        access   = "Allow", priority = 200, direction = "Outbound"
      }
      } : rule_name => rule if key != "private_endpoints"
    }
  ) }
  nsg_rules = { for key, subnet in var.subnets : key => {
    for name, rule in merge(local.baseline_rules[key], subnet.rules) : name => merge(rule, {
      name = name
      # Omitted source ports keep the existing wildcard; augmented rules use only the plural form.
      source_port_range = try(rule.source_port_ranges, null) == null ? coalesce(try(rule.source_port_range, null), "*") : null
    })
  } }
  # A default UDR alone loses to more-specific peering routes. Pin hub/approved remote prefixes to the NVA.
  routes = { for key, subnet in var.subnets : key => merge(subnet.routes, {
    for prefix in local.inspection_address_prefixes : "baseline-inspect-${replace(replace(prefix, ".", "-"), "/", "-")}" => {
      address_prefix = prefix, next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.egress_next_hop_ip
    }
    }, {
    default-egress = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.egress_next_hop_ip }
  }) }

  workload_stem = trimsuffix(module.naming.workload_vnet, "-spoke-vnet")
  action_group_ids = local.notification_required ? distinct(concat(
    [for key in var.operations.platform_action_group_keys : lookup(var.platform.action_group_ids, key, null) if contains(keys(var.platform.action_group_ids), key)],
    tolist(var.operations.action_group_ids), [for group in module.alert_contacts : group.id]
  )) : []
  application_insights_id = var.monitoring.enabled ? (
    var.monitoring.existing_application_insights == null ? try(module.application_insights[0].id, null) : var.monitoring.existing_application_insights.id
  ) : null
  application_insights_name = var.monitoring.enabled ? (
    var.monitoring.existing_application_insights == null ? try(module.application_insights[0].name, null) : try(split("/", var.monitoring.existing_application_insights.id)[8], null)
  ) : null
  manage_telemetry_access = local.create_application_insights || var.monitoring.manage_existing_telemetry_access

  workload_access_assignments = merge([for scope_key in local.resource_group_keys : {
    for key, assignment in var.workload_access_group_ids : "${scope_key}-${key}" => {
      scope                = module.resource_groups.group_ids[scope_key]
      principal_id         = assignment.principal_id
      principal_type       = "Group"
      role_definition_name = assignment.role
    } if assignment.resource_group_keys == null ? true : contains(assignment.resource_group_keys, scope_key)
  }]...)
}
