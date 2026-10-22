locals {
  role_assignments = merge(
    { for key, reader in var.secret_readers : "reader-${key}" => {
      scope                            = module.vault.id
      principal_id                     = reader.principal_id
      principal_type                   = reader.principal_type
      role_definition_name             = "Key Vault Secrets User"
      skip_service_principal_aad_check = reader.principal_type == "ServicePrincipal"
    } },
    { for key, id in var.secret_officer_group_ids : "officer-${key}" => {
      scope                = module.vault.id
      principal_id         = id
      principal_type       = "Group"
      role_definition_name = "Key Vault Secrets Officer"
    } },
    { for key, grant in var.data_access : "data-${key}" => {
      scope                            = module.vault.id
      principal_id                     = grant.principal_id
      principal_type                   = grant.principal_type
      role_definition_name             = grant.role_definition_name
      skip_service_principal_aad_check = grant.principal_type == "ServicePrincipal"
    } }
  )

  # Keep the legacy default key known even when the caller is creating its subnet.
  private_endpoints = var.private_endpoints != null ? var.private_endpoints : {
    default = {
      subnet_id                     = var.private_endpoint_subnet_id
      private_dns_zone_id           = var.private_dns_zone_id
      name                          = null
      resource_group_name           = null
      location                      = null
      custom_network_interface_name = null
      private_ip_address            = null
      manual_connection             = false
      request_message               = null
    }
  }
  role_assignment_identities = concat(
    [for reader in values(var.secret_readers) : "${lower(reader.principal_id)}:Key Vault Secrets User"],
    [for id in values(var.secret_officer_group_ids) : "${lower(id)}:Key Vault Secrets Officer"],
    [for grant in values(var.data_access) : "${lower(grant.principal_id)}:${grant.role_definition_name}"]
  )
  keys = { for name, key in var.keys : name => merge(key, {
    key_size = startswith(key.key_type, "RSA") ? coalesce(key.key_size, 3072) : null
    curve    = startswith(key.key_type, "EC") ? coalesce(key.curve, "P-256") : null
  }) }
  metric_alerts = {
    availability = { metric_name = "Availability", operator = "LessThan", threshold = var.monitoring.availability_threshold, description = "Vault availability below the approved SLO." }
    latency      = { metric_name = "ServiceApiLatency", operator = "GreaterThan", threshold = var.monitoring.latency_threshold_ms, description = "Vault service latency exceeded the approved threshold." }
    saturation   = { metric_name = "SaturationShoebox", operator = "GreaterThan", threshold = var.monitoring.saturation_threshold, description = "Vault saturation exceeded the approved capacity threshold." }
  }
  evaluation_minutes = { PT1M = 1, PT5M = 5, PT15M = 15, PT30M = 30, PT1H = 60, PT6H = 360, PT12H = 720, P1D = 1440 }
  firewall_ranges = { for cidr in var.network_access.ip_rules : cidr => {
    first = try(sum([for index, octet in split(".", cidrhost(cidr, 0)) : parseint(octet, 10) * pow(256, 3 - index)]), 0)
    last  = try(sum([for index, octet in split(".", cidrhost(cidr, -1)) : parseint(octet, 10) * pow(256, 3 - index)]), 0)
  } }
  reserved_ranges = [for cidr in ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8", "169.254.0.0/16", "0.0.0.0/8", "224.0.0.0/3", "100.64.0.0/10"] : {
    first = sum([for index, octet in split(".", cidrhost(cidr, 0)) : parseint(octet, 10) * pow(256, 3 - index)])
    last  = sum([for index, octet in split(".", cidrhost(cidr, -1)) : parseint(octet, 10) * pow(256, 3 - index)])
  }]
}
