removed {
  from = azurerm_resource_provider_registration.required

  lifecycle {
    destroy = false
  }
}
