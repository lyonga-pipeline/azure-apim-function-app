data "azurerm_client_config" "workload" {}
data "azurerm_client_config" "connectivity" {
  provider = azurerm.connectivity
}
data "azurerm_client_config" "dns" {
  provider = azurerm.dns
}

locals {
  # cidrhost parses IPv4; integer ranges allow complete containment/overlap checks, including differently sized prefixes.
  cidrs = distinct(concat(var.address_space, var.platform.hub_address_space, var.reserved_address_spaces, flatten([for subnet in values(var.subnets) : subnet.address_prefixes])))
  cidr_ranges = { for cidr in local.cidrs : cidr => {
    first = try(sum([for i, octet in split(".", cidrhost(cidr, 0)) : parseint(octet, 10) * pow(256, 3 - i)]), 0)
    last  = try(sum([for i, octet in split(".", cidrhost(cidr, -1)) : parseint(octet, 10) * pow(256, 3 - i)]), 0)
  } }
  subnet_prefixes  = flatten([for key, subnet in var.subnets : [for cidr in subnet.address_prefixes : { key = key, cidr = cidr }]])
  egress_ip_number = try(sum([for i, octet in split(".", var.egress_next_hop_ip) : parseint(octet, 10) * pow(256, 3 - i)]), -1)
}

resource "terraform_data" "contracts" {
  input = {
    management_version   = var.platform.management_contract_version
    connectivity_version = var.platform.connectivity_contract_version
    attachment_owner     = var.manage_hub_attachment ? "this-blueprint" : "central-attachment-workspace"
  }
  lifecycle {
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
  }
}
