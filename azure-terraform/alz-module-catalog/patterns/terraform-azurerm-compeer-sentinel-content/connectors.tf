# Connector names mirror the existing terraform-azurerm-compeer-sentinel module
# (ti, mdatp, aad, mdc) so an adopted connector can be imported rather than
# recreated. Connector resource names are the connector IDs in Azure.

resource "azurerm_sentinel_data_connector_azure_active_directory" "entra_id" {
  count = local.connectors.entra_id ? 1 : 0

  name                       = "aad"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_microsoft_threat_protection" "defender_xdr" {
  count = local.connectors.defender_xdr ? 1 : 0

  name                       = "mtp"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "defender_for_endpoint" {
  count = local.connectors.defender_for_endpoint ? 1 : 0

  name                       = "mdatp"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_azure_advanced_threat_protection" "defender_for_identity" {
  count = local.connectors.defender_for_identity ? 1 : 0

  name                       = "mdi"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_microsoft_cloud_app_security" "defender_for_cloud_apps" {
  count = local.connectors.defender_for_cloud_apps != null ? 1 : 0

  name                       = "mcas"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
  alerts_enabled             = local.connectors.defender_for_cloud_apps.alerts_enabled
  discovery_logs_enabled     = local.connectors.defender_for_cloud_apps.discovery_logs_enabled
}

resource "azurerm_sentinel_data_connector_office_atp" "office_atp" {
  count = local.connectors.office_atp ? 1 : 0

  name                       = "office-atp"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_office_irm" "office_irm" {
  count = local.connectors.office_irm ? 1 : 0

  name                       = "office-irm"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_office_power_bi" "power_bi" {
  count = local.connectors.power_bi ? 1 : 0

  name                       = "power-bi"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_office_365" "office_365" {
  count = local.connectors.office_365 != null ? 1 : 0

  name                       = "o365"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
  exchange_enabled           = local.connectors.office_365.exchange_enabled
  sharepoint_enabled         = local.connectors.office_365.sharepoint_enabled
  teams_enabled              = local.connectors.office_365.teams_enabled
}

# One Defender for Cloud connector per subscription: the connector is
# subscription-scoped. Alerts from Defender for Cloud plans enabled by
# platform-policy / platform-management flow here.
resource "azurerm_sentinel_data_connector_azure_security_center" "defender_for_cloud" {
  for_each = local.connectors.defender_for_cloud

  name                       = coalesce(each.value.name, each.key)
  log_analytics_workspace_id = local.workspace_id
  subscription_id            = each.value.subscription_id
}

resource "azurerm_sentinel_data_connector_threat_intelligence" "threat_intelligence" {
  count = local.connectors.threat_intelligence != null ? 1 : 0

  name                       = "ti"
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
  lookback_date              = local.connectors.threat_intelligence.lookback_date
}

resource "azurerm_sentinel_data_connector_microsoft_threat_intelligence" "microsoft_threat_intelligence" {
  count = local.connectors.microsoft_threat_intelligence != null ? 1 : 0

  name                                         = "mdti"
  log_analytics_workspace_id                   = local.workspace_id
  tenant_id                                    = var.tenant_id
  microsoft_emerging_threat_feed_lookback_date = local.connectors.microsoft_threat_intelligence.lookback_date
}

resource "azurerm_sentinel_data_connector_threat_intelligence_taxii" "taxii" {
  for_each = local.connectors.threat_intelligence_taxii

  name                       = each.key
  display_name               = each.value.display_name
  log_analytics_workspace_id = local.workspace_id
  tenant_id                  = var.tenant_id
  api_root_url               = each.value.api_root_url
  collection_id              = each.value.collection_id
  user_name                  = each.value.user_name
  password                   = try(var.taxii_passwords[each.key], null)
  polling_frequency          = each.value.polling_frequency
  lookback_date              = each.value.lookback_date
}
