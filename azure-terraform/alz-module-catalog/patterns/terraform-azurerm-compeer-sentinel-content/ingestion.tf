# Data source integration. A Sentinel data source is rarely just a connector:
# agent feeds and third-party pipelines need an endpoint, a table, a rule and an
# association. They are modelled here so the SOC can add a source (for example
# Cloudflare logs delivered by Cribl) in one reviewed change.

locals {
  ingestion_endpoints    = var.ingestion == null ? {} : var.ingestion.endpoints
  ingestion_tables       = var.ingestion == null ? {} : var.ingestion.custom_tables
  ingestion_rules        = var.ingestion == null ? {} : var.ingestion.rules
  ingestion_associations = var.ingestion == null ? {} : var.ingestion.associations

  custom_ingestion_rules = { for key, rule in local.ingestion_rules : key => rule if rule.preset == "custom_ingestion" }

  # Stream the pipeline posts to. Defaults to the table's own stream, which
  # needs no output_stream; a different input name means a raw shape that the
  # rule transforms into the table.
  custom_input_streams = {
    for key, rule in local.custom_ingestion_rules :
    key => coalesce(rule.input_stream_name, "Custom-${rule.table_key}")
  }

  rule_kinds = {
    # Classic Logs Ingestion rules (through a data collection endpoint) carry no
    # kind. The provider's Direct kind is not offered by every azurerm 4.x
    # release this pattern allows, so it is not exposed.
    for key, rule in local.ingestion_rules : key => (
      rule.preset == "custom_ingestion" ? null :
      contains(["windows_security_events", "windows_events"], rule.preset) ? "Windows" : "Linux"
    )
  }

  rule_streams = {
    for key, rule in local.ingestion_rules : key => (
      rule.preset == "custom_ingestion" ? [local.custom_input_streams[key]] :
      rule.preset == "windows_security_events" ? ["Microsoft-SecurityEvent"] :
      rule.preset == "windows_events" ? ["Microsoft-Event"] :
      rule.preset == "syslog" ? ["Microsoft-Syslog"] : ["Microsoft-CommonSecurityLog"]
    )
  }

  # Only set when the flow actually lands in a different stream than it
  # arrived on (provider guidance).
  rule_output_streams = {
    for key, rule in local.custom_ingestion_rules :
    key => local.custom_input_streams[key] == "Custom-${rule.table_key}" ? null : "Custom-${rule.table_key}"
  }

  # Stream-declaration types are lower-case and have no guid type.
  stream_type_map = { boolean = "boolean", dateTime = "datetime", dynamic = "dynamic", guid = "string", int = "int", long = "long", real = "real", string = "string" }

  rule_stream_columns = {
    for key, rule in local.custom_ingestion_rules : key => (
      rule.stream_columns != null ? rule.stream_columns : [
        for column in local.ingestion_tables[rule.table_key].columns : { name = column.name, type = local.stream_type_map[column.type] }
      ]
    )
  }

  # A source is delivered only when the rule exists AND something is attached
  # to it (agent rules) or it has a table to land in (pipeline rules).
  associated_rule_keys = toset([for association in values(local.ingestion_associations) : association.rule_key])

  ingestion_sources = distinct(concat(
    [for key, rule in local.ingestion_rules : "windows_security_events" if rule.preset == "windows_security_events" && contains(local.associated_rule_keys, key)],
    [for key, rule in local.ingestion_rules : "syslog" if rule.preset == "syslog" && contains(local.associated_rule_keys, key)],
    [for key, rule in local.ingestion_rules : "common_security_log" if rule.preset == "cef" && contains(local.associated_rule_keys, key)],
    [for key, rule in local.custom_ingestion_rules : rule.table_key],
  ))

  publisher_assignments = merge([
    for key, rule in local.custom_ingestion_rules : {
      for principal_id in rule.publisher_principal_ids : "${key}/${principal_id}" => {
        rule_key     = key
        principal_id = principal_id
      }
    }
  ]...)
}

resource "azurerm_monitor_data_collection_endpoint" "endpoint" {
  for_each = local.ingestion_endpoints

  name                          = coalesce(each.value.name, each.key)
  resource_group_name           = var.ingestion.resource_group_name
  location                      = var.ingestion.location
  description                   = each.value.description
  public_network_access_enabled = each.value.public_network_access_enabled
  tags                          = var.ingestion.tags
}

resource "azurerm_log_analytics_workspace_table_custom_log" "table" {
  for_each = local.ingestion_tables

  name                    = each.key
  workspace_id            = local.workspace_id
  description             = each.value.description
  plan                    = each.value.plan
  retention_in_days       = each.value.retention_in_days
  total_retention_in_days = each.value.total_retention_in_days

  dynamic "column" {
    for_each = each.value.columns
    content {
      name        = column.value.name
      type        = column.value.type
      description = column.value.description
    }
  }
}

resource "azurerm_monitor_data_collection_rule" "rule" {
  for_each = local.ingestion_rules

  name                        = coalesce(each.value.name, each.key)
  resource_group_name         = var.ingestion.resource_group_name
  location                    = var.ingestion.location
  kind                        = local.rule_kinds[each.key]
  description                 = each.value.description
  data_collection_endpoint_id = each.value.endpoint_key == null ? null : azurerm_monitor_data_collection_endpoint.endpoint[each.value.endpoint_key].id
  tags                        = var.ingestion.tags

  destinations {
    log_analytics {
      name                  = "sentinel-workspace"
      workspace_resource_id = local.workspace_id
    }
  }

  data_flow {
    streams       = local.rule_streams[each.key]
    destinations  = ["sentinel-workspace"]
    output_stream = each.value.preset == "custom_ingestion" ? local.rule_output_streams[each.key] : null
    transform_kql = each.value.transform_kql
  }

  dynamic "stream_declaration" {
    for_each = each.value.preset == "custom_ingestion" ? [local.custom_input_streams[each.key]] : []
    content {
      stream_name = stream_declaration.value
      dynamic "column" {
        for_each = local.rule_stream_columns[each.key]
        content {
          name = column.value.name
          type = column.value.type
        }
      }
    }
  }

  dynamic "data_sources" {
    for_each = each.value.preset == "custom_ingestion" ? [] : [1]
    content {
      dynamic "windows_event_log" {
        for_each = contains(["windows_security_events", "windows_events"], each.value.preset) ? [1] : []
        content {
          name           = each.value.preset
          streams        = local.rule_streams[each.key]
          x_path_queries = each.value.preset == "windows_security_events" ? ["Security!*"] : each.value.x_path_queries
        }
      }
      dynamic "syslog" {
        for_each = contains(["syslog", "cef"], each.value.preset) ? [1] : []
        content {
          name           = each.value.preset
          streams        = local.rule_streams[each.key]
          facility_names = each.value.facility_names
          log_levels     = each.value.log_levels
        }
      }
    }
  }

  depends_on = [azurerm_log_analytics_workspace_table_custom_log.table]
}

resource "azurerm_monitor_data_collection_rule_association" "association" {
  for_each = local.ingestion_associations

  name                    = coalesce(each.value.name, each.key)
  target_resource_id      = each.value.target_resource_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.rule[each.value.rule_key].id
}

# A third-party pipeline authenticates with an Entra application and needs
# Monitoring Metrics Publisher on the one rule it posts to, nothing wider.
# Assigning it here is deliberately narrow; broader RBAC stays with
# platform-authorization.
module "publisher_roles" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = {
    for key, assignment in local.publisher_assignments : key => {
      scope                            = azurerm_monitor_data_collection_rule.rule[assignment.rule_key].id
      principal_id                     = assignment.principal_id
      principal_type                   = "ServicePrincipal"
      role_definition_name             = "Monitoring Metrics Publisher"
      skip_service_principal_aad_check = true
    }
  }
}
