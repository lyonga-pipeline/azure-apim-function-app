output "id" { value = azurerm_lb.this.id }
output "backend_pool_ids" {
  value = { for key, value in azurerm_lb_backend_address_pool.this : key => value.id }
}
