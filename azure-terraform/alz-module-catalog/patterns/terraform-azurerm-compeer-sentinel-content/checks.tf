# Non-blocking review prompts. These warn at plan time and never fail a run.

check "defender_alert_connector_overlap" {
  assert {
    condition = !(
      var.data_connectors.defender_xdr && (
        var.data_connectors.defender_for_endpoint ||
        var.data_connectors.defender_for_identity ||
        var.data_connectors.defender_for_cloud_apps != null ||
        var.data_connectors.office_atp
      )
    )
    error_message = "defender_xdr is enabled together with product-specific Defender connectors. Confirm with the SOC that alerts will not arrive twice (once through Defender XDR and once through each product connector) before enabling both."
  }
}

check "duplicate_incident_creation" {
  assert {
    condition = length([
      for rule in values(var.microsoft_incident_rules) : rule.product_filter if rule.enabled
      ]) == length(distinct([
        for rule in values(var.microsoft_incident_rules) : rule.product_filter if rule.enabled
    ]))
    error_message = "More than one enabled microsoft_incident_rules entry uses the same product_filter. Overlapping severity filters create duplicate incidents for the same alert."
  }
}
