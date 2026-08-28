resource "azurerm_monitor_data_collection_rule_association" "this" {
  name                        = var.name
  target_resource_id          = var.target_resource_id
  data_collection_rule_id     = var.data_collection_rule_id
  data_collection_endpoint_id = var.data_collection_endpoint_id
  description                 = var.description

  lifecycle {
    precondition {
      condition     = var.data_collection_rule_id != null || var.data_collection_endpoint_id != null
      error_message = "At least one of data_collection_rule_id or data_collection_endpoint_id must be set."
    }
  }
}
