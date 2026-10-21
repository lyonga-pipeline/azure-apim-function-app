data "azurerm_client_config" "workload" {}
data "azurerm_client_config" "dns" {
  provider = azurerm.dns
}


resource "terraform_data" "contracts" {
  input = {
    management_version   = var.platform.management_contract_version
    connectivity_version = var.platform.connectivity_contract_version
    attachment_owner     = "central-attachment-workspace"
  }
  lifecycle {
    # Cross-input rules belong in contracts so unsupported Core versions do not fail parsing validations.
    precondition {
      condition = alltrue(flatten([for subnet in values(var.subnets) : [for rule in values(subnet.rules) : [for id in concat(
        rule.source_application_security_group_ids == null ? [] : tolist(rule.source_application_security_group_ids),
        rule.destination_application_security_group_ids == null ? [] : tolist(rule.destination_application_security_group_ids)
        ) : try(lower(split("/", id)[2]) == lower(var.subscription_id), false)
      ]]]))
      error_message = "ASG rules must reference the workload subscription. The application owner must ensure ASG NIC membership belongs to this VNet."
    }
    precondition {
      condition = alltrue([for subnet in values(var.subnets) :
        length(distinct([for rule in values(subnet.rules) : "${rule.direction}:${rule.priority}"])) == length(subnet.rules) &&
        alltrue([for name in keys(subnet.rules) : !startswith(name, "baseline-")]) &&
        alltrue([for name in keys(subnet.routes) : name != "default-egress" && !startswith(name, "baseline-")]) &&
        alltrue([for route in values(subnet.routes) : route.address_prefix != "0.0.0.0/0" && !contains(local.inspection_address_prefixes, route.address_prefix) && can(cidrnetmask(route.address_prefix)) && (
          route.next_hop_type == "None" || (route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == var.egress_next_hop_ip)
        )])
      ])
      error_message = "Rule priorities must be unique per direction; baseline- names are reserved. Custom IPv4 routes may blackhole or use the approved NVA, never bypass inspection."
    }
    precondition {
      condition = alltrue([for assignment in values(var.workload_access_group_ids) : assignment.resource_group_keys == null ? true : (
        length(assignment.resource_group_keys) > 0 && length(setsubtract(assignment.resource_group_keys, toset(local.resource_group_keys))) == 0
      )])
      error_message = "resource_group_keys must select non-empty, existing blueprint RG keys: network, security, application, operations, and data only when storage is configured."
    }
    precondition {
      condition     = length(local.mandatory_tag_keys) > 0 && length(setsubtract(local.mandatory_tag_keys, toset(keys(module.tags.tags)))) == 0
      error_message = "Workload tags must include every approved governance mandatory tag key; resolve metadata before deploying."
    }
    precondition {
      condition     = var.platform.management_contract_version == "0.1.0" && var.platform.connectivity_contract_version == "0.1.0"
      error_message = "Management/connectivity must publish the supported 0.1.0 public contracts. Resolve output access/version drift rather than falling back silently."
    }
    precondition {
      condition = (
        data.azurerm_client_config.workload.subscription_id == var.subscription_id &&
        data.azurerm_client_config.workload.tenant_id == var.tenant_id &&
        data.azurerm_client_config.dns.tenant_id == var.tenant_id &&
        (!var.key_vault.enabled || try(split("/", var.platform.key_vault_private_dns_zone_id)[2] == data.azurerm_client_config.dns.subscription_id, false))
      )
      error_message = "Providers must target the workload and existing private-DNS subscriptions in the same tenant. The central attachment workspace independently validates its hub provider."
    }
    precondition {
      condition = (
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.platform.hub_virtual_network_id)) &&
        length(var.platform.hub_address_space) > 0 && alltrue([for cidr in var.platform.hub_address_space : can(cidrnetmask(cidr))])
      )
      error_message = "The connectivity contract must publish the actual hub VNet resource ID and approved IPv4 address space."
    }
    precondition {
      condition = alltrue(flatten([for i, cidr in var.address_space : [for j, other in var.address_space :
        i == j || local.cidr_ranges[cidr].last < local.cidr_ranges[other].first || local.cidr_ranges[cidr].first > local.cidr_ranges[other].last
        ]])) && alltrue(flatten([for cidr in var.address_space : [for other in concat(var.platform.hub_address_space, var.reserved_address_spaces) :
        local.cidr_ranges[cidr].last < local.cidr_ranges[other].first || local.cidr_ranges[cidr].first > local.cidr_ranges[other].last
      ]]))
      error_message = "Spoke prefixes must be mutually non-overlapping and must not overlap hub or supplied IPAM-reserved/on-prem prefixes."
    }
    precondition {
      condition = alltrue([for prefix in local.subnet_prefixes : anytrue([for cidr in var.address_space :
        local.cidr_ranges[prefix.cidr].first >= local.cidr_ranges[cidr].first && local.cidr_ranges[prefix.cidr].last <= local.cidr_ranges[cidr].last
        ])]) && alltrue(flatten([for i, prefix in local.subnet_prefixes : [for j, other in local.subnet_prefixes :
        i == j || local.cidr_ranges[prefix.cidr].last < local.cidr_ranges[other.cidr].first || local.cidr_ranges[prefix.cidr].first > local.cidr_ranges[other.cidr].last
      ]]))
      error_message = "Every subnet must fit completely within the VNet and must not overlap any other subnet prefix."
    }
    precondition {
      condition = anytrue([for cidr in var.platform.hub_address_space :
        local.egress_ip_number > local.cidr_ranges[cidr].first && local.egress_ip_number < local.cidr_ranges[cidr].last
      ])
      error_message = "The approved default-route next hop must be an actual hub firewall/NVA IPv4 address within the hub range, not a guessed public or spoke IP."
    }
    precondition {
      condition     = (length(var.platform.dns_server_ips) > 0 || var.allow_azure_provided_dns) && alltrue([for ip in var.platform.dns_server_ips : can(cidrnetmask("${ip}/32"))])
      error_message = "Supply approved hybrid DNS server IPs or explicitly approve allow_azure_provided_dns. Private zone links alone do not configure custom DNS forwarding."
    }
    precondition {
      condition = alltrue(flatten([for cidr in local.inspection_address_prefixes : [for spoke in var.address_space :
        local.cidr_ranges[cidr].last < local.cidr_ranges[spoke].first || local.cidr_ranges[cidr].first > local.cidr_ranges[spoke].last
      ]])) && alltrue([for subnet in values(var.subnets) : !subnet.bgp_route_propagation_enabled])
      error_message = "Inspection prefixes must not overlap this spoke. Disable gateway BGP propagation on spoke route tables so learned routes cannot bypass the approved hub NVA."
    }
  }
}

resource "terraform_data" "capability_contract" {
  lifecycle {
    precondition {
      condition     = !local.create_failed_requests_alert || var.operations.create_action_group || length(var.operations.action_group_ids) + length(var.operations.platform_action_group_keys) > 0
      error_message = "Enabled alerts require approved action-group keys/IDs or explicit create_action_group with real recipients."
    }
    precondition {
      condition     = alltrue([for setting in values(var.diagnostics.existing_settings) : lower(setting.workspace_id) == lower(var.platform.log_analytics_workspace_id)])
      error_message = "Every reused diagnostic setting must declare the approved central LAW as its destination."
    }
    precondition {
      condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.OperationalInsights/workspaces/[^/]+$", var.platform.log_analytics_workspace_id))
      error_message = "Logging always references the approved central Log Analytics workspace ARM ID; this blueprint does not create a replacement LAW."
    }
    precondition {
      condition     = !var.monitoring.enabled || var.monitoring.existing_application_insights == null ? true : lower(var.monitoring.existing_application_insights.workspace_id) == lower(var.platform.log_analytics_workspace_id)
      error_message = "Reused Application Insights must declare the approved central LAW ID. Its owner must also verify actual workspace linkage, Entra authentication and ingestion in Azure."
    }
    precondition {
      condition = !local.notification_required || alltrue([
        for key in var.operations.platform_action_group_keys : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Insights/actionGroups/[^/]+$", lookup(var.platform.action_group_ids, key, "")))
      ])
      error_message = "Selected platform action-group keys must exist and contain valid ARM IDs in the approved management contract. Supply an existing ID or explicitly create an application group; missing shared services never trigger fallback creation."
    }
    precondition {
      condition = length(local.enabled_storage_accounts) == 0 || (
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/privatelink\\.blob\\.core\\.windows\\.net$", var.platform.storage_blob_private_dns_zone_id)) &&
        try(lower(split("/", var.platform.storage_blob_private_dns_zone_id)[2]) == lower(data.azurerm_client_config.dns.subscription_id), false)
      )
      error_message = "Private Blob storage requires the actual existing central Blob DNS-zone ID and its correct DNS provider subscription."
    }
    precondition {
      condition = !local.is_production || alltrue([for key in keys(local.enabled_storage_accounts) :
        contains(["ZRS", "GZRS", "RAGZRS"], local.storage_replication[key]) && local.storage_retention[key] >= 30
      ])
      error_message = "This production profile requires zone-redundant storage and at least 30 days of Blob/container delete retention. Region/DR exceptions need a separately reviewed profile."
    }
    precondition {
      condition = !local.backup_enabled ? true : (
        try(lower(split("/", var.backup.recovery_vault_id)[2]) == lower(var.subscription_id), false) &&
        alltrue([for id in values(var.backup.virtual_machines) : try(lower(split("/", id)[2]) == lower(var.subscription_id), false)])
      )
      error_message = "VMs and their Recovery Services vault must belong to this workload subscription. Cross-subscription backup is not assumed."
    }
    precondition {
      condition = (
        length(setsubtract(toset(keys(var.diagnostics.existing_settings)), toset(keys(local.diagnostic_requirements)))) == 0 &&
        alltrue([for key, required in local.diagnostic_requirements : var.diagnostics.enabled || contains(keys(var.diagnostics.existing_settings), key)]) &&
        alltrue([for key, setting in var.diagnostics.existing_settings : try(
          length(setsubtract(local.diagnostic_requirements[key].logs, setting.log_categories)) == 0 &&
          length(setsubtract(local.diagnostic_requirements[key].metrics, setting.metric_categories)) == 0, false
        )])
      )
      error_message = "Every enabled vault/storage target needs managed or explicitly reused central audit coverage. Existing-setting keys must match enabled targets and include every required log/metric category. Disabling creation is not permission to remove auditing."
    }
  }
}

# Target IDs are known after parent creation; keep this check outside the parent dependency chain.
resource "terraform_data" "reuse_contract" {
  lifecycle {
    precondition {
      condition = !var.monitoring.alerts_enabled || var.monitoring.existing_failed_requests_alert == null ? true : (
        lower(var.monitoring.existing_failed_requests_alert.application_insights_id) == lower(local.application_insights_id) &&
        !var.operations.create_action_group && length(var.operations.action_group_ids) == 0 && length(var.operations.platform_action_group_keys) == 0
      )
      error_message = "Reused alerts must cover the selected Application Insights component. Their existing routing stays externally owned: do not supply new operations routes or create an unused action group."
    }
    precondition {
      condition = alltrue([for key, setting in var.diagnostics.existing_settings : try(
        lower(join("/", slice(split("/", setting.id), 0, length(split("/", setting.id)) - 4))) == lower(local.diagnostic_targets[key]), false
      )])
      error_message = "A reused diagnostic setting must belong to the exact enabled resource (including blobServices/default), not a different account, vault or service."
    }
  }
}
