output "ids" {
  description = "Management lock IDs keyed by input key."
  value       = { for key, lock in azurerm_management_lock.this : key => lock.id }
}

output "names" {
  description = "Management lock names keyed by input key."
  value       = { for key, lock in azurerm_management_lock.this : key => lock.name }
}

output "locks" {
  description = "Management lock attributes keyed by input key."
  value = {
    for key, lock in azurerm_management_lock.this : key => {
      id         = lock.id
      name       = lock.name
      scope      = lock.scope
      lock_level = lock.lock_level
      notes      = lock.notes
    }
  }
}
