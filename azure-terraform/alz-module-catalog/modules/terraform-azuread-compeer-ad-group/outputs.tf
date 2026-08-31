output "id" {
  description = "Resource ID of the group."
  value       = azuread_group.ad_group.id
}

output "object_id" {
  description = "Object ID of the group."
  value       = azuread_group.ad_group.object_id
}

output "display_name" {
  description = "Display name of the group."
  value       = azuread_group.ad_group.display_name
}
