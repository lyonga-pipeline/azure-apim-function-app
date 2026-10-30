locals {
  # The topic owner supplies identity for reuse; new topics expose their own principal.
  topic_principal_ids = { for key, value in var.secret_rotations : key => (
    value.create_system_topic ? azurerm_eventgrid_system_topic.vault[key].identity[0].principal_id : value.topic_principal_id
  ) }
}
