output "ids" {
  description = "Management lock IDs keyed by input key."
  value       = { for key, lock in azurerm_management_lock.resource_lock : key => lock.id }
}

output "names" {
  description = "Management lock names keyed by input key."
  value       = { for key, lock in azurerm_management_lock.resource_lock : key => lock.name }
}

output "locks" {
  description = "Management lock attributes keyed by input key."
  value = {
    for key, lock in azurerm_management_lock.resource_lock : key => {
      id         = lock.id
      name       = lock.name
      scope      = lock.scope
      lock_level = lock.lock_level
      notes      = lock.notes
    }
  }
}
