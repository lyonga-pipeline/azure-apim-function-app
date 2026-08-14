output "ids" {
  description = "Management lock IDs keyed by input key."
  value       = { for key, lock in azurerm_management_lock.this : key => lock.id }
}
