output "id" { value = azurerm_static_web_app_custom_domain.this.id }
output "domain_name" { value = azurerm_static_web_app_custom_domain.this.domain_name }
output "validation_token" {
  value     = azurerm_static_web_app_custom_domain.this.validation_token
  sensitive = true
}
