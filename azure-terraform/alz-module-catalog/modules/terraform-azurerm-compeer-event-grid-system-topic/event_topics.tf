# Event Grid System Topic
resource "azurerm_eventgrid_system_topic" "system_topic" {
  name                = var.eventgrid_topic_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # The source resource for the system topic
  source_arm_resource_id = var.source_arm_resource_id

  topic_type = var.topic_type

  identity {
    type         = var.eventgrid_identity_type
    identity_ids = var.eventgrid_identity_ids
  }
}
