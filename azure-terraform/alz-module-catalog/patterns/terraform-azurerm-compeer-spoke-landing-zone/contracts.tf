data "azurerm_client_config" "workload" {}
data "azurerm_client_config" "connectivity" {
  provider = azurerm.connectivity
}
data "azurerm_client_config" "dns" {
  provider = azurerm.dns
}


resource "terraform_data" "contracts" {
  input = {
    management_version   = var.platform.management_contract_version
    connectivity_version = var.platform.connectivity_contract_version
    attachment_owner     = var.manage_hub_attachment ? "this-blueprint" : "central-attachment-workspace"
  }
  lifecycle {
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
        data.azurerm_client_config.connectivity.tenant_id == var.tenant_id &&
        data.azurerm_client_config.dns.tenant_id == var.tenant_id &&
        try(split("/", var.platform.hub_virtual_network_id)[2] == data.azurerm_client_config.connectivity.subscription_id, false) &&
        try(split("/", var.platform.key_vault_private_dns_zone_id)[2] == data.azurerm_client_config.dns.subscription_id, false)
      )
      error_message = "Provider aliases must target the workload, hub and existing private-DNS subscriptions in the same tenant. DNS may live in a different subscription from the hub."
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
      condition = length(var.storage_accounts) == 0 || (
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/privatelink\\.blob\\.core\\.windows\\.net$", var.platform.storage_blob_private_dns_zone_id)) &&
        try(lower(split("/", var.platform.storage_blob_private_dns_zone_id)[2]) == lower(data.azurerm_client_config.dns.subscription_id), false)
      )
      error_message = "Private Blob storage requires the actual existing central Blob DNS-zone ID and its correct DNS provider subscription."
    }
    precondition {
      condition = !local.is_production || alltrue([for key in keys(var.storage_accounts) :
        contains(["ZRS", "GZRS", "RAGZRS"], local.storage_replication[key]) && local.storage_retention[key] >= 30
      ])
      error_message = "This production profile requires zone-redundant storage and at least 30 days of Blob/container delete retention. Region/DR exceptions need a separately reviewed profile."
    }
    precondition {
      condition = var.backup == null ? true : (
        try(lower(split("/", var.backup.recovery_vault_id)[2]) == lower(var.subscription_id), false) &&
        alltrue([for id in values(var.backup.virtual_machines) : try(lower(split("/", id)[2]) == lower(var.subscription_id), false)])
      )
      error_message = "VMs and their Recovery Services vault must belong to this workload subscription. Cross-subscription backup is not assumed."
    }
  }
}
