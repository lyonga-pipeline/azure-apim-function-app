output "secret_rotation_subscription_ids" {
  value = { for key, value in azurerm_eventgrid_system_topic_event_subscription.rotation : key => value.id }
}
output "created_system_topic_ids" {
  value = { for key, value in azurerm_eventgrid_system_topic.vault : key => value.id }
}
